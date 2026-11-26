"""Train the contract-level reentrancy GNN, following assets/notebooks/traininggfdmodels-290d56.ipynb.

Three stages, all reading the same cache of graphs:
  build  (backend image)  .sol -> call graph + embeddings with the product's own convert_to_fcg and the reentrancy encoder,
                          so training sees exactly what /analyze produces
  train  (GPU env: PyTorch + CUDA build of DGL)  GAT [2048, 2048] + max pooling, n_gph=2, fc 256/64, Adam lr 1e-4,
                          CrossEntropy, batch 256, 100 epochs, seed 42, every graph kept: the notebook's settings
  eval   (backend image)  reload the checkpoint with the product's DGL and score Test again

Different from the notebook, on purpose: the saved epoch is chosen on a validation split of Train, scored one contract
at a time as /analyze does. The notebook keeps the best epoch on Test, which is optimistic; that number is logged too.
n_gph=2 makes a prediction depend on the other contracts in its batch, so Test is reported both ways.

  DATA=<...>/SourceCodeSyntaxDataset/ReentrancyDataset CACHE=<dir> OUT=<dir> REPO=<repo> python train_reentrancy_gfd.py build|train|eval
"""
import importlib.util, json, os, random, shutil, signal, sys, tempfile
from pathlib import Path

import dgl
import numpy as np
import torch
import torch.nn.functional as F
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.model_selection import train_test_split

DATA, CACHE, OUT, REPO = (Path(os.environ[k]) for k in ("DATA", "CACHE", "OUT", "REPO"))
ENCODER = "Quangnguyen711/codebert-solidity-re-entrancy"
EPOCHS, LR, BATCH, SEED = 100, 1e-4, 256, 42
ARCH = dict(mtype=["GAT"], infeats=768, hfeats=[2048, 2048], fc1_layer=256, fc2_layer=64, n_gph=2, outclass=2, gptype="max", ginfeat=1024, num_query_vectors=1)
CKPT = "best_model_GAT_2L_max_reentrancy.pt"
DEV = torch.device("cuda" if torch.cuda.is_available() and os.environ.get("GNN_DEVICE", "cuda") == "cuda" else "cpu")


def seed_everything(s):
    random.seed(s); np.random.seed(s); torch.manual_seed(s); torch.cuda.manual_seed_all(s)


def build():
    from transformers import RobertaModel, RobertaTokenizer
    from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg

    def alarm(*_):
        raise TimeoutError()
    signal.signal(signal.SIGALRM, alarm)
    cfg = {"configurable": {"embedd_tokenizer": RobertaTokenizer.from_pretrained(ENCODER), "embedd_model": RobertaModel.from_pretrained(ENCODER).to(os.environ.get("ENC_DEVICE", "cuda")).eval()}}   # convert_to_fcg swallows a CUDA OOM as "no graph": use ENC_DEVICE=cpu on a shared GPU
    if torch.cuda.is_available() and os.environ.get("ENC_DEVICE", "cuda") == "cuda":
        del_me = torch.empty(2 << 30, dtype=torch.uint8, device="cuda"); del del_me   # stays reserved by PyTorch: other jobs on a shared GPU cannot take it mid-run
    failed = {}
    for split in ("Train", "Test"):
        for cls in ("NonVulnerable", "Vulnerable"):
            dest = CACHE / split / cls
            dest.mkdir(parents=True, exist_ok=True)
            for sol in sorted((DATA / split / cls).glob("*.sol")):
                if (dest / f"{sol.stem}.fcg").exists():
                    continue
                signal.alarm(300)
                try:
                    with tempfile.TemporaryDirectory() as tmp:
                        st = convert_to_fcg({"sol_file_path": str(sol), "fcg_save_dir": tmp}, cfg)
                        if str(st.get("fcg_file_path", "")).endswith(".fcg"):
                            shutil.move(st["mapping_file_path"], dest / f"{sol.stem}_mapping.json")
                            shutil.move(st["fcg_file_path"], dest / f"{sol.stem}.fcg")
                        else:
                            failed[f"{split}/{cls}/{sol.name}"] = "no graph"
                except TimeoutError:
                    failed[f"{split}/{cls}/{sol.name}"] = "timeout"
                signal.alarm(0)
    (CACHE / "failed.json").write_text(json.dumps(failed, indent=1))
    print("@@ built", {f"{s}/{c}": len(list((CACHE / s / c).glob("*.fcg"))) for s in ("Train", "Test") for c in ("NonVulnerable", "Vulnerable")}, "failed", len(failed))


def load(split):
    items = []
    for cls, y in (("NonVulnerable", 0), ("Vulnerable", 1)):
        for f in sorted((CACHE / split / cls).glob("*.fcg")):
            g = dgl.load_graphs(str(f))[0][0]
            h = dgl.add_self_loop(dgl.graph(g.edges(), num_nodes=g.num_nodes()))
            h.ndata["features"] = g.ndata["featuresH"].float()
            items.append({"name": f"{cls}/{f.stem}.sol", "g": h.to(DEV), "y": y})
    return items


def make_model():
    spec = importlib.util.spec_from_file_location("GraphClasifier", REPO / "src/infrastructure/analysis_model/GraphClasifier.py")
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
    model = mod.GraphNN(**ARCH)
    # GraphClasifier.py pins the device to CPU, imports torch's Sequential (which cannot pass (graph, features); the
    # notebook uses DGL's, same state_dict keys) and builds a float edge list when the batch holds one contract.
    model.device = DEV
    model.GPH = dgl.nn.pytorch.Sequential(*model.GPH)
    pairs = lambda n: torch.tensor([[i, j] for i in range(n) for j in range(n) if i != j], dtype=torch.long).reshape(-1, 2)
    model.create_graph_adjacency = lambda n: dgl.graph((pairs(n)[:, 0], pairs(n)[:, 1]), num_nodes=n)
    return model.to(DEV)


def metrics(y, p):
    pr, rc, f1, _ = precision_recall_fscore_support(y, p, labels=[0, 1], zero_division=0)
    return {"n": len(y), "vulnerable": int(sum(y)), "P": round(float(pr[1]), 3), "R": round(float(rc[1]), 3), "F1": round(float(f1[1]), 3),
            "P_non_vulnerable": round(float(pr[0]), 3), "R_non_vulnerable": round(float(rc[0]), 3), "F1_non_vulnerable": round(float(f1[0]), 3),
            "accuracy": round(float(accuracy_score(y, p)), 3), "predicted_vulnerable": int(sum(p))}


def forward(model, items):
    bg = dgl.batch([i["g"] for i in items])
    return model(bg, bg.ndata["features"]).reshape(len(items), -1)


def evaluate(model, items, single=True):
    with torch.no_grad():
        out = torch.cat([forward(model, [i]) for i in items]) if single else torch.cat([forward(model, items[k:k + 128]) for k in range(0, len(items), 128)])
    y = [i["y"] for i in items]
    return metrics(y, out.argmax(1).tolist()), float(F.cross_entropy(out, torch.tensor(y, device=DEV))), out.argmax(1).tolist()


def train():
    seed_everything(SEED)
    train_items, test = load("Train"), load("Test")
    tr, va = train_test_split(range(len(train_items)), test_size=0.2, random_state=SEED, stratify=[i["y"] for i in train_items])
    val = [train_items[i] for i in va]
    seed_everything(SEED)
    model = make_model()
    opt = torch.optim.Adam(model.parameters(), lr=LR)
    best, best_state, history, nb_best = None, None, [], (0, 0)
    for epoch in range(EPOCHS):
        model.train()
        order = list(tr); random.shuffle(order)
        losses = []
        for k in range(0, len(order), BATCH):
            batch = [train_items[i] for i in order[k:k + BATCH]]
            loss = F.cross_entropy(forward(model, batch), torch.tensor([i["y"] for i in batch], device=DEV))
            opt.zero_grad(); loss.backward(); opt.step(); losses.append(float(loss))
        model.eval()
        vm, vloss, _ = evaluate(model, val)
        tm, _, _ = evaluate(model, test, single=False)   # batched, as the notebook scores it
        history.append({"epoch": epoch, "train_loss": round(sum(losses) / len(losses), 4), "val_f1": vm["F1"], "val_acc": vm["accuracy"], "val_loss": round(vloss, 4), "test_f1": tm["F1"], "test_acc": tm["accuracy"]})
        print(f"epoch {epoch} loss {history[-1]['train_loss']} val_f1 {vm['F1']} val_acc {vm['accuracy']} test_f1_batched {tm['F1']}", flush=True)
        nb_best = max(nb_best, (tm["F1"], tm["accuracy"]))
        key = (vm["F1"] + vm["F1_non_vulnerable"], -vloss)   # macro-F1 on validation, then lower loss
        if best is None or key > best[0]:
            best, best_state = (key, epoch, vm), {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}
    model.load_state_dict(best_state); model.eval()
    OUT.mkdir(parents=True, exist_ok=True)
    torch.save(best_state, OUT / CKPT)
    single, _, preds = evaluate(model, test)
    failed = json.loads((CACHE / "failed.json").read_text()) if (CACHE / "failed.json").exists() else {}
    report = {"encoder": ENCODER, "device": str(DEV), "torch": torch.__version__, "dgl": dgl.__version__,
              "config": {**ARCH, "lr": LR, "batch": BATCH, "epochs": EPOCHS, "seed": SEED, "parameters": sum(p.numel() for p in model.parameters())},
              "data": {"train_graphs": len(train_items), "train_fit": len(tr), "train_validation": len(va), "test_graphs": len(test),
                       "train_vulnerable": sum(i["y"] for i in train_items), "test_vulnerable": sum(i["y"] for i in test), "no_graph": failed},
              "selected_epoch": best[1], "validation": best[2], "test_one_contract_at_a_time": single,
              "test_batched_like_notebook": evaluate(model, test, single=False)[0], "train_fit": evaluate(model, [train_items[i] for i in tr])[0],
              "notebook_style_best_test": {"F1": nb_best[0], "accuracy": nb_best[1], "note": "best epoch picked on Test, as the notebook does; optimistic"},
              "test_predictions": [{"file": i["name"], "label": i["y"], "pred": p} for i, p in zip(test, preds)], "history": history}
    (OUT / "training_report.json").write_text(json.dumps(report, indent=1))
    print("@@ " + json.dumps({k: v for k, v in report.items() if k not in ("history", "test_predictions", "data")}))


def evaluate_checkpoint():
    model = make_model()
    model.load_state_dict(torch.load(OUT / CKPT, map_location=DEV)); model.eval()
    print("@@ eval", json.dumps({"dgl": dgl.__version__, "device": str(DEV), "test_one_contract_at_a_time": evaluate(model, load("Test"))[0]}))


if __name__ == "__main__":
    {"build": build, "train": train, "eval": evaluate_checkpoint}[sys.argv[1]]()
