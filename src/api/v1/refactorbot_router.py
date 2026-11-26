"""
API Router for RefactorBot Service - Smart Contract Refactoring Assistant
"""

import asyncio
import json
import logging
from typing import List, Dict, Any, Optional
from bson import ObjectId
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.responses import StreamingResponse
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, Field, field_validator
from src.utils.language import normalize_language

from src.services.refactorbot_service import RefactorBotService
from src.models.entity import UserInDB
from src.infrastructure.database import get_analysis_sessions_collection
from src.workflows.gfd_workflow.utils.fix_check import check_fix, WHOLE_FILE
from .authentication_router import get_current_user
from .analyze_router import _session_query
from src.services.findings import find, replace_entry
from src.models.entity import FunctionFix
from src.utils.timezone import now_vietnam, ensure_utc_for_db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/refactor", tags=["refactorbot"])

# Request/Response Models
class RefactoringAdviceRequest(BaseModel):
    """Request model for getting refactoring advice"""
    code: str = Field(..., description="Solidity code to refactor", min_length=1, max_length=200_000)
    issue_description: str = Field(..., description="Description of the issue or vulnerability", min_length=1, max_length=20_000)
    language: str = Field("en", description="Language for the answer: en or vi")

class RefactoringSuggestion(BaseModel):
    """Model for a single refactoring suggestion"""
    type: str = Field(..., description="Type of suggestion (code_fix, pattern_advice, resource_link, etc.)")
    description: str = Field(..., description="Description of the suggestion")
    code: Optional[str] = Field(None, description="Suggested code snippet if applicable")
    content: Optional[str] = Field(None, description="Additional content or explanation")
    url: Optional[str] = Field(None, description="Resource URL if applicable")

class RefactoringAdviceResponse(BaseModel):
    """Response model for refactoring advice"""
    suggestions: List[RefactoringSuggestion] = Field(default_factory=list, description="List of refactoring suggestions")
    explanation: str = Field(..., description="Detailed explanation of the suggestions")
    analysis: Optional[Dict[str, Any]] = Field(None, description="Analysis results")
    validation: Optional[Dict[str, Any]] = Field(None, description="Validation results")

class ConversationMessage(BaseModel):
    """Model for a conversation message"""
    role: str = Field(..., description="Role of the message sender (user or assistant)")
    content: str = Field(..., description="Content of the message", max_length=50_000)

class ConversationRequest(BaseModel):
    """Request model for conversation-based refactoring"""
    code: str = Field(..., description="Current code being discussed", min_length=1, max_length=200_000)
    conversation_history: List[ConversationMessage] = Field(
        ..., 
        description="Previous conversation messages",
        min_items=1
    )
    language: str = Field("en", description="Language for the answer: en or vi")

    @field_validator("conversation_history")
    @classmethod
    def keep_recent(cls, history):
        return history[-40:]  # every message goes to the LLM on each turn: cap the cost of long chats

class ConversationResponse(BaseModel):
    """Response model for conversation"""
    bot_message: str = Field(..., description="Bot's response message")
    suggested_code: Optional[str] = Field(None, description="Suggested code snippet if applicable")

class ValidationRequest(BaseModel):
    """Request model for validating refactored code"""
    original_code: str = Field(..., description="Original code before refactoring", min_length=1, max_length=200_000)
    suggested_code: str = Field(..., description="Suggested refactored code", min_length=1, max_length=200_000)
    session_id: Optional[str] = Field(None, description="Analysis session holding the contract; enables a real compile + Slither re-check")
    function_name: Optional[str] = Field(None, description="Flagged function the suggestion replaces")
    vulnerability: Optional[str] = Field(None, description="Scan that flagged the function (timestamp or reentrancy); defaults to the first that did")

class ValidationResponse(BaseModel):
    """Response model for validation"""
    is_valid: bool = Field(..., description="Whether the suggested code is valid")
    message: str = Field(..., description="Validation message or errors")
    compiled: Optional[bool] = Field(None, description="Whether the patched contract compiles")
    solc_version: Optional[str] = None
    original_solc_version: Optional[str] = None
    slither_error: Optional[str] = Field(None, description="Set when Slither could not analyse one side; its counts are then incomplete")
    compiler_output: Optional[str] = None
    findings_before: List[Dict[str, Any]] = Field(default_factory=list, description="Slither findings on the original function")
    findings_after: List[Dict[str, Any]] = Field(default_factory=list, description="Slither findings on the patched function")
    patched_lines: List[int] = Field(default_factory=list)
    requires_review: bool = Field(True, description="Always true: a passing check is not proof the fix is correct")
    recorded: bool = Field(False, description="Whether this check was saved on the finding for an expert to approve")
    record_note: Optional[str] = Field(None, description="Why the check was not saved, when it was not")


# Service instance
refactorbot_service = RefactorBotService()

# solc + two Slither runs per check, on a host shared by every user: at most two checks at once.
_CHECK_SLOTS = asyncio.Semaphore(2)


@router.post("/advice", response_model=RefactoringAdviceResponse, status_code=status.HTTP_200_OK)
async def get_refactoring_advice(
    request: RefactoringAdviceRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get AI-powered refactoring advice for smart contract code.
    
    This endpoint analyzes the provided Solidity code and generates specific
    refactoring suggestions to address the described issue or vulnerability.
    
    Args:
        request: Contains the code and issue description
        current_user: Current authenticated user
    
    Returns:
        RefactoringAdviceResponse: Suggestions, explanations, and analysis
    
    Raises:
        HTTPException: If analysis fails or encounters an error
    """
    try:
        logger.info(f"Refactoring advice requested by user {current_user.username} for issue: {request.issue_description}")
        logger.debug(f"Code length: {len(request.code)} characters")
        
        # Get refactoring advice from service
        result = await refactorbot_service.get_refactoring_advice(
            code=request.code,
            issue_description=request.issue_description,
            language=normalize_language(request.language)
        )
        
        logger.debug(f"Service returned result with keys: {list(result.keys()) if result else 'NONE'}")
        
        # Check for errors in the result
        if "error" in result:
            logger.error(f"Error generating refactoring advice: {result['error']}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to generate refactoring advice: {result['error']}"
            )
        
        # Convert suggestions to response models
        suggestions = [
            RefactoringSuggestion(**suggestion)
            for suggestion in result.get("suggestions", [])
        ]
        
        response = RefactoringAdviceResponse(
            suggestions=suggestions,
            explanation=result.get("explanation", ""),
            analysis=result.get("analysis"),
            validation=result.get("validation")
        )
        
        logger.info(f"Generated {len(suggestions)} refactoring suggestions successfully")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in get_refactoring_advice: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred: {str(e)}"
        )


@router.post("/conversation", response_model=ConversationResponse, status_code=status.HTTP_200_OK)
async def continue_refactoring_conversation(
    request: ConversationRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Continue a conversational interaction for iterative code refinement.
    
    This endpoint allows users to have a back-and-forth conversation with the AI
    to iteratively improve and refine their smart contract code.
    
    Args:
        request: Contains the code and conversation history
        current_user: Current authenticated user
    
    Returns:
        ConversationResponse: Bot's message and optional suggested code
    
    Raises:
        HTTPException: If conversation handling fails
    """
    try:
        logger.info(f"Conversation request by user {current_user.username} with {len(request.conversation_history)} messages")
        
        # Convert conversation messages to dict format
        conversation_history = [
            {"role": msg.role, "content": msg.content}
            for msg in request.conversation_history
        ]
        
        # Get conversation response from service
        result = await refactorbot_service.get_code_fix_conversation(
            conversation_history=conversation_history,
            current_code=request.code,
            language=normalize_language(request.language)
        )
        
        # Check for errors
        if "error" in result:
            logger.error(f"Error in conversation: {result['error']}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to process conversation: {result['error']}"
            )
        
        response = ConversationResponse(
            bot_message=result.get("bot_message", ""),
            suggested_code=result.get("suggested_code")
        )
        
        logger.info("Conversation processed successfully")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in continue_refactoring_conversation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred: {str(e)}"
        )


@router.post("/chat/stream")
async def stream_refactoring_chat(
    request: ConversationRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Stream the assistant's next reply as NDJSON: {"delta"} lines, then {"done"} or {"error"}."""
    history = [{"role": msg.role, "content": msg.content} for msg in request.conversation_history]

    async def events():
        async for event in refactorbot_service.stream_chat(request.code, history, normalize_language(request.language)):
            yield json.dumps(event, ensure_ascii=False) + "\n"

    return StreamingResponse(events(), media_type="application/x-ndjson", headers={"X-Accel-Buffering": "no"})


@router.post("/validate", response_model=ValidationResponse, status_code=status.HTTP_200_OK)
async def validate_refactoring(
    request: ValidationRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Validate suggested refactored code.
    
    This endpoint performs validation checks on the suggested refactored code,
    including syntax validation and basic security checks.
    
    Args:
        request: Contains original and suggested code
        current_user: Current authenticated user
    
    Returns:
        ValidationResponse: Validation result and message
    
    Raises:
        HTTPException: If validation process fails
    """
    try:
        logger.info(f"Validation request by user {current_user.username}")
        
        if request.session_id and (request.function_name or WHOLE_FILE.search(request.suggested_code)):
            response = await _check_against_contract(request, current_user)
        else:
            # No contract context: only the shallow syntax check is possible.
            is_valid, message = refactorbot_service.validate_suggested_refactoring(
                original_code=request.original_code,
                suggested_code=request.suggested_code
            )
            response = ValidationResponse(
                is_valid=is_valid,
                message=f"{message.rstrip('.')}. Not compiled: open the fix from an analysis session to compile and re-check it."
            )
        is_valid, message = response.is_valid, response.message

        logger.info(f"Validation result: {is_valid} - {message}")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in validate_refactoring: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred during validation: {str(e)}"
        )


async def _check_against_contract(request: ValidationRequest, current_user: UserInDB) -> ValidationResponse:
    """Splice the fix into the analysed contract, compile it and compare Slither findings before/after."""
    sessions = await get_analysis_sessions_collection()
    try:
        session = await sessions.find_one(_session_query(request.session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not session:
        raise HTTPException(status_code=404, detail="Analysis session not found")

    span = None  # a whole edited file (the IDE) replaces everything, so no function span is needed
    finding = find(session, request.function_name, request.vulnerability) if request.function_name else None
    if not WHOLE_FILE.search(request.suggested_code):
        if not finding or not finding["span"]:
            raise HTTPException(status_code=404, detail="Function source location not found; re-run the analysis")
        span = finding["span"]

    async with _CHECK_SLOTS:  # waiting here, not inside a worker thread, so queued checks don't drain the shared threadpool
        result = await run_in_threadpool(check_fix, session["file_path"], span, request.suggested_code)
    before, after = len(result["findings_before"]), len(result["findings_after"])
    scope = "this function" if span else "the contract"
    if result["compiled"]:
        upgraded = (f" (the original uses {result['original_solc_version']}: the fix changes the compiler version, review that too)"
                    if result["original_solc_version"] != result["solc_version"] else "")
        message = (f"Compiles with solc {result['solc_version']}{upgraded}. Slither findings on {scope}: "
                   f"{before} before, {after} after. This is not proof the fix is correct: "
                   "an expert must review the change and run the contract's own tests.")
        if result["slither_error"]:
            message += " Slither could not analyse every version, so these counts are incomplete."
    else:
        message = f"Does not compile with solc {result['solc_version']}. See the compiler output."
    recorded, record_note = False, None
    if finding:  # keep the check on the finding, so an expert can approve exactly what was compiled (anyone may propose a fix)
        fix = FunctionFix(vulnerability=finding["vulnerability"], function_name=finding["function_name"], suggested_code=request.suggested_code,
                          compiled=result["compiled"], solc_version=result["solc_version"], findings_before=before, findings_after=after,
                          compiler_output=(result["compiler_output"] or "")[:2000], checked_by=current_user.username,
                          checked_at=ensure_utc_for_db(now_vietnam())).dict()
        fix["decision"] = fix["decision"].value
        await sessions.update_one({"_id": session["_id"]}, replace_entry("fixes", fix))
        recorded = True
    return ValidationResponse(is_valid=result["compiled"], message=message, recorded=recorded, record_note=record_note, **result)
