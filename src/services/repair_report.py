"""CI gate for exported repair evidence, never a security certification."""

import argparse
import hashlib
from pathlib import Path

from pydantic import BaseModel, ValidationError

from src.models.ai_safety import FindingReview, ProposalReview, VerificationResult


class ReviewedProposal(BaseModel):
    suggested_code: str | None
    finding_review: FindingReview | None
    proposal_review: ProposalReview | None
    verification: VerificationResult


class RepairReport(BaseModel):
    thread_id: str
    code: str
    test_source: str | None
    response: ReviewedProposal


def evidence_failures(report: RepairReport) -> list[str]:
    response = report.response
    verification = response.verification
    finding, proposal = response.finding_review, response.proposal_review
    source_digest = hashlib.sha256(report.code.encode()).hexdigest()
    patch_digest = hashlib.sha256((response.suggested_code or "").encode()).hexdigest()
    test_digest = hashlib.sha256((report.test_source or "").encode()).hexdigest()
    failures = []
    if finding is None or finding.decision != "confirmed" or finding.source_sha256 != source_digest or finding.thread_id != report.thread_id:
        failures.append("A source-bound qualified reviewer confirmation is required.")
    elif finding.end_line < finding.start_line or finding.end_line > len(report.code.splitlines()):
        failures.append("The finding's evidence line range is invalid.")
    if not response.suggested_code or verification.status != "passed" or verification.source_sha256 != patch_digest:
        failures.append("Compilation must pass for the exact proposed code.")
    if (not report.test_source or verification.tests.status != "passed" or not verification.tests.cases
            or any(case.status != "passed" for case in verification.tests.cases)
            or verification.tests.test_source_sha256 != test_digest):
        failures.append("Behavioral assertions must pass with the supplied, source-bound test harness.")
    if (proposal is None or proposal.decision != "accepted_for_manual_application"
            or proposal.proposal_sha256 != patch_digest or proposal.thread_id != report.thread_id):
        failures.append("A qualified reviewer must accept this exact proposal for manual application.")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    args = parser.parse_args()
    try:
        report = RepairReport.model_validate_json(args.report.read_text(encoding="utf-8"))
    except (OSError, ValidationError):
        print("Repair evidence is missing or invalid. Export the current owned review report again.")
        return 1
    failures = evidence_failures(report)
    for failure in failures:
        print(failure)
    if failures:
        return 1
    print("Recorded review, compilation and supplied assertions passed. Manual application still requires judgment; security is not proven.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
