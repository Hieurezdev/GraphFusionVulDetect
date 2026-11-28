"""Deleting uploaded code everywhere it is kept, by hand or when its retention period ends.

A scan's code lives in: its storage directory (the .sol file and the call graphs), its session document (function code,
fixes), the knowledge base (only with training consent) and the label log (expert verdicts). Deleting a scan removes
the first three and scrubs the code, notes and paths from the label log, whose hash chain stays valid (label_log.scrub).
Every deletion is written to the deletion log, without any code.
"""
import asyncio
import logging
import shutil
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

from bson import ObjectId

from src.config.settings import settings
from src.infrastructure.database import (get_analysis_sessions_collection, get_collection, get_label_events_collection,
                                         get_projects_collection)
from src.services import knowledge
from src.services.label_log import scrub

logger = logging.getLogger(__name__)
STORAGE_ROOT = Path("storage").resolve()  # /analyze stores every upload in its own directory under ./storage


def own_directory(file_path: Optional[str]) -> Optional[Path]:
    """The scan's own upload directory, never storage itself or anything outside it (a path from the database is not trusted)."""
    if not file_path:
        return None
    d = Path(file_path).resolve().parent
    return d if STORAGE_ROOT in d.parents else None


async def log_deletion(organization_id, kind: str, target_id: str, actor: str, reason: str, removed: dict, **info) -> None:
    await (await get_collection("deletion_log")).insert_one({
        "organization_id": organization_id, "kind": kind, "target_id": target_id, "actor": actor, "reason": reason,
        "removed": removed, "at": datetime.now(timezone.utc), **info})


async def delete_session(session: dict, actor: str, reason: str = "manual") -> dict:
    """Remove one scan and its code everywhere; returns what was removed. Files go first: if anything fails, the
    session document is still there and the deletion can be run again."""
    sid = str(session["_id"])
    removed = {"files": 0, "knowledge_items": 0, "label_events_scrubbed": 0}
    directory = own_directory(session.get("file_path"))
    if directory and directory.exists():
        removed["files"] = sum(1 for p in directory.rglob("*") if p.is_file())
        await asyncio.to_thread(shutil.rmtree, directory)
    events = await get_label_events_collection()
    seqs = [e["seq"] async for e in events.find({"session_id": sid}, {"seq": 1})]
    removed["knowledge_items"] = await asyncio.to_thread(knowledge.remove_for_sessions, [sid], seqs)
    removed["label_events_scrubbed"] = await scrub(events, {"session_id": sid},
                                                   {"function_code": None, "file_path": None, "graph_path": None, "note": None})
    if session.get("project_id"):
        try:
            await (await get_projects_collection()).update_one(
                {"_id": ObjectId(session["project_id"])}, {"$pull": {"files": {"file_path": session.get("file_path")}}})
        except Exception as e:  # a malformed project id must not keep the code stored
            logger.warning(f"project reference of session {sid} not removed: {e}")
    await (await get_analysis_sessions_collection()).delete_one({"_id": session["_id"]})
    await log_deletion(session.get("organization_id"), "session", sid, actor, reason, removed,
                       filename=session.get("filename"), project_id=session.get("project_id"))
    return removed


async def delete_project(project: dict, actor: str) -> dict:
    """A project with every scan in it."""
    sessions = await get_analysis_sessions_collection()
    total = {"sessions": 0, "files": 0, "knowledge_items": 0, "label_events_scrubbed": 0}
    async for s in sessions.find({"project_id": str(project["_id"])}):
        for k, v in (await delete_session(s, actor, reason="project_deleted")).items():
            total[k] += v
        total["sessions"] += 1
    await (await get_projects_collection()).delete_one({"_id": project["_id"]})
    await log_deletion(project.get("organization_id"), "project", str(project["_id"]), actor, "manual", total, name=project.get("name"))
    return total


def expires_at(session: dict, retention_days: int):
    started = session.get("started_at")
    if not started:
        return None
    if started.tzinfo is None:
        started = started.replace(tzinfo=timezone.utc)
    return started + timedelta(days=retention_days)


async def purge_expired(now: Optional[datetime] = None) -> int:
    """Delete the scans older than their organisation's retention period; returns how many were deleted."""
    from src.services.organizations import policy_of
    now = now or datetime.now(timezone.utc)
    sessions = await get_analysis_sessions_collection()
    scopes = [({"organization_id": str(o["_id"])}, policy_of(o)["retention_days"])
              async for o in (await get_collection("organizations")).find({}, {"policy": 1})]
    scopes.append(({"organization_id": {"$in": [None]}}, settings.RETENTION_DAYS))  # ScanGuard reviewers' own uploads
    deleted = 0
    for query, days in scopes:
        expired = {**query, "started_at": {"$lt": now - timedelta(days=days)}, "status": {"$ne": "processing"}}
        async for s in sessions.find(expired):
            try:
                await delete_session(s, actor="system", reason="retention")
                deleted += 1
            except Exception as e:  # one stuck scan must not stop the others from expiring
                logger.error(f"retention: could not delete session {s['_id']}: {e}")
    return deleted


async def retention_loop() -> None:
    while True:
        try:
            n = await purge_expired()
            if n:
                logger.info(f"retention: deleted {n} expired scan(s)")
        except Exception as e:
            logger.error(f"retention run failed: {e}")
        await asyncio.sleep(settings.RETENTION_INTERVAL_SECONDS)
