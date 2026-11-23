"""Human confirmation gates plus optional real compiler/EVM demonstration."""

import hashlib
import os
from pathlib import Path

import pytest

from src.models.ai_safety import BehavioralTestCase, BehavioralTests, VerificationResult
from src.services.solidity_validation import validate_solidity
from test_refactor_review import client  # Reuse the API fixture without a real database or provider.

EXAMPLES = Path(__file__).resolve().parents[1] / "examples" / "reviewed_repair"


def start_thread(web, code="contract Example {}"):
    review = web.post("/refactor/review", json={"operation": "advice", "code": code, "issue_description": "Synthetic model hypothesis requiring source review", "context_id": "demo:Vault.set"}).json()
    result = web.post("/refactor/advice", json={**review["payload"], "review_token": review["review_token"], "consent_confirmed": True})
    assert result.status_code == 200, result.text
    return result.json()


def finding_request(thread_id, decision="confirmed"):
    return {"thread_id": thread_id, "decision": decision, "start_line": 1, "end_line": 1,
            "evidence_note": "Synthetic expert attestation for test purposes: caller authorization is required by the specification.", "qualified_reviewer": True}


def proposal_request(thread_id, proposal, decision="accepted_for_manual_application"):
    return {"thread_id": thread_id, "proposal_sha256": hashlib.sha256(proposal.encode()).hexdigest(),
            "decision": decision, "note": "Synthetic reviewer checked the diff and specified remaining coverage risks.", "qualified_reviewer": True}


def test_review_requires_owner_qualification_valid_lines_and_exact_source(client):
    web, database, calls = client
    response = start_thread(web)
    request = finding_request(response["thread_id"])
    assert web.post("/refactor/finding-review", json={**request, "qualified_reviewer": False}).status_code == 422
    assert web.post("/refactor/finding-review", json={**request, "end_line": 2}).status_code == 422
    assert web.post("/refactor/finding-review", json={**request, "thread_id": "missing"}).status_code == 404
    review = web.post("/refactor/finding-review", json=request).json()
    assert review["reviewer_id"] == "alice" and review["qualification"] == "self_attested"
    assert review["source_sha256"] == hashlib.sha256(b"contract Example {}").hexdigest()
    from bson import BSON
    from src.models.ai_safety import FindingReview
    persisted = BSON(BSON.encode(FindingReview.model_validate(review).model_dump())).decode()
    assert FindingReview.model_validate(persisted).model_dump(mode="json")["reviewed_at"].endswith("Z")
    thread = database.refactor_threads.docs[response["thread_id"]]
    changed = {"operation": "conversation", "code": "contract Changed {}", "thread_id": response["thread_id"], "context_id": "demo:Vault.set", "conversation_history": [*thread["messages"], {"role": "user", "content": "Suggest a fix"}]}
    assert web.post("/refactor/review", json=changed).status_code == 409
    assert len(calls) == 1
    from src.api.v1 import refactorbot_router as api
    from types import SimpleNamespace
    web.app.dependency_overrides[api.get_current_user] = lambda: SimpleNamespace(id="bob")
    assert web.post("/refactor/finding-review", json=request).status_code == 404
    assert web.get(f'/refactor/threads/{response["thread_id"]}/report').status_code == 404


@pytest.mark.parametrize("decision", ["rejected", "manual_review"])
def test_unconfirmed_findings_cannot_trigger_repairs(client, decision):
    web, database, calls = client
    response = start_thread(web)
    assert web.post("/refactor/finding-review", json=finding_request(response["thread_id"], decision)).status_code == 200
    thread = database.refactor_threads.docs[response["thread_id"]]
    payload = {"operation": "conversation", "code": thread["code"], "thread_id": response["thread_id"], "context_id": "demo:Vault.set", "conversation_history": [*thread["messages"], {"role": "user", "content": "Suggest a fix"}]}
    review = web.post("/refactor/review", json=payload).json()
    result = web.post("/refactor/conversation", json={**review["payload"], "review_token": review["review_token"], "consent_confirmed": True})
    assert result.status_code == 409 and len(calls) == 1


def test_acceptance_requires_tests_and_is_invalidated_by_reverification(client, monkeypatch):
    from src.api.v1 import refactorbot_router as api
    web, database, _ = client
    response = start_thread(web)
    thread_id = response["thread_id"]
    web.post("/refactor/finding-review", json=finding_request(thread_id))
    thread = database.refactor_threads.docs[thread_id]
    proposal = "pragma solidity ^0.8.20; contract Fixed {}"
    thread["response"]["suggested_code"] = proposal
    request = proposal_request(thread_id, proposal)
    assert web.post("/refactor/proposal-review", json=request).status_code == 409
    manual = web.post("/refactor/proposal-review", json={**request, "decision": "manual_review"})
    assert manual.status_code == 200
    digest = request["proposal_sha256"]
    verification = VerificationResult(status="passed", message="Real behavior represented by a unit test fixture", source_sha256=digest)
    thread["response"]["verification"] = verification.model_dump()
    assert web.post("/refactor/proposal-review", json=request).status_code == 409
    thread["test_source"] = "contract FixtureTests { function testBehavior() public {} }"
    verification.tests = BehavioralTests(status="passed", message="Fixture assertions", test_source_sha256=hashlib.sha256(thread["test_source"].encode()).hexdigest(), cases=[BehavioralTestCase(name="Example.testBehavior", status="passed", message="Fixture")])
    thread["response"]["verification"] = verification.model_dump()
    assert web.post("/refactor/proposal-review", json={**request, "proposal_sha256": "0" * 64}).status_code == 409
    accepted = web.post("/refactor/proposal-review", json=request)
    assert accepted.status_code == 200 and accepted.json()["reviewer_id"] == "alice"
    from src.services.repair_report import RepairReport, evidence_failures
    report = web.get(f"/refactor/threads/{thread_id}/report").json()
    assert not evidence_failures(RepairReport.model_validate(report))
    report["test_source"] += " // altered"
    assert evidence_failures(RepairReport.model_validate(report))
    monkeypatch.setattr(api.refactorbot_service, "validate_suggested_refactoring", lambda *args: VerificationResult(status="not_run", message="Compiler unavailable"))
    checked = web.post("/refactor/validate", json={"thread_id": thread_id, "original_code": thread["code"], "suggested_code": proposal})
    assert checked.status_code == 200
    assert thread["response"]["proposal_review"] is None
    assert web.post("/refactor/proposal-review", json=request).status_code == 409
    report = web.get(f"/refactor/threads/{thread_id}/report").json()
    assert report["response"]["finding_review"]["decision"] == "confirmed"
    assert report["response"]["verification"]["security_verified"] is False


def test_editor_save_invalidates_evidence_and_preserves_original_and_history(client):
    web, database, _ = client
    response = start_thread(web)
    thread_id = response["thread_id"]
    request = {"thread_id": thread_id, "previous_proposal": None, "proposed_code": "pragma solidity ^0.8.20; contract Fixed {}"}
    assert web.post("/refactor/proposal", json=request).status_code == 409
    assert web.post("/refactor/finding-review", json=finding_request(thread_id)).status_code == 200
    before = database.refactor_threads.docs[thread_id]
    original, messages = before["code"], list(before["messages"])
    saved = web.post("/refactor/proposal", json=request)
    assert saved.status_code == 200
    assert saved.json()["proposal_origin"] == "human_edit"
    assert saved.json()["verification"]["status"] == "not_run"
    assert saved.json()["verification"]["tests"]["status"] == "not_run"
    assert saved.json()["proposal_review"] is None
    assert before["code"] == original and before["messages"] == messages
    assert saved.json()["verification"]["source_sha256"] == hashlib.sha256(request["proposed_code"].encode()).hexdigest()
    assert web.post("/refactor/proposal", json=request).status_code == 409
    from src.api.v1 import refactorbot_router as api
    from types import SimpleNamespace
    web.app.dependency_overrides[api.get_current_user] = lambda: SimpleNamespace(id="bob")
    assert web.post("/refactor/proposal", json=request).status_code == 404


def test_baseline_compile_does_not_mutate_a_reviewed_proposal(client, monkeypatch):
    from src.api.v1 import refactorbot_router as api
    web, database, _ = client
    response = start_thread(web)
    before = dict(database.refactor_threads.docs[response["thread_id"]])
    monkeypatch.setattr(api, "validate_solidity", lambda *args: VerificationResult(status="passed", message="Synthetic baseline compile", source_sha256="0" * 64))
    result = web.post("/refactor/compile", json={"code": "contract Example {}"})
    assert result.status_code == 200 and result.json()["status"] == "passed"
    assert database.refactor_threads.docs[response["thread_id"]] == before


@pytest.mark.skipif(os.environ.get("RUN_SOLIDITY_INTEGRATION") != "1", reason="Requires the installed Docker solc image and local EVM dependencies")
def test_real_compiler_and_evm_expose_bug_and_check_repair():
    original = (EXAMPLES / "Vulnerable.sol").read_text()
    fixed = (EXAMPLES / "Fixed.sol").read_text()
    tests = (EXAMPLES / "Tests.sol").read_text()
    before = validate_solidity(original, original, tests)
    assert before.status == "passed", before.message
    assert before.tests.status == "failed", before.tests.message
    assert {case.name: case.status for case in before.tests.cases} == {"RepairTests.testOwnerCanSet": "passed", "RepairTests.testUnauthorizedCannotSet": "failed"}
    after = validate_solidity(fixed, original, tests)
    assert after.status == after.tests.status == "passed", after.model_dump()
    assert len(after.tests.cases) == 2 and after.security_verified is False
    assert after.tests.test_source_sha256 == hashlib.sha256(tests.encode()).hexdigest()
    manual = validate_solidity("pragma solidity 0.7.6; contract MissingCompiler {}")
    assert manual.status == manual.tests.status == "not_run" and manual.security_verified is False


@pytest.mark.skipif(os.environ.get("RUN_SOLIDITY_INTEGRATION") != "1", reason="Requires the installed Docker solc image and local EVM dependencies")
def test_reviewed_api_flow_with_real_verification(client, monkeypatch):
    from langchain_core.messages import AIMessage
    from types import SimpleNamespace
    from src.api.v1 import refactorbot_router as api
    from src.services.repair_report import RepairReport, evidence_failures
    from src.workflows.chatbot_workflow.workflow import ChatbotWorkflow

    web, database, _ = client
    original = (EXAMPLES / "Vulnerable.sol").read_text()
    fixed = (EXAMPLES / "Fixed.sol").read_text()
    tests = (EXAMPLES / "Tests.sol").read_text()
    replies = iter(["The caller-controlled write at lines 8–9 needs review against the owner-only requirement.", "Proposed owner check; inspect remaining risks.\n```solidity\n" + fixed + "\n```"])
    provider_calls = []

    class Model:
        def invoke(self, messages):
            provider_calls.append(messages)
            return AIMessage(content=next(replies))

    workflow = ChatbotWorkflow()
    workflow.llm_client = SimpleNamespace(get_instance=lambda: Model())

    async def explain(code, issue, language):
        return await workflow.arun(code, issue_description=issue, language=language)

    async def repair(history, code, language):
        return await workflow.arun(code, conversation_history=history, language=language)

    monkeypatch.setattr(api.refactorbot_service, "get_refactoring_advice", explain)
    monkeypatch.setattr(api.refactorbot_service, "get_code_fix_conversation", repair)
    response = start_thread(web, original)
    assert response["suggested_code"] is None and response["verification"]["status"] == "not_run"
    thread_id = response["thread_id"]
    confirmation = {**finding_request(thread_id), "start_line": 8, "end_line": 9}
    assert web.post("/refactor/finding-review", json=confirmation).status_code == 200
    history = database.refactor_threads.docs[thread_id]["messages"]
    payload = {"operation": "conversation", "code": original, "issue_description": "Review the owner-only state write", "context_id": "demo:Vault.set", "thread_id": thread_id,
               "conversation_history": [*history, {"role": "user", "content": "Suggest the minimal owner-only fix."}]}
    reviewed = web.post("/refactor/review", json=payload).json()
    result = web.post("/refactor/conversation", json={**reviewed["payload"], "review_token": reviewed["review_token"], "consent_confirmed": True})
    assert result.status_code == 200, result.text
    response = result.json()
    assert response["verification"]["status"] == "passed" and response["verification"]["tests"]["status"] == "not_run"
    proposal = response["suggested_code"]
    decision = proposal_request(thread_id, proposal)
    assert web.post("/refactor/proposal-review", json=decision).status_code == 409
    result = web.post("/refactor/validate", json={"thread_id": thread_id, "original_code": original, "suggested_code": proposal, "test_source": tests})
    assert result.status_code == 200, result.text
    assert result.json()["tests"]["status"] == "passed", result.json()
    assert len(provider_calls) == 2  # Validation and human decisions make no provider calls.
    assert web.post("/refactor/proposal-review", json=decision).status_code == 200
    report = web.get(f"/refactor/threads/{thread_id}/report").json()
    assert not evidence_failures(RepairReport.model_validate(report))
    assert report["response"]["verification"]["security_verified"] is False
