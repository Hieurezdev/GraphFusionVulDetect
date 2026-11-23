"""Compile reviewed Solidity with fixed native or isolated Docker compilers."""

import json
import hashlib
import re
import shutil
import subprocess
import uuid
import os
import tempfile
from pathlib import Path

from semantic_version import NpmSpec, Version

from src.models.ai_safety import CompilerDiagnostic, VerificationResult
from src.services.evm_tests import TestArtifact, execute_tests

SUPPORTED_COMPILERS = {"0.4.24", "0.8.0", "0.8.20"}
_NON_CODE = re.compile(r"""//[^\r\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'""", re.DOTALL)


class CompilerSelectionError(ValueError):
    """No configured compiler can satisfy the source's declared constraints."""


def check_imports(code: str, allowed: set[str]) -> None:
    """Reject filesystem imports before invoking a compiler in the app container."""
    tokens = re.findall(r'''//[^\r\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[A-Za-z_$][\w$]*|[^\s]''', code, re.DOTALL)
    importing = False
    for token in tokens:
        if token.startswith(("//", "/*")):
            continue
        if token == "import":
            importing = True
        elif importing and token.startswith(('"', "'")):
            if token[1:-1] not in allowed:
                raise ValueError("External imports are unsupported. Supply a standalone contract; tests may import Contract.sol.")
        elif token == ";":
            importing = False


def _constraints(code: str) -> list[str]:
    cleaned = _NON_CODE.sub(" ", code)
    expressions = re.findall(r"\bpragma\s+solidity\b\s*([^;]+);", cleaned)
    return [re.sub(r"([~^<>=]+)\s+(?=\d)", r"\1", " ".join(expression.split())) for expression in expressions]


def select_compiler(code: str, original_code: str | None = None) -> tuple[str, list[str]]:
    constraints = _constraints(code)
    original_constraints = _constraints(original_code or "")
    warnings: list[str] = []
    if not constraints:
        constraints = original_constraints
        if constraints:
            warnings.append("The proposal has no Solidity pragma. The compiler was selected using the original source pragma without changing the proposed code.")
    elif original_constraints and constraints != original_constraints:
        warnings.append("The proposed Solidity pragma differs from the original source. Review the compiler-version change before applying.")
    if not constraints:
        raise CompilerSelectionError("No Solidity version pragma was found in the proposal or original source. Add an explicit pragma before compiling.")
    try:
        specifications = [NpmSpec(expression) for expression in constraints]
    except ValueError as error:
        raise CompilerSelectionError("The Solidity version pragma is invalid or unsupported. Correct the version constraint before compiling.") from error
    matches = [Version(version) for version in SUPPORTED_COMPILERS if all(spec.match(Version(version)) for spec in specifications)]
    if not matches:
        raise CompilerSelectionError("No configured compiler satisfies all Solidity pragma constraints. Available versions: 0.4.24, 0.8.0, 0.8.20.")
    return str(max(matches)), warnings


def diagnostic_location(code: str, start: int, end: int) -> dict[str, int]:
    """Translate Solidity UTF-8 offsets into Monaco's one-based UTF-16 columns."""
    source = code.encode("utf-8")
    if start < 0 or end < start or end > len(source):
        return {}
    before, through = source[:start], source[:end]
    start_text = before.rsplit(b"\n", 1)[-1].decode("utf-8")
    end_text = through.rsplit(b"\n", 1)[-1].decode("utf-8")
    return {"start_line": before.count(b"\n") + 1, "start_column": len(start_text.encode("utf-16-le")) // 2 + 1,
            "end_line": through.count(b"\n") + 1, "end_column": len(end_text.encode("utf-16-le")) // 2 + 1}


def validate_solidity(code: str, original_code: str | None = None, test_source: str | None = None) -> VerificationResult:
    result = _compile_solidity(code, original_code, test_source)
    result.source_sha256 = hashlib.sha256(code.encode("utf-8")).hexdigest()
    if test_source:
        result.tests.test_source_sha256 = hashlib.sha256(test_source.encode("utf-8")).hexdigest()
    return result


def _compile_solidity(code: str, original_code: str | None, test_source: str | None) -> VerificationResult:
    if not code.strip():
        return VerificationResult(status="not_run", message="No suggested code was produced.")
    if not re.search(r"\b(contract|library|interface)\s+\w+", _NON_CODE.sub(" ", code)):
        return VerificationResult(status="not_run", message="A function fragment cannot be compiled independently. Provide the full contract and dependencies.")
    try:
        version, selection_warnings = select_compiler(code, original_code)
    except CompilerSelectionError as error:
        return VerificationResult(status="not_run", message=str(error))
    native = Path(f"ge-sc-artifacts/solc-{version}/solc-{version}").resolve()
    # Host development uses Docker wrappers; only the image enables native execution.
    use_native = os.environ.get("SOLIDITY_NATIVE") == "1"
    docker = shutil.which("docker")
    if not use_native and docker is None:
        return VerificationResult(status="not_run", message="Docker is unavailable; compilation was not performed.", compiler=version, warnings=selection_warnings)
    name = "graphfusion-check-" + uuid.uuid4().hex
    command = [docker, "run", "--rm", "--interactive", "--pull=never", "--name", name,
               "--platform", "linux/amd64", "--network", "none", "--read-only",
               "--memory", "256m", "--cpus", "1", "--pids-limit", "64",
               "--cap-drop", "ALL", "--security-opt", "no-new-privileges",
               "ethereum/solc:" + version, "--standard-json"]
    compiler_input = {"language": "Solidity", "sources": {"Contract.sol": {"content": code}},
                      "settings": {"outputSelection": {"*": {"*": ["abi", "evm.bytecode.object"]}}}}
    if test_source:
        compiler_input["sources"]["Tests.sol"] = {"content": test_source}
    compiler_env: dict[str, str] | None = None
    if use_native:
        if not native.is_file():
            return VerificationResult(status="not_run", message="The packaged Solidity compiler is missing. Rebuild the backend image.", compiler=version)
        try:
            check_imports(code, {"Contract.sol", "Tests.sol"})
            if test_source:
                check_imports(test_source, {"Contract.sol", "Tests.sol"})
        except ValueError as error:
            return VerificationResult(status="failed", message=str(error), compiler=version)
        command = ["prlimit", "--as=536870912", "--cpu=25", "--", str(native), "--standard-json"]
        compiler_env = {"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8"}
    try:
        with tempfile.TemporaryDirectory(prefix="graphfusion-compile-") as directory:
            result = subprocess.run(command, input=json.dumps(compiler_input), text=True, capture_output=True, timeout=25, check=False, cwd=directory, env=compiler_env)
    except subprocess.TimeoutExpired:
        if not use_native:
            subprocess.run([docker, "rm", "--force", name], capture_output=True, timeout=5, check=False)
        return VerificationResult(status="failed", message="Compilation exceeded the 25-second limit.", compiler=version, warnings=selection_warnings)
    if result.returncode != 0:
        return VerificationResult(status="not_run", message="The configured compiler could not run. Check the compiler installation and resource limits.", compiler=version, warnings=selection_warnings)
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError:
        return VerificationResult(status="failed", message="The compiler returned an invalid response.", compiler=version, warnings=selection_warnings)
    errors = output.get("errors", [])
    diagnostics = []
    for item in errors[:50]:
        location = item.get("sourceLocation") or {}
        filename = location.get("file")
        positions = {}
        if filename in compiler_input["sources"]:
            positions = diagnostic_location(compiler_input["sources"][filename]["content"], location.get("start", -1), location.get("end", -1))
        diagnostics.append(CompilerDiagnostic(severity=item.get("severity", "error"), message=item.get("message", "Compiler diagnostic")[:2000], source_file=filename, **positions))
    failures = [item.get("message", "Compiler error")[:500] for item in errors if item.get("severity") == "error"]
    warnings = selection_warnings + [item.get("message", "Compiler warning")[:500] for item in errors if item.get("severity") == "warning"]
    if failures:
        return VerificationResult(status="failed", message="\n".join(failures[:5]), compiler=version, warnings=warnings[:5], diagnostics=diagnostics)
    if not output.get("contracts"):
        return VerificationResult(status="failed", message="The compiler produced no contract artifacts.", compiler=version)
    result = VerificationResult(status="passed", message="Compilation passed. This does not prove security.", compiler=version, warnings=warnings[:5], diagnostics=diagnostics)
    if test_source:
        artifacts = []
        for name, artifact in output["contracts"].get("Tests.sol", {}).items():
            abi = artifact.get("abi", [])
            functions = [entry["name"] for entry in abi if entry.get("type") == "function" and entry.get("name", "").startswith("test") and not entry.get("inputs") and not entry.get("outputs")]
            if not functions:
                continue
            bytecode = artifact.get("evm", {}).get("bytecode", {}).get("object", "")
            if not bytecode or not re.fullmatch(r"[0-9a-fA-F]+", bytecode):
                result.tests.message = "A test contract is abstract or requires linked libraries. Supply deployable test contracts."
                return result
            if len(functions) > 20 or any(entry.get("type") == "constructor" and entry.get("inputs") for entry in abi):
                result.tests.message = "Test contracts require a zero-argument constructor and at most 20 test functions."
                return result
            setup = any(entry.get("type") == "function" and entry.get("name") == "setUp" and not entry.get("inputs") and not entry.get("outputs") for entry in abi)
            artifacts.append(TestArtifact(name=name, bytecode=bytecode, functions=functions, setup=setup))
        result.tests = execute_tests(artifacts)
    return result
