"""Organisations (workspaces) and their data policy. See src/services/access.py for the roles."""
from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId

from src.config.settings import settings
from src.infrastructure.database import get_collection, get_users_collection, get_projects_collection, get_analysis_sessions_collection


def default_policy() -> dict:
    return {
        "retention_days": settings.RETENTION_DAYS,
        # The explainer and RefactorBot send flagged function code to the configured LLM; off = no explanations or chat
        # unless the server runs a local model (LOCAL_LLM_MODEL).
        "external_llm": True,
        "training_data": False,     # code and verdicts may be used to retrain the models (off until an admin opts in)
        "platform_experts": False,  # ScanGuard reviewers may open scans whose owner asked for a review
    }


def policy_of(org: Optional[dict]) -> dict:
    return {**default_policy(), **((org or {}).get("policy") or {})}


def llm_is_external() -> bool:
    return not settings.LOCAL_LLM_MODEL


def llm_allowed(org: Optional[dict]) -> bool:
    """May this organisation's code go to the LLM the server is configured with?"""
    return not llm_is_external() or policy_of(org)["external_llm"]


async def create_organization(name: str, personal: bool) -> dict:
    orgs = await get_collection("organizations")
    doc = {"name": name, "personal": personal, "policy": default_policy(), "created_at": datetime.now(timezone.utc)}
    doc["_id"] = (await orgs.insert_one(dict(doc))).inserted_id
    return doc


async def get_organization(org_id: Optional[str]) -> Optional[dict]:
    if not org_id:
        return None
    return await (await get_collection("organizations")).find_one({"_id": ObjectId(org_id)})


async def platform_review_orgs() -> list:
    """Ids of the organisations that let ScanGuard reviewers open the scans sent to them."""
    orgs = await get_collection("organizations")
    return [str(o["_id"]) async for o in orgs.find({"policy.platform_experts": True}, {"_id": 1})]


async def migrate_to_organizations() -> dict:
    """Idempotent, at startup: give every account from before organisations its own personal workspace (as its admin)
    and stamp its projects and scans with it. Experts without one stay ScanGuard reviewers."""
    users, projects, sessions = await get_users_collection(), await get_projects_collection(), await get_analysis_sessions_collection()
    created = 0
    async for user in users.find({"organization_id": {"$exists": False}}):
        if user.get("role") == "expert":
            await users.update_one({"_id": user["_id"]}, {"$set": {"organization_id": None}})
            continue
        org = await create_organization(f"{user.get('full_name') or user['username']}", personal=True)
        await users.update_one({"_id": user["_id"]}, {"$set": {"organization_id": str(org["_id"]), "role": "admin"}})
        created += 1
    stamped = 0
    async for user in users.find({"organization_id": {"$type": "string"}}, {"organization_id": 1}):
        missing = {"user_id": str(user["_id"]), "organization_id": {"$exists": False}}
        stamp = {"$set": {"organization_id": user["organization_id"]}}
        await projects.update_many(missing, stamp)
        stamped += (await sessions.update_many(missing, stamp)).modified_count
    return {"organizations_created": created, "sessions_stamped": stamped}
