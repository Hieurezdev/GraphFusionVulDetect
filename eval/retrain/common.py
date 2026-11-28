"""Shared pieces of the retraining loop (step 1.9): graph loading, the contract-level model, metrics, McNemar."""
import json
import math
import random
from pathlib import Path

import dgl
import torch

REPO = Path(__file__).resolve().parents[2]
GRAPHS = REPO / "eval/retrain/graphs"
SEED = 42
# The team's training settings (eval/ablation/ablation.py), unchanged
SPECS = {
    "timestamp": dict(arch=dict(mtype=["GCN"], n_gph=0, num_query_vectors=2), lr=5e-4, batch=128, epochs=200,
                      deployed="src/infrastructure/analysis_model/best_model_GCN_2L_max.pt"),
    "reentrancy": dict(arch=dict(mtype=["GAT"], n_gph=2, num_query_vectors=1), lr=1e-4, batch=256, epochs=100,
                       deployed="src/infrastructure/analysis_model/best_model_GAT_2L_max_reentrancy.pt"),
}


def index(vuln, split):
    return [json.loads(l) for l in open(GRAPHS / vuln / split / "index.jsonl", encoding="utf-8")]


def load_item(row):
    """One contract as the model consumes it: self-loops added, CodeBERT vectors as node features (as src_vul_detector does)."""
    g = dgl.load_graphs(str(REPO / row["graph"]))[0][0]
    h = dgl.add_self_loop(dgl.graph(g.edges(), num_nodes=g.num_nodes()))
    h.ndata["x"] = g.ndata["featuresH"].float()
    label = row["label"] if "label" in row else row["y"]   # graph index rows say "label", dataset snapshot rows "y"
    return {"file": row["file"], "file_hash": row["file_hash"], "y": label, "g": h}


def new_model(vuln):
    from src.infrastructure.analysis_model.GraphClasifier import GraphNN
    return GraphNN(infeats=768, hfeats=[2048, 2048], fc1_layer=256, fc2_layer=64, outclass=2, gptype="max", ginfeat=1024, **SPECS[vuln]["arch"])


def seed_all():
    random.seed(SEED)
    torch.manual_seed(SEED)


def forward(model, items):
    bg = dgl.batch([i["g"] for i in items])
    return model(bg, bg.ndata["x"]).reshape(len(items), -1)


def predict(model, items, vuln):
    """Labels for items; models with n_gph > 0 depend on the batch, so they score one contract at a time like /analyze."""
    single = SPECS[vuln]["arch"]["n_gph"] > 0
    model.eval()
    with torch.no_grad():
        chunks = [[i] for i in items] if single else [items[k:k + 256] for k in range(0, len(items), 256)]
        return torch.cat([forward(model, c) for c in chunks]).argmax(1).tolist()


def macro_f1(y, p):
    return prf(y, p)["macro_F1"]


def prf(y, p):
    out = {}
    for c, name in ((0, "non_vulnerable"), (1, "vulnerable")):
        tp = sum(a == c and b == c for a, b in zip(y, p))
        fp = sum(a != c and b == c for a, b in zip(y, p))
        fn = sum(a == c and b != c for a, b in zip(y, p))
        P = tp / (tp + fp) if tp + fp else 0.0
        R = tp / (tp + fn) if tp + fn else 0.0
        out[name] = {"P": round(P, 3), "R": round(R, 3), "F1": round(2 * P * R / (P + R), 3) if P + R else 0.0}
    out["macro_F1"] = round((out["non_vulnerable"]["F1"] + out["vulnerable"]["F1"]) / 2, 3)
    out["accuracy"] = round(sum(a == b for a, b in zip(y, p)) / len(y), 3) if y else 0.0
    return out


def mcnemar(y, a, b):
    """Exact two-sided McNemar on the contracts where exactly one of the two systems is right: (a right only, b right only, p)."""
    x = sum(i == t and j != t for t, i, j in zip(y, a, b))
    z = sum(i != t and j == t for t, i, j in zip(y, a, b))
    n = x + z
    p = min(1.0, 2 * sum(math.comb(n, k) for k in range(min(x, z) + 1)) / 2 ** n) if n else 1.0
    return x, z, round(p, 4)
