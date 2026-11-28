"""Check the hash chain of the expert label log (step 1.3 of docs/KE_HOACH_TRIEN_KHAI.md).

Exit code 0 = every event is intact; 1 = the first broken event is printed (edited, deleted or inserted afterwards).
Usage: uv run python scripts/verify_label_log.py
"""
import sys

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
from pymongo import MongoClient  # noqa: E402

from src.config.settings import settings  # noqa: E402
from src.services.label_log import verify_events  # noqa: E402


def main() -> int:
    col = MongoClient(settings.MONGODB_URL)[settings.MONGODB_DATABASE].label_events
    total = col.count_documents({})
    problem = verify_events(col.find({}, sort=[("seq", 1)]))
    if problem:
        print(f"BROKEN at seq {problem['seq']}: {problem['problem']} ({total} events)")
        return 1
    print(f"OK: {total} events, chain intact")
    return 0


if __name__ == "__main__":
    sys.exit(main())
