"""Compare measurement runs of run_baseline.py: timing, and whether the model verdicts stayed identical.

Usage: python eval/baseline/compare.py timing baseline after_parallel after_embcache
"""
import json
import statistics as st
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent


def load(kind, tag):
    rows = [json.loads(l) for l in open(OUT / f"{kind}_{tag}.jsonl", encoding="utf-8")]
    by = {}
    for r in rows:
        key = r["file"].replace("\\", "/").split("SourceCodeSyntaxDataset/")[-1]
        by.setdefault(key, r)  # first repeat
    return by


def verdicts(r):
    return {k: (v.get("predicted_class"), round(v.get("confidence_score", 0), 4)) for k, v in (r.get("verdicts") or {}).items() if k != "_summary"}


def main(kind, *tags):
    runs = {t: load(kind, t) for t in tags}
    base = tags[0]
    print(f"{'run':<22}{'n':>4}{'err':>5}{'wall med':>10}{'wall max':>10}{'model med':>11}{'llm med':>9}{'same verdicts':>15}")
    for t in tags:
        rows = runs[t]
        ok = [r for r in rows.values() if "wall_s" in r]
        wall = [r["wall_s"] for r in ok]
        model = [r["t_models_done_s"] for r in ok if r.get("t_models_done_s")]
        llm = [r["t_llm_s"] for r in ok if r.get("t_llm_s")]
        same = sum(verdicts(r) == verdicts(runs[base].get(k, {})) for k, r in rows.items() if k in runs[base])
        f = lambda xs, fn: f"{fn(xs):.1f}" if xs else "-"
        print(f"{t:<22}{len(rows):>4}{len(rows) - len(ok):>5}{f(wall, st.median):>10}{f(wall, max):>10}{f(model, st.median):>11}{f(llm, st.median):>9}{same:>9}/{len(rows)}")
    if len(tags) > 1:
        print("\nper contract wall time (s):")
        for k in runs[base]:
            print("  " + " | ".join(f"{runs[t].get(k, {}).get('wall_s', '-'):>7}" for t in tags) + "  " + k[-48:])


if __name__ == "__main__":
    main(*sys.argv[1:])
