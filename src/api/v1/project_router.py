import hashlib
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from bson import ObjectId
from src.models.entity import (
    ProjectCreate, ProjectUpdate, Project, ProjectResponse, 
    ProjectFile, ProjectStatus, UserInDB, AnalysisSession
)
from src.infrastructure.database import get_projects_collection, get_analysis_sessions_collection
from src.utils.timezone import now_vietnam, ensure_utc_for_db, to_vietnam
from .authentication_router import get_current_user
from src.services import audit, data_lifecycle
from src.services.access import can, scope


def can_delete_project(user: UserInDB, project: dict) -> bool:
    return can(user, "delete_project") or (project.get("user_id") == user.id and can(user, "delete_own_session"))


def require_upload(user: UserInDB) -> None:
    if not can(user, "upload"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your role cannot create or change projects")

router = APIRouter(prefix="/projects", tags=["projects"])
logger = logging.getLogger("GraphFusionVulDetect-Projects")


def serialize_project(project_doc: dict) -> dict:
    """Convert MongoDB document to serializable dict"""
    if "_id" in project_doc:
        project_doc["id"] = str(project_doc["_id"])
        del project_doc["_id"]
    return project_doc


@router.post("/", response_model=ProjectResponse)
async def create_project(
    project_data: ProjectCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new project"""
    require_upload(current_user)
    projects_collection = await get_projects_collection()
    
    # Check if user already has a project with this name
    existing_project = await projects_collection.find_one({
        **scope(current_user),
        "name": project_data.name
    })
    
    if existing_project:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A project with this name already exists"
        )
    
    # Create project document
    project_doc = {
        "name": project_data.name,
        "description": project_data.description,
        "user_id": current_user.id,
        "organization_id": current_user.organization_id,
        "status": ProjectStatus.CREATED,
        "files": [],
        "analysis_count": 0,
        "created_at": ensure_utc_for_db(now_vietnam()),
        "updated_at": ensure_utc_for_db(now_vietnam())
    }
    
    # Insert project into database
    result = await projects_collection.insert_one(project_doc)
    project_doc["_id"] = result.inserted_id
    
    # Return project response
    return ProjectResponse(
        id=str(project_doc["_id"]),
        user_id=project_doc.get("user_id"),
        name=project_doc["name"],
        description=project_doc["description"],
        status=project_doc["status"],
        files_count=len(project_doc["files"]),
        analysis_count=project_doc["analysis_count"],
        created_at=to_vietnam(project_doc["created_at"]),
        updated_at=to_vietnam(project_doc["updated_at"])
    )


@router.get("/", response_model=List[ProjectResponse])
async def list_projects(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status: Optional[ProjectStatus] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """List user's projects"""
    projects_collection = await get_projects_collection()
    
    # Build query
    query = {**scope(current_user)}
    if status:
        query["status"] = status
    
    # Execute query
    cursor = projects_collection.find(query).sort("updated_at", -1).skip(skip).limit(limit)
    projects = await cursor.to_list(length=limit)
    
    # Convert to response format
    return [
        ProjectResponse(
            id=str(project["_id"]),
            user_id=project.get("user_id"),
            name=project["name"],
            description=project.get("description"),
            status=project["status"],
            files_count=len(project.get("files", [])),
            analysis_count=project.get("analysis_count", 0),
            created_at=to_vietnam(project["created_at"]),
            updated_at=to_vietnam(project["updated_at"])
        )
        for project in projects
    ]


@router.get("/{project_id}", response_model=Project)
async def get_project(
    project_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific project"""
    projects_collection = await get_projects_collection()
    
    try:
        project_doc = await projects_collection.find_one({
            "_id": ObjectId(project_id),
            **scope(current_user)
        })
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid project ID"
        )
    
    if not project_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )
    
    project_doc = serialize_project(project_doc)
    project_doc["created_at"] = to_vietnam(project_doc["created_at"])
    project_doc["updated_at"] = to_vietnam(project_doc["updated_at"])
    return Project(**project_doc)


@router.put("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: str,
    project_data: ProjectUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a project"""
    require_upload(current_user)
    projects_collection = await get_projects_collection()
    
    try:
        # Check if project exists and belongs to user
        existing_project = await projects_collection.find_one({
            "_id": ObjectId(project_id),
            **scope(current_user)
        })
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid project ID"
        )
    
    if not existing_project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )
    
    # Build update data
    update_data = {"updated_at": ensure_utc_for_db(now_vietnam())}
    
    if project_data.name is not None:
        # Check for name conflicts
        name_conflict = await projects_collection.find_one({
            **scope(current_user),
            "name": project_data.name,
            "_id": {"$ne": ObjectId(project_id)}
        })
        if name_conflict:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A project with this name already exists"
            )
        update_data["name"] = project_data.name
    
    if project_data.description is not None:
        update_data["description"] = project_data.description
    
    if project_data.status is not None:
        update_data["status"] = project_data.status
    
    # Update project
    await projects_collection.update_one(
        {"_id": ObjectId(project_id)},
        {"$set": update_data}
    )
    
    # Get updated project
    updated_project = await projects_collection.find_one({"_id": ObjectId(project_id)})
    
    return ProjectResponse(
        id=str(updated_project["_id"]),
        user_id=updated_project.get("user_id"),
        name=updated_project["name"],
        description=updated_project.get("description"),
        status=updated_project["status"],
        files_count=len(updated_project.get("files", [])),
        analysis_count=updated_project.get("analysis_count", 0),
        created_at=to_vietnam(updated_project["created_at"]),
        updated_at=to_vietnam(updated_project["updated_at"])
    )


@router.delete("/{project_id}")
async def delete_project(
    project_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a project with every scan in it, and their code everywhere it is kept (the workspace admin, or whoever created
    the project when their role may delete its own scans)"""
    projects_collection = await get_projects_collection()
    try:
        project_doc = await projects_collection.find_one({"_id": ObjectId(project_id), **scope(current_user)})
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid project ID")
    if not project_doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    if not can_delete_project(current_user, project_doc):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the workspace admin or the project's creator can delete it")
    removed = await data_lifecycle.delete_project(project_doc, current_user.username)
    await audit.record(current_user, "delete_project", project_doc.get("organization_id"), target=project_id,
                       detail={"name": project_doc.get("name"), **removed})
    return {"message": "Project deleted successfully", "removed": removed}


@router.post("/{project_id}/files", response_model=ProjectFile)
async def add_file_to_project(
    project_id: str,
    file: UploadFile = File(...),
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a file to a project"""
    require_upload(current_user)
    projects_collection = await get_projects_collection()
    
    try:
        # Check if project exists and belongs to user
        project_doc = await projects_collection.find_one({
            "_id": ObjectId(project_id),
            **scope(current_user)
        })
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid project ID"
        )
    
    if not project_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )
    
    # Read file content and calculate hash
    file_content = await file.read()
    file_hash = hashlib.sha256(file_content).hexdigest()
    
    # Create file info
    project_file = ProjectFile(
        filename=file.filename,
        file_size=len(file_content),
        file_path="",  # Will be set when file is saved during analysis
        file_hash=file_hash,
        uploaded_at=ensure_utc_for_db(now_vietnam())
    )
    
    # Update project with new file
    await projects_collection.update_one(
        {"_id": ObjectId(project_id)},
        {
            "$push": {"files": project_file.model_dump()},
            "$set": {"updated_at": ensure_utc_for_db(now_vietnam())}
        }
    )
    
    return project_file


@router.get("/{project_id}/files", response_model=List[ProjectFile])
async def list_project_files(
    project_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """List files in a project"""
    project = await get_project(project_id, current_user)
    return project.files


@router.get("/{project_id}/sessions", response_model=List[AnalysisSession])
async def get_project_analysis_sessions(
    project_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get analysis sessions for a specific project"""
    # First verify user has access to the project
    await get_project(project_id, current_user)
    
    sessions_collection = await get_analysis_sessions_collection()
    
    # Build query for this project
    query = {
        "project_id": project_id,
        **scope(current_user)
    }
    
    # Execute query
    cursor = sessions_collection.find(query).sort("started_at", -1).skip(skip).limit(limit)
    sessions = await cursor.to_list(length=limit)
    
    # Convert to response format
    result = []
    from .analyze_router import present
    for session in sessions:
        analysis_session = present(session, current_user)
        analysis_session.started_at = to_vietnam(analysis_session.started_at)
        analysis_session.completed_at = to_vietnam(analysis_session.completed_at)
        for step in analysis_session.steps:
            step.started_at = to_vietnam(step.started_at)
            step.completed_at = to_vietnam(step.completed_at)
        result.append(analysis_session)
    return result
