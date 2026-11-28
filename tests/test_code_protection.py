"""End-to-end checks of the protection of uploaded code (docs/KE_HOACH_BAO_VE_MA_NGUON.md) against a real MongoDB.

Run with a throwaway database, e.g.:
    docker run -d --name gfdtest-mongo -p 27099:27017 mongo:7
    TEST_MONGODB_URL=mongodb://localhost:27099 pytest tests/test_code_protection.py
"""
import os
import shutil
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

URL = os.environ.get("TEST_MONGODB_URL")
pytestmark = pytest.mark.skipif(not URL, reason="needs TEST_MONGODB_URL (a throwaway MongoDB)")


@pytest.fixture(scope="module")
def env():
    os.environ["MONGODB_URL"], os.environ["MONGODB_DATABASE"] = URL, "gfd_protection_test"
    from src.config.settings import settings
    settings.MONGODB_URL, settings.MONGODB_DATABASE, settings.LOCAL_LLM_MODEL = URL, "gfd_protection_test", ""
    from pymongo import MongoClient
    MongoClient(URL).drop_database("gfd_protection_test")
    from fastapi import FastAPI
    from fastapi.testclient import TestClient
    from src.api.router import create_router
    from src.infrastructure.database import db_manager
    from src.services import knowledge
    knowledge._client = None
    db_manager.database = None
    app = FastAPI()
    app.include_router(create_router())
    with TestClient(app) as client:
        yield client
    MongoClient(URL).drop_database("gfd_protection_test")


def H(token):
    return {"Authorization": f"Bearer {token}"}


def login(c, name, password="secret1"):
    return c.post("/api/v1/auth/login", json={"username": name, "password": password}).json()["access_token"]


def accept(c, token, training=None):
    body = {"terms": True, "privacy": True, "upload_rights": True, **({} if training is None else {"training_data": training})}
    r = c.post("/api/v1/auth/consents", headers=H(token), json=body)
    assert r.status_code == 200, r.text
    return r.json()


def db():
    from pymongo import MongoClient
    return MongoClient(URL)["gfd_protection_test"]


def make_session(org_id, user_id, started=None):
    """A finished scan as /analyze stores it: an upload directory with the file and a graph, one flagged function."""
    d = Path("storage") / f"test_{os.urandom(4).hex()}"
    (d / "timestamp").mkdir(parents=True)
    (d / "c.sol").write_text("pragma solidity ^0.4.24; contract C { function f() public { if (now > 1) {} } }")
    (d / "timestamp" / "c.fcg").write_text("graph")
    doc = {"organization_id": org_id, "user_id": user_id, "file_path": str(d / "c.sol"), "filename": "c.sol", "file_hash": "h" + d.name,
           "status": "completed", "training_consent": True, "started_at": started or datetime.now(timezone.utc),
           "steps": [{"step_name": "detect_vulnerability_func", "vulnerability": "timestamp", "status": "completed",
                      "started_at": datetime.now(timezone.utc),
                      "result_data": {"fcg_file_path": str(d / "timestamp" / "c.fcg"),
                                      "func_vulnerability_predictions": [{"function_name": "C.f", "prediction": 1, "confidence": 0.9,
                                                                          "function_code": "function f() public { if (now > 1) {} }"}]}}]}
    sid = db().analysis_sessions.insert_one(doc).inserted_id
    return str(sid), d


def test_consent_roles_access_and_deletion(env):
    c = env
    from src.services.label_log import append_label_event, verify_events
    from src.infrastructure.database import get_label_events_collection

    # 1. A new account must accept the required texts before anything else
    assert c.post("/api/v1/auth/register", json={"username": "alice", "email": "alice@example.com", "password": "secret1",
                                                 "account_type": "business"}).status_code == 400  # needs the organisation's name
    assert c.post("/api/v1/auth/register", json={"username": "alice", "email": "alice@example.com", "password": "secret1",
                                                 "account_type": "business", "organization_name": "Acme"}).status_code == 200
    a = login(c, "alice")
    me = c.get("/api/v1/auth/me", headers=H(a)).json()
    assert me["role"] == "admin" and set(me["consents_required"]) == {"terms", "privacy", "upload_rights"}
    r = c.get("/api/v1/sessions", headers=H(a))
    assert r.status_code == 403 and r.json()["detail"]["code"] == "consent_required"
    assert c.post("/api/v1/auth/consents", headers=H(a), json={"terms": True}).status_code == 400
    me = accept(c, a, training=True)
    assert me["consents_required"] == [] and me["policy"]["training_data"] is True and me["organization_name"] == "Acme"
    assert "fix_tools" not in me["permissions"] and not me["personal_workspace"]  # a business admin manages, does not fix code
    assert c.get("/api/v1/sessions", headers=H(a)).status_code == 200
    assert {d["key"] for d in c.get("/api/v1/auth/legal").json()} == {"terms", "privacy", "upload_rights", "training_data"}
    assert c.get("/api/v1/auth/legal?lang=en").json()[0]["title"] == "Terms of use and software licence"

    # 2. The admin adds members
    for name, role in (("bob", "developer"), ("carol", "non_tech"), ("dave", "expert")):
        r = c.post("/api/v1/organization/members", headers=H(a), json={"username": name, "email": f"{name}@example.com", "password": "secret1", "role": role})
        assert r.status_code == 201, r.text
    tok = {n: login(c, n) for n in ("bob", "carol", "dave")}
    for t in tok.values():
        accept(c, t, training=False)  # a member's answer on training data is ignored
    me = c.get("/api/v1/auth/me", headers=H(a)).json()
    assert me["policy"]["training_data"] is True
    assert c.get("/api/v1/organization", headers=H(tok["bob"])).status_code == 403
    carol = c.get("/api/v1/auth/me", headers=H(tok["carol"])).json()
    assert {"upload", "view_source", "fix_tools"} <= set(carol["permissions"])  # non-tech works like a developer

    org = me["organization_id"]
    alice_id = me["user_id"]
    bob_id = c.get("/api/v1/auth/me", headers=H(tok["bob"])).json()["user_id"]
    sid, d = make_session(org, bob_id)  # the developer's own scan
    c.portal.call(_append, sid, org)  # on the app's event loop: the Motor client belongs to it
    db().knowledge.insert_one({"kind": "expert_verdict", "vulnerability": "timestamp", "code": "x", "session_id": sid, "vector": [0.1] * 4})

    # 3. Non-tech opens the code like a developer; the business admin has no fix tools
    s = c.get(f"/api/v1/sessions/{sid}", headers=H(tok["bob"])).json()
    assert s["expires_at"] and c.get(f"/api/v1/sessions/{sid}/source", headers=H(tok["carol"])).status_code == 404  # bob's, not hers
    assert c.post("/api/v1/refactor/chat/stream", headers=H(a), json={"code": "x", "conversation_history": [{"role": "user", "content": "hi"}]}).status_code == 403

    # 3b. The creator of a project may delete it (non-tech included); another member may not
    pid = c.post("/api/v1/projects/", headers=H(tok["carol"]), json={"name": "Carol's"}).json()["id"]
    assert [p["id"] for p in c.get("/api/v1/projects/", headers=H(tok["bob"])).json()] == []  # developers see only their own
    assert c.delete(f"/api/v1/projects/{pid}", headers=H(tok["bob"])).status_code == 404
    assert pid in [p["id"] for p in c.get("/api/v1/projects/", headers=H(a)).json()]  # the admin sees every project
    assert c.delete(f"/api/v1/projects/{pid}", headers=H(tok["carol"])).status_code == 200

    # 4. Another workspace cannot see it; the attempt is logged for this workspace's admin
    c.post("/api/v1/auth/register", json={"username": "eve", "email": "eve@example.com", "password": "secret1"})
    e = login(c, "eve")
    accept(c, e)
    assert c.get(f"/api/v1/sessions/{sid}", headers=H(e)).status_code == 404
    assert c.get(f"/api/v1/sessions/{sid}/source", headers=H(e)).status_code == 404

    # 5. The uploader opens the source (logged); another member cannot delete it
    assert "now" in c.get(f"/api/v1/sessions/{sid}/source", headers=H(tok["bob"])).json()["source"]
    assert c.delete(f"/api/v1/sessions/{sid}", headers=H(tok["carol"])).status_code == 404
    log = c.get("/api/v1/organization/audit", headers=H(a)).json()
    actions = {(x["actor"], x["action"]) for x in log}
    assert {("bob", "view_source"), ("carol", "access_denied"), ("eve", "access_denied"), ("alice", "member_add")} <= actions
    assert "view_source" in c.get("/api/v1/organization/audit?format=csv", headers=H(a)).text

    # 6. Deleting removes the files, the session and the knowledge item, scrubs the label log and keeps its chain valid
    r = c.delete(f"/api/v1/sessions/{sid}", headers=H(a))
    assert r.status_code == 200, r.text
    assert r.json()["removed"] == {"files": 2, "knowledge_items": 1, "label_events_scrubbed": 1}
    assert not d.exists() and db().analysis_sessions.count_documents({}) == 0 and db().knowledge.count_documents({}) == 0
    ev = db().label_events.find_one({"session_id": sid})
    assert ev["function_code"] is None and ev["verdict"] == "confirmed" and "function_code" in ev["scrubbed"]
    assert verify_events(db().label_events.find({}, sort=[("seq", 1)])) is None
    assert c.get(f"/api/v1/sessions/{sid}/source", headers=H(a)).status_code == 404
    dels = c.get("/api/v1/organization/deletions", headers=H(a)).json()
    assert dels[0]["kind"] == "session" and dels[0]["actor"] == "alice" and dels[0]["filename"] == "c.sol"

    # 7. Retention: a scan older than the workspace's period is purged
    c.put("/api/v1/organization/policy", headers=H(a), json={"retention_days": 7})
    old, old_dir = make_session(org, alice_id, started=datetime.now(timezone.utc) - timedelta(days=8))
    fresh, fresh_dir = make_session(org, alice_id)
    from src.services.data_lifecycle import purge_expired
    assert c.portal.call(purge_expired) == 1
    assert not old_dir.exists() and fresh_dir.exists()
    assert db().deletion_log.find_one({"target_id": old})["reason"] == "retention"

    # 8. Policy: no external LLM -> no fix assistant; withdrawing training consent
    assert c.put("/api/v1/organization/policy", headers=H(a), json={"external_llm": False}).json()["external_llm"] is False
    assert c.post("/api/v1/refactor/chat/stream", headers=H(tok["bob"]), json={"code": "x", "conversation_history": [{"role": "user", "content": "hi"}]}).status_code == 403
    c.put("/api/v1/organization/policy", headers=H(a), json={"training_data": False})
    assert db().analysis_sessions.find_one({"_id": __import__("bson").ObjectId(fresh)})["training_consent"] is False

    # 9. The workspace keeps an admin; a role change signs the member out
    members = {m["username"]: m for m in c.get("/api/v1/organization/members", headers=H(a)).json()}
    assert c.put(f"/api/v1/organization/members/{members['alice']['id']}", headers=H(a), json={"role": "developer"}).status_code == 409
    assert c.put(f"/api/v1/organization/members/{members['bob']['id']}", headers=H(a), json={"role": "non_tech"}).status_code == 200
    assert c.get("/api/v1/auth/me", headers=H(tok["bob"])).status_code == 401

    # 10. A personal (guest) workspace has no members; deleting the account deletes its workspace and code
    assert c.post("/api/v1/organization/members", headers=H(e), json={"username": "guestmember", "email": "gm@example.com", "password": "secret1", "role": "developer"}).status_code == 403
    _, eve_dir = make_session(c.get("/api/v1/auth/me", headers=H(e)).json()["organization_id"], "x")
    assert c.request("DELETE", "/api/v1/auth/account", headers=H(e), json={"password": "secret1"}).status_code == 200
    assert not eve_dir.exists() and db().users.count_documents({"username": "eve"}) == 0
    shutil.rmtree(fresh_dir, ignore_errors=True)


def test_accounts_from_before_organisations_get_a_workspace(env):
    from datetime import datetime, timezone
    from src.services.organizations import migrate_to_organizations
    users = db().users
    legacy = users.insert_one({"username": "old", "email": "old@example.com", "hashed_password": "x", "created_at": datetime.now(timezone.utc)}).inserted_id
    reviewer = users.insert_one({"username": "rev", "email": "rev@example.com", "hashed_password": "x", "role": "expert",
                                 "created_at": datetime.now(timezone.utc)}).inserted_id
    db().analysis_sessions.insert_one({"user_id": str(legacy), "file_path": "", "filename": "a.sol", "started_at": datetime.now(timezone.utc)})
    first = env.portal.call(migrate_to_organizations)
    assert first == {"organizations_created": 1, "sessions_stamped": 1}
    assert env.portal.call(migrate_to_organizations) == {"organizations_created": 0, "sessions_stamped": 0}
    old = users.find_one({"_id": legacy})
    assert old["role"] == "admin" and old["organization_id"]
    assert db().analysis_sessions.find_one({"user_id": str(legacy)})["organization_id"] == old["organization_id"]
    assert users.find_one({"_id": reviewer})["organization_id"] is None  # stays a ScanGuard reviewer


async def _append(sid, org):
    from src.infrastructure.database import get_label_events_collection
    from src.services.label_log import append_label_event
    return await append_label_event(await get_label_events_collection(), {
        "session_id": sid, "vulnerability": "timestamp", "function_name": "C.f", "function_code": "function f() {}",
        "file_path": "storage/x/c.sol", "verdict": "confirmed", "note": "uses now", "reviewer": "dave", "training_consent": True})


def test_label_log_v1_chain_migrates_and_detects_edits():
    from src.services.label_log import GENESIS, event_hash, migrate_to_v2, verify_events, SCRUBBABLE
    v1, prev = [], GENESIS
    for i in range(3):
        e = {"seq": i, "prev_hash": prev, "function_code": f"code {i}", "reviewer": "dave", "verdict": "confirmed"}
        e["hash"] = event_hash(e)
        prev = e["hash"]
        v1.append(e)
    v2 = migrate_to_v2(v1)
    assert verify_events(v2) is None and all(e["hash_version"] == 2 and e["v1_hash"] for e in v2)
    scrubbed = [dict(e) for e in v2]
    scrubbed[1].update(function_code=None, scrubbed=["function_code"])
    assert verify_events(scrubbed) is None
    edited = [dict(e) for e in v2]
    edited[1]["function_code"] = "something else"
    assert "function_code" in verify_events(edited)["problem"]
    edited = [dict(e) for e in v2]
    edited[2]["verdict"] = "false_positive"
    assert verify_events(edited)["problem"] == "content changed after it was written"
    broken = [dict(e) for e in v1]
    broken[0]["verdict"] = "false_positive"
    with pytest.raises(ValueError):
        migrate_to_v2(broken)
