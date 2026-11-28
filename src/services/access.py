"""Who may do what with an organisation's code (docs/KE_HOACH_BAO_VE_MA_NGUON.md, section 4).

An organisation (workspace) owns its projects, scans and code. Every member has one role:
  admin      business administrator: members, data policy, audit log, deletion; never reviews alerts or fixes;
  developer  uploads code, uses the IDE, SARIF and the fix tools;
  non_tech   the same rights as a developer; the interface and the AI texts avoid technical words for them;
  expert     the organisation's own reviewer: confirms or rejects alerts and decides on fixes.
An expert without an organisation is a ScanGuard reviewer: they see a scan only when its owner asked for a review and
the organisation's policy lets ScanGuard reviewers in.

Developers and non-technical members see only the projects and scans they created; the admin and the workspace's
experts see all of the workspace's.
"""
from typing import Optional

ROLES = ("admin", "developer", "non_tech", "expert")
OWN_ONLY = {"developer", "non_tech"}  # see only what they uploaded themselves
ROLE_LABELS = {"admin": "Admin", "developer": "Developer", "non_tech": "Non-tech", "expert": "Expert"}
LEGACY_ROLES = {"user": "admin"}  # accounts from before organisations: each one is alone in its own workspace

PERMISSIONS = {
    "upload": {"admin", "developer", "non_tech", "expert"},       # create projects, upload, look up tokens
    "view_source": {"admin", "developer", "non_tech", "expert"},  # source, IDE, function code, SARIF
    "fix_tools": {"developer", "non_tech", "expert"},             # RefactorBot, repair agent, compile a fix
    "request_review": {"admin", "developer", "non_tech"},
    "delete_own_session": {"admin", "developer", "non_tech"},
    "delete_any_session": {"admin"},
    "delete_project": {"admin"},
    "review": {"expert"},                                 # verdicts on alerts and decisions on fixes
    "manage_organization": {"admin"},                     # members, policy, audit log, deletion history
}
# Alone in a personal workspace the admin is also its developer: without this, a self-registered user could not fix code.
PERSONAL_ADMIN_EXTRA = {"fix_tools"}


def role_of(user) -> str:
    return LEGACY_ROLES.get(user.role, user.role)


def is_platform_expert(user) -> bool:
    return role_of(user) == "expert" and not user.organization_id


def plain_language(user) -> bool:
    """Texts for this user avoid technical words (the interface does the same on its side)."""
    return role_of(user) == "non_tech"


def is_personal(user) -> bool:
    org = getattr(user, "organization", None)
    return not user.organization_id or bool((org or {}).get("personal"))


def can(user, permission: str) -> bool:
    role = role_of(user)
    if role in PERMISSIONS[permission]:
        return True
    return role == "admin" and permission in PERSONAL_ADMIN_EXTRA and is_personal(user)


def allowed(user) -> list:
    """The permissions of this user, for the client (it hides what the server would refuse anyway)."""
    return sorted(p for p in PERMISSIONS if can(user, p))


def scope(user, platform_orgs: Optional[list] = None) -> dict:
    """MongoDB filter of the scans (and projects) this user may open.

    platform_orgs: ids of the organisations that let ScanGuard reviewers in (only read for a ScanGuard reviewer).
    """
    if is_platform_expert(user):
        return {"$or": [{"user_id": user.id},
                        {"review_requested": True, "organization_id": {"$in": list(platform_orgs or [])}}]}
    if user.organization_id and role_of(user) in OWN_ONLY:
        return {"organization_id": user.organization_id, "user_id": user.id}
    if user.organization_id:
        return {"organization_id": user.organization_id}
    return {"user_id": user.id}  # an account not migrated yet: only what it uploaded itself
