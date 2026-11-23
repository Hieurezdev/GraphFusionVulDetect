"""Source-bound evidence and portable SARIF diagnostics for model hypotheses."""

import hashlib
from pathlib import Path
from urllib.parse import quote

from pydantic import BaseModel, Field


class SourceLocation(BaseModel):
    filename: str
    start_line: int = Field(ge=1)
    end_line: int = Field(ge=1)
    source_sha256: str


class FunctionFinding(BaseModel):
    function_name: str
    function_code: str = ""
    prediction: int
    confidence: str | float | None = None
    source_location: SourceLocation | None = None


def byte_location(source: bytes, start: int | None, length: int | None, filename: str) -> SourceLocation | None:
    if start is None or length is None or start < 0 or length <= 0 or start + length > len(source):
        return None
    return SourceLocation(filename=Path(filename).name, start_line=source[:start].count(b"\n") + 1,
                          end_line=source[:start + length - 1].count(b"\n") + 1,
                          source_sha256=hashlib.sha256(source).hexdigest())


def locate_snippet(source: str, snippet: str, filename: str) -> SourceLocation | None:
    """Legacy results get a location only when their exact snippet is unique."""
    raw, target = source.encode("utf-8"), snippet.encode("utf-8")
    if not target or raw.count(target) != 1:
        return None
    return byte_location(raw, raw.index(target), len(target), filename)


def sarif_report(source: str, filename: str, findings: list[FunctionFinding], contract_flagged: bool, completed: bool) -> dict:
    digest = hashlib.sha256(source.encode("utf-8")).hexdigest()
    results = []
    for finding in findings:
        if finding.prediction != 1:
            continue
        location = finding.source_location
        if location is None or location.source_sha256 != digest:
            location = locate_snippet(source, finding.function_code, filename)
        result = {"ruleId": "GFD001", "level": "warning",
                  "message": {"text": f"AI-generated hypothesis for {finding.function_name}. Confirm evidence with a qualified reviewer; the model score is uncalibrated and is not severity."},
                  "properties": {"reviewRequired": True, "modelScore": finding.confidence, "sourceSha256": digest, "securityVerified": False}}
        if location:
            result["locations"] = [{"physicalLocation": {"artifactLocation": {"uri": quote(Path(filename).name)},
                                                        "region": {"startLine": location.start_line, "endLine": location.end_line}}}]
        results.append(result)
    if contract_flagged and not results:
        results.append({"ruleId": "GFD001", "level": "warning", "message": {"text": "AI-generated contract-level hypothesis. No specific function or line has been established; manual review is required."},
                        "locations": [{"physicalLocation": {"artifactLocation": {"uri": quote(Path(filename).name)}}}],
                        "properties": {"reviewRequired": True, "sourceSha256": digest, "securityVerified": False}})
    return {"version": "2.1.0", "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
            "runs": [{"tool": {"driver": {"name": "GraphFusionVulDetect", "rules": [{"id": "GFD001", "shortDescription": {"text": "Unconfirmed model hypothesis"}}]}},
                      "invocations": [{"executionSuccessful": completed}], "results": results,
                      "properties": {"warning": "Warnings and absence of warnings do not prove contract security. Expert review and behavioral tests remain required.", "sourceSha256": digest}}]}
