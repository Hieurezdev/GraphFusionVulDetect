"""What a finding is, in one place: a function one vulnerability scan flagged, with its expert review and its fix.

Used by the analysis stream (the closing summary), the review and fix endpoints, the findings endpoint and SARIF.
"""
from typing import Optional

from src.workflows.gfd_workflow.graph.state import VULNERABILITIES

DEFAULT = "timestamp"  # sessions stored before the dual scan carry no vulnerability on their steps and reviews


def vulnerability_of(item: dict) -> str:
    return item.get("vulnerability") or DEFAULT


def replace_entry(field: str, entry: dict) -> list:
    """One atomic update that swaps the entry for (vulnerability, function_name) in the list `field` for `entry`.

    Reading the list, editing it in Python and writing it back lost one of two concurrent edits.
    `entry` is wrapped in $literal, so user text starting with "$" is stored as text, not read as an expression.
    """
    same = {"$and": [
        {"$eq": [{"$ifNull": ["$$e.vulnerability", DEFAULT]}, entry["vulnerability"]]},
        {"$eq": ["$$e.function_name", entry["function_name"]]},
    ]}
    kept = {"$filter": {"input": {"$ifNull": [f"${field}", []]}, "as": "e", "cond": {"$not": [same]}}}
    return [{"$set": {field: {"$concatArrays": [kept, [{"$literal": entry}]]}}}]


def summarize(events: list, order: Optional[list] = None) -> dict:
    """Close a scan: one verdict per vulnerability type, one conclusion for the contract, and what a person must still check."""
    per, manual = {}, []
    for vuln in dict.fromkeys([*(order or []), *(vulnerability_of(e) for e in events)]):   # scan order, not arrival order
        by_node = {e["node"]: e.get("output") or {} for e in events if vulnerability_of(e) == vuln}
        src = by_node.get("detect_vulnerability_src")
        flagged = [p for p in by_node.get("detect_vulnerability_func", {}).get("func_vulnerability_predictions", []) if p.get("prediction") == 1]
        if "error" in by_node or src is None:
            status = "failed"
        elif src.get("predicted_class") != "Vulnerable":
            status = "not_flagged"
        else:
            status = "flagged" if flagged else "flagged_no_function"
        per[vuln] = {"label": VULNERABILITIES.get(vuln, vuln), "status": status, "confidence": (src or {}).get("confidence_score"),
                     "flagged_functions": len(flagged), "error": by_node.get("error", {}).get("error")}
        if status == "failed":
            manual.append({"vulnerability": vuln, "reason": "analysis_failed"})
        elif status == "flagged_no_function":
            manual.append({"vulnerability": vuln, "reason": "contract_flagged_no_function"})
    statuses = {v["status"] for v in per.values()}
    conclusion = "alerts" if statuses & {"flagged", "flagged_no_function"} else "manual_review" if "failed" in statuses else "no_alerts"
    return {"vulnerabilities": per, "conclusion": conclusion, "manual_review": manual}


def stage(review: Optional[dict], fix: Optional[dict]) -> str:
    """Where a finding stands in detect -> expert review -> fix -> compile/re-check -> expert approval."""
    status = (review or {}).get("status", "pending")
    if status == "pending":
        return "awaiting_review"
    if status == "false_positive":
        return "closed_false_positive"
    if status == "needs_manual_review":
        return "manual_review"
    if not fix:
        return "awaiting_fix"
    if not fix.get("compiled"):
        return "fix_failed_check"
    return {"proposed": "awaiting_fix_approval", "accepted": "fix_accepted", "rejected": "awaiting_fix",
            "needs_manual_review": "manual_review"}[fix.get("decision", "proposed")]


def session_findings(session: dict) -> list:
    """Every flagged function of a stored session, with its review, fix and stage."""
    key = lambda item: (vulnerability_of(item), item.get("function_name"))
    reviews = {key(r): r for r in session.get("reviews", [])}
    fixes = {key(f): f for f in session.get("fixes", [])}
    explanations, findings = {}, []
    for step in session.get("steps", []):
        for e in (step.get("result_data") or {}).get("explanations") or []:
            explanations[(vulnerability_of(step), e.get("function_name"))] = e.get("explanation")
    for step in session.get("steps", []):
        vuln = vulnerability_of(step)
        for p in (step.get("result_data") or {}).get("func_vulnerability_predictions") or []:
            if p.get("prediction") != 1:
                continue
            k = (vuln, p.get("function_name"))
            findings.append({"vulnerability": vuln, "vulnerability_label": VULNERABILITIES.get(vuln, vuln), "function_name": p.get("function_name"),
                             "lines": p.get("lines") or [], "span": p.get("span") or [], "confidence": p.get("confidence"),
                             "explanation": explanations.get(k), "review": reviews.get(k), "fix": fixes.get(k), "stage": stage(reviews.get(k), fixes.get(k))})
    return findings


def find(session: dict, function_name: str, vulnerability: Optional[str] = None) -> Optional[dict]:
    """The finding for a function; without a vulnerability type, the first scan that flagged it."""
    return next((f for f in session_findings(session)
                 if f["function_name"] == function_name and vulnerability in (None, f["vulnerability"])), None)
