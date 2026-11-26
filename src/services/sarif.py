"""Turn a stored analysis session into SARIF 2.1.0, which VS Code (SARIF Viewer) and GitHub code scanning read."""

DISCLAIMER = ("Model output, not proof: every alert needs expert confirmation, "
              "and the absence of alerts does not mean the contract is safe.")

from src.services.findings import session_findings, vulnerability_of
from src.workflows.gfd_workflow.graph.state import VULNERABILITIES

PREFIXES = {"timestamp": "GFD-TS", "reentrancy": "GFD-RE"}


def _rules(vulnerability: str) -> list:
    label, prefix = VULNERABILITIES[vulnerability], PREFIXES[vulnerability]
    return [
        {"id": f"{prefix}-FUNC", "name": label.replace(" ", "") + "Function",
         "shortDescription": {"text": f"Function flagged for {label.lower()}"},
         "help": {"text": "A GNN model flagged this function. Confirm or reject it in GraphFusion before fixing. " + DISCLAIMER}},
        {"id": f"{prefix}-CONTRACT", "name": label.replace(" ", "") + "Contract",
         "shortDescription": {"text": f"Contract flagged for {label.lower()}"},
         "help": {"text": "The contract-level model flagged this file. Review it manually. " + DISCLAIMER}},
    ]

# GitHub hides suppressed results; a rejected alert stays in the file as an audit trail.
LEVELS = {"confirmed": "error", "needs_manual_review": "warning", "pending": "warning", "false_positive": "note"}


def _outputs(session: dict, node: str) -> list:
    return [s.get("result_data") or {} for s in session.get("steps", []) if s.get("step_name") == node]


def session_to_sarif(session: dict, uri: str) -> dict:
    results, scanned = [], []

    for step in session.get("steps", []):
        out = step.get("result_data") or {}
        if step.get("step_name") != "detect_vulnerability_src":
            continue
        vulnerability = vulnerability_of(step)
        scanned.append(vulnerability)
        if out.get("predicted_class") == "Vulnerable":
            results.append({
                "ruleId": f"{PREFIXES[vulnerability]}-CONTRACT", "level": "warning",
                "message": {"text": f"Contract flagged for {VULNERABILITIES[vulnerability].lower()} ({out.get('confidence_score', 0):.1%} confidence). Needs manual review."},
                "locations": [{"physicalLocation": {"artifactLocation": {"uri": uri}, "region": {"startLine": 1}}}],
            })

    for f in session_findings(session):
        review, fix = f["review"] or {}, f["fix"] or {}
        status = review.get("status", "pending")
        lines = f["lines"] or [1, 1]
        text = f"{f['function_name']} flagged for {f['vulnerability_label'].lower()} ({f['confidence']} confidence). Expert review: {status.replace('_', ' ')}."
        if review.get("note"):
            text += f" Note from {review.get('reviewer')}: {review['note']}"
        if fix:
            text += (f" Fix: {'compiles' if fix.get('compiled') else 'does not compile'}, Slither findings {fix.get('findings_before')} -> {fix.get('findings_after')}, "
                     f"decision: {str(fix.get('decision', 'proposed')).replace('_', ' ')}.")
        if f["explanation"]:
            text += "\n\n" + f["explanation"]
        result = {
            "ruleId": f"{PREFIXES[f['vulnerability']]}-FUNC", "level": LEVELS.get(status, "warning"), "message": {"text": text},
            "locations": [{"physicalLocation": {"artifactLocation": {"uri": uri},
                                                "region": {"startLine": lines[0], "endLine": lines[1]}}}],
            "properties": {"confidence": f["confidence"], "reviewStatus": status, "reviewer": review.get("reviewer"),
                           "workflowStage": f["stage"], "fixDecision": fix.get("decision")},
        }
        if status == "false_positive":
            result["suppressions"] = [{"kind": "external", "status": "accepted",
                                       "justification": review.get("note") or "Rejected by expert review"}]
        results.append(result)

    rules = [r for v in dict.fromkeys(scanned or ["timestamp"]) for r in _rules(v)]
    return {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [{
            "tool": {"driver": {"name": "GraphFusion", "informationUri": "https://scanguard.ptitai.org", "rules": rules}},
            "results": results,
            "properties": {"disclaimer": DISCLAIMER, "sessionId": str(session.get("_id", ""))},
        }],
    }
