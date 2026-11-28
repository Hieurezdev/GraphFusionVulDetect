"""Agreement report of the expert label log (step 2.6 of docs/KE_HOACH_TRIEN_KHAI.md).

Prints: items reviewed by two or more experts, Cohen's kappa between the first two reviewers of each such item,
the items they disagree on, and each expert's rejection rate with a flag when it is far above the others'.
Usage: uv run python scripts/label_agreement.py
"""
import json
import sys

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
from pymongo import MongoClient  # noqa: E402

from src.config.settings import settings  # noqa: E402
from src.services.label_log import cohen_kappa, consensus, disagreements, latest_verdicts, reviewer_rates  # noqa: E402


def main():
    events = list(MongoClient(settings.MONGODB_URL)[settings.MONGODB_DATABASE].label_events.find({}, sort=[("seq", 1)]))
    lv = latest_verdicts(events)
    pairs = [tuple(list(by.values())[:2]) for by in lv.values() if len(by) >= 2]
    report = {"events": len(events), "items": len(lv), "items_with_two_or_more_reviewers": len(pairs),
              "cohen_kappa": cohen_kappa(pairs), "agreed_items": len(consensus(events)),
              "disagreements": disagreements(events), "reviewers": reviewer_rates(events)}
    print(json.dumps(report, indent=1, ensure_ascii=False, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
