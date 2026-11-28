"""Build the product's call graphs for a dataset split once, for retraining and gating (step 1.9).

Graphs go to eval/retrain/graphs/<vuln>/<split>/<Vulnerable|NonVulnerable>/<name>.fcg with an index.jsonl
(file, label, sha256 of the file, graph path, status). Uses the same convert_to_fcg as /analyze, so a model trained on
these graphs sees exactly what the product feeds it. Existing graphs are kept (re-run = resume).
Usage: uv run python scripts/build_graphs.py timestamp Train Test
"""
import hashlib
import json
import sys
import time
from pathlib import Path

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
from src.workflows.gfd_workflow.workflow import gfd_workflow  # noqa: E402
from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg  # noqa: E402

REPO = Path(__file__).resolve().parents[1]
DATA = REPO / "assets/datasets/full/SourceCodeSyntaxDataset"
FOLDER = {"timestamp": "TimestampDependencyDataset", "reentrancy": "ReentrancyDataset"}
GRAPHS = REPO / "eval/retrain/graphs"


def main(vuln, splits):
    gfd_workflow.initialize()
    cfg = {"configurable": {**gfd_workflow.models[vuln], "llm": None}}
    for split in splits:
        out_dir = GRAPHS / vuln / split
        out_dir.mkdir(parents=True, exist_ok=True)
        index_path = out_dir / "index.jsonl"
        done = {}
        if index_path.exists():
            for line in open(index_path, encoding="utf-8"):
                r = json.loads(line)
                done[r["file"]] = r
        files = sorted((DATA / FOLDER[vuln] / split).rglob("*.sol"))
        t0 = time.time()
        with open(index_path, "a", encoding="utf-8") as idx:
            for n, path in enumerate(files, 1):
                rel = str(path.relative_to(DATA / FOLDER[vuln])).replace("\\", "/")
                if rel in done:
                    continue
                label = 0 if "NonVulnerable" in path.parts else 1
                row = {"file": rel, "label": label, "file_hash": hashlib.sha256(path.read_bytes()).hexdigest()}
                try:
                    save = out_dir / ("NonVulnerable" if label == 0 else "Vulnerable")
                    state = convert_to_fcg({"sol_file_path": str(path), "fcg_save_dir": str(save), "vulnerability": vuln}, cfg)
                    fcg = str(state.get("fcg_file_path", ""))
                    if not fcg.endswith(".fcg"):
                        raise RuntimeError("no graph")
                    row.update(status="ok", graph=str(Path(fcg).relative_to(REPO)).replace("\\", "/"))
                except Exception as e:  # a contract that does not compile is recorded and skipped
                    row.update(status="no_graph", error=str(e)[:200])
                idx.write(json.dumps(row) + "\n")
                idx.flush()
                if n % 50 == 0:
                    print(f"{vuln}/{split}: {n}/{len(files)} ({time.time() - t0:.0f}s)", flush=True)
        print(f"{vuln}/{split}: done in {time.time() - t0:.0f}s", flush=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:] or ["Train", "Test"])
