"""Why do our reentrancy numbers differ from the paper? Two factors, measured separately.

  encoder   'product' = Quangnguyen711/codebert-solidity-re-entrancy (what the product and eval/ablation use)
            'paper'   = Quangnguyen711/codebert-syntax-solidity-re-entrancy (what Sol2GraphConverter.ipynb embedded the paper's graphs with)
  protocol  'ours'    = fit on 80% of Train, pick the epoch on the other 20%, score Test one contract at a time
            'paper'   = fit on all of Train, score Test in one batch every epoch, report the best epoch (as the notebook does)

REPO=<repo> python paper_protocol.py   (GPU env; writes eval/ablation/paper_protocol.json)
"""
import importlib.util, json, os, random, sys
from pathlib import Path

import dgl, torch
import torch.nn.functional as F
from transformers import RobertaModel, RobertaTokenizer

REPO = Path(os.environ["REPO"])
DATA = REPO / "assets/datasets/SourceCodeSyntaxDatasetFull/ReentrancyDataset"
PAPER_ENCODER = "Quangnguyen711/codebert-syntax-solidity-re-entrancy"
DEV = torch.device("cuda")
SEED, EPOCHS, LR, BATCH = 42, 100, 1e-4, 256


def files(split):
    for cls, y in (("NonVulnerable", 0), ("Vulnerable", 1)):
        for f in sorted((DATA / split / f"{cls}_Fcg").glob("*.fcg")):
            yield f, y


def embed_paper():
    tok, enc = RobertaTokenizer.from_pretrained(PAPER_ENCODER), RobertaModel.from_pretrained(PAPER_ENCODER).to(DEV).eval()
    for split in ("Train", "Test"):
        for f, _ in files(split):
            dest = f.with_name(f.stem + "_paperenc.pt")
            if dest.exists():
                continue
            m = json.load(open(str(f).replace(".fcg", "_mapping.json"), encoding="utf-8"))
            x = torch.zeros(len(m["node"]), 768)
            for name, i in m["node"].items():   # same call as Sol2GraphConverter.ipynb: truncation=True, [CLS]
                with torch.no_grad():
                    x[i] = enc(**tok(m["code"].get(name, ""), return_tensors="pt", truncation=True, padding=True).to(DEV)).last_hidden_state[0, 0].cpu()
            torch.save(x, dest)


def load(split, encoder):
    items = []
    for f, y in files(split):
        g = dgl.load_graphs(str(f))[0][0]
        h = dgl.add_self_loop(dgl.graph(g.edges(), num_nodes=g.num_nodes()))
        h.ndata["x"] = (g.ndata["featuresH"] if encoder == "product" else torch.load(f.with_name(f.stem + "_paperenc.pt"))).float()
        items.append((h.to(DEV), y))
    return items


def prf(y, p):
    tp = sum(a and b for a, b in zip(y, p)); fp = sum((not a) and b for a, b in zip(y, p)); fn = sum(a and not b for a, b in zip(y, p))
    P, R = tp / max(tp + fp, 1), tp / max(tp + fn, 1)
    return {"P": round(P, 3), "R": round(R, 3), "F1": round(2 * P * R / max(P + R, 1e-9), 3), "acc": round(sum(a == b for a, b in zip(y, p)) / len(y), 3)}


def run(encoder, protocol):
    random.seed(SEED); torch.manual_seed(SEED); torch.cuda.manual_seed_all(SEED)
    spec = importlib.util.spec_from_file_location("GraphClasifier", REPO / "src/infrastructure/analysis_model/GraphClasifier.py")
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
    model = mod.GraphNN(mtype=["GAT"], infeats=768, hfeats=[2048, 2048], fc1_layer=256, fc2_layer=64, n_gph=2, outclass=2, gptype="max", ginfeat=1024, num_query_vectors=1)
    model.device = DEV; model.to(DEV)
    fwd = lambda items: model(dgl.batch([g for g, _ in items]), torch.cat([g.ndata["x"] for g, _ in items])).reshape(len(items), -1)
    train, test = load("Train", encoder), load("Test", encoder)
    idx = list(range(len(train))); random.Random(SEED).shuffle(idx)
    val, fit = ([train[i] for i in idx[:len(idx) // 5]], idx[len(idx) // 5:]) if protocol == "ours" else ([], idx)
    opt = torch.optim.Adam(model.parameters(), lr=LR)
    ty, best, pick = [y for _, y in test], None, None
    for epoch in range(EPOCHS):
        model.train(); random.shuffle(fit)
        for k in range(0, len(fit), BATCH):
            b = [train[i] for i in fit[k:k + BATCH]]
            loss = F.cross_entropy(fwd(b), torch.tensor([y for _, y in b], device=DEV))
            opt.zero_grad(); loss.backward(); opt.step()
        model.eval()
        with torch.no_grad():
            if protocol == "paper":
                m = prf(ty, fwd(test).argmax(1).tolist())
                if best is None or (m["F1"], m["acc"]) > (best["F1"], best["acc"]):
                    best = {**m, "epoch": epoch}
            else:
                vm = prf([y for _, y in val], torch.cat([fwd([v]) for v in val]).argmax(1).tolist())
                if pick is None or vm["F1"] > pick[0]:
                    pick = (vm["F1"], epoch)
                    best = {**prf(ty, torch.cat([fwd([t]) for t in test]).argmax(1).tolist()), "epoch": epoch, "val_F1": vm["F1"]}
    return best


if __name__ == "__main__":
    embed_paper()
    out = {}
    for encoder in ("product", "paper"):
        for protocol in ("ours", "paper"):
            out[f"encoder={encoder} protocol={protocol}"] = run(encoder, protocol)
            print("@@", f"encoder={encoder} protocol={protocol}", out[f"encoder={encoder} protocol={protocol}"], flush=True)
    (REPO / "eval/ablation/paper_protocol.json").write_text(json.dumps({"paper": {"P": 0.70, "R": 0.93, "F1": 0.80, "acc": 0.77}, "runs": out}, indent=1))
