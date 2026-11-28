"""Measure the running product through its own API (step 0.1 of docs/KE_HOACH_TRIEN_KHAI.md).

For each contract it uploads the file to POST /api/v1/analyze, reads the NDJSON stream and records:
  - wall time of the whole scan, and the time at which each pipeline node finished (per vulnerability scan);
  - the model verdicts and flagged functions;
  - whether each LLM explanation recognises a likely false positive (hard-negative check).

The same script is reused after each improvement (--tag after_cache, --tag after_rag, ...) so numbers are comparable.

Usage:
  python eval/baseline/run_baseline.py --set timing --tag baseline
  python eval/baseline/run_baseline.py --set hardneg --tag baseline
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import requests

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "eval" / "baseline"
API = os.getenv("GFD_API", "http://localhost:8000/api/v1")
USER = os.getenv("GFD_USER", "demo_user@example.com")
PASSWORD = os.getenv("GFD_PASSWORD", "Demo@12345")

# Full research dataset (807/193 timestamp, 611/147 reentrancy), extracted from the uploaded archive into assets/datasets/full/.
DATA = REPO / "assets/datasets/full/SourceCodeSyntaxDataset"
TS = DATA / "TimestampDependencyDataset"
RE = DATA / "ReentrancyDataset"

# "dương tính giả" / "false positive" counts only when it is not negated ("không phải dương tính giả", "not a false positive").
FP_WORDS = re.compile(r"(?i)(?<!không phải )(?<!không phải là )(?<!not a )(?<!not )(dương tính giả|false positive|cơ sở yếu|weak basis)")


def deployed_rows():
    rows = [json.loads(l) for l in open(REPO / "eval/ablation/deployed_inference/results.jsonl", encoding="utf-8")]
    return [r for r in rows if r["status"] == "ok"]


def same_files_as(tag_file: Path):
    """The exact contracts of an earlier run (e.g. the baseline), mapped onto the full dataset, so runs stay comparable."""
    out = []
    for line in open(tag_file, encoding="utf-8"):
        f = json.loads(line)["file"].replace("\\", "/")
        if "SourceCodeSyntaxDataset/" in f:
            f = "assets/datasets/full/SourceCodeSyntaxDataset/" + f.split("SourceCodeSyntaxDataset/", 1)[1]
        p = REPO / f
        if p not in out:
            out.append(p)
    return out


def timing_set():
    """A fixed, mixed set: timestamp test (vulnerable / non-vulnerable, small to large), reentrancy test, the demo."""
    rows = sorted((r for r in deployed_rows() if r["split"] == "Test"), key=lambda r: r["lines"])
    pick = []
    for label in (1, 0):
        same = [r for r in rows if r["label"] == label]
        for q in (0.1, 0.5, 0.9):  # small, medium, large
            pick.append(TS / same[int(q * (len(same) - 1))]["file"])
    pick += sorted((RE / "Test/Vulnerable").glob("*.sol"))[:2] + sorted((RE / "Test/NonVulnerable").glob("*.sol"))[:2]
    pick.append(REPO / "demo/EtherStore.sol")
    return pick


def hardneg_set():
    """Timestamp test contracts labelled non-vulnerable that the deployed model flags: the false positives an explanation should doubt."""
    return [TS / r["file"] for r in deployed_rows() if r["split"] == "Test" and r["label"] == 0 and r["pred"]["full"] == 1]


def login():
    r = requests.post(f"{API}/auth/login", json={"username": USER, "password": PASSWORD}, timeout=30)
    r.raise_for_status()
    return r.json()["access_token"]


def scan(path: Path, language: str = "vi", extra: dict | None = None) -> dict:
    token = login()
    t0 = time.perf_counter()
    events = []
    with open(path, "rb") as f:
        r = requests.post(f"{API}/analyze", headers={"Authorization": f"Bearer {token}"},
                          files={"file": (path.name, f, "text/plain")}, data={"language": language, **(extra or {})},
                          stream=True, timeout=900)
        r.raise_for_status()
        session_id = r.headers.get("X-Session-ID")
        for line in r.iter_lines(decode_unicode=True):
            if not line:
                continue
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            ev["_t"] = round(time.perf_counter() - t0, 3)
            events.append(ev)
    rel = str(path.relative_to(REPO)) if path.is_relative_to(REPO) else str(path)
    return {"file": rel, "wall_s": round(time.perf_counter() - t0, 3), "events": events, "session_id": session_id}


def summarise(res: dict) -> dict:
    nodes, explanations, verdicts, flagged, session = [], [], {}, {}, res.get("session_id")
    order = {}
    for ev in res["events"]:
        node, out = ev.get("node"), ev.get("output") or {}
        session = ev.get("session_id", session)
        if node:
            nodes.append({"node": node, "t": ev["_t"]})
        if node == "start":
            order = {i: v for i, v in enumerate(out.get("vulnerabilities", []))}
        vuln = ev.get("vulnerability") or out.get("vulnerability")
        if node == "detect_vulnerability_src":
            verdicts.setdefault(vuln or f"scan{len(verdicts)}", out)
        if node == "detect_vulnerability_func":
            flagged[vuln or f"scan{len(flagged)}"] = [p["function_name"] for p in out.get("func_vulnerability_predictions", []) if p.get("prediction") == 1]
        if node == "explain_vulnerability_func":
            for e in out.get("explanations", []):
                text = e.get("explanation", "")
                explanations.append({"vulnerability": vuln, "function": e.get("function_name"),
                                     "doubts_alert": bool(FP_WORDS.search(text)), "chars": len(text)})
        if node == "summary":
            verdicts["_summary"] = out
    t_detect = max((n["t"] for n in nodes if n["node"] == "detect_vulnerability_func"), default=None)
    t_explain = max((n["t"] for n in nodes if n["node"] == "explain_vulnerability_func"), default=None)
    return {"file": res["file"], "wall_s": res["wall_s"], "t_models_done_s": t_detect,
            "t_llm_s": round(t_explain - t_detect, 3) if t_explain and t_detect else None,
            "verdicts": verdicts, "flagged": flagged, "explanations": explanations, "nodes": nodes, "session_id": session}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", choices=["timing", "hardneg"], required=True)
    ap.add_argument("--tag", default="baseline")
    ap.add_argument("--repeat", type=int, default=1, help="scan each file this many times (cache checks)")
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    base = OUT / f"{args.set}_baseline.jsonl"
    if args.tag != "baseline" and base.exists():
        files = same_files_as(base)   # identical contracts to the baseline
    else:
        files = timing_set() if args.set == "timing" else hardneg_set()
    if args.limit:
        files = files[:args.limit]
    out = OUT / f"{args.set}_{args.tag}.jsonl"
    with open(out, "w", encoding="utf-8") as f:
        for i, path in enumerate(files, 1):
            for rep in range(args.repeat):
                try:
                    s = summarise(scan(path))
                except Exception as e:  # keep going: one failing contract must not stop the run
                    s = {"file": str(path.relative_to(REPO)), "error": str(e)[:300]}
                s["repeat"] = rep
                f.write(json.dumps(s, ensure_ascii=False) + "\n")
                f.flush()
                print(f"[{i}/{len(files)}] rep {rep} {s.get('file')}: {s.get('wall_s', s.get('error'))}", flush=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    sys.exit(main())
