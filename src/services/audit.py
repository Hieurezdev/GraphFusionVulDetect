"""Append-only audit log of an organisation: who opened whose code, deleted what, changed a role or the data policy.
Shown to the organisation's admin. Entries never hold code."""
import csv
import io
import json
from datetime import datetime, timezone
from typing import Optional

from src.infrastructure.database import get_collection

ACTIONS = ("view_source", "export_sarif", "access_denied", "request_review", "delete_session", "delete_project",
           "delete_account", "member_add", "member_update", "member_remove", "policy_change", "consent")


async def record(actor, action: str, organization_id: Optional[str], target: Optional[str] = None, detail: Optional[dict] = None) -> None:
    assert action in ACTIONS, action
    await (await get_collection("audit_log")).insert_one({
        "organization_id": organization_id,
        "actor": getattr(actor, "username", actor) if actor else "system",
        "actor_role": getattr(actor, "role", None),
        "action": action, "target": target, "detail": detail or {},
        "at": datetime.now(timezone.utc),
    })


def _cell(v):
    if hasattr(v, "isoformat"):
        return v.isoformat()
    return json.dumps(v, ensure_ascii=False, default=str) if isinstance(v, (dict, list)) else v


def to_csv(rows: list, fields: list) -> str:
    out = io.StringIO()
    w = csv.DictWriter(out, fieldnames=fields, extrasaction="ignore")
    w.writeheader()
    for r in rows:
        w.writerow({k: _cell(r.get(k)) for k in fields})
    return out.getvalue()
