"""Seed the knowledge base with labelled functions of the TRAINING split (step 1.8 of docs/KE_HOACH_TRIEN_KHAI.md).

Source: assets/datasets/full/FunctionSyntaxDataset/<vuln>/train.csv (function, label), the verified function-level labels
of the research dataset. Only functions containing the syntax the model reacts to are kept (now / block.timestamp;
call.value / call{ / .call( ): the non-vulnerable ones among them are exactly the "hard negatives" the explainer should
be able to compare against. Test splits and DAppSCAN are never loaded. Re-running replaces the dataset items only.
Usage: uv run python scripts/seed_knowledge.py
"""
import csv
import re
import sys
import time

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
from src.workflows.gfd_workflow.workflow import gfd_workflow  # noqa: E402
from src.services import knowledge  # noqa: E402

csv.field_size_limit(10 ** 9)
SOURCES = {
    "timestamp": ("assets/datasets/full/FunctionSyntaxDataset/TimestampDependencyDataset/train.csv", re.compile(r"\bnow\b|block\.timestamp")),
    "reentrancy": ("assets/datasets/full/FunctionSyntaxDataset/ReentrancyDataset/train.csv", re.compile(r"\.call\.value|\.call\{|\.call\(")),
}


def main():
    gfd_workflow.initialize()
    col = knowledge._col()
    removed = col.delete_many({"kind": "dataset"}).deleted_count
    print(f"removed {removed} old dataset item(s)")
    for vuln, (path, keyword) in SOURCES.items():
        if vuln not in gfd_workflow.models:
            print(f"{vuln}: model not loaded, skipped")
            continue
        rows = [r for r in csv.DictReader(open(path, encoding="utf-8")) if keyword.search(r["function"])]
        seen, t0, n = set(), time.time(), 0
        for r in rows:
            code = r["function"].strip()
            if code in seen:
                continue  # verbatim duplicates add nothing to retrieval
            seen.add(code)
            knowledge.add_item("dataset", vuln, code, verdict=int(r["label"]), source=f"{path.split('/')[-2]} train.csv")
            n += 1
            if n % 200 == 0:
                print(f"{vuln}: {n}/{len(rows)} ({time.time() - t0:.0f}s)", flush=True)
        print(f"{vuln}: {n} item(s) in {time.time() - t0:.0f}s", flush=True)
    print("total items:", col.count_documents({}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
