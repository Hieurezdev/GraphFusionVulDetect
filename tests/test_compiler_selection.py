import json
from types import SimpleNamespace

import pytest

from src.services.solidity_validation import CompilerSelectionError, select_compiler, validate_solidity


@pytest.mark.parametrize("constraint,expected", [
    ("^0.4.13", "0.4.24"),
    ("^0.8.19", "0.8.20"),
    (">= 0.8.0 < 0.9.0", "0.8.20"),
    ("=0.8.0", "0.8.0"),
    ("~0.8.0", "0.8.20"),
    ("0.8.0 || ^0.4.13", "0.8.0"),
])
def test_selects_compatible_compiler_instead_of_exact_first_number(constraint, expected):
    compiler, warnings = select_compiler(f"pragma solidity {constraint}; contract Example {{}}")
    assert compiler == expected and not warnings


def test_multiple_pragmas_are_intersected():
    assert select_compiler("pragma solidity ^0.8.0; pragma solidity <0.8.1;")[0] == "0.8.0"
    with pytest.raises(CompilerSelectionError):
        select_compiler("pragma solidity ^0.8.0; pragma solidity ^0.4.13;")


def test_comments_and_strings_cannot_change_compiler_selection():
    code = '''// pragma solidity ^0.5.0;
    /* pragma solidity ^0.6.0; */
    pragma solidity ^0.4.13;
    contract Example { string constant example = "pragma solidity ^0.8.20;"; }
    '''
    assert select_compiler(code)[0] == "0.4.24"


@pytest.mark.parametrize("code", ["pragma solidity 0.4.13;", "pragma solidity ^0.8.25;", "pragma solidity invalid;", "contract Example {}"])
def test_missing_or_incompatible_constraints_do_not_choose_arbitrary_version(code):
    with pytest.raises(CompilerSelectionError):
        select_compiler(code)


def test_omitted_proposal_pragma_uses_original_without_rewriting_code(monkeypatch):
    from src.services import solidity_validation as module
    calls = []
    monkeypatch.setattr(module.shutil, "which", lambda name: "/fake/docker")

    def run(command, **kwargs):
        calls.append((command, kwargs))
        return SimpleNamespace(returncode=0, stdout='{"contracts":{"Contract.sol":{"Example":{}}}}')

    monkeypatch.setattr(module.subprocess, "run", run)
    proposal = "contract Example { uint256 public value; }"
    result = validate_solidity(proposal, "pragma solidity ^0.4.13; contract Example {}")
    assert result.status == "passed" and result.compiler == "0.4.24"
    assert any("original source pragma" in warning for warning in result.warnings)
    assert json.loads(calls[0][1]["input"])["sources"]["Contract.sol"]["content"] == proposal


def test_explicit_proposal_version_takes_precedence_and_is_disclosed():
    compiler, warnings = select_compiler("pragma solidity ^0.8.19; contract Example {}", "pragma solidity ^0.4.13; contract Example {}")
    assert compiler == "0.8.20" and any("differs" in item for item in warnings)


def test_diagnostics_use_utf8_offsets_and_utf16_editor_columns(monkeypatch):
    from src.services import solidity_validation as module
    code = 'pragma solidity ^0.8.20;\ncontract Demo { /* 😀 tên */ BROKEN }'
    start = code.encode().index(b'BROKEN')
    position = module.diagnostic_location(code, start, start + len(b'BROKEN'))
    prefix = code.split('\n')[1].split('BROKEN')[0]
    assert position == {'start_line': 2, 'start_column': len(prefix.encode('utf-16-le')) // 2 + 1,
                        'end_line': 2, 'end_column': len(prefix.encode('utf-16-le')) // 2 + 7}
    monkeypatch.setattr(module.shutil, 'which', lambda name: '/fake/docker')
    output = {'errors': [{'severity': 'error', 'message': 'Expected declaration', 'sourceLocation': {'file': 'Contract.sol', 'start': start, 'end': start + 6}}]}
    monkeypatch.setattr(module.subprocess, 'run', lambda *args, **kwargs: SimpleNamespace(returncode=0, stdout=json.dumps(output)))
    result = module.validate_solidity(code)
    assert result.status == 'failed' and result.diagnostics[0].source_file == 'Contract.sol'
    assert result.diagnostics[0].start_line == 2 and result.diagnostics[0].start_column == position['start_column']


@pytest.mark.parametrize("code", [
    'import "/etc/passwd"; contract Demo {}',
    'import {Demo} from "../private.sol";',
    "import * as Demo from 'https://example.org/remote.sol';",
    'import "\\x43ontract.sol";',
])
def test_native_compiler_rejects_external_imports(code):
    from src.services.solidity_validation import check_imports
    with pytest.raises(ValueError, match="External imports"):
        check_imports(code, {"Contract.sol", "Tests.sol"})


def test_native_import_check_ignores_comments_and_strings():
    from src.services.solidity_validation import check_imports
    check_imports('/* import "private.sol"; */ import "Contract.sol"; // import "other.sol"\ncontract Demo { string value = "import"; }', {"Contract.sol"})


def test_native_compiler_receives_no_provider_credentials(monkeypatch, tmp_path):
    from src.services import solidity_validation as module
    version = tmp_path / 'ge-sc-artifacts/solc-0.8.20'
    version.mkdir(parents=True)
    (version / 'solc-0.8.20').touch()
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv('SOLIDITY_NATIVE', '1')
    monkeypatch.setenv('GEMINI_API_KEY1', 'private-test-value')
    calls = []

    def run(command, **kwargs):
        calls.append((command, kwargs))
        return SimpleNamespace(returncode=0, stdout='{"contracts":{"Contract.sol":{"Demo":{}}}}')

    monkeypatch.setattr(module.subprocess, 'run', run)
    result = validate_solidity('pragma solidity ^0.8.20; contract Demo {}')
    assert result.status == 'passed'
    command, options = calls[0]
    assert command[0] == 'prlimit' and command[-1] == '--standard-json'
    assert 'GEMINI_API_KEY1' not in options['env']
    assert options['cwd'] != str(tmp_path)
