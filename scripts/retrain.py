"""Retrain the contract-level GNN on base data + feedback (step 1.9 of docs/KE_HOACH_TRIEN_KHAI.md).

Same protocol as the team's notebooks / eval/ablation: Adam, cross-entropy, seed 42, 20% of the training data held out
for validation, epoch chosen by validation macro-F1 (never on the test set or the feedback holdout).
  --mode scratch   new weights, the team's learning rate and epochs (or --epochs);
  --mode finetune  start from the active checkpoint, lr / 5, few epochs.
Writes models/<vuln>/<version>/graph.pt + meta.json. Nothing is activated here: scripts/gate.py decides.
Usage: uv run python scripts/retrain.py timestamp eval/retrain/datasets/<snapshot>.json --mode finetune
"""
import argparse
import hashlib
import json
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "eval/retrain"))
import torch  # noqa: E402
import torch.nn.functional as F  # noqa: E402

from common import REPO, SEED, SPECS, forward, load_item, macro_f1, new_model, predict, seed_all  # noqa: E402
from src.services.model_registry import active_graph_path  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vuln")
    ap.add_argument("dataset")
    ap.add_argument("--mode", choices=["scratch", "finetune"], required=True)
    ap.add_argument("--epochs", type=int)
    args = ap.parse_args()
    spec = SPECS[args.vuln]
    snap = json.loads(Path(args.dataset).read_text(encoding="utf-8"))
    rows = snap["base_train"] + snap["feedback_train"]
    items = [load_item(r) for r in rows]

    seed_all()
    idx = list(range(len(items)))
    random.Random(SEED).shuffle(idx)
    cut = len(idx) // 5
    va, tr = [items[i] for i in idx[:cut]], idx[cut:]
    model = new_model(args.vuln)
    base_ckpt = None
    if args.mode == "finetune":
        base_ckpt = active_graph_path(args.vuln, spec["deployed"])
        model.load_state_dict(torch.load(REPO / base_ckpt, map_location="cpu"))
    lr = spec["lr"] if args.mode == "scratch" else spec["lr"] / 5
    epochs = args.epochs or (spec["epochs"] if args.mode == "scratch" else 20)
    opt = torch.optim.Adam(model.parameters(), lr=lr)
    yv = [i["y"] for i in va]
    best, best_state, t0 = None, None, time.time()
    if args.mode == "finetune":  # epoch 0 = the starting checkpoint itself, so fine-tuning can only be chosen if it helps validation
        best, best_state = ((macro_f1(yv, predict(model, va, args.vuln)), 0.0), -1), {k: v.detach().clone() for k, v in model.state_dict().items()}
    for epoch in range(epochs):
        model.train()
        random.shuffle(tr)
        for k in range(0, len(tr), spec["batch"]):
            batch = [items[i] for i in tr[k:k + spec["batch"]]]
            loss = F.cross_entropy(forward(model, batch), torch.tensor([i["y"] for i in batch]))
            opt.zero_grad()
            loss.backward()
            opt.step()
        pv = predict(model, va, args.vuln)
        key = (macro_f1(yv, pv), -float(loss))
        if best is None or key > best[0]:
            best, best_state = (key, epoch), {k: v.detach().clone() for k, v in model.state_dict().items()}
        if epoch % 5 == 0 or epoch == epochs - 1:
            print(f"epoch {epoch} loss {float(loss):.4f} val macro-F1 {key[0]:.3f} ({time.time() - t0:.0f}s)", flush=True)
    model.load_state_dict(best_state)
    digest = hashlib.sha256()
    for v in best_state.values():
        digest.update(v.cpu().numpy().tobytes())
    version = f"{args.mode}-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M')}-{digest.hexdigest()[:8]}"
    out = REPO / "models" / args.vuln / version
    out.mkdir(parents=True, exist_ok=True)
    torch.save(best_state, out / "graph.pt")
    meta = {"vulnerability": args.vuln, "version": version, "mode": args.mode, "dataset": args.dataset, "dataset_sha256": snap["sha256"],
            "base_checkpoint": base_ckpt, "lr": lr, "epochs": epochs, "selected_epoch": best[1], "validation_macro_f1": round(best[0][0], 3),
            "train_contracts": len(tr), "validation_contracts": len(va), "train_seconds": round(time.time() - t0, 1),
            "torch": torch.__version__, "device": "cpu", "seed": SEED}
    (out / "meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")
    print(json.dumps({"checkpoint": str((out / "graph.pt").relative_to(REPO)).replace("\\", "/"), **meta}, indent=1))


if __name__ == "__main__":
    main()
