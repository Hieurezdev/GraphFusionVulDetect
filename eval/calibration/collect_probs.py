"""Contract-level P(vulnerable) of the deployed models on the test sets, computed on this machine (step 1.7).

Runs the product's own graph builder and contract-level GNN (no LLM) on every test contract of the full dataset and
writes one JSON line per contract: file, label, p_vul, raw logits. The logits allow refitting a temperature later.
Usage: uv run python eval/calibration/collect_probs.py [timestamp|reentrancy ...]
"""
import json
import sys
import tempfile
import time
from pathlib import Path

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
import dgl  # noqa: E402
import torch  # noqa: E402
import torch.nn.functional as F  # noqa: E402

from src.workflows.gfd_workflow.workflow import gfd_workflow  # noqa: E402
from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
DATA = REPO / "assets/datasets/full/SourceCodeSyntaxDataset"
FOLDER = {"timestamp": "TimestampDependencyDataset", "reentrancy": "ReentrancyDataset"}
OUT = REPO / "eval/calibration"


def logits_of(model, fcg_path):
    graph = dgl.load_graphs(fcg_path)[0][0]
    graph.ndata["features"] = graph.ndata["featuresH"]
    graph = dgl.add_self_loop(graph)
    with torch.no_grad():
        return model(dgl.batch([graph]).to(model.device), graph.ndata["features"].to(model.device))[0]


def main(vulns):
    gfd_workflow.initialize()
    for vuln in vulns:
        models = gfd_workflow.models[vuln]
        cfg = {"configurable": {**models, "llm": None}}
        files = sorted((DATA / FOLDER[vuln] / "Test").rglob("*.sol"))
        out = OUT / f"probs_{vuln}_test.jsonl"
        t0, done = time.time(), 0
        with open(out, "w", encoding="utf-8") as f:
            for path in files:
                label = 0 if "NonVulnerable" in path.parts else 1
                row = {"file": str(path.relative_to(DATA)).replace("\\", "/"), "label": label}
                try:
                    state = convert_to_fcg({"sol_file_path": str(path), "fcg_save_dir": tempfile.mkdtemp(), "vulnerability": vuln}, cfg)
                    fcg = state.get("fcg_file_path", "")
                    if not str(fcg).endswith(".fcg"):
                        raise RuntimeError("no graph")
                    z = logits_of(models["graph_vul_model"], fcg)
                    row.update(status="ok", logits=[round(float(v), 6) for v in z], p_vul=round(float(F.softmax(z, 0)[1]), 6),
                               model_version=gfd_workflow.versions[vuln])
                except Exception as e:  # a contract that does not compile is reported, not fatal
                    row.update(status="no_graph", error=str(e)[:200])
                f.write(json.dumps(row) + "\n")
                done += 1
                if done % 25 == 0:
                    print(f"{vuln}: {done}/{len(files)} ({time.time() - t0:.0f}s)", flush=True)
        print(f"{vuln}: wrote {out} in {time.time() - t0:.0f}s", flush=True)


if __name__ == "__main__":
    main(sys.argv[1:] or ["timestamp", "reentrancy"])
