"""Score .sol files offline with the product's own pipeline, for either vulnerability type.

Same steps as /analyze: convert_to_fcg (Slither + solc picked from the pragma + CodeBERT), the contract-level GNN, then the
function-level GNN. The function model is run for every contract and the contract verdict is stored next to it, so a report
can show both what the product would display (functions only when the contract is flagged) and what the gate hides.

docker run --rm --gpus all -v $PWD:/repo:ro -v $PWD/eval/generalization/out:/repo/eval/generalization/out -e PYTHONPATH=/graphfusion \
  -w /graphfusion --entrypoint .venv/bin/python scanguard-backend /repo/eval/generalization/score.py <timestamp|reentrancy> <list.txt> <out.jsonl>
list.txt: one path per line, relative to the repo root.
"""
import hashlib, importlib.util, json, os, signal, sys, tempfile, time
from pathlib import Path

import dgl
import torch
from transformers import RobertaModel, RobertaTokenizer

from src.infrastructure.analysis_model.NodeDetector import NodeClassifierGNN
from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg

REPO = Path("/repo")
M = REPO / "src/infrastructure/analysis_model"
SPECS = {
    "timestamp": dict(encoder="Quangnguyen711/codebert-solidity-time-dep", graph=M / "best_model_GCN_2L_max.pt", node=M / "best_node_classifier_model.pt",
                      arch=dict(mtype=["GCN"], n_gph=0, num_query_vectors=2)),
    "reentrancy": dict(encoder="Quangnguyen711/codebert-solidity-re-entrancy", graph=M / "best_model_GAT_2L_max_reentrancy.pt",
                       node=M / "best_node_classifier_model_reentrancy.pt", arch=dict(mtype=["GAT"], n_gph=2, num_query_vectors=1)),
}


class Timeout(Exception):
    pass


def _alarm(*_):
    raise Timeout()


def main(vuln, list_file, out_file):
    spec = SPECS[vuln]
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    if dev == "cuda":
        try:
            hold = torch.empty(2 << 30, dtype=torch.uint8, device="cuda"); del hold   # stays reserved on a shared GPU
        except torch.OutOfMemoryError:
            dev = "cpu"   # GPU taken by other jobs: slower, same results
    print("encoder on", dev, flush=True)
    tok = RobertaTokenizer.from_pretrained(spec["encoder"])
    enc = RobertaModel.from_pretrained(spec["encoder"]).eval()
    cfg_cpu = {"configurable": {"embedd_tokenizer": tok, "embedd_model": enc}}
    cfg = {"configurable": {"embedd_tokenizer": tok, "embedd_model": RobertaModel.from_pretrained(spec["encoder"]).to(dev).eval()}} if dev == "cuda" else cfg_cpu
    # GraphClasifier from the working tree: the copy inside the image cannot run n_gph > 0.
    ms = importlib.util.spec_from_file_location("GraphClasifier", M / "GraphClasifier.py")
    mod = importlib.util.module_from_spec(ms); ms.loader.exec_module(mod)
    gm = mod.GraphNN(infeats=768, hfeats=[2048, 2048], fc1_layer=256, fc2_layer=64, outclass=2, gptype="max", ginfeat=1024, **spec["arch"])
    gm.load_state_dict(torch.load(spec["graph"], map_location="cpu")); gm.eval()
    nm = NodeClassifierGNN(mtype=["GAT", ""], infeats=768, hfeats=[256, 128], fc1_layer=256, fc2_layer=64, outclass=2, ginfeat=1024)
    nm.load_state_dict(torch.load(spec["node"], map_location="cpu")); nm.eval()

    out = REPO / out_file
    out.parent.mkdir(parents=True, exist_ok=True)
    done = {json.loads(l)["file"] for l in out.read_text().splitlines()} if out.exists() else set()
    signal.signal(signal.SIGALRM, _alarm)
    with out.open("a") as fh:
        for rel in (REPO / list_file).read_text().split("\n"):
            if not rel or rel in done:
                continue
            sol = REPO / rel
            row = {"file": rel, "lines": sol.read_bytes().count(b"\n") + 1, "status": "ok"}
            t0 = time.time()
            signal.alarm(600)
            try:
                with tempfile.TemporaryDirectory() as tmp:
                    st = convert_to_fcg({"sol_file_path": str(sol), "fcg_save_dir": tmp}, cfg)
                    if cfg is not cfg_cpu and not str(st.get("fcg_file_path", "")).endswith(".fcg"):
                        # convert_to_fcg reports a CUDA out-of-memory on a shared GPU as "no graph": ask again on CPU before believing it
                        torch.cuda.empty_cache()
                        st = convert_to_fcg({"sol_file_path": str(sol), "fcg_save_dir": tmp}, cfg_cpu)
                    if not str(st.get("fcg_file_path", "")).endswith(".fcg"):
                        row["status"] = "no_graph"
                    else:
                        g = dgl.load_graphs(st["fcg_file_path"])[0][0]
                        m = json.load(open(st["mapping_file_path"], encoding="utf-8"))
                if row["status"] == "ok":
                    row["t_graph_embed"] = round(time.time() - t0, 2)
                    t1 = time.time()
                    x = g.ndata["featuresH"].float()
                    h = dgl.add_self_loop(dgl.graph(g.edges(), num_nodes=g.num_nodes()))
                    with torch.no_grad():
                        pc = torch.softmax(gm(dgl.batch([h]), x).reshape(1, -1), 1)[0]
                        pn = torch.softmax(nm(h, x), 1)
                    row.update(t_gnn=round(time.time() - t1, 2), contract_pred=int(pc.argmax()), contract_p=round(float(pc[1]), 4), edges=g.num_edges(), functions=[])
                    for name, i in m["node"].items():
                        code = m["code"].get(name, "")
                        row["functions"].append({"name": name, "lines": m.get("lines", {}).get(name), "pred": int(pn[i].argmax()), "p": round(float(pn[i][1]), 4),
                                                 "md5": hashlib.md5("".join(code.split()).encode()).hexdigest(), "tokens": len(tok(code)["input_ids"])})
            except Timeout:
                row["status"] = "timeout"
            except Exception as e:
                row["status"], row["error"] = "error", str(e)[:200]
            signal.alarm(0)
            row["seconds"] = round(time.time() - t0, 2)
            fh.write(json.dumps(row) + "\n"); fh.flush()
    if os.getuid() == 0:
        s = REPO.stat(); os.chown(out, s.st_uid, s.st_gid)
    rows = [json.loads(l) for l in out.read_text().splitlines()]
    print("@@ scored", vuln, out_file, len(rows), {k: sum(r["status"] == k for r in rows) for k in {r["status"] for r in rows}})


if __name__ == "__main__":
    main(*sys.argv[1:4])
