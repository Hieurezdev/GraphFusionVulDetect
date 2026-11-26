from src.services.sarif import session_to_sarif

SESSION = {
    "_id": "abc",
    "steps": [
        {"step_name": "detect_vulnerability_src", "result_data": {"predicted_class": "Vulnerable", "confidence_score": 0.97}},
        {"step_name": "detect_vulnerability_func", "result_data": {"func_vulnerability_predictions": [
            {"function_name": "C.a()", "prediction": 1, "confidence": "90%", "lines": [12, 17]},
            {"function_name": "C.b()", "prediction": 1, "confidence": "80%", "lines": [20, 22]},
            {"function_name": "C.c()", "prediction": 0, "confidence": "99%", "lines": [24, 25]},
        ]}},
        {"step_name": "explain_vulnerability_func", "result_data": {"explanations": [{"function_name": "C.a()", "explanation": "L13 uses now"}]}},
    ],
    "reviews": [
        {"function_name": "C.a()", "status": "confirmed", "reviewer": "alice", "note": "real"},
        {"function_name": "C.b()", "status": "false_positive", "reviewer": "alice", "note": "now only logged"},
    ],
}


def test_sarif_carries_lines_reviews_and_suppressions():
    run = session_to_sarif(SESSION, "contracts/C.sol")["runs"][0]
    contract, a, b = run["results"]  # unflagged C.c() is left out
    assert contract["ruleId"] == "GFD-TS-CONTRACT"
    region = a["locations"][0]["physicalLocation"]
    assert region["artifactLocation"]["uri"] == "contracts/C.sol"
    assert region["region"] == {"startLine": 12, "endLine": 17}
    assert a["level"] == "error" and "L13 uses now" in a["message"]["text"]
    assert b["suppressions"][0]["justification"] == "now only logged"
    assert "not proof" in run["properties"]["disclaimer"]


def test_sarif_keeps_the_two_scans_apart():
    session = {"steps": [
        {"step_name": "detect_vulnerability_src", "vulnerability": "reentrancy", "result_data": {"predicted_class": "Vulnerable", "confidence_score": 0.8}},
        {"step_name": "detect_vulnerability_func", "vulnerability": "reentrancy", "result_data": {"func_vulnerability_predictions": [
            {"function_name": "C.a()", "prediction": 1, "confidence": "90%", "lines": [12, 17]}]}},
        {"step_name": "detect_vulnerability_src", "vulnerability": "timestamp", "result_data": {"predicted_class": "Non-Vulnerable", "confidence_score": 0.9}},
    ], "reviews": [{"vulnerability": "timestamp", "function_name": "C.a()", "status": "false_positive", "reviewer": "alice"}]}
    run = session_to_sarif(session, "C.sol")["runs"][0]
    assert [r["ruleId"] for r in run["results"]] == ["GFD-RE-CONTRACT", "GFD-RE-FUNC"]
    assert run["results"][1]["properties"]["reviewStatus"] == "pending"   # the timestamp review is about another finding
    assert {r["id"] for r in run["tool"]["driver"]["rules"]} == {"GFD-RE-FUNC", "GFD-RE-CONTRACT", "GFD-TS-FUNC", "GFD-TS-CONTRACT"}
