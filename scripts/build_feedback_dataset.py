"""Freeze the data of one retraining run into a hashed snapshot (step 1.9 of docs/KE_HOACH_TRIEN_KHAI.md).

Feedback comes from two places:
  - the label log: consented expert verdicts (needs_manual_review dropped). For the CONTRACT-level model only
    "confirmed" gives a contract label (vulnerable); a rejected alert says nothing about the rest of the contract;
  - --simulate F: during the hackathon there are too few real verdicts, so a stratified share F of the TRAINING split
    stands in for expert feedback, marked origin="simulated". The paper's test set and DAppSCAN are never used.
Splits are made by file_hash, and any file whose hash or name is in the test set is removed, so the held-out numbers
cannot be inflated by duplicates (the overlap problem of the team's paper).
Usage: uv run python scripts/build_feedback_dataset.py timestamp --simulate 0.2
"""
import argparse
import hashlib
import json
import random
import sys
from datetime import datetime, timezone
from pathlib import Path

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "eval/retrain"))
from common import index, SEED, REPO  # noqa: E402

OUT = REPO / "eval/retrain/datasets"


def label_log_samples(vuln, min_reviewers=2):
    """Contract-level positives from consented expert verdicts that at least `min_reviewers` experts agree on (step 2.6)."""
    from pymongo import MongoClient
    from src.config.settings import settings
    from src.services.label_log import consensus, item_key
    col = MongoClient(settings.MONGODB_URL)[settings.MONGODB_DATABASE].label_events
    events = list(col.find({"vulnerability": vuln, "training_consent": True}, sort=[("seq", 1)]))
    agreed = consensus(events, min_reviewers)
    last = {item_key(e): e for e in events}
    out, seen = [], set()
    for key, verdict in agreed.items():
        e = last[key]
        if verdict == "confirmed" and e.get("graph_path") and e.get("file_hash") and e["file_hash"] not in seen:
            seen.add(e["file_hash"])
            out.append({"file": e.get("file_path"), "file_hash": e["file_hash"], "y": 1, "graph": str(e["graph_path"]).replace("\\", "/"),
                        "origin": "expert", "label_seq": e["seq"]})
    print(f"label log: {len(events)} consented verdict events, {len(agreed)} item(s) with {min_reviewers}-expert agreement, "
          f"{len(out)} contract positive(s) used", file=sys.stderr)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vuln")
    ap.add_argument("--simulate", type=float, default=0.0, help="share of the training split used as simulated feedback")
    ap.add_argument("--holdout", type=float, default=0.3, help="share of feedback kept for the gate, never trained on")
    ap.add_argument("--min-reviewers", type=int, default=2, help="experts who must agree before a verdict becomes a label")
    args = ap.parse_args()

    train = [r for r in index(args.vuln, "Train") if r["status"] == "ok"]
    test = [r for r in index(args.vuln, "Test") if r["status"] == "ok"]
    test_hashes = {r["file_hash"] for r in test}
    test_names = {r["file"].split("/")[-1] for r in test}
    clean = lambda rows: [r for r in rows if r["file_hash"] not in test_hashes and str(r.get("file", "")).split("/")[-1] not in test_names]

    rng = random.Random(SEED)
    simulated = []
    if args.simulate:
        for label in (0, 1):
            members = [r for r in train if r["label"] == label]
            rng.shuffle(members)
            simulated += members[:round(len(members) * args.simulate)]
    sim_hashes = {r["file_hash"] for r in simulated}
    base = [{"file": r["file"], "file_hash": r["file_hash"], "y": r["label"], "graph": r["graph"], "origin": "dataset"}
            for r in clean(train) if r["file_hash"] not in sim_hashes]
    feedback = [{"file": r["file"], "file_hash": r["file_hash"], "y": r["label"], "graph": r["graph"], "origin": "simulated"} for r in clean(simulated)]
    feedback += clean(label_log_samples(args.vuln, args.min_reviewers))

    # holdout split by file hash, stratified by label
    holdout_hashes = set()
    for label in (0, 1):
        hashes = sorted({s["file_hash"] for s in feedback if s["y"] == label})
        rng.shuffle(hashes)
        holdout_hashes |= set(hashes[:round(len(hashes) * args.holdout)])
    fb_train = [s for s in feedback if s["file_hash"] not in holdout_hashes]
    fb_hold = [s for s in feedback if s["file_hash"] in holdout_hashes]
    base = [s for s in base if s["file_hash"] not in holdout_hashes]  # a duplicate of a holdout file may not be trained on

    snap = {"vulnerability": args.vuln, "created": datetime.now(timezone.utc).isoformat(), "seed": SEED, "min_reviewers": args.min_reviewers,
            "simulate": args.simulate, "holdout": args.holdout,
            "counts": {"base_train": len(base), "feedback_train": len(fb_train), "feedback_holdout": len(fb_hold),
                       "removed_as_test_duplicates": len(train) - len(clean(train)),
                       "expert_samples": sum(s["origin"] == "expert" for s in feedback)},
            "base_train": base, "feedback_train": fb_train, "feedback_holdout": fb_hold}
    body = json.dumps(snap, sort_keys=True, ensure_ascii=False)
    snap["sha256"] = hashlib.sha256(body.encode("utf-8")).hexdigest()
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{args.vuln}_{snap['sha256'][:12]}.json"
    path.write_text(json.dumps(snap, ensure_ascii=False, indent=1), encoding="utf-8")
    print(json.dumps({"path": str(path.relative_to(REPO)), "sha256": snap["sha256"], **snap["counts"]}, indent=1))


if __name__ == "__main__":
    main()
