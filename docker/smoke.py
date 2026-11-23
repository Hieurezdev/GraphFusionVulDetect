"""Exercise packaged compilers, local EVM and trained detector without external AI."""

import tempfile
from pathlib import Path

from src.services.solidity_validation import validate_solidity
from src.workflows.gfd_workflow.workflow import GFDWorkflow


for version in ("0.4.24", "0.8.0", "0.8.20"):
    report = validate_solidity(f"pragma solidity {version}; contract Demo {{}}")
    assert report.status == "passed", report.model_dump()
    broken = validate_solidity(f"pragma solidity {version}; contract Demo {{ BROKEN }}")
    assert broken.status == "failed", broken.model_dump()
    assert broken.diagnostics

source = "pragma solidity 0.8.20; contract Demo { function value() external pure returns(uint) { return 2; } }"
for expected, status in ((2, "passed"), (3, "failed")):
    tests = ('pragma solidity 0.8.20; import "Contract.sol"; contract Checks { '
             'function testValue() public { Demo demo = new Demo(); require(demo.value() == '
             + str(expected) + '); } }')
    report = validate_solidity(source, source, tests)
    assert report.status == "passed" and report.tests.status == status, report.model_dump()

blocked = validate_solidity('pragma solidity 0.8.20; import "/etc/passwd"; contract Demo {}')
assert blocked.status == "failed" and "External imports" in blocked.message

workflow = GFDWorkflow()
workflow._load_embedding_model()
workflow._load_graph_model()
workflow._load_node_model()
pipeline = workflow.build_pipeline()
config = {"configurable": {"embedd_tokenizer": workflow.embedd_tokenizer, "embedd_model": workflow.embedd_model,
                           "graph_vul_model": workflow.graph_vul_model, "node_vul_model": workflow.node_vul_model, "llm": None}}
with tempfile.TemporaryDirectory(dir="storage", prefix="smoke-") as directory:
    contract = Path(directory) / "Probe.sol"
    contract.write_text('pragma solidity 0.4.24; contract Probe { function draw() public view returns(bool) { return block.timestamp % 2 == 0; } }')
    state = pipeline.invoke({"sol_file_path": str(contract), "fcg_save_dir": str(Path(directory) / "fcg"), "language": "en"}, config)
    assert state["predicted_class"] in {"Vulnerable", "Non-Vulnerable"}
    assert Path(state["mapping_file_path"]).is_file()
print("PASS: all fixed compilers, syntax diagnostics, passing/failing EVM assertions, import rejection and trained detector inference")
