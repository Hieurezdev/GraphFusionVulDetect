"""Hard positives / negatives with human labels, from the Consolidated Ground Truth (github.com/gsalzer/cgt, di Angelo & Salzer 2023).

Positive: a contract a CGT source set manually marked as having the weakness. Hard negative: one manually marked as NOT having
it although its source contains the syntax keyword the models key on. SmartBugs-curated and SolidiFI rows are dropped (training
sources / synthetic), so are contracts with conflicting labels and contracts whose text equals a Train or Test file.

usage: prepare_cgt.py <consolidated.csv> <dir of downloaded sources> <Kaggle SourceCodeSyntaxDataset> <out dir>
"""
import csv, hashlib, json, re, sys
from collections import defaultdict
from pathlib import Path

PROPS = {"timestamp": (r"block info dependency|timedependency|time affected by miners|swc-116", r"block\s*\.\s*timestamp|\bnow\b", "TimestampDependencyDataset"),
         "reentrancy": (r"re-?entrancy|swc-107", r"\.call\s*\.\s*value\s*\(", "ReentrancyDataset")}
SKIP = {"SBcurated", "SolidiFI"}
MAX_NEG = 150
norm = lambda s: hashlib.md5("".join(re.sub(r"//.*", "", s).split()).encode()).hexdigest()


def rows(csv_path):
    for r in csv.DictReader(open(csv_path, encoding="utf-8", errors="replace"), delimiter=";"):
        if r["dataset"] not in SKIP and r["fp_sol"]:
            for vuln, (prop, _, _) in PROPS.items():
                if re.search(prop, r["property"].lower()):
                    yield vuln, r


if __name__ == "__main__":
    csv_path, src_dir, kaggle, out = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4])
    if len(sys.argv) > 5:   # "list": print the source fingerprints to download
        print("\n".join(sorted({r["fp_sol"] for _, r in rows(csv_path)}))); sys.exit()
    labels = {}
    for vuln, (_, key, dataset) in PROPS.items():
        known = {norm(p.read_text(errors="replace")) for p in (kaggle / dataset).rglob("*.sol")}
        seen = defaultdict(list)
        for v, r in rows(csv_path):
            if v == vuln:
                seen[r["fp_sol"]].append(r)
        stats, neg = defaultdict(int), 0
        (out / vuln).mkdir(parents=True, exist_ok=True)
        for fp in sorted(seen):
            holds = {r["property_holds"] for r in seen[fp]}
            f = src_dir / f"{fp}.sol"
            if not f.exists():
                stats["no source"] += 1; continue
            src = f.read_text(errors="replace")
            if len(holds) != 1:
                stats["conflicting labels"] += 1; continue
            if norm(src) in known:
                stats["same as a Train/Test file"] += 1; continue
            y = int(holds == {"t"})
            if not y and not re.search(key, src):
                stats["negative without the keyword (not hard)"] += 1; continue
            if not y:
                neg += 1
                if neg > MAX_NEG:
                    stats["negatives over the cap"] += 1; continue
            name = f"{'pos' if y else 'neg'}__{fp}.sol"
            (out / vuln / name).write_text(src)
            labels[f"{vuln}/{name}"] = {"label": y, "sources": sorted({f"{r['dataset']}: {r['property']}" for r in seen[fp]}), "address": seen[fp][0]["addr"], "contract": seen[fp][0]["contractname"]}
            stats["kept positive" if y else "kept hard negative"] += 1
        print(vuln, dict(stats))
    (out / "labels.json").write_text(json.dumps(labels, indent=1))
