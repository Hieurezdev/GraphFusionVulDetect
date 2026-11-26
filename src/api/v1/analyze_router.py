import os
import asyncio
import tempfile
import logging
import hashlib
import json
from typing import List
from pathlib import Path
from datetime import datetime, timezone

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Form, Query
from fastapi.responses import StreamingResponse
from bson import ObjectId
from pymongo import ReturnDocument
from src.services.analysis_service import vulnerability_analysis_service
from src.services.sarif import session_to_sarif
from src.services.graph_loader import get_vulnerabilities
from src.services.findings import find, session_findings, replace_entry
from src.models.entity import (
    StreamingNodeOutput, AnalysisSession, AnalysisSessionCreate,
    AnalysisSessionStatus, AnalysisStep, ProjectFile, UserInDB,
    FunctionReview, FunctionReviewUpdate, FunctionFix, FixDecision, FixDecisionUpdate
)
from src.infrastructure.database import get_analysis_sessions_collection, get_projects_collection
from src.utils.timezone import now_utc, now_vietnam, ensure_utc_for_db
from .authentication_router import get_current_user

_background: set = set()

router = APIRouter(tags=["analysis"])

# Setup logging
logger = logging.getLogger("GraphFusionVulDetect-API")

@router.post("/analyze")
async def analyze_contract(
    file: UploadFile = File(..., description="Solidity file to analyze"),
    project_id: str = Form(None, description="Optional project ID to associate the analysis with"),
    language: str = Form("en", description="Language for generated explanations: en or vi"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Upload and analyze a Solidity smart contract file for vulnerabilities.

    The contract is scanned for every supported vulnerability type at once (timestamp dependency and
    reentrancy), one pipeline per type side by side; the stream ends with one conclusion for the contract.
    
    This endpoint accepts a Solidity file upload and streams the analysis process
    in real-time using NDJSON format.
    
    Args:
        file: Solidity file to analyze
        project_id: Optional project ID to associate the analysis with
        current_user: Current authenticated user
    
    Returns:
        StreamingResponse: NDJSON stream of analysis progress and results
    """
    
    # Log received project_id for debugging
    logger.info(f"Analysis request - project_id: {project_id}, file: {file.filename}")
    
    # Read file content
    file_content = await file.read()
    # The client controls the multipart filename: keep only its last component, or "../x.sol" escapes storage.
    filename = Path(file.filename or "").name
    
    # Validate file
    is_valid, error_message = vulnerability_analysis_service.validate_solidity_file(
        filename, file_content
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error_message)
    
    # Create analysis session
    sessions_collection = await get_analysis_sessions_collection()
    projects_collection = await get_projects_collection()
    
    # Validate project if provided
    if project_id:
        try:
            project_doc = await projects_collection.find_one({
                "_id": ObjectId(project_id),
                "user_id": current_user.id
            })
            if not project_doc:
                raise HTTPException(
                    status_code=404,
                    detail="Project not found or access denied"
                )
        except Exception as e:
            if "ObjectId" in str(e):
                raise HTTPException(status_code=400, detail="Invalid project ID format")
            raise
    
    # Create directory for this analysis
    # A fresh directory per upload: a per-second name let two same-second uploads overwrite each other.
    os.makedirs("./storage", exist_ok=True)
    temp_dir = tempfile.mkdtemp(prefix=datetime.now().strftime('%Y%m%d_%H%M%S_'), dir="./storage")

    # Save file and get path
    file_path = os.path.join(temp_dir, filename)
    with open(file_path, 'wb') as f:
        f.write(file_content)
    
    # Calculate file hash
    file_hash = hashlib.sha256(file_content).hexdigest()
    
    # Create analysis session
    session_doc = {
        "project_id": project_id,
        "user_id": current_user.id,
        "file_path": file_path,
        "filename": filename,
        "file_hash": file_hash,
        "vulnerabilities": get_vulnerabilities(),
        "status": AnalysisSessionStatus.PROCESSING,
        "steps": [],
        "started_at": ensure_utc_for_db(now_vietnam()),
        "completed_at": None,
        "error_message": None
    }
    
    session_result = await sessions_collection.insert_one(session_doc)
    session_id = str(session_result.inserted_id)
    
    # Update project if provided
    if project_id:
        # Add file to project if not already exists
        project_file = ProjectFile(
            filename=filename,
            file_size=len(file_content),
            file_path=file_path,
            file_hash=file_hash,
            uploaded_at=ensure_utc_for_db(now_vietnam())
        )
        
        # Check if file already exists in project
        existing_file = await projects_collection.find_one({
            "_id": ObjectId(project_id),
            "files.file_hash": file_hash
        })
        
        if not existing_file:
            await projects_collection.update_one(
                {"_id": ObjectId(project_id)},
                {
                    "$push": {"files": project_file.dict()},
                    "$inc": {"analysis_count": 1},
                    "$set": {
                        "updated_at": ensure_utc_for_db(now_vietnam()),
                        "status": "analyzing"
                    }
                }
            )
        else:
            await projects_collection.update_one(
                {"_id": ObjectId(project_id)},
                {
                    "$inc": {"analysis_count": 1},
                    "$set": {
                        "updated_at": ensure_utc_for_db(now_vietnam()),
                        "status": "analyzing"
                    }
                }
            )
    
    # Create streaming generator
    async def stream_analysis():
        try:
            # Stream analysis results and save each step
            async for result_line in vulnerability_analysis_service.analyze_solidity_file(
                file_path, temp_dir, language
            ):
                # Parse the result
                try:
                    result_data = json.loads(result_line.strip())
                    
                    # Save step to database
                    step = AnalysisStep(
                        step_name=result_data.get("node", "unknown"),
                        vulnerability=result_data.get("vulnerability"),
                        status="completed",
                        result_data=result_data.get("output", {}),
                        started_at=ensure_utc_for_db(now_vietnam()),
                        completed_at=ensure_utc_for_db(now_vietnam())
                    )
                    
                    await sessions_collection.update_one(
                        {"_id": ObjectId(session_id)},
                        {"$push": {"steps": step.dict()}}
                    )
                    
                except json.JSONDecodeError:
                    # Handle non-JSON lines
                    pass
                
                # Send result to client
                yield result_line
            
            # Mark session as completed
            await sessions_collection.update_one(
                {"_id": ObjectId(session_id)},
                {
                    "$set": {
                        "status": AnalysisSessionStatus.COMPLETED,
                        "completed_at": ensure_utc_for_db(now_vietnam())
                    }
                }
            )
            
            # Update project status if provided
            if project_id:
                await projects_collection.update_one(
                    {"_id": ObjectId(project_id)},
                    {
                        "$set": {
                            "status": "completed",
                            "updated_at": ensure_utc_for_db(now_vietnam())
                        }
                    }
                )
                
        except (asyncio.CancelledError, GeneratorExit):
            # The client disconnected: the scans were stopped, so close the session instead of leaving it "processing".
            # A separate task, because this one is being cancelled and its own awaits would be cancelled too.
            task = asyncio.get_running_loop().create_task(sessions_collection.update_one(
                {"_id": ObjectId(session_id)},
                {"$set": {"status": AnalysisSessionStatus.FAILED, "completed_at": ensure_utc_for_db(now_vietnam()),
                          "error_message": "Analysis stopped: the connection closed before it finished. Run it again."}}))
            _background.add(task)  # the loop keeps only a weak reference to tasks
            task.add_done_callback(_background.discard)
            raise
        except Exception as e:
            logger.error(f"Analysis error: {str(e)}", exc_info=True)
            
            # Mark session as failed
            await sessions_collection.update_one(
                {"_id": ObjectId(session_id)},
                {
                    "$set": {
                        "status": AnalysisSessionStatus.FAILED,
                        "completed_at": ensure_utc_for_db(now_vietnam()),
                        "error_message": str(e)
                    }
                }
            )
            
            # Update project status if provided
            if project_id:
                await projects_collection.update_one(
                    {"_id": ObjectId(project_id)},
                    {
                        "$set": {
                            "status": "failed",
                            "updated_at": ensure_utc_for_db(now_vietnam())
                        }
                    }
                )
            
            # Send error as final message
            error_output = {
                "node": "error",
                "output": {
                    "error": f"Analysis failed: {str(e)}",
                    "session_id": session_id
                }
            }
            yield f"{json.dumps(error_output)}\n"
    
    return StreamingResponse(
        stream_analysis(), 
        media_type="application/x-ndjson",
        headers={"X-Session-ID": session_id}
    )


@router.get("/sessions", response_model=List[AnalysisSession])
async def list_analysis_sessions(
    project_id: str = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List analysis sessions for the current user"""
    sessions_collection = await get_analysis_sessions_collection()
    
    # Build query
    query = {"user_id": current_user.id}
    if project_id:
        try:
            query["project_id"] = project_id
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
    
    # Execute query
    cursor = sessions_collection.find(query).sort("started_at", -1).skip(skip).limit(limit)
    sessions = await cursor.to_list(length=limit)
    
    # Convert to response format
    result = []
    for session in sessions:
        session["id"] = str(session["_id"])
        del session["_id"]
        result.append(AnalysisSession(**session))
    
    return result


@router.get("/sessions/{session_id}", response_model=AnalysisSession)
async def get_analysis_session(
    session_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific analysis session"""
    sessions_collection = await get_analysis_sessions_collection()
    
    try:
        session_doc = await sessions_collection.find_one(_session_query(session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    
    if not session_doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")
    
    session_doc["id"] = str(session_doc["_id"])
    del session_doc["_id"]
    return AnalysisSession(**session_doc)


def _session_query(session_id: str, user: UserInDB) -> dict:
    """Owners see their own sessions; experts see every session so they can review it."""
    query = {"_id": ObjectId(session_id)}
    if user.role != "expert":
        query["user_id"] = user.id
    return query


async def require_expert(current_user: UserInDB = Depends(get_current_user)) -> UserInDB:
    if current_user.role != "expert":
        raise HTTPException(status_code=403, detail="Only expert accounts can confirm or reject alerts")
    return current_user


@router.get("/reviews/queue", response_model=List[AnalysisSession])
async def review_queue(limit: int = Query(50, le=200), current_user: UserInDB = Depends(require_expert)):
    """Sessions, from any user, in which the model flagged at least one function: the expert's worklist."""
    sessions_collection = await get_analysis_sessions_collection()
    cursor = sessions_collection.find(
        {"steps.result_data.func_vulnerability_predictions.prediction": 1}
    ).sort("started_at", -1).limit(limit)
    result = []
    for session in await cursor.to_list(length=limit):
        session["id"] = str(session.pop("_id"))
        result.append(AnalysisSession(**session))
    return result


@router.put("/sessions/{session_id}/reviews", response_model=List[FunctionReview])
async def review_function(
    session_id: str,
    review: FunctionReviewUpdate,
    current_user: UserInDB = Depends(require_expert)
):
    """Record an expert verdict (confirmed / false positive / needs manual review) on a flagged function."""
    sessions_collection = await get_analysis_sessions_collection()
    try:
        session_doc = await sessions_collection.find_one(_session_query(session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not session_doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")

    if not find(session_doc, review.function_name, review.vulnerability):
        raise HTTPException(status_code=404, detail="Function not flagged by this scan in this analysis")

    entry = FunctionReview(**review.dict(), reviewer=current_user.username, reviewed_at=ensure_utc_for_db(now_vietnam())).dict()
    entry["status"] = review.status.value
    # Function names contain dots, so reviews live in a list rather than a dict keyed by name.
    updated = await sessions_collection.find_one_and_update(
        {"_id": ObjectId(session_id)}, replace_entry("reviews", entry), return_document=ReturnDocument.AFTER)
    return updated.get("reviews", [])


@router.get("/sessions/{session_id}/findings")
async def list_findings(session_id: str, current_user: UserInDB = Depends(get_current_user)):
    """Every flagged function with its expert review, its fix and where it stands in the workflow."""
    sessions_collection = await get_analysis_sessions_collection()
    try:
        session_doc = await sessions_collection.find_one(_session_query(session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not session_doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")
    return session_findings(session_doc)


@router.put("/sessions/{session_id}/fixes", response_model=List[FunctionFix])
async def decide_fix(session_id: str, update: FixDecisionUpdate, current_user: UserInDB = Depends(require_expert)):
    """Expert decision on a checked fix. Anyone may propose a fix; it can only be accepted for a confirmed finding, and only if it compiled."""
    sessions_collection = await get_analysis_sessions_collection()
    try:
        session_doc = await sessions_collection.find_one(_session_query(session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not session_doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")
    finding = find(session_doc, update.function_name, update.vulnerability)
    if not finding or not finding["fix"]:
        raise HTTPException(status_code=404, detail="No checked fix is recorded for this finding; compile and re-check a fix first")
    if update.decision == FixDecision.ACCEPTED and (finding["review"] or {}).get("status") != "confirmed":
        raise HTTPException(status_code=409, detail="Confirm the alert before accepting a fix for it")
    if update.decision == FixDecision.ACCEPTED and not finding["fix"].get("compiled"):
        raise HTTPException(status_code=409, detail="This fix does not compile and cannot be accepted")
    # Decide on exactly the code the expert was shown: if the owner re-checked a different fix since, nothing matches.
    match = {"vulnerability": update.vulnerability, "function_name": update.function_name, "suggested_code": update.suggested_code}
    if update.decision == FixDecision.ACCEPTED:
        match["compiled"] = True
    updated = await sessions_collection.find_one_and_update(
        {"_id": ObjectId(session_id), "fixes": {"$elemMatch": match}},
        {"$set": {"fixes.$[f].decision": update.decision.value, "fixes.$[f].note": update.note,
                  "fixes.$[f].decided_by": current_user.username, "fixes.$[f].decided_at": ensure_utc_for_db(now_vietnam())}},
        array_filters=[{f"f.{k}": v for k, v in match.items()}],
        return_document=ReturnDocument.AFTER)
    if updated is None:
        raise HTTPException(status_code=409, detail="This fix changed since you opened it. Reload and review the current version.")
    return updated.get("fixes", [])


@router.get("/sessions/{session_id}/source")
async def get_session_source(session_id: str, current_user: UserInDB = Depends(get_current_user)):
    """The analysed contract's source, for the in-browser IDE."""
    sessions_collection = await get_analysis_sessions_collection()
    try:
        session_doc = await sessions_collection.find_one(_session_query(session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not session_doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")
    try:
        source = Path(session_doc["file_path"]).read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        raise HTTPException(status_code=410, detail="Contract file is no longer stored; re-run the analysis")
    return {"filename": session_doc["filename"], "source": source}


@router.get("/sessions/{session_id}/sarif")
async def export_session_sarif(
    session_id: str,
    uri: str = Query(None, max_length=500, description="Path of the contract in your repo, so IDE/CI can point at it; defaults to the uploaded filename"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Export the alerts (lines, confidence, expert review) as SARIF for VS Code and GitHub code scanning."""
    sessions_collection = await get_analysis_sessions_collection()
    try:
        session_doc = await sessions_collection.find_one(_session_query(session_id, current_user))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not session_doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")
    return session_to_sarif(session_doc, uri or session_doc["filename"])


@router.get("/health")
async def analysis_health_check():
    """Check if analysis service is ready"""
    try:
        # Try to initialize the service to check if models are loaded
        vulnerability_analysis_service._initialize_if_needed()
        return {
            "status": "ready",
            "message": "Analysis service is ready to process requests"
        }
    except Exception as e:
        return {
            "status": "not_ready",
            "message": f"Analysis service is not ready: {str(e)}"
        }