"""Benchmark + inference-time ablation of the deployed timestamp pipeline. Nothing is trained.

Every variant scores the same contracts on the same machine with the deployed weights:
  full            deployed pipeline: fine-tuned CodeBERT embeddings + call-graph edges + GCN
  no_graph        same embeddings, call-graph edges removed (self-loops only)
  base_encoder    call graph kept, embeddings from microsoft/codebert-base (no vulnerability fine-tuning)
  base_no_graph   both removed
  random_features call graph kept, Gaussian noise as node features (floor)
  slither         Slither's own "timestamp" detector (static-analysis baseline)
  keyword         contract mentions block.timestamp / now (trivial baseline)

docker run --rm --gpus all -v $PWD:/repo:ro -v $PWD/eval/ablation:/out -v <hf cache>:/hf-cache -e HF_HOME=/hf-cache \
  -e PYTHONPATH=/graphfusion -w /graphfusion --entrypoint .venv/bin/python scanguard-backend /out/run_ablation.py
"""
import inspect, json, os, re, resource, signal, subprocess, tempfile, time
from pathlib import Path

import dgl
import numpy as np
import torch
from sklearn.metrics import accuracy_score, f1_score, precision_recall_fscore_support
from transformers import RobertaModel, RobertaTokenizer

from src.infrastructure.analysis_model.GraphClasifier import GraphNN
from src.workflows.gfd_workflow.nodes.fcg_converter.embedding_generator import get_embeddings
from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg
from src.workflows.gfd_workflow.utils.fix_check import solc_for

DATA = Path("/repo/assets/datasets/SourceCodeSyntaxDataset/TimestampDependencyDataset")
OUT = Path("/out")
WEIGHTS = "src/infrastructure/analysis_model/best_model_GCN_2L_max.pt"
ENCODER, BASE = "Quangnguyen711/codebert-solidity-time-dep", "microsoft/codebert-base"
VARIANTS = ["full", "no_graph", "base_encoder", "base_no_graph", "random_features", "slither", "keyword"]
DEV = "cuda" if torch.cuda.is_available() else "cpu"


class Timeout(Exception):
    pass


def _alarm(*_):
    raise Timeout()


def slither_timestamp(path):
    """Number of findings of Slither's timestamp detector, compiled the way the product compiles."""
    from slither.slither import Slither
    from slither.detectors import all_detectors
    det = next(d for d in vars(all_detectors).values() if inspect.isclass(d) and getattr(d, "ARGUMENT", None) == "timestamp")
    try:
        sl = Slither(path, solc=solc_for(Path(path).read_text(errors="replace")))
    except Exception:
        sl = Slither(path, solc=os.path.abspath("ge-sc-artifacts/solc-0.4.24/solc-0.4.24"))
    sl.register_detector(det)
    return sum(len(r) for r in sl.run_detectors())


def main():
    tok, enc = RobertaTokenizer.from_pretrained(ENCODER), RobertaModel.from_pretrained(ENCODER).to(DEV).eval()
    btok, benc = RobertaTokenizer.from_pretrained(BASE), RobertaModel.from_pretrained(BASE).to(DEV).eval()
    gm = GraphNN(mtype=["GCN"], infeats=768, hfeats=[2048, 2048], fc1_layer=256, fc2_layer=64, n_gph=0, outclass=2,
                 gptype="max", ginfeat=1024, num_query_vectors=2)   # same call as workflow._load_graph_model
    gm.load_state_dict(torch.load(WEIGHTS, map_location="cpu")); gm.eval()
    cfg = {"configurable": {"embedd_tokenizer": tok, "embedd_model": enc}}

    def score(g, x):
        with torch.no_grad():
            p = torch.softmax(gm(dgl.batch([dgl.add_self_loop(g)]), x), 1)[0]
        return int(p.argmax()), round(float(p[1]), 4)

    log = OUT / "results.jsonl"
    done = {json.loads(l)["file"] for l in log.read_text().splitlines()} if log.exists() else set()
    signal.signal(signal.SIGALRM, _alarm)
    with log.open("a") as fh:
        for split in ("Test", "Train"):
            for cls, y in (("NonVulnerable", 0), ("Vulnerable", 1)):
                for sol in sorted((DATA / split / cls).glob("*.sol")):
                    key = f"{split}/{cls}/{sol.name}"
                    if key in done:
                        continue
                    src = sol.read_text(errors="replace")
                    row = {"file": key, "split": split, "label": y, "lines": src.count("\n") + 1, "status": "ok", "pred": {}, "p_vul": {}, "t": {}}
                    row["pred"]["keyword"] = int(bool(re.search(r"block\.timestamp|\bnow\b", src)))
                    signal.alarm(300)
                    try:
                        t0 = time.time()
                        try:
                            row["pred"]["slither"] = int(slither_timestamp(str(sol)) > 0)
                        except Timeout:
                            raise
                        except Exception as e:
                            row["slither_error"] = str(e)[:150]
                        row["t"]["slither"] = round(time.time() - t0, 3)

                        with tempfile.TemporaryDirectory() as tmp:
                            t0 = time.time()
                            st = convert_to_fcg({"sol_file_path": str(sol), "fcg_save_dir": tmp}, cfg)   # the product's own step
                            row["t"]["graph_and_embed"] = round(time.time() - t0, 3)
                            if not str(st.get("fcg_file_path", "")).endswith(".fcg"):
                                row["status"] = "no_graph"
                            else:
                                g = dgl.load_graphs(st["fcg_file_path"])[0][0]
                                m = json.load(open(st["mapping_file_path"], encoding="utf-8"))
                                x = g.ndata["featuresH"].float()
                                n = g.num_nodes()
                                bare = dgl.graph(g.edges(), num_nodes=n)
                                empty = dgl.graph(([], []), num_nodes=n)
                                t0 = time.time()
                                xb = torch.zeros(n, 768)
                                for name, i in m["node"].items():
                                    xb[i] = torch.from_numpy(get_embeddings(btok, benc, m["code"].get(name, "")))
                                row["t"]["base_embed"] = round(time.time() - t0, 3)
                                xr = torch.randn(n, 768, generator=torch.Generator().manual_seed(42)) * x.std() + x.mean()
                                t0 = time.time()
                                full = score(bare, x)
                                row["t"]["gnn"] = round(time.time() - t0, 4)
                                for v, (gg, xx) in {"no_graph": (empty, x), "base_encoder": (bare, xb), "base_no_graph": (empty, xb), "random_features": (bare, xr)}.items():
                                    row["pred"][v], row["p_vul"][v] = score(gg, xx)
                                row["pred"]["full"], row["p_vul"]["full"] = full
                                row["functions"], row["edges"] = n, g.num_edges()
                    except Timeout:
                        row["status"] = "timeout"
                    except Exception as e:
                        row["status"], row["error"] = "error", str(e)[:200]
                    signal.alarm(0)
                    fh.write(json.dumps(row) + "\n"); fh.flush()

    rows = [json.loads(l) for l in log.read_text().splitlines()]
    hw = {"gpu": subprocess.run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"], capture_output=True, text=True).stdout.strip(),
          "cpu": next((l.split(":")[1].strip() for l in open("/proc/cpuinfo") if l.startswith("model name")), "?"), "cores": os.cpu_count(),
          "encoder_device": DEV, "gnn_device": "cpu", "torch": torch.__version__, "dgl": dgl.__version__,
          "peak_rss_mb": round(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024),
          "peak_gpu_mb": round(torch.cuda.max_memory_allocated() / 2 ** 20) if DEV == "cuda" else 0,
          "gnn_parameters": sum(p.numel() for p in gm.parameters()), "encoder_parameters": sum(p.numel() for p in enc.parameters())}
    summary = {"hardware": hw, "weights": WEIGHTS, "encoder": ENCODER, "base_encoder": BASE, "splits": {}}
    rng = np.random.default_rng(0)
    for split in ("Test", "Train"):
        allr = [r for r in rows if r["split"] == split]
        sub = [r for r in allr if r["status"] == "ok" and "slither" in r["pred"]]   # contracts every variant could score
        y = np.array([r["label"] for r in sub])
        s = {"files": len(allr), "scored_by_all": len(sub), "status": {k: sum(r["status"] == k for r in allr) for k in {r["status"] for r in allr}},
             "vulnerable": int(y.sum()), "non_vulnerable": int((1 - y).sum()), "variants": {}}
        full = np.array([r["pred"]["full"] for r in sub])
        boot = [rng.integers(0, len(sub), len(sub)) for _ in range(1000)]
        for v in VARIANTS:
            p = np.array([r["pred"][v] for r in sub])
            pr, rc, f1, _ = precision_recall_fscore_support(y, p, labels=[0, 1], zero_division=0)
            macro = [f1_score(y[b], p[b], average="macro", zero_division=0) for b in boot]
            s["variants"][v] = {"non_vulnerable": {"P": round(pr[0], 3), "R": round(rc[0], 3), "F1": round(f1[0], 3)},
                                "vulnerable": {"P": round(pr[1], 3), "R": round(rc[1], 3), "F1": round(f1[1], 3)},
                                "macro_F1": round(float(f1.mean()), 3), "macro_F1_ci95": [round(float(np.percentile(macro, 2.5)), 3), round(float(np.percentile(macro, 97.5)), 3)],
                                "accuracy": round(accuracy_score(y, p), 3), "predicted_vulnerable": int(p.sum()),
                                "full_right_this_wrong": int(((full == y) & (p != y)).sum()), "full_wrong_this_right": int(((full != y) & (p == y)).sum())}
        for k in ("slither", "graph_and_embed", "base_embed", "gnn"):
            t = sorted(r["t"][k] for r in sub if k in r["t"])
            s.setdefault("seconds_per_contract", {})[k] = {"median": t[len(t) // 2], "p95": t[int(len(t) * .95)], "max": t[-1], "total": round(sum(t), 1)} if t else None
        s["flips_full_vs_no_graph"] = [{"file": r["file"], "label": r["label"], "full": r["pred"]["full"], "no_graph": r["pred"]["no_graph"],
                                        "p_full": r["p_vul"]["full"], "p_no_graph": r["p_vul"]["no_graph"], "functions": r["functions"], "edges": r["edges"]}
                                       for r in sub if r["pred"]["full"] != r["pred"]["no_graph"]]
        summary["splits"][split] = s
    (OUT / "summary.json").write_text(json.dumps(summary, indent=1))
    own = OUT.stat()
    for f in OUT.iterdir():
        os.chown(f, own.st_uid, own.st_gid)


if __name__ == "__main__":
    main()
