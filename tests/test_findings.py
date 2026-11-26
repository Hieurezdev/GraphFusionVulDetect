from src.services.findings import find, session_findings, stage, summarize


def event(vuln, node, **output):
    return {"node": node, "vulnerability": vuln, "output": output}


FLAGGED = [{"function_name": "C.pay()", "prediction": 1, "confidence": "91%", "lines": [5, 9], "span": [40, 80]},
           {"function_name": "C.get()", "prediction": 0, "confidence": "99%"}]


def test_summary_gives_one_verdict_per_scan_and_one_conclusion():
    s = summarize([
        event("timestamp", "detect_vulnerability_src", predicted_class="Non-Vulnerable", confidence_score=0.9),
        event("reentrancy", "detect_vulnerability_src", predicted_class="Vulnerable", confidence_score=0.8),
        event("reentrancy", "detect_vulnerability_func", func_vulnerability_predictions=FLAGGED),
    ])
    assert s["vulnerabilities"]["timestamp"]["status"] == "not_flagged"
    assert s["vulnerabilities"]["reentrancy"] == {"label": "Reentrancy", "status": "flagged", "confidence": 0.8, "flagged_functions": 1, "error": None}
    assert s["conclusion"] == "alerts" and s["manual_review"] == []


def test_summary_sends_failed_and_unlocated_scans_to_manual_review():
    s = summarize([
        event("timestamp", "error", error="solc failed"),
        event("reentrancy", "detect_vulnerability_src", predicted_class="Vulnerable", confidence_score=0.7),
        event("reentrancy", "detect_vulnerability_func", func_vulnerability_predictions=[FLAGGED[1]]),
    ])
    assert s["manual_review"] == [{"vulnerability": "timestamp", "reason": "analysis_failed"},
                                  {"vulnerability": "reentrancy", "reason": "contract_flagged_no_function"}]
    assert s["conclusion"] == "alerts"
    only_failed = summarize([event("timestamp", "error", error="x"), event("reentrancy", "detect_vulnerability_src", predicted_class="Non-Vulnerable")])
    assert only_failed["conclusion"] == "manual_review"   # a clean scan next to a failed one is not "no alerts"


def test_stage_follows_review_then_fix():
    assert stage(None, None) == "awaiting_review"
    assert stage({"status": "false_positive"}, None) == "closed_false_positive"
    assert stage({"status": "needs_manual_review"}, None) == "manual_review"
    assert stage({"status": "confirmed"}, None) == "awaiting_fix"
    assert stage({"status": "confirmed"}, {"compiled": False}) == "fix_failed_check"
    assert stage({"status": "confirmed"}, {"compiled": True}) == "awaiting_fix_approval"
    assert stage({"status": "confirmed"}, {"compiled": True, "decision": "accepted"}) == "fix_accepted"
    assert stage({"status": "confirmed"}, {"compiled": True, "decision": "rejected"}) == "awaiting_fix"


def test_findings_are_keyed_by_scan_and_function_and_old_sessions_default_to_timestamp():
    session = {
        "steps": [
            {"step_name": "detect_vulnerability_func", "result_data": {"func_vulnerability_predictions": FLAGGED}},                       # stored before the dual scan
            {"step_name": "detect_vulnerability_func", "vulnerability": "reentrancy", "result_data": {"func_vulnerability_predictions": FLAGGED}},
            {"step_name": "explain_vulnerability_func", "vulnerability": "reentrancy", "result_data": {"explanations": [{"function_name": "C.pay()", "explanation": "L7"}]}},
        ],
        "reviews": [{"function_name": "C.pay()", "status": "confirmed"}],                                                             # no vulnerability: timestamp
        "fixes": [{"vulnerability": "reentrancy", "function_name": "C.pay()", "compiled": True}],
    }
    ts, re = session_findings(session)
    assert (ts["vulnerability"], ts["stage"], ts["fix"]) == ("timestamp", "awaiting_fix", None)
    assert (re["vulnerability"], re["stage"], re["explanation"]) == ("reentrancy", "awaiting_review", "L7")
    assert find(session, "C.pay()")["vulnerability"] == "timestamp" and find(session, "C.pay()", "reentrancy")["span"] == [40, 80]
    assert find(session, "C.get()") is None
