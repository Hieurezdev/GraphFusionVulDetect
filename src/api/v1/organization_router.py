"""Workspace administration for its admin (docs/KE_HOACH_BAO_VE_MA_NGUON.md, section 6): members and roles, the data
policy, projects, the audit log and the deletion history. Nothing here returns code."""
import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import Response

from src.infrastructure.database import get_analysis_sessions_collection, get_collection, get_projects_collection, get_users_collection
from src.models.entity import MemberCreate, MemberUpdate, PolicyUpdate, UserInDB
from src.services import audit, data_lifecycle, knowledge
from src.services.access import LEGACY_ROLES as LEGACY, can
from src.services.organizations import policy_of
from src.utils.helper import get_password_hash
from .authentication_router import get_current_user

router = APIRouter(prefix="/organization", tags=["organization"])
MEMBER_FIELDS = ("username", "email", "full_name", "role", "is_active", "created_at", "last_login", "consents")


async def require_admin(current_user: UserInDB = Depends(get_current_user)) -> UserInDB:
    if not current_user.organization_id or not can(current_user, "manage_organization"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the workspace admin can do this")
    return current_user


def _member(doc: dict) -> dict:
    from src.services.legal import missing_consents
    out = {k: doc.get(k) for k in MEMBER_FIELDS}
    out["id"], out["role"] = str(doc["_id"]), LEGACY.get(doc.get("role"), doc.get("role"))
    out["consents_ok"] = not missing_consents(type("U", (), {"consents": doc.get("consents") or {}})())
    del out["consents"]
    return out



@router.get("")
async def overview(admin: UserInDB = Depends(require_admin)):
    """The workspace, its policy and the dashboard figures."""
    org_id = admin.organization_id
    sessions, projects, users = await get_analysis_sessions_collection(), await get_projects_collection(), await get_users_collection()
    month = datetime.now(timezone.utc).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    policy = policy_of(admin.organization)
    alerts, pending, verdicts, fixes, soon = {}, 0, {"confirmed": 0, "false_positive": 0, "needs_manual_review": 0}, 0, 0
    today = datetime.now(timezone.utc).date()
    days = {(today - timedelta(days=i)).isoformat(): {"scans": 0, "flagged": 0} for i in range(29, -1, -1)}
    from src.services.findings import session_findings
    horizon = datetime.now(timezone.utc) + timedelta(days=7)
    async for s in sessions.find({"organization_id": org_id}, {"steps.vulnerability": 1, "steps.result_data.func_vulnerability_predictions.prediction": 1,
                                                               "steps.result_data.func_vulnerability_predictions.function_name": 1,
                                                               "reviews": 1, "fixes": 1, "started_at": 1}):
        found = session_findings(s)
        started = s.get("started_at")
        day = started.date().isoformat() if hasattr(started, "date") else None
        if day in days:
            days[day]["scans"] += 1
            days[day]["flagged"] += bool(found)
        for f in found:
            alerts[f["vulnerability"]] = alerts.get(f["vulnerability"], 0) + 1
            status_ = (f["review"] or {}).get("status", "pending")
            if status_ == "pending":
                pending += 1
            elif status_ in verdicts:
                verdicts[status_] += 1
        fixes += sum(1 for x in s.get("fixes") or [] if x.get("decision") == "accepted")
        exp = data_lifecycle.expires_at(s, policy["retention_days"])
        soon += bool(exp and exp <= horizon)
    return {
        "organization": {"id": org_id, "name": (admin.organization or {}).get("name"), "personal": bool((admin.organization or {}).get("personal"))},
        "policy": policy,
        "stats": {"projects": await projects.count_documents({"organization_id": org_id}),
                  "members": await users.count_documents({"organization_id": org_id}),
                  "scans_this_month": await sessions.count_documents({"organization_id": org_id, "started_at": {"$gte": month}}),
                  "alerts_by_vulnerability": alerts, "alerts_pending_review": pending, "verdicts": verdicts,
                  "fixes_accepted": fixes, "storage_bytes": _storage_bytes([p async for p in projects.find({"organization_id": org_id}, {"files.file_size": 1})]),
                  "scans_expiring_in_7_days": soon,
                  "scans_by_day": [{"day": d, **v} for d, v in days.items()],
                  "members_by_role": {LEGACY.get(r["_id"], r["_id"]): r["n"] async for r in users.aggregate(
                      [{"$match": {"organization_id": org_id}}, {"$group": {"_id": "$role", "n": {"$sum": 1}}}])}},
    }


def _storage_bytes(projects: list) -> int:
    return sum(f.get("file_size") or 0 for p in projects for f in p.get("files") or [])


# ---- Members -----------------------------------------------------------------------------------------------------
@router.get("/members")
async def list_members(admin: UserInDB = Depends(require_admin)):
    users = await get_users_collection()
    return [_member(u) async for u in users.find({"organization_id": admin.organization_id}).sort("created_at", 1)]


@router.post("/members", status_code=201)
async def add_member(body: MemberCreate, admin: UserInDB = Depends(require_admin)):
    """The admin creates the account directly; the new member accepts the terms at their first sign-in."""
    if (admin.organization or {}).get("personal"):
        raise HTTPException(status_code=403, detail="A personal (guest) account has no members: register a business account to add a team")
    users = await get_users_collection()
    names = [body.username, body.email]
    if await users.find_one({"$or": [{"username": {"$in": names}}, {"email": {"$in": names}}]}):
        raise HTTPException(status_code=400, detail="Username or email already registered")
    doc = {"username": body.username, "email": body.email, "full_name": body.full_name, "hashed_password": get_password_hash(body.password),
           "is_active": True, "role": body.role, "organization_id": admin.organization_id, "consents": {},
           "created_at": datetime.now(timezone.utc), "last_login": None}
    doc["_id"] = (await users.insert_one(dict(doc))).inserted_id
    await audit.record(admin, "member_add", admin.organization_id, target=body.username, detail={"role": body.role})
    return _member(doc)


async def _target(member_id: str, admin: UserInDB) -> dict:
    try:
        doc = await (await get_users_collection()).find_one({"_id": ObjectId(member_id), "organization_id": admin.organization_id})
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid member id")
    if not doc:
        raise HTTPException(status_code=404, detail="Member not found")
    return doc


async def _other_active_admins(admin: UserInDB, member_id: str) -> int:
    return await (await get_users_collection()).count_documents(
        {"organization_id": admin.organization_id, "role": {"$in": ["admin", "user"]}, "is_active": True, "_id": {"$ne": ObjectId(member_id)}})


@router.put("/members/{member_id}")
async def update_member(member_id: str, body: MemberUpdate, admin: UserInDB = Depends(require_admin)):
    doc = await _target(member_id, admin)
    change = {k: v for k, v in body.model_dump().items() if v is not None}
    if not change:
        raise HTTPException(status_code=400, detail="Nothing to change")
    loses_admin = (change.get("role", "admin") != "admin" or change.get("is_active") is False) and LEGACY.get(doc.get("role"), doc.get("role")) == "admin"
    if loses_admin and not await _other_active_admins(admin, member_id):
        raise HTTPException(status_code=409, detail="The workspace must keep at least one active admin")
    update = {"$set": change}
    if change.get("is_active") is False or "role" in change:
        update["$inc"] = {"token_version": 1}  # sign the member out everywhere: their old token carries the old rights
    await (await get_users_collection()).update_one({"_id": doc["_id"]}, update)
    await audit.record(admin, "member_update", admin.organization_id, target=doc["username"],
                       detail={k: {"from": LEGACY.get(doc.get(k), doc.get(k)), "to": v} for k, v in change.items()})
    return _member({**doc, **change})


@router.delete("/members/{member_id}")
async def remove_member(member_id: str, admin: UserInDB = Depends(require_admin)):
    """Remove the account from the workspace (it is deleted). Its scans stay: they belong to the organisation."""
    doc = await _target(member_id, admin)
    if LEGACY.get(doc.get("role"), doc.get("role")) == "admin" and not await _other_active_admins(admin, member_id):
        raise HTTPException(status_code=409, detail="The workspace must keep at least one active admin")
    await (await get_users_collection()).delete_one({"_id": doc["_id"]})
    await audit.record(admin, "member_remove", admin.organization_id, target=doc["username"])
    return {"message": "Member removed"}


# ---- Data policy -------------------------------------------------------------------------------------------------
async def apply_policy(admin: UserInDB, change: dict) -> dict:
    """Store a policy change, log it, and act on it: withdrawing training consent removes the workspace's code from the
    knowledge base and keeps it out of future verdicts."""
    before = policy_of(admin.organization)
    change = {k: v for k, v in change.items() if v is not None and before.get(k) != v}
    if not change:
        return before
    await (await get_collection("organizations")).update_one({"_id": ObjectId(admin.organization_id)},
                                                             {"$set": {f"policy.{k}": v for k, v in change.items()}})
    detail = {k: {"from": before.get(k), "to": v} for k, v in change.items()}
    if change.get("training_data") is False:
        sessions = await get_analysis_sessions_collection()
        ids = [str(s["_id"]) async for s in sessions.find({"organization_id": admin.organization_id}, {"_id": 1})]
        await sessions.update_many({"organization_id": admin.organization_id}, {"$set": {"training_consent": False}})
        from src.infrastructure.database import get_label_events_collection
        seqs = [e["seq"] async for e in (await get_label_events_collection()).find({"session_id": {"$in": ids}}, {"seq": 1})]
        detail["knowledge_items_removed"] = await asyncio.to_thread(knowledge.remove_for_sessions, ids, seqs)
    await audit.record(admin, "policy_change", admin.organization_id, detail=detail)
    return {**before, **change}


@router.put("/policy")
async def update_policy(body: PolicyUpdate, admin: UserInDB = Depends(require_admin)):
    return await apply_policy(admin, body.model_dump())


# ---- Projects ----------------------------------------------------------------------------------------------------
@router.get("/projects")
async def list_projects(admin: UserInDB = Depends(require_admin)):
    projects, sessions = await get_projects_collection(), await get_analysis_sessions_collection()
    out = []
    async for p in projects.find({"organization_id": admin.organization_id}).sort("updated_at", -1):
        pid = str(p["_id"])
        out.append({"id": pid, "name": p.get("name"), "status": p.get("status"),
                    "scans": await sessions.count_documents({"project_id": pid}),
                    "alerts": await sessions.count_documents({"project_id": pid, "steps.result_data.func_vulnerability_predictions.prediction": 1}),
                    "storage_bytes": _storage_bytes([p]), "updated_at": p.get("updated_at")})
    return out


# ---- Audit log and deletion history ------------------------------------------------------------------------------
def _since(value: Optional[str]):
    try:
        return datetime.fromisoformat(value) if value else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Dates must be ISO 8601, e.g. 2026-11-01")


async def _rows(name: str, query: dict, since, until, limit: int) -> list:
    if since or until:
        query["at"] = {**({"$gte": since} if since else {}), **({"$lte": until} if until else {})}
    rows = await (await get_collection(name)).find(query, {"_id": 0}).sort("at", -1).limit(limit).to_list(length=limit)
    return rows


@router.get("/audit")
async def audit_log(actor: Optional[str] = None, action: Optional[str] = None, since: Optional[str] = None, until: Optional[str] = None,
                    format: str = Query("json", pattern="^(json|csv)$"), limit: int = Query(500, ge=1, le=10000),
                    admin: UserInDB = Depends(require_admin)):
    query = {"organization_id": admin.organization_id, **({"actor": actor} if actor else {}), **({"action": action} if action else {})}
    rows = await _rows("audit_log", query, _since(since), _since(until), limit)
    if format == "csv":
        return Response(audit.to_csv(rows, ["at", "actor", "actor_role", "action", "target", "detail"]), media_type="text/csv",
                        headers={"Content-Disposition": "attachment; filename=audit-log.csv"})
    return rows


@router.get("/deletions")
async def deletion_history(since: Optional[str] = None, until: Optional[str] = None, format: str = Query("json", pattern="^(json|csv)$"),
                           limit: int = Query(500, ge=1, le=10000), admin: UserInDB = Depends(require_admin)):
    rows = await _rows("deletion_log", {"organization_id": admin.organization_id}, _since(since), _since(until), limit)
    if format == "csv":
        return Response(audit.to_csv(rows, ["at", "kind", "target_id", "filename", "name", "actor", "reason", "removed"]), media_type="text/csv",
                        headers={"Content-Disposition": "attachment; filename=deletions.csv"})
    return rows
