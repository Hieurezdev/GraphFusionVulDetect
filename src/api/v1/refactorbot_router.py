"""Reviewed external-AI requests, owned conversation history and local verification."""

import logging
import hashlib
import uuid
from datetime import datetime, timedelta, timezone
from typing import Literal

import httpx
from anyio import to_thread
from fastapi import APIRouter, Depends, HTTPException, Query
from motor.motor_asyncio import AsyncIOMotorDatabase
from openai import APIError, APIConnectionError, APITimeoutError
from pydantic import BaseModel, Field
from pymongo.errors import DuplicateKeyError

from src.config.settings import settings
from src.infrastructure.database import get_db
from src.models.ai_safety import (AiDisclosure, AiPayload, AiReview, ApprovedAiRequest, ConversationMessage,
                                  FindingReview, FindingReviewRequest, ProposalReview, ProposalReviewRequest, VerificationResult)
from src.models.entity import UserInDB
from src.services.ai_safety import AiResponseError, AiSafetyError, require_approval, review_payload
from src.services.refactorbot_service import RefactorBotService
from src.services.solidity_validation import validate_solidity
from .authentication_router import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/refactor", tags=["refactorbot"])
refactorbot_service = RefactorBotService()


class RefactoringSuggestion(BaseModel):
    type: str
    description: str
    code: str | None = None
    content: str | None = None
    url: str | None = None


class RefactorResponse(BaseModel):
    thread_id: str
    explanation: str
    bot_message: str
    suggestions: list[RefactoringSuggestion]
    suggested_code: str | None
    verification: VerificationResult
    disclosure: AiDisclosure
    repair_attempts: int
    finding_review: FindingReview | None = None
    proposal_review: ProposalReview | None = None
    proposal_origin: Literal["ai", "human_edit"] = "ai"


class RefactorThread(BaseModel):
    thread_id: str
    context_id: str | None = None
    code: str
    conversation_history: list[ConversationMessage]
    response: RefactorResponse
    test_source: str | None = None


class ValidationRequest(BaseModel):
    original_code: str = Field(min_length=1)
    suggested_code: str = Field(min_length=1)
    thread_id: str | None = Field(default=None, max_length=64)
    test_source: str | None = Field(default=None, max_length=30000)


class ProposalEditRequest(BaseModel):
    thread_id: str = Field(min_length=1, max_length=64)
    previous_proposal: str | None
    proposed_code: str = Field(min_length=1)


class CompileRequest(BaseModel):
    code: str = Field(min_length=1)
    test_source: str | None = Field(default=None, max_length=30000)


class StoredThread(BaseModel):
    id: str = Field(alias="_id")
    user_id: str
    context_id: str | None
    code: str
    messages: list[ConversationMessage]
    response: RefactorResponse
    revision: int
    test_source: str | None = None


def source_hash(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


async def _owned_thread(payload: AiPayload, user_id: str, database: AsyncIOMotorDatabase) -> StoredThread | None:
    if not payload.thread_id:
        return None
    document = await database.refactor_threads.find_one({"_id": payload.thread_id, "user_id": user_id})
    if document is None:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    thread = StoredThread.model_validate(document)
    messages = [item.model_dump() for item in payload.conversation_history]
    if messages[:-1] != [message.model_dump() for message in thread.messages] or payload.context_id != thread.context_id or payload.code != thread.code:
        raise HTTPException(status_code=409, detail="Conversation changed. Reopen the function to load its latest history.")
    return thread


@router.post("/review", response_model=AiReview)
async def review_external_request(payload: AiPayload, current_user: UserInDB = Depends(get_current_user)) -> AiReview:
    review = review_payload(payload, current_user.id)
    if payload.thread_id:
        await _owned_thread(review.payload, current_user.id, await get_db())
    return review


async def _run_approved(request: ApprovedAiRequest, user: UserInDB, operation: str) -> RefactorResponse:
    try:
        payload, approval_id = require_approval(request, user.id, operation)
    except AiSafetyError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error
    database = await get_db()
    thread = await _owned_thread(payload, user.id, database)
    if operation == "conversation" and (thread is None or thread.response.finding_review is None
            or thread.response.finding_review.decision != "confirmed"
            or thread.response.finding_review.source_sha256 != source_hash(payload.code)):
        raise HTTPException(status_code=409, detail="A qualified reviewer must confirm the finding and source lines before requesting a repair.")
    try:
        await database.ai_approvals.insert_one({"_id": approval_id, "user_id": user.id, "expires_at": datetime.now(timezone.utc) + timedelta(minutes=5)})
    except DuplicateKeyError as error:
        raise HTTPException(status_code=409, detail="This approval was already used. Review the content again.") from error
    history = [message.model_dump() for message in payload.conversation_history]
    try:
        if operation == "advice":
            result = await refactorbot_service.get_refactoring_advice(payload.code, payload.issue_description, payload.language)
        else:
            result = await refactorbot_service.get_code_fix_conversation(history, payload.code, payload.language)
    except AiSafetyError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except AiResponseError as error:
        logger.warning("External AI response was unusable", extra={"error_type": type(error).__name__})
        raise HTTPException(status_code=502, detail=str(error)) from error
    except (APITimeoutError, httpx.TimeoutException) as error:
        logger.warning("External AI request timed out", extra={"error_type": type(error).__name__})
        raise HTTPException(status_code=504, detail="The AI provider timed out. Review and try again, or ask about a smaller code section.") from error
    except APIConnectionError as error:
        logger.warning("External AI provider could not be reached", extra={"error_type": type(error).__name__})
        raise HTTPException(status_code=502, detail="Cannot connect to the configured AI provider. Ask the administrator to check the proxy and network connection.") from error
    except APIError as error:
        status = getattr(error, "status_code", None)
        logger.error("External AI provider rejected the request", extra={"error_type": type(error).__name__, "upstream_status": status})
        if status in (401, 403):
            detail = "AI provider authentication failed. Ask the administrator to check the configured API key."
        elif status == 429:
            raise HTTPException(status_code=503, detail="The AI provider is busy or rate-limited. Wait before reviewing and trying again.") from error
        elif status in (400, 422):
            detail = "The AI provider rejected the request parameters or context length. Use less code/history or ask the administrator to check the proxy configuration."
        else:
            detail = "The AI provider is temporarily unavailable. Review and try again later."
        raise HTTPException(status_code=502, detail=detail) from error
    except (httpx.HTTPError, ValueError) as error:
        logger.error("External AI request failed", extra={"error_type": type(error).__name__})
        raise HTTPException(status_code=502, detail="The AI provider could not complete this request. Review and retry, or inspect the code manually.") from error
    answer = result.get("bot_message") or result.get("explanation") or ""
    thread_id = payload.thread_id or uuid.uuid4().hex
    response = RefactorResponse(
        thread_id=thread_id,
        explanation=result.get("explanation") or answer,
        bot_message=answer,
        suggestions=result.get("refactoring_suggestions") or [],
        suggested_code=result.get("suggested_code"),
        verification=VerificationResult(**(result.get("validation_result") or {"status": "not_run", "message": "Explanation only. Confirm the finding before requesting a repair."})),
        disclosure=AiDisclosure(model=settings.MODEL_NAME),
        repair_attempts=result.get("repair_attempts") or 0,
        finding_review=thread.response.finding_review if thread else None,
    )
    updated = {"user_id": user.id, "context_id": payload.context_id, "code": payload.code,
               "messages": history + [{"role": "assistant", "content": answer}],
               "response": response.model_dump(), "test_source": None, "updated_at": datetime.now(timezone.utc)}
    if thread:
        write = await database.refactor_threads.update_one({"_id": thread_id, "user_id": user.id, "revision": thread.revision}, {"$set": updated, "$inc": {"revision": 1}})
        if write.matched_count != 1:
            raise HTTPException(status_code=409, detail="Conversation changed while the AI was working. Reopen the function.")
    else:
        await database.refactor_threads.insert_one({"_id": thread_id, "revision": 1, **updated})
    return response


@router.post("/advice", response_model=RefactorResponse)
async def get_refactoring_advice(request: ApprovedAiRequest, current_user: UserInDB = Depends(get_current_user)) -> RefactorResponse:
    return await _run_approved(request, current_user, "advice")


@router.post("/conversation", response_model=RefactorResponse)
async def continue_refactoring_conversation(request: ApprovedAiRequest, current_user: UserInDB = Depends(get_current_user)) -> RefactorResponse:
    return await _run_approved(request, current_user, "conversation")


@router.get("/threads", response_model=RefactorThread | None)
async def latest_conversation(context_id: str = Query(max_length=256), current_user: UserInDB = Depends(get_current_user)) -> RefactorThread | None:
    database = await get_db()
    thread = await database.refactor_threads.find_one({"user_id": current_user.id, "context_id": context_id}, sort=[("updated_at", -1)])
    if thread is None:
        return None
    stored = StoredThread.model_validate(thread)
    return RefactorThread(thread_id=stored.id, context_id=stored.context_id, code=stored.code, conversation_history=stored.messages, response=stored.response, test_source=stored.test_source)


@router.post("/finding-review", response_model=FindingReview)
async def review_finding(request: FindingReviewRequest, current_user: UserInDB = Depends(get_current_user)) -> FindingReview:
    database = await get_db()
    document = await database.refactor_threads.find_one({"_id": request.thread_id, "user_id": current_user.id})
    if document is None:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    stored = StoredThread.model_validate(document)
    if request.end_line < request.start_line or request.end_line > len(stored.code.splitlines()):
        raise HTTPException(status_code=422, detail="Select an existing inclusive source line range.")
    review = FindingReview(**request.model_dump(), reviewer_id=current_user.id, reviewed_at=datetime.now(timezone.utc), source_sha256=source_hash(stored.code))
    updated = await database.refactor_threads.update_one(
        {"_id": stored.id, "user_id": current_user.id, "revision": stored.revision},
        {"$set": {"response.finding_review": review.model_dump(), "response.proposal_review": None}, "$inc": {"revision": 1}})
    if updated.matched_count != 1:
        raise HTTPException(status_code=409, detail="Conversation changed. Reopen the finding before reviewing again.")
    return review


@router.post("/proposal-review", response_model=ProposalReview)
async def review_proposal(request: ProposalReviewRequest, current_user: UserInDB = Depends(get_current_user)) -> ProposalReview:
    database = await get_db()
    document = await database.refactor_threads.find_one({"_id": request.thread_id, "user_id": current_user.id})
    if document is None:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    stored = StoredThread.model_validate(document)
    response = stored.response
    if not response.suggested_code or source_hash(response.suggested_code) != request.proposal_sha256:
        raise HTTPException(status_code=409, detail="The proposal changed. Review the current diff again.")
    if request.decision == "accepted_for_manual_application" and (
        response.finding_review is None or response.finding_review.decision != "confirmed"
        or response.finding_review.source_sha256 != source_hash(stored.code)
        or response.verification.status != "passed" or response.verification.tests.status != "passed"
        or not response.verification.tests.cases
        or any(case.status != "passed" for case in response.verification.tests.cases)
        or not stored.test_source
        or response.verification.tests.test_source_sha256 != source_hash(stored.test_source)
        or response.verification.source_sha256 != request.proposal_sha256
    ):
        raise HTTPException(status_code=409, detail="Manual review required: confirm the finding and pass compilation and behavioral tests for this exact proposal before accepting it.")
    review = ProposalReview(**request.model_dump(), reviewer_id=current_user.id, reviewed_at=datetime.now(timezone.utc))
    updated = await database.refactor_threads.update_one(
        {"_id": stored.id, "user_id": current_user.id, "revision": stored.revision},
        {"$set": {"response.proposal_review": review.model_dump()}, "$inc": {"revision": 1}})
    if updated.matched_count != 1:
        raise HTTPException(status_code=409, detail="Conversation changed. Reopen the finding before reviewing again.")
    return review


@router.post("/proposal", response_model=RefactorResponse)
async def save_editor_proposal(request: ProposalEditRequest, current_user: UserInDB = Depends(get_current_user)) -> RefactorResponse:
    database = await get_db()
    document = await database.refactor_threads.find_one({"_id": request.thread_id, "user_id": current_user.id})
    if document is None:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    stored = StoredThread.model_validate(document)
    finding = stored.response.finding_review
    if finding is None or finding.decision != "confirmed" or finding.source_sha256 != source_hash(stored.code):
        raise HTTPException(status_code=409, detail="Confirm the finding before saving a repair proposal.")
    if stored.response.suggested_code != request.previous_proposal:
        raise HTTPException(status_code=409, detail="The proposal changed. Reopen the finding before saving your draft.")
    response = stored.response.model_copy(update={
        "suggested_code": request.proposed_code, "proposal_origin": "human_edit", "proposal_review": None,
        "verification": VerificationResult(status="not_run", message="The editor proposal changed. Compile and run tests again before review.", source_sha256=source_hash(request.proposed_code)),
    })
    updated = await database.refactor_threads.update_one(
        {"_id": stored.id, "user_id": current_user.id, "revision": stored.revision},
        {"$set": {"response": response.model_dump(), "updated_at": datetime.now(timezone.utc)}, "$inc": {"revision": 1}})
    if updated.matched_count != 1:
        raise HTTPException(status_code=409, detail="The proposal changed. Reopen the finding before saving your draft.")
    return response


@router.get("/threads/{thread_id}/report", response_model=RefactorThread)
async def repair_report(thread_id: str, current_user: UserInDB = Depends(get_current_user)) -> RefactorThread:
    database = await get_db()
    document = await database.refactor_threads.find_one({"_id": thread_id, "user_id": current_user.id})
    if document is None:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    stored = StoredThread.model_validate(document)
    return RefactorThread(thread_id=stored.id, context_id=stored.context_id, code=stored.code, conversation_history=stored.messages, response=stored.response, test_source=stored.test_source)


@router.post("/validate", response_model=VerificationResult)
async def validate_refactoring(request: ValidationRequest, current_user: UserInDB = Depends(get_current_user)) -> VerificationResult:
    database = None
    thread_query = {"_id": request.thread_id, "user_id": current_user.id,
                    "code": request.original_code, "response.suggested_code": request.suggested_code}
    if request.thread_id:
        database = await get_db()
        document = await database.refactor_threads.find_one(thread_query)
        if document is None:
            raise HTTPException(status_code=404, detail="The stored proposal is unavailable or changed. Reopen the finding before compiling.")
        thread_query["revision"] = document["revision"]
    if request.test_source:
        result = await to_thread.run_sync(refactorbot_service.validate_suggested_refactoring, request.original_code, request.suggested_code, request.test_source)
    else:
        result = await to_thread.run_sync(refactorbot_service.validate_suggested_refactoring, request.original_code, request.suggested_code)
    if database is not None:
        updated = await database.refactor_threads.update_one(thread_query, {"$set": {"response.verification": result.model_dump(), "test_source": request.test_source, "response.proposal_review": None}, "$inc": {"revision": 1}})
        if updated.matched_count != 1:
            raise HTTPException(status_code=409, detail="The proposal changed during compilation. Reopen the finding before compiling again.")
    return result


@router.post("/compile", response_model=VerificationResult)
async def compile_editor_source(request: CompileRequest, current_user: UserInDB = Depends(get_current_user)) -> VerificationResult:
    """Compile a baseline or unsaved draft without changing review evidence."""
    return await to_thread.run_sync(validate_solidity, request.code, None, request.test_source)
