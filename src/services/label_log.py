"""Append-only, hash-chained log of expert verdicts (step 1.3 of docs/KE_HOACH_TRIEN_KHAI.md).

The review stored on a session is overwritten when an expert changes their mind, so it cannot show who said what, or
prove that a label used for retraining was not edited afterwards. Every verdict is therefore also appended here as one
event: the function, what the model predicted, the expert's verdict, and whether the uploader agreed to their code
being used for training. Each event carries `seq` (unique index: concurrent writers cannot fork the chain) and
`hash` = sha256 of its canonical JSON, which includes the previous event's hash. Editing or deleting any stored event
breaks every hash after it, which `verify_events` reports.

Version 2 events can still be scrubbed when their contract is deleted: the fields that may carry code or a person's
name (SCRUBBABLE) are left out of the hash and replaced in it by their sha256 (`<field>_sha`). A scrubbed field is
listed in `scrubbed`; a field that is still present must match its sha, so editing it is still detected.
"""
import hashlib
import json
from datetime import datetime, timezone
from typing import Iterable, Optional

from pymongo.errors import DuplicateKeyError

GENESIS = "0" * 64
HASHED_OUT = ("_id", "hash")  # fields not covered by the hash
SCRUBBABLE = ("function_code", "file_path", "graph_path", "note", "reviewer")
HASH_VERSION = 2


def now_iso() -> str:
    """UTC timestamp as a string: Mongo truncates datetimes to milliseconds, which would change a hashed value."""
    return datetime.now(timezone.utc).isoformat(timespec="microseconds")


def _canon(value) -> bytes:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def field_sha(value) -> Optional[str]:
    return None if value is None else hashlib.sha256(_canon(value)).hexdigest()


def seal(event: dict) -> dict:
    """Make an event version 2: each scrubbable field is covered by its sha instead of its value."""
    for f in SCRUBBABLE:
        event[f + "_sha"] = field_sha(event.get(f))
    event["hash_version"] = HASH_VERSION
    return event


def event_hash(event: dict) -> str:
    out = HASHED_OUT + ((*SCRUBBABLE, "scrubbed") if event.get("hash_version", 1) >= 2 else ())
    return hashlib.sha256(_canon({k: v for k, v in event.items() if k not in out})).hexdigest()


def verify_events(events: Iterable[dict]) -> Optional[dict]:
    """First problem in a chain read in `seq` order, or None when every link and hash holds."""
    prev, expected_seq = GENESIS, 0
    for e in events:
        if e.get("seq") != expected_seq:
            return {"seq": e.get("seq"), "problem": f"expected seq {expected_seq} (an event was deleted or inserted)"}
        if e.get("prev_hash") != prev:
            return {"seq": e["seq"], "problem": "prev_hash does not match the previous event"}
        if event_hash(e) != e.get("hash"):
            return {"seq": e["seq"], "problem": "content changed after it was written"}
        if e.get("hash_version", 1) >= 2:
            changed = [f for f in SCRUBBABLE if f not in (e.get("scrubbed") or []) and field_sha(e.get(f)) != e.get(f + "_sha")]
            if changed:
                return {"seq": e["seq"], "problem": f"{', '.join(changed)} changed after it was written"}
        prev, expected_seq = e["hash"], expected_seq + 1
    return None


async def append_label_event(collection, event: dict, attempts: int = 8) -> dict:
    """Append one event at the end of the chain; retried when another writer took the same seq first."""
    for _ in range(attempts):
        last = await collection.find_one(sort=[("seq", -1)])
        doc = {**event, "seq": (last["seq"] + 1) if last else 0, "prev_hash": last["hash"] if last else GENESIS}
        doc.setdefault("created_at", now_iso())
        seal(doc)
        doc["hash"] = event_hash(doc)
        try:
            await collection.insert_one(dict(doc))
            return doc
        except DuplicateKeyError:
            continue
    raise RuntimeError("could not append to the label log: too many concurrent writers")


def build_label_event(session: dict, finding: dict, review: dict, reviewer: str, random_audit: bool = False) -> dict:
    """The event for one verdict: enough to rebuild a training sample without the session (code, graph, prediction)."""
    vuln = finding.get("vulnerability")
    prediction = next((p for step in session.get("steps", []) if (step.get("vulnerability") or "timestamp") == vuln
                       for p in (step.get("result_data") or {}).get("func_vulnerability_predictions") or []
                       if p.get("function_name") == finding.get("function_name")), {})
    graph = next(((step.get("result_data") or {}).get("fcg_file_path") for step in session.get("steps", [])
                  if (step.get("vulnerability") or "timestamp") == vuln and (step.get("result_data") or {}).get("fcg_file_path")), None)
    contract = next(((step.get("result_data") or {}) for step in session.get("steps", [])
                     if (step.get("vulnerability") or "timestamp") == vuln and "predicted_class" in (step.get("result_data") or {})), {})
    return {
        "session_id": str(session.get("_id")),
        "file_hash": session.get("file_hash"),
        "file_path": session.get("file_path"),
        "vulnerability": vuln,
        "function_name": finding.get("function_name"),
        # Without the uploader's consent the code is not kept here: nothing may train on it (the sha still identifies it)
        "function_code": prediction.get("function_code") if session.get("training_consent") else None,
        "lines": finding.get("lines") or prediction.get("lines"),
        "graph_path": graph,
        "model_prediction": prediction.get("prediction"),
        "model_confidence": prediction.get("confidence"),
        "contract_prediction": contract.get("predicted_class"),
        "contract_confidence": contract.get("confidence_score"),
        "model_version": session.get("model_versions", {}).get(vuln),
        "verdict": review.get("status"),
        "note": review.get("note"),
        "reviewer": reviewer,
        "training_consent": bool(session.get("training_consent", False)),
        "random_audit": random_audit,
    }



async def scrub(collection, query: dict, values: dict) -> int:
    """Blank or replace scrubbable fields of the matching events without breaking the chain (version 2 events).

    A version 1 event hashes these fields directly: scrubbing it breaks the chain from there on, so run
    scripts/migrate_label_log_v2.py first. Privacy wins: version 1 events are scrubbed too and the count is logged.
    """
    assert set(values) <= set(SCRUBBABLE), "only scrubbable fields can be scrubbed"
    result = await collection.update_many(query, {"$set": values, "$addToSet": {"scrubbed": {"$each": list(values)}}})
    return result.modified_count


def migrate_to_v2(events: list) -> list:
    """The same chain as version 2 events, re-linked in seq order. Refuses a chain that does not verify as it is."""
    problem = verify_events(events)
    if problem:
        raise ValueError(f"label log does not verify, not migrating: {problem}")
    prev, out = GENESIS, []
    for e in events:
        doc = {k: v for k, v in e.items() if k != "hash"}
        if doc.get("hash_version", 1) < 2:
            doc["v1_hash"] = e["hash"]
            seal(doc)
        doc["prev_hash"] = prev
        doc["hash"] = event_hash(doc)
        prev = doc["hash"]
        out.append(doc)
    return out


# ---- Step 2.6: two-expert agreement --------------------------------------------------------------------------------
def item_key(event: dict) -> tuple:
    return event.get("session_id"), event.get("vulnerability"), event.get("function_name")


def latest_verdicts(events) -> dict:
    """item -> {reviewer: their latest verdict}; events must come in seq order (a reviewer may change their mind)."""
    out = {}
    for e in events:
        out.setdefault(item_key(e), {})[e.get("reviewer")] = e.get("verdict")
    return out


def consensus(events, min_reviewers: int = 2) -> dict:
    """item -> agreed verdict, only where at least `min_reviewers` different experts gave the same final verdict and nobody
    disagrees. needs_manual_review never counts as agreement on a label."""
    agreed = {}
    for key, by in latest_verdicts(events).items():
        verdicts = set(by.values())
        if len(by) >= min_reviewers and len(verdicts) == 1 and verdicts <= {"confirmed", "false_positive"}:
            agreed[key] = verdicts.pop()
    return agreed


def disagreements(events) -> list:
    """Items where experts' final verdicts differ: they need a third look before any of them is used for training."""
    return [{"session_id": k[0], "vulnerability": k[1], "function_name": k[2], "verdicts": by}
            for k, by in latest_verdicts(events).items() if len(set(by.values())) > 1]


def cohen_kappa(pairs) -> Optional[float]:
    """Cohen's kappa for two raters over items labelled by both: [(verdict_a, verdict_b), ...]."""
    pairs = list(pairs)
    if not pairs:
        return None
    labels = sorted({x for p in pairs for x in p})
    n = len(pairs)
    po = sum(a == b for a, b in pairs) / n
    pe = sum((sum(a == l for a, _ in pairs) / n) * (sum(b == l for _, b in pairs) / n) for l in labels)
    return 1.0 if pe == 1 else round((po - pe) / (1 - pe), 4)


def reviewer_rates(events, min_items: int = 10, factor: float = 2.0) -> list:
    """Per expert: how often they reject alerts. Flag one whose rejection rate is over `factor` times the others' (a
    possible sign of careless or poisoned labels), once they have reviewed at least `min_items` items."""
    by_reviewer = {}
    for (_, _, _), by in latest_verdicts(events).items():
        for reviewer, verdict in by.items():
            by_reviewer.setdefault(reviewer, []).append(verdict)
    rows = []
    for reviewer, verdicts in by_reviewer.items():
        others = [v for r, vs in by_reviewer.items() if r != reviewer for v in vs]
        rate = verdicts.count("false_positive") / len(verdicts)
        base = others.count("false_positive") / len(others) if others else None
        rows.append({"reviewer": reviewer, "items": len(verdicts), "rejection_rate": round(rate, 3),
                     "others_rate": round(base, 3) if base is not None else None,
                     "flag": bool(len(verdicts) >= min_items and base is not None and rate > factor * max(base, 0.05))})
    return rows
