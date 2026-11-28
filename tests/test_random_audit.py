from src.services.findings import pick_random_audits, audit_findings, find, session_findings

PRED = lambda name, flagged: {"function_name": name, "function_code": f"function {name}() {{}}", "lines": [1, 2], "span": [0, 10], "prediction": int(flagged)}


def _session(n_unflagged=200):
    preds = [PRED("C.hit", True)] + [PRED(f"C.f{i}", False) for i in range(n_unflagged)]
    return {"_id": "s", "steps": [{"vulnerability": "timestamp", "result_data": {"func_vulnerability_predictions": preds}}], "reviews": []}


def test_sample_takes_only_unflagged_functions_at_about_the_rate_and_is_reproducible():
    s = _session()
    a, b = pick_random_audits(s, 0.1, "seed-1"), pick_random_audits(s, 0.1, "seed-1")
    assert a == b and 5 <= len(a) <= 40
    assert all(x["function_name"] != "C.hit" for x in a)
    assert pick_random_audits(s, 0.0, "seed-1") == []


def test_audits_are_blind_and_never_part_of_the_alerts():
    s = _session(50)
    s["random_audits"] = pick_random_audits(s, 1.0, "x")[:2]
    audits = audit_findings(s)
    assert all(f["random_audit"] and f["confidence"] is None and f["explanation"] is None for f in audits)
    assert [f["function_name"] for f in session_findings(s)] == ["C.hit"]          # alerts unchanged (SARIF, uploader view)
    name = audits[0]["function_name"]
    assert find(s, name, "timestamp") is None and find(s, name, "timestamp", include_audits=True)["random_audit"]


def test_review_priority_orders_unreviewed_by_confidence_then_audits_then_done():
    from datetime import datetime
    from src.api.v1.analyze_router import review_priority

    def session(conf, reviewed=False, audits=False):
        steps = [{"vulnerability": "timestamp", "result_data": {"predicted_class": "Vulnerable", "confidence_score": conf}},
                 {"vulnerability": "timestamp", "result_data": {"func_vulnerability_predictions": [PRED("C.hit", conf > 0)]}}]
        reviews = [{"vulnerability": "timestamp", "function_name": "C.hit", "status": "confirmed"}] if reviewed else []
        ra = [{"vulnerability": "timestamp", "function_name": "C.f0", "lines": [], "span": []}] if audits else []
        return {"steps": steps, "reviews": reviews, "random_audits": ra, "started_at": datetime(2026, 11, 28), "name": (conf, reviewed, audits)}

    order = sorted([session(0.6), session(0.95), session(0.99, reviewed=True), session(0.0, audits=True)], key=review_priority, reverse=True)
    assert [s["name"] for s in order] == [(0.95, False, False), (0.6, False, False), (0.0, False, True), (0.99, True, False)]
