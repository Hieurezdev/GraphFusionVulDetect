"""Calibration helpers shared by the baseline (step 0.1) and the temperature fit (step 1.7)."""
import json
import math
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def deployed_probs(split: str = "Test"):
    """(p_vulnerable, label, file) of the deployed timestamp contract model, as stored by eval/ablation/deployed_inference."""
    rows = [json.loads(l) for l in open(REPO / "eval/ablation/deployed_inference/results.jsonl", encoding="utf-8")]
    return [(r["p_vul"]["full"], r["label"], r["file"]) for r in rows if r["status"] == "ok" and r["split"] == split]


def ece(probs, labels, bins: int = 10) -> float:
    """Expected calibration error of the predicted class's confidence (the number the product shows), equal-width bins."""
    total, err = len(probs), 0.0
    for b in range(bins):
        lo, hi = b / bins, (b + 1) / bins
        idx = [i for i, p in enumerate(probs) if lo < max(p, 1 - p) <= hi or (b == 0 and max(p, 1 - p) == lo)]
        if not idx:
            continue
        conf = sum(max(probs[i], 1 - probs[i]) for i in idx) / len(idx)
        acc = sum((probs[i] >= 0.5) == bool(labels[i]) for i in idx) / len(idx)
        err += len(idx) / total * abs(acc - conf)
    return err


def logit(p: float) -> float:
    p = min(max(p, 1e-6), 1 - 1e-6)
    return math.log(p / (1 - p))


def apply_t(p: float, t: float) -> float:
    """Temperature scaling of a 2-class softmax = scaling the logit difference by 1/T."""
    return 1 / (1 + math.exp(-logit(p) / t))


def nll(probs, labels, t: float) -> float:
    s = 0.0
    for p, y in zip(probs, labels):
        q = min(max(apply_t(p, t), 1e-9), 1 - 1e-9)
        s -= math.log(q if y else 1 - q)
    return s / len(probs)


def fit_t(probs, labels) -> float:
    """Temperature minimising NLL (golden-section search on log T in [1/20, 20])."""
    a, b = math.log(0.05), math.log(20)
    g = (math.sqrt(5) - 1) / 2
    c, d = b - g * (b - a), a + g * (b - a)
    for _ in range(80):
        if nll(probs, labels, math.exp(c)) < nll(probs, labels, math.exp(d)):
            b = d
        else:
            a = c
        c, d = b - g * (b - a), a + g * (b - a)
    return math.exp((a + b) / 2)
