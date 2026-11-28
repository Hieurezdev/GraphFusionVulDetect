"""Compare the shadow candidate with the active model on real scans (step 2.7 of docs/KE_HOACH_TRIEN_KHAI.md).

For every stored scan that carries a shadow prediction: do the two models agree, and, where experts have reviewed the
session, which one matches the expert view (contract positive = at least one function of that scan confirmed)?
Usage: uv run python scripts/shadow_report.py [timestamp|reentrancy]
"""
import json
import sys

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
from pymongo import MongoClient  # noqa: E402

from src.config.settings import settings  # noqa: E402
from src.services.label_log import latest_verdicts  # noqa: E402


def main(vulns):
    db = MongoClient(settings.MONGODB_URL)[settings.MONGODB_DATABASE]
    verdicts = latest_verdicts(db.label_events.find({}, sort=[("seq", 1)]))
    confirmed = {(k[0], k[1]) for k, by in verdicts.items() if "confirmed" in by.values()}
    reviewed = {(k[0], k[1]) for k in verdicts}
    report = {}
    for vuln in vulns:
        rows = []
        for s in db.analysis_sessions.find({"steps.result_data.shadow": {"$exists": True}}, {"steps": 1}):
            for st in s.get("steps", []):
                d = st.get("result_data") or {}
                if (st.get("vulnerability") or "timestamp") == vuln and "shadow" in d:
                    key = (str(s["_id"]), vuln)
                    rows.append({"active": d["predicted_class"] == "Vulnerable", "shadow": d["shadow"]["predicted_class"] == "Vulnerable",
                                 "version": d["shadow"]["version"], "expert": (key in confirmed) if key in reviewed else None})
        judged = [r for r in rows if r["expert"] is not None]
        report[vuln] = {"scans_with_shadow": len(rows), "shadow_versions": sorted({r["version"] for r in rows}),
                        "models_agree": sum(r["active"] == r["shadow"] for r in rows),
                        "expert_reviewed": len(judged),
                        "active_matches_expert": sum(r["active"] == r["expert"] for r in judged),
                        "shadow_matches_expert": sum(r["shadow"] == r["expert"] for r in judged)}
    print(json.dumps(report, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["timestamp", "reentrancy"]))
