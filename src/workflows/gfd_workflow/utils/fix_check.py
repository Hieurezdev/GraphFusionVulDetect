"""Check a proposed fix against the real contract: splice it in, compile with the pragma's solc, re-run Slither."""

import inspect
import os
import re
import subprocess
import tempfile
from pathlib import Path

ARTIFACTS = "ge-sc-artifacts"
DEFAULT_SOLC = "0.4.24"  # same fallback as graph_converter.get_call_graph
WHOLE_FILE = re.compile(r"^\s*(pragma\s+solidity|contract|library|interface)\b", re.M)


def solc_for(source: str) -> str:
    """Path of the solc matching the first pragma version, falling back like graph_converter does."""
    m = re.search(r"pragma solidity[^;]*?(\d+\.\d+\.\d+)", source)
    version = m.group(1) if m else DEFAULT_SOLC
    path = f"{ARTIFACTS}/solc-{version}/solc-{version}"
    # Absolute: solc runs from a temp dir.
    return os.path.abspath(path if os.path.exists(path) else f"{ARTIFACTS}/solc-{DEFAULT_SOLC}/solc-{DEFAULT_SOLC}")


def line_range(source: bytes, start: int, length: int) -> range:
    return range(source[:start].count(b"\n") + 1, source[:start + length].count(b"\n") + 2)


def slither_findings(path: str, solc: str, lines: range) -> list:
    """Slither detector results that touch the given lines."""
    from slither.slither import Slither
    from slither.detectors import all_detectors
    from slither.detectors.abstract_detector import AbstractDetector

    slither = Slither(path, solc=solc)
    for detector in vars(all_detectors).values():
        if inspect.isclass(detector) and issubclass(detector, AbstractDetector):
            slither.register_detector(detector)

    findings, seen = [], set()
    for results in slither.run_detectors():
        for r in results:
            hit = sorted({l for e in r.get("elements", []) for l in e.get("source_mapping", {}).get("lines", [])} & set(lines))
            key = (r["check"], r["description"])
            if hit and key not in seen:
                seen.add(key)
                findings.append({"check": r["check"], "impact": r["impact"], "confidence": r["confidence"],
                                 "description": r["description"].strip(), "lines": hit})
    return findings


def check_fix(source_path: str, span: list, new_code: str) -> dict:
    """Compile the contract with `new_code` replacing the byte span (or the whole file if it is one)."""
    original = Path(source_path).read_bytes()
    new = new_code.strip().encode("utf-8")
    if WHOLE_FILE.search(new_code):
        patched, old_lines, new_lines = new, range(1, original.count(b"\n") + 2), range(1, new.count(b"\n") + 2)
    else:
        start, length = span
        patched = original[:start] + new + original[start + length:]
        old_lines, new_lines = line_range(original, start, length), line_range(patched, start, len(new))

    # Each side gets the solc its own pragma asks for: a fix may move the contract to a newer Solidity.
    solc = solc_for(patched.decode("utf-8", "replace"))
    original_solc = solc_for(original.decode("utf-8", "replace"))
    slither_errors = []

    def findings(path: str, compiler: str, lines: range, label: str) -> list:
        try:
            return slither_findings(path, compiler, lines)
        except Exception as e:  # a Slither crash must not hide the compile result
            slither_errors.append(f"{label}: {str(e).strip()[:500]}")
            return []

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / Path(source_path).name
        path.write_bytes(patched)
        run = subprocess.run([solc, str(path)], capture_output=True, text=True, timeout=120, cwd=tmp)
        compiled = run.returncode == 0
        compiler_output = (run.stderr + run.stdout).replace(str(path), path.name).strip()[:4000]
        before = findings(source_path, original_solc, old_lines, "Slither on the original")
        after = findings(str(path), solc, new_lines, "Slither on the fix") if compiled else []

    return {
        "compiled": compiled,
        "solc_version": Path(solc).name.removeprefix("solc-"),
        "original_solc_version": Path(original_solc).name.removeprefix("solc-"),
        "compiler_output": compiler_output,
        "findings_before": before,
        "findings_after": after,
        "slither_error": "\n".join(slither_errors) or None,
        "patched_lines": [new_lines.start, new_lines.stop - 1],
    }
