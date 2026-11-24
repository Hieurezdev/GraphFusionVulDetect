"""Turn a stored analysis session into SARIF 2.1.0, which VS Code (SARIF Viewer) and GitHub code scanning read."""

DISCLAIMER = ("Model output, not proof: every alert needs expert confirmation, "
              "and the absence of alerts does not mean the contract is safe.")

RULES = [
    {"id": "GFD-TS-FUNC", "name": "TimestampDependencyFunction",
     "shortDescription": {"text": "Function flagged for timestamp dependency"},
     "help": {"text": "A GNN model flagged this function. Confirm or reject it in GraphFusion before fixing. " + DISCLAIMER}},
    {"id": "GFD-TS-CONTRACT", "name": "TimestampDependencyContract",
     "shortDescription": {"text": "Contract flagged for timestamp dependency"},
     "help": {"text": "The contract-level model flagged this file. Review it manually. " + DISCLAIMER}},
]

# GitHub hides suppressed results; a rejected alert stays in the file as an audit trail.
LEVELS = {"confirmed": "error", "needs_manual_review": "warning", "pending": "warning", "false_positive": "note"}


def _outputs(session: dict, node: str) -> list:
    return [s.get("result_data") or {} for s in session.get("steps", []) if s.get("step_name") == node]


def session_to_sarif(session: dict, uri: str) -> dict:
    reviews = {r["function_name"]: r for r in session.get("reviews", [])}
    explanations = {e["function_name"]: e["explanation"]
                    for out in _outputs(session, "explain_vulnerability_func") for e in out.get("explanations", [])}
    results = []

    for out in _outputs(session, "detect_vulnerability_src"):
        if out.get("predicted_class") == "Vulnerable":
            results.append({
                "ruleId": "GFD-TS-CONTRACT", "level": "warning",
                "message": {"text": f"Contract flagged ({out.get('confidence_score', 0):.1%} confidence). Needs manual review."},
                "locations": [{"physicalLocation": {"artifactLocation": {"uri": uri}, "region": {"startLine": 1}}}],
            })

    for out in _outputs(session, "detect_vulnerability_func"):
        for p in out.get("func_vulnerability_predictions", []):
            if p.get("prediction") != 1:
                continue
            name = p["function_name"]
            review = reviews.get(name, {})
            status = review.get("status", "pending")
            lines = p.get("lines") or [1, 1]
            text = f"{name} flagged ({p.get('confidence')} confidence). Expert review: {status.replace('_', ' ')}."
            if review.get("note"):
                text += f" Note from {review.get('reviewer')}: {review['note']}"
            if name in explanations:
                text += "\n\n" + explanations[name]
            result = {
                "ruleId": "GFD-TS-FUNC", "level": LEVELS.get(status, "warning"), "message": {"text": text},
                "locations": [{"physicalLocation": {"artifactLocation": {"uri": uri},
                                                    "region": {"startLine": lines[0], "endLine": lines[1]}}}],
                "properties": {"confidence": p.get("confidence"), "reviewStatus": status, "reviewer": review.get("reviewer")},
            }
            if status == "false_positive":
                result["suppressions"] = [{"kind": "external", "status": "accepted",
                                           "justification": review.get("note") or "Rejected by expert review"}]
            results.append(result)

    return {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [{
            "tool": {"driver": {"name": "GraphFusion", "informationUri": "https://scanguard.ptitai.org", "rules": RULES}},
            "results": results,
            "properties": {"disclaimer": DISCLAIMER, "sessionId": str(session.get("_id", ""))},
        }],
    }
