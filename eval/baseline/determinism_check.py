"""Does one contract get the same verdict in two fresh processes? (found while checking the caches of step 1.5)

Runs the detection pipeline (no LLM) on one contract and prints the contract-level confidence per vulnerability plus a
fingerprint of the graph that was built. Run it twice with different PYTHONHASHSEED values and compare.
Usage: EMBEDDING_CACHE=false PYTHONHASHSEED=1 uv run python eval/baseline/determinism_check.py <file.sol>
"""
import hashlib
import json
import os
import sys
import tempfile

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
import dgl  # noqa: E402

from src.workflows.gfd_workflow.workflow import gfd_workflow  # noqa: E402
from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg  # noqa: E402
from src.workflows.gfd_workflow.nodes.src_vul_detector import detect_vulnerability_src  # noqa: E402

path = sys.argv[1]
gfd_workflow.initialize()
gfd_workflow.llm = None
out = {"hashseed": os.environ.get("PYTHONHASHSEED")}
for vuln, models in gfd_workflow.models.items():
    cfg = {"configurable": {**models, "llm": None}}
    state = {"sol_file_path": path, "fcg_save_dir": tempfile.mkdtemp(), "vulnerability": vuln, "language": "en"}
    state = convert_to_fcg(state, cfg)
    g = dgl.load_graphs(state["fcg_file_path"])[0][0]
    src, dst = g.edges()
    fp = hashlib.sha256(json.dumps([sorted(zip(src.tolist(), dst.tolist())), g.ndata["features"].round(decimals=6).tolist()]).encode()).hexdigest()[:12]
    state = detect_vulnerability_src(state, cfg)
    out[vuln] = {"class": state["predicted_class"], "confidence": round(state["confidence_score"], 6),
                 "nodes": g.num_nodes(), "edges": g.num_edges(), "graph_fingerprint": fp}
print(json.dumps(out))
