import os
import pytest
from src.workflows.gfd_workflow.utils.fix_check import check_fix, line_range

SRC = "pragma solidity ^0.4.24;\n// Ghi chú tiếng Việt\ncontract C {\n    uint x;\n    function f() public { x = 1; }\n}\n"


def span_of_f():
    data = SRC.encode()
    start = data.index(b"function f")
    return [start, data.index(b"}", start) + 1 - start]


def test_line_range_uses_byte_offsets():
    start, length = span_of_f()
    assert list(line_range(SRC.encode(), start, length)) == [5]


@pytest.mark.skipif(not os.path.exists("ge-sc-artifacts/solc-0.4.24"), reason="needs the solc binaries from the Docker image")
def test_check_fix_compiles_good_and_rejects_broken(tmp_path):
    path = tmp_path / "c.sol"
    path.write_text(SRC, encoding="utf-8")
    good = check_fix(str(path), span_of_f(), "function f() public { x = 2; }")
    assert good["compiled"] and good["patched_lines"] == [5, 5]
    bad = check_fix(str(path), span_of_f(), "function f() public { x = 2 }")
    assert not bad["compiled"] and "Error" in bad["compiler_output"]


@pytest.mark.skipif(not os.path.exists("ge-sc-artifacts/solc-0.8.20"), reason="needs the solc binaries from the Docker image")
def test_fix_that_upgrades_solidity_scans_each_side_with_its_own_solc(tmp_path):
    # Regression: a 0.8 rewrite of a 0.4 contract made Slither compile the 0.4 original with solc 0.8 and crash.
    path = tmp_path / "c.sol"
    path.write_text(SRC, encoding="utf-8")
    upgraded = "pragma solidity ^0.8.20;\ncontract C {\n    uint x;\n    function f() public { x = 1; }\n}\n"
    res = check_fix(str(path), None, upgraded)
    assert res["compiled"] and res["solc_version"] == "0.8.20" and res["original_solc_version"] == "0.4.24"
    assert res["slither_error"] is None
