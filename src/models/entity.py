from typing import Optional, List, Dict, Any, Union
from pydantic import BaseModel, Field, EmailStr
from enum import Enum
from datetime import datetime
from src.utils.timezone import now_utc, now_vietnam, to_vietnam

# Authentication schemas
class UserRegister(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, pattern=r"^[A-Za-z0-9_.-]+$",
                          description="Username for the account; no '@', so it can never look like someone's email")
    email: EmailStr = Field(..., description="Email address for the account")
    password: str = Field(..., min_length=6, description="Password for the account")
    full_name: Optional[str] = Field(default=None, max_length=100, description="Full name of the user")
    account_type: str = Field(default="personal", pattern=r"^(personal|business)$",
                              description="personal: a guest workspace for one person; business: an organisation whose admin adds members")
    organization_name: Optional[str] = Field(default=None, max_length=100, description="Required for a business account")

class UserLogin(BaseModel):
    username: str = Field(..., description="Username or email")
    password: str = Field(..., description="Password")

class Token(BaseModel):
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiration time in seconds")

class TokenData(BaseModel):
    username: Optional[str] = None
    user_id: Optional[str] = None

class UserProfile(BaseModel):
    user_id: Optional[str] = Field(default=None, description="The unique identifier of the user")
    username: Optional[str] = Field(default=None, description="The user's login name")
    email: Optional[str] = Field(default=None, description="The user's email address")
    full_name: Optional[str] = Field(default=None, description="The user's full name")
    bio: Optional[str] = Field(default=None, description="A short bio of the user")
    created_at: Optional[datetime] = Field(default=None, description="Account creation timestamp")
    last_login: Optional[datetime] = Field(default=None, description="Last login timestamp")
    role: str = Field(default="admin", description="admin, developer, non_tech or expert (src/services/access.py)")
    organization_id: Optional[str] = Field(default=None, description="Workspace the account belongs to; none for a ScanGuard reviewer")
    organization_name: Optional[str] = None
    personal_workspace: bool = Field(default=True, description="The account is alone in its own workspace")
    permissions: List[str] = Field(default_factory=list, description="What the server lets this account do")
    policy: Dict[str, Any] = Field(default_factory=dict, description="The workspace's data policy")
    llm_external: bool = Field(default=True, description="The server's LLM is an outside service (code leaves the server when used)")
    consents_required: List[str] = Field(default_factory=list, description="Legal documents to accept before using the service")

class UserInDB(BaseModel):
    id: str = Field(..., alias="_id")
    username: str
    email: str
    full_name: Optional[str] = None
    hashed_password: str
    is_active: bool = True
    created_at: datetime
    last_login: Optional[datetime] = None
    token_version: int = 0
    password_changed_at: Optional[datetime] = None
    role: str = "user"  # admin, developer, non_tech or expert; "user" = an account from before organisations (admin)
    organization_id: Optional[str] = None
    organization: Optional[Dict[str, Any]] = None  # loaded with the user on every request, never stored
    consents: Dict[str, str] = Field(default_factory=dict)  # legal document -> accepted version

class PasswordChange(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=6)

# Project related schemas
class ProjectStatus(str, Enum):
    CREATED = "created"
    ANALYZING = "analyzing"
    COMPLETED = "completed"
    FAILED = "failed"

class ProjectCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Project name")
    description: Optional[str] = Field(default=None, max_length=500, description="Project description")

class ProjectUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=100, description="Project name")
    description: Optional[str] = Field(default=None, max_length=500, description="Project description")
    status: Optional[ProjectStatus] = Field(default=None, description="Project status")

class ProjectFile(BaseModel):
    filename: str = Field(..., description="Name of the uploaded file")
    file_size: int = Field(..., description="Size of the file in bytes")
    file_path: str = Field(..., description="Path where the file is stored")
    file_hash: str = Field(..., description="Hash of the file content")
    uploaded_at: datetime = Field(default_factory=now_utc, description="Upload timestamp")

class Project(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id", description="Unique project identifier")
    name: str = Field(..., description="Project name")
    description: Optional[str] = Field(default=None, description="Project description")
    user_id: str = Field(..., description="ID of the user who created the project")
    status: ProjectStatus = Field(default=ProjectStatus.CREATED, description="Project status")
    files: List[ProjectFile] = Field(default_factory=list, description="Files associated with the project")
    analysis_count: int = Field(default=0, description="Number of analyses performed")
    created_at: datetime = Field(default_factory=now_utc, description="Project creation timestamp")
    updated_at: datetime = Field(default_factory=now_utc, description="Project last update timestamp")

class ProjectResponse(BaseModel):
    id: str = Field(..., description="Unique project identifier")
    user_id: Optional[str] = Field(default=None, description="Who created the project")
    name: str = Field(..., description="Project name")
    description: Optional[str] = Field(default=None, description="Project description")
    status: ProjectStatus = Field(..., description="Project status")
    files_count: int = Field(..., description="Number of files in the project")
    analysis_count: int = Field(..., description="Number of analyses performed")
    created_at: datetime = Field(..., description="Project creation timestamp")
    updated_at: datetime = Field(..., description="Project last update timestamp")

# Analysis session related schemas
class AnalysisSessionStatus(str, Enum):
    CREATED = "created"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class AnalysisSessionCreate(BaseModel):
    project_id: str = Field(..., description="ID of the project this analysis belongs to")
    file_path: str = Field(..., description="Path to the file being analyzed")
    filename: str = Field(..., description="Name of the file being analyzed")

class AnalysisStep(BaseModel):
    step_name: str = Field(..., description="Name of the analysis step")
    vulnerability: Optional[str] = Field(default=None, description="Vulnerability scan the step belongs to; none for start/summary and for sessions stored before the dual scan")
    status: str = Field(..., description="Status of the step (started, completed, failed)")
    result_data: Dict[str, Any] = Field(default_factory=dict, description="Result data from the step")
    started_at: datetime = Field(default_factory=now_utc, description="Step start timestamp")
    completed_at: Optional[datetime] = Field(default=None, description="Step completion timestamp")
    error_message: Optional[str] = Field(default=None, description="Error message if step failed")

class ReviewStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    FALSE_POSITIVE = "false_positive"
    NEEDS_MANUAL_REVIEW = "needs_manual_review"

class FunctionReviewUpdate(BaseModel):
    vulnerability: str = Field(default="timestamp", description="Scan that flagged the function: timestamp or reentrancy")
    function_name: str = Field(..., min_length=1, max_length=300)
    status: ReviewStatus
    note: Optional[str] = Field(default=None, max_length=2000)

class FunctionReview(FunctionReviewUpdate):
    reviewer: str
    reviewed_at: datetime

class FixDecision(str, Enum):
    PROPOSED = "proposed"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    NEEDS_MANUAL_REVIEW = "needs_manual_review"

class FixDecisionUpdate(BaseModel):
    vulnerability: str = Field(default="timestamp")
    function_name: str = Field(..., min_length=1, max_length=300)
    decision: FixDecision
    note: Optional[str] = Field(default=None, max_length=2000)
    suggested_code: str = Field(..., max_length=200_000, description="The fix code the expert reviewed; the decision only applies if it is still the recorded one")

class FunctionFix(BaseModel):
    """A proposed fix for a confirmed finding, with the result of compiling and re-checking it, and the expert's decision."""
    vulnerability: str = "timestamp"
    function_name: str
    suggested_code: str
    compiled: bool
    solc_version: Optional[str] = None
    findings_before: int = 0
    findings_after: int = 0
    compiler_output: Optional[str] = None
    checked_by: str
    checked_at: datetime
    decision: FixDecision = FixDecision.PROPOSED
    decided_by: Optional[str] = None
    decided_at: Optional[datetime] = None
    note: Optional[str] = None

class AnalysisSession(BaseModel):
    id: Optional[str] = Field(default=None, description="Unique session identifier")
    project_id: Optional[str] = Field(default=None, description="ID of the project this analysis belongs to; none for a quick single-file analysis")
    user_id: str = Field(..., description="ID of the user who initiated the analysis")
    file_path: str = Field(..., description="Path to the file being analyzed")
    filename: str = Field(..., description="Name of the file being analyzed")
    vulnerabilities: List[str] = Field(default_factory=lambda: ["timestamp"], description="Vulnerability types this analysis scanned for")
    status: AnalysisSessionStatus = Field(default=AnalysisSessionStatus.CREATED, description="Session status")
    steps: List[AnalysisStep] = Field(default_factory=list, description="Analysis steps and their results")
    started_at: datetime = Field(default_factory=now_utc, description="Analysis start timestamp")
    completed_at: Optional[datetime] = Field(default=None, description="Analysis completion timestamp")
    error_message: Optional[str] = Field(default=None, description="Error message if analysis failed")
    reviews: List[FunctionReview] = Field(default_factory=list, description="Expert verdicts on flagged functions")
    fixes: List[FunctionFix] = Field(default_factory=list, description="Checked fixes for confirmed findings and the expert's decision on each")
    model_versions: Dict[str, Optional[str]] = Field(default_factory=dict, description="Checkpoint version that scored each vulnerability type")
    training_consent: bool = Field(default=False, description="Uploader agreed that this code and the verdicts on it may be used for retraining")
    random_audits: List[Dict[str, Any]] = Field(default_factory=list, description="Unflagged functions sampled at random for a blind expert check")
    organization_id: Optional[str] = Field(default=None, description="Workspace that owns the scan")
    review_requested: bool = Field(default=False, description="The owner asked an expert to review this scan")
    expires_at: Optional[datetime] = Field(default=None, description="When the scan and its code are deleted automatically")

# Analysis related schemas
class VulnerabilityType(str, Enum):
    REENTRANCY = "reentrancy"
    INTEGER_OVERFLOW = "integer_overflow"
    ACCESS_CONTROL = "access_control"
    UNCHECKED_CALL = "unchecked_call"
    TIMESTAMP_DEPENDENCY = "timestamp_dependency"
    OTHER = "other"

class VulnerabilitySeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

# Streaming response schemas based on server.py logic
class StreamingNodeOutput(BaseModel):
    """Base model for streaming node outputs"""
    node: str = Field(..., description="Name of the processing node")
    output: Dict[str, Any] = Field(..., description="Output data from the node")

class ConvertToFCGOutput(BaseModel):
    """Output from convert_to_fcg node"""
    fcg_file_path: Optional[str] = Field(default=None, description="Path to the generated FCG file")
    mapping_file_path: Optional[str] = Field(default=None, description="Path to the mapping file")
    error: Optional[str] = Field(default=None, description="Error message if conversion failed")

class VulnerabilityDetectionSrcOutput(BaseModel):
    """Output from detect_vulnerability_src node"""
    predicted_class: Optional[int] = Field(default=None, description="Predicted vulnerability class (0: safe, 1: vulnerable)")
    confidence_score: Optional[float] = Field(default=None, description="Confidence score of the prediction")
    error: Optional[str] = Field(default=None, description="Error message if detection failed")

class FunctionVulnerabilityPrediction(BaseModel):
    """Individual function vulnerability prediction"""
    function_name: Optional[str] = Field(default=None, description="Name of the function")
    prediction: Optional[int] = Field(default=None, description="Vulnerability prediction (0: safe, 1: vulnerable)")
    confidence: Optional[float] = Field(default=None, description="Confidence score")

class VulnerabilityDetectionFuncOutput(BaseModel):
    """Output from detect_vulnerability_func node"""
    func_vulnerability_predictions: Optional[List[FunctionVulnerabilityPrediction]] = Field(default=None, description="Function-level vulnerability predictions")
    fcg_edges: Optional[List[List[int]]] = Field(default=None, description="FCG edges information")
    error: Optional[str] = Field(default=None, description="Error message if detection failed")

class VulnerabilityExplanation(BaseModel):
    """Vulnerability explanation for a function"""
    function_name: Optional[str] = Field(default=None, description="Name of the function")
    explanation: Optional[str] = Field(default=None, description="LLM-generated explanation of the vulnerability")

class VulnerabilityExplanationOutput(BaseModel):
    """Output from explain_vulnerability_func node"""
    explanations: Optional[List[VulnerabilityExplanation]] = Field(default=None, description="Vulnerability explanations for functions")
    error: Optional[str] = Field(default=None, description="Error message if explanation failed")

# Legacy schemas (keeping for backward compatibility)
class FileUploadRequest(BaseModel):
    filename: str = Field(..., description="Name of the uploaded file")
    content_type: str = Field(default="text/plain", description="MIME type of the file")

class VulnerabilityResult(BaseModel):
    type: VulnerabilityType = Field(..., description="Type of vulnerability detected")
    severity: VulnerabilitySeverity = Field(..., description="Severity level of the vulnerability")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score (0-1)")
    line_number: Optional[int] = Field(default=None, description="Line number where vulnerability was found")
    description: str = Field(..., description="Description of the vulnerability")
    recommendation: Optional[str] = Field(default=None, description="Recommendation to fix the vulnerability")

class GraphAnalysisResult(BaseModel):
    nodes_count: int = Field(..., description="Number of nodes in the generated graph")
    edges_count: int = Field(..., description="Number of edges in the generated graph")
    complexity_score: float = Field(..., description="Complexity score of the code")
    graph_features: Dict[str, Any] = Field(default_factory=dict, description="Additional graph features")

class AnalysisRequest(BaseModel):
    file_path: str = Field(..., description="Path to the uploaded file")
    analysis_type: str = Field(default="full", description="Type of analysis to perform")
    model_version: str = Field(default="latest", description="Version of the model to use")

class AnalysisResponse(BaseModel):
    analysis_id: str = Field(..., description="Unique identifier for this analysis")
    file_name: str = Field(..., description="Name of the analyzed file")
    file_size: int = Field(..., description="Size of the analyzed file in bytes")
    analysis_timestamp: datetime = Field(default_factory=now_utc, description="Timestamp when analysis was performed")
    vulnerabilities: List[VulnerabilityResult] = Field(default_factory=list, description="List of detected vulnerabilities")
    graph_analysis: Optional[GraphAnalysisResult] = Field(default=None, description="Graph analysis results")
    processing_time: float = Field(..., description="Time taken to process the file in seconds")
    status: str = Field(default="completed", description="Status of the analysis")
    error_message: Optional[str] = Field(default=None, description="Error message if analysis failed")

class AnalysisStatus(BaseModel):
    analysis_id: str = Field(..., description="Unique identifier for the analysis")
    status: str = Field(..., description="Current status of the analysis")
    progress: float = Field(..., ge=0.0, le=1.0, description="Progress percentage (0-1)")
    estimated_time_remaining: Optional[float] = Field(default=None, description="Estimated time remaining in seconds")

class FileInfo(BaseModel):
    filename: str = Field(..., description="Name of the file")
    file_size: int = Field(..., description="Size of the file in bytes")
    file_type: str = Field(..., description="Type/extension of the file")
    upload_timestamp: datetime = Field(default_factory=now_utc, description="When the file was uploaded")
    saved_path: str = Field(..., description="Path where the file is saved on the server")

# Protection of uploaded code (docs/KE_HOACH_BAO_VE_MA_NGUON.md)
class ConsentSubmit(BaseModel):
    terms: bool = False
    privacy: bool = False
    upload_rights: bool = False
    training_data: Optional[bool] = Field(default=None, description="Workspace admins only: may the workspace's code be used for training")

class AccountDelete(BaseModel):
    password: str = Field(..., min_length=1)

class MemberCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, pattern=r"^[A-Za-z0-9_.-]+$")
    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: Optional[str] = Field(default=None, max_length=100)
    role: str = Field(..., pattern=r"^(admin|developer|non_tech|expert)$")

class MemberUpdate(BaseModel):
    role: Optional[str] = Field(default=None, pattern=r"^(admin|developer|non_tech|expert)$")
    is_active: Optional[bool] = None

class PolicyUpdate(BaseModel):
    retention_days: Optional[int] = Field(default=None, ge=1, le=365)
    external_llm: Optional[bool] = None
    training_data: Optional[bool] = None
    platform_experts: Optional[bool] = None
