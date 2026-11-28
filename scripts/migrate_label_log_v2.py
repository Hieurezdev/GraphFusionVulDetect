"""One-off: convert the label log to version 2 events, so a deleted contract's code can be scrubbed from it without
breaking the hash chain (src/services/label_log.py). Run once on each deployment, backend stopped or idle:

    python -m scripts.migrate_label_log_v2            # dry run: verifies the chain and reports
    python -m scripts.migrate_label_log_v2 --apply    # rewrites every event (the old hash is kept as v1_hash)

It refuses a chain that does not verify as it is, so a tampered log is never re-sealed.
"""
import sys

from pymongo import MongoClient

from src.config.settings import settings
from src.services.label_log import migrate_to_v2, verify_events


def main(apply: bool) -> None:
    col = MongoClient(settings.MONGODB_URL)[settings.MONGODB_DATABASE].label_events
    events = list(col.find({}, sort=[("seq", 1)]))
    old = sum(e.get("hash_version", 1) < 2 for e in events)
    migrated = migrate_to_v2(events)
    assert verify_events(migrated) is None
    print(f"{len(events)} event(s), {old} in version 1; chain verifies.")
    if not apply:
        print("Dry run: nothing written. Add --apply to rewrite.")
        return
    for doc in migrated:
        col.replace_one({"_id": doc["_id"]}, doc)
    assert verify_events(col.find({}, sort=[("seq", 1)])) is None
    print(f"Rewrote {len(migrated)} event(s) as version 2; chain verifies.")


if __name__ == "__main__":
    main("--apply" in sys.argv)
