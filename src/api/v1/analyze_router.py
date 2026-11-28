import os
import time
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
from src.services.graph_loader import get_vulnerabilities, get_model_versions, get_pipeline_fingerprint
from src.services.label_log import append_label_event, build_label_event
from src.services.knowledge import add_item, add_from_label_event
from src.services.findings import find, session_findings, replace_entry, pick_random_audits, audit_findings
from src.config.settings import settings
from src.utils.language import normalize_language
from src.models.entity import (
    StreamingNodeOutput, AnalysisSession, AnalysisSessionCreate,
    AnalysisSessionStatus, AnalysisStep, ProjectFile, UserInDB,
    FunctionReview, FunctionReviewUpdate, FunctionFix, FixDecision, FixDecisionUpdate
)
from src.infrastructure.database import get_analysis_sessions_collection, get_projects_collection, get_label_events_collection
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
    training_consent: bool = Form(False, description="Uploader agrees that this code and the expert verdicts on it may be used to retrain the models"),
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
        "model_versions": get_model_versions(),
        "pipeline": get_pipeline_fingerprint(),
        "language": normalize_language(language),
        "training_consent": bool(training_consent),
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
    
    # Same bytes, same model checkpoints, same explanation language -> same result: replay the stored steps (step 1.5).
    cached = None
    if settings.RESULT_CACHE:
        cached = await sessions_collection.find_one(
            {"_id": {"$ne": ObjectId(session_id)}, "file_hash": file_hash, "pipeline": session_doc["pipeline"],
             "language": session_doc["language"], "status": AnalysisSessionStatus.COMPLETED, "steps.step_name": "summary"},
            sort=[("completed_at", -1)])
        if cached:
            await sessions_collection.update_one({"_id": ObjectId(session_id)}, {"$set": {"cached_from": str(cached["_id"])}})

    async def replay(doc):
        """The stored events of an earlier scan of the same file, in their original order (expert reviews are not copied)."""
        for st in doc.get("steps", []):
            event = {"node": st.get("step_name"), "output": st.get("result_data") or {}}
            if st.get("vulnerability"):
                event["vulnerability"] = st["vulnerability"]
            if event["node"] == "start":
                event["output"] = {**event["output"], "cached_from": str(doc["_id"])}
            yield json.dumps(event) + "\n"

    async def run_job():
        """The analysis itself, detached from the HTTP connection (step 1.6): a client that disconnects or reloads the page
        no longer stops it. Every event is stored as a step; clients follow them with tail_session_events()."""
        from src.services import metrics
        t0, outcome = time.perf_counter(), "failed"
        metrics.gauge_add("analysis_running", 1, help_text="Analyses running or waiting for a slot")
        try:
            source = replay(cached) if cached else vulnerability_analysis_service.analyze_solidity_file(file_path, temp_dir, language)
            async for result_line in source:
                try:
                    result_data = json.loads(result_line.strip())
                except json.JSONDecodeError:
                    continue
                step = AnalysisStep(
                    step_name=result_data.get("node", "unknown"),
                    vulnerability=result_data.get("vulnerability"),
                    status="completed",
                    result_data=result_data.get("output", {}),
                    started_at=ensure_utc_for_db(now_vietnam()),
                    completed_at=ensure_utc_for_db(now_vietnam())
                )
                await sessions_collection.update_one({"_id": ObjectId(session_id)}, {"$push": {"steps": step.dict()}})
                _notify(session_id)

            # Mark session as completed; with the uploader's consent, queue a random sample of unflagged functions for experts
            done = {"status": AnalysisSessionStatus.COMPLETED, "completed_at": ensure_utc_for_db(now_vietnam())}
            if training_consent and settings.RANDOM_AUDIT_RATE > 0:
                stored = await sessions_collection.find_one({"_id": ObjectId(session_id)}, {"steps": 1})
                done["random_audits"] = pick_random_audits(stored or {}, settings.RANDOM_AUDIT_RATE, session_id)
            await sessions_collection.update_one({"_id": ObjectId(session_id)}, {"$set": done})
            outcome = "cached" if cached else "completed"
            
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
                
        except asyncio.CancelledError:
            # Only a server shutdown cancels the job now; fail_orphaned_sessions() closes it at the next start if this cannot.
            task = asyncio.get_running_loop().create_task(sessions_collection.update_one(
                {"_id": ObjectId(session_id)},
                {"$set": {"status": AnalysisSessionStatus.FAILED, "completed_at": ensure_utc_for_db(now_vietnam()),
                          "error_message": "Analysis stopped: the server shut down before it finished. Run it again."}}))
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
            
        finally:
            _notify(session_id)  # wake the clients following this session so they see the final status at once
            _session_signals.pop(session_id, None)  # followers already woken re-read the final status and stop
            metrics.gauge_add("analysis_running", -1)
            metrics.inc("analysis_jobs_total", help_text="Finished analyses by outcome", outcome=outcome)
            metrics.observe("analysis_duration_seconds", time.perf_counter() - t0, help_text="Analysis duration (whole contract)", outcome=outcome)

    job = asyncio.get_running_loop().create_task(run_job())
    _background.add(job)  # the loop keeps only a weak reference to tasks
    job.add_done_callback(_background.discard)

    return StreamingResponse(
        tail_session_events(session_id),
        media_type="application/x-ndjson",
        headers={"X-Session-ID": session_id}
    )


# Step 1.6: clients follow a session's stored steps instead of holding the analysis itself.
_session_signals: dict = {}  # session id -> asyncio.Event, set when a step is stored (in-process wake-up; polling covers the rest)


def _notify(session_id: str) -> None:
    signal = _session_signals.get(session_id)
    if signal:
        signal.set()


def step_to_event(step: dict) -> dict:
    """A stored step back into the stream event it was saved from."""
    event = {"node": step.get("step_name"), "output": step.get("result_data") or {}}
    if step.get("vulnerability"):
        event["vulnerability"] = step["vulnerability"]
    return event


async def tail_session_events(session_id: str, start: int = 0, poll_seconds: float = 0.5):
    """NDJSON of a session's events from index `start`: those already stored, then each new one, until it finishes.

    The status and the steps come from one read of the document, and steps are stored before the final status, so a
    finished status means every step has been sent. A failed analysis ends with an error event, as the stream always did.
    """
    sessions_collection = await get_analysis_sessions_collection()
    signal = _session_signals.setdefault(session_id, asyncio.Event())
    sent = start
    while True:
        doc = await sessions_collection.find_one(
            {"_id": ObjectId(session_id)}, {"steps": {"$slice": [sent, 100000]}, "status": 1, "error_message": 1})
        if doc is None:
            return
        for step in doc.get("steps", []):
            sent += 1
            yield json.dumps(step_to_event(step)) + "\n"
        status = doc.get("status")
        if status in (AnalysisSessionStatus.COMPLETED, AnalysisSessionStatus.FAILED):
            _session_signals.pop(session_id, None)  # no growth over a long run: one entry per running analysis at most
        if status == AnalysisSessionStatus.COMPLETED:
            return
        if status == AnalysisSessionStatus.FAILED:
            yield json.dumps({"node": "error", "output": {"error": f"Analysis failed: {doc.get('error_message') or 'unknown error'}",
                                                         "session_id": session_id}}) + "\n"
            return
        signal = _session_signals.setdefault(session_id, signal)
        signal.clear()
        try:
            await asyncio.wait_for(signal.wait(), timeout=poll_seconds)
        except asyncio.TimeoutError:
            pass


async def fail_orphaned_sessions() -> int:
    """At startup: analyses still 'processing' belonged to a server process that is gone; close them so clients stop waiting."""
    sessions_collection = await get_analysis_sessions_collection()
    result = await sessions_collection.update_many(
        {"status": AnalysisSessionStatus.PROCESSING},
        {"$set": {"status": AnalysisSessionStatus.FAILED, "completed_at": ensure_utc_for_db(now_vietnam()),
                  "error_message": "The server restarted before this analysis finished. Run it again."}})
    return result.modified_count


@router.get("/sessions/{session_id}/events")
async def session_events(session_id: str, start: int = Query(0, ge=0), current_user: UserInDB = Depends(get_current_user)):
    """Follow an analysis from its `start`-th event: after a reload or a dropped connection, the client reattaches here."""
    sessions_collection = await get_analysis_sessions_collection()
    try:
        doc = await sessions_collection.find_one(_session_query(session_id, current_user), {"_id": 1})
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid session ID format")
    if not doc:
        raise HTTPException(status_code=404, detail="Analysis session not found")
    return StreamingResponse(tail_session_events(session_id, start), media_type="application/x-ndjson",
                             headers={"X-Session-ID": session_id})


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
    """Sessions, from any user, with a flagged function or a random audit: the expert's worklist."""
    sessions_collection = await get_analysis_sessions_collection()
    cursor = sessions_collection.find(
        {"$or": [{"steps.result_data.func_vulnerability_predictions.prediction": 1}, {"random_audits.0": {"$exists": True}}]}
    ).sort("started_at", -1).limit(limit)
    sessions = await cursor.to_list(length=limit)
    # Step 1.7: work that is most likely right comes first. Sessions with unreviewed alerts are ordered by the highest
    # (calibrated) contract-level confidence among them; sessions with only random audits follow; fully reviewed ones last.
    sessions.sort(key=review_priority, reverse=True)
    result = []
    for session in sessions:
        session["id"] = str(session.pop("_id"))
        result.append(AnalysisSession(**session))
    return result


@router.get("/reviews/disagreements")
async def review_disagreements(current_user: UserInDB = Depends(require_expert)):
    """Step 2.6: items whose experts' final verdicts differ, plus agreement statistics. None of these is used for training
    until a further review settles it."""
    from src.services.label_log import disagreements, cohen_kappa, latest_verdicts, reviewer_rates
    events = await (await get_label_events_collection()).find({}, sort=[("seq", 1)]).to_list(length=None)
    both = [list(by.values())[:2] for by in latest_verdicts(events).values() if len(by) >= 2]
    return {"disagreements": disagreements(events), "items_with_two_reviewers": len(both),
            "cohen_kappa": cohen_kappa([tuple(p) for p in both]), "reviewers": reviewer_rates(events)}


def review_priority(session: dict) -> tuple:
    """(has unreviewed alerts, best contract confidence among them, has unreviewed audits, newest first)."""
    reviewed = {(r.get("vulnerability") or "timestamp", r.get("function_name")) for r in session.get("reviews", [])
                if r.get("status") not in (None, "pending")}
    pending = [f for f in session_findings(session) if (f["vulnerability"], f["function_name"]) not in reviewed]
    confidence = {}
    for step in session.get("steps", []):
        data = step.get("result_data") or {}
        if data.get("predicted_class") == "Vulnerable":
            confidence[step.get("vulnerability") or "timestamp"] = data.get("confidence_score") or 0.0
    best = max((confidence.get(f["vulnerability"], 0.0) for f in pending), default=0.0)
    audits = any((a["vulnerability"], a["function_name"]) not in reviewed for a in session.get("random_audits") or [])
    started = session.get("started_at")
    return (bool(pending), best, audits, started.timestamp() if hasattr(started, "timestamp") else 0)


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

    finding = find(session_doc, review.function_name, review.vulnerability, include_audits=True)
    if not finding:
        raise HTTPException(status_code=404, detail="Function not flagged or sampled for audit by this scan in this analysis")

    entry = FunctionReview(**review.dict(), reviewer=current_user.username, reviewed_at=ensure_utc_for_db(now_vietnam())).dict()
    entry["status"] = review.status.value
    # Function names contain dots, so reviews live in a list rather than a dict keyed by name.
    updated = await sessions_collection.find_one_and_update(
        {"_id": ObjectId(session_id)}, replace_entry("reviews", entry), return_document=ReturnDocument.AFTER)
    # Every verdict is also appended to the hash-chained label log: the session keeps only the latest one.
    event = await append_label_event(await get_label_events_collection(),
                                     build_label_event(session_doc, finding, entry, current_user.username, random_audit=bool(finding.get("random_audit"))))
    await _remember(add_from_label_event, event)  # step 1.8: the verdict is retrievable for the next similar function
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
    # Random audits are an expert's task, never an alert: the uploader does not see them
    return session_findings(session_doc) + (audit_findings(session_doc) if current_user.role == "expert" else [])


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
    if update.decision == FixDecision.ACCEPTED and updated.get("training_consent"):
        # Step 1.8: an accepted fix becomes a precedent for similar functions (original + fixed code)
        await _remember(add_item, "approved_fix", update.vulnerability, _function_code(updated, update.vulnerability, update.function_name),
                        note=update.note, source=f"session {session_id}", file_hash=updated.get("file_hash"), fixed_code=update.suggested_code)
    return updated.get("fixes", [])


def _function_code(session: dict, vulnerability: str, function_name: str) -> str:
    return next((p.get("function_code") or "" for step in session.get("steps", []) if (step.get("vulnerability") or "timestamp") == vulnerability
                 for p in (step.get("result_data") or {}).get("func_vulnerability_predictions") or [] if p.get("function_name") == function_name), "")


async def _remember(fn, *args, **kwargs):
    """Add to the knowledge base in a worker thread (it encodes the code); a failure is logged, never returned to the expert."""
    try:
        await asyncio.to_thread(fn, *args, **kwargs)
    except Exception as e:
        logger.warning(f"knowledge base update failed: {e}")


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