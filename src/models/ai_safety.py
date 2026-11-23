"""Validated payloads crossing the external AI boundary."""

from datetime import datetime, timezone
from typing import Annotated, Literal

from pydantic import AfterValidator, BaseModel, Field, field_validator, model_validator


def _review_time_utc(value: datetime) -> datetime:
    # MongoDB returns naive UTC datetimes with the default client configuration.
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value.astimezone(timezone.utc)


ReviewTimestamp = Annotated[datetime, AfterValidator(_review_time_utc)]


class ConversationMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1)


class AiPayload(BaseModel):
    operation: Literal["advice", "conversation"]
    code: str = Field(min_length=1)
    issue_description: str = ""
    conversation_history: list[ConversationMessage] = Field(default_factory=list)
    language: Literal["en", "vi"] = "en"
    thread_id: str | None = Field(default=None, max_length=64)
    context_id: str | None = Field(default=None, max_length=256)

    @model_validator(mode="after")
    def check_operation(self) -> "AiPayload":
        if self.operation == "advice" and not self.issue_description.strip():
            raise ValueError("An issue description is required for advice")
        if self.operation == "conversation" and (
            not self.conversation_history or self.conversation_history[-1].role != "user"
        ):
            raise ValueError("A conversation must end with a user message")
        return self


class AiFinding(BaseModel):
    category: str
    count: int


class AiReview(BaseModel):
    payload: AiPayload
    findings: list[AiFinding]
    blocked: bool
    review_token: str | None
    provider: str
    model: str
    encrypted_transport: bool


class ApprovedAiRequest(AiPayload):
    review_token: str = Field(min_length=1, max_length=4096)
    consent_confirmed: Literal[True]


class BehavioralTestCase(BaseModel):
    name: str
    status: Literal["passed", "failed"]
    message: str


class BehavioralTests(BaseModel):
    status: Literal["passed", "failed", "not_run"] = "not_run"
    message: str = "No behavioral tests were supplied. Expert review is required."
    cases: list[BehavioralTestCase] = Field(default_factory=list)
    test_source_sha256: str | None = None


class CompilerDiagnostic(BaseModel):
    severity: Literal["error", "warning", "info"]
    message: str
    source_file: str | None = None
    start_line: int | None = Field(default=None, ge=1)
    start_column: int | None = Field(default=None, ge=1)
    end_line: int | None = Field(default=None, ge=1)
    end_column: int | None = Field(default=None, ge=1)


class VerificationResult(BaseModel):
    status: Literal["passed", "failed", "not_run"]
    message: str
    compiler: str | None = None
    warnings: list[str] = Field(default_factory=list)
    security_verified: Literal[False] = False
    source_sha256: str | None = None
    tests: BehavioralTests = Field(default_factory=BehavioralTests)
    diagnostics: list[CompilerDiagnostic] = Field(default_factory=list)


class FindingReviewRequest(BaseModel):
    thread_id: str = Field(min_length=1, max_length=64)
    decision: Literal["confirmed", "rejected", "manual_review"]
    start_line: int = Field(ge=1)
    end_line: int = Field(ge=1)
    evidence_note: str = Field(min_length=10, max_length=4000)
    qualified_reviewer: Literal[True]

    @field_validator("evidence_note")
    @classmethod
    def require_rationale(cls, value: str) -> str:
        if len(value.strip()) < 10:
            raise ValueError("Provide evidence and rationale of at least ten non-padding characters")
        return value.strip()


class FindingReview(FindingReviewRequest):
    reviewer_id: str
    reviewed_at: ReviewTimestamp
    source_sha256: str
    qualification: Literal["self_attested"] = "self_attested"


class ProposalReviewRequest(BaseModel):
    thread_id: str = Field(min_length=1, max_length=64)
    proposal_sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    decision: Literal["accepted_for_manual_application", "rejected", "manual_review"]
    note: str = Field(min_length=10, max_length=4000)
    qualified_reviewer: Literal[True]

    @field_validator("note")
    @classmethod
    def require_rationale(cls, value: str) -> str:
        if len(value.strip()) < 10:
            raise ValueError("Provide rationale and remaining risks of at least ten non-padding characters")
        return value.strip()


class ProposalReview(ProposalReviewRequest):
    reviewer_id: str
    reviewed_at: ReviewTimestamp
    qualification: Literal["self_attested"] = "self_attested"


class AiDisclosure(BaseModel):
    ai_generated: Literal[True] = True
    model: str
    confidence: None = None
    confidence_calibrated: Literal[False] = False
    warning: str = "AI-generated content may be incorrect. Compiler success does not prove security."
