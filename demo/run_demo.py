"""End-to-end walkthrough of the confirmed-fix workflow against a running API. Prints each step; exits non-zero if a rule is broken.

  detect (both scans, side by side) -> explain -> expert review -> fix -> compile + Slither re-check -> expert approval,
  plus the cases that stay with a human: an unconfirmed alert, a fix that does not compile, a finding without a prepared fix.

BASE=http://127.0.0.1:8000 USER_LOGIN=name:password EXPERT_LOGIN=name:password python demo/run_demo.py [contract.sol]
The expert account needs role "expert" in the users collection.
"""
import json, os, sys, urllib.error, urllib.request, uuid
from pathlib import Path

BASE = os.environ.get("BASE", "http://127.0.0.1:8000")
CONTRACT = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).with_name("EtherStore.sol"))
# The expert's verdicts and the prepared fix for the demo contract (EtherStore, the textbook reentrancy example).
# Both scans flag withdrawFunds: the reentrancy alert is real; the timestamp alert is a weekly limit, where a few
# seconds of miner drift change nothing. A finding with no entry here is sent to manual review.
VERDICTS = {("reentrancy", "withdrawFunds"): "confirmed", ("timestamp", "withdrawFunds"): "false_positive"}
FIXES = {
    ("reentrancy", "withdrawFunds"): "function withdrawFunds (uint256 _weiToWithdraw) public {\n require(balances[msg.sender] >= _weiToWithdraw);\n require(_weiToWithdraw <= withdrawalLimit);\n require(now >= lastWithdrawTime[msg.sender] + 1 weeks);\n balances[msg.sender] -= _weiToWithdraw;\n lastWithdrawTime[msg.sender] = now;\n msg.sender.transfer(_weiToWithdraw);\n }",
}
BROKEN = "function withdrawFunds (uint256 _weiToWithdraw) public { this is not solidity }"
key = lambda f: (f["vulnerability"], f["function_name"].split(".")[-1].split("(")[0])


def call(path, token=None, body=None, method=None, form=None):
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    data = None
    if form:
        b = uuid.uuid4().hex
        data = b"".join(f'--{b}\r\nContent-Disposition: form-data; name="{k}"'.encode() + (f'; filename="{v[0]}"\r\n\r\n'.encode() + v[1] if isinstance(v, tuple) else f"\r\n\r\n{v}".encode()) + b"\r\n" for k, v in form.items()) + f"--{b}--\r\n".encode()
        headers["Content-Type"] = f"multipart/form-data; boundary={b}"
    elif body is not None:
        data, headers["Content-Type"] = json.dumps(body).encode(), "application/json"
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method or ("POST" if data else "GET"))
    try:
        with urllib.request.urlopen(req, timeout=900) as r:
            return r.status, r.read().decode(), dict(r.headers)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(), {}


def login(spec):
    name, password = spec.split(":", 1)
    status, body, _ = call("/api/v1/auth/login", body={"username": name, "password": password})
    assert status == 200, body
    return json.loads(body)["access_token"]


def step(n, text):
    print(f"\n[{n}] {text}")


def main():
    user, expert = login(os.environ["USER_LOGIN"]), login(os.environ["EXPERT_LOGIN"])

    step(1, f"DETECT + EXPLAIN: upload {CONTRACT.name}; both scans run side by side")
    status, body, headers = call("/api/v1/analyze", user, form={"language": "en", "file": (CONTRACT.name, CONTRACT.read_bytes())})
    assert status == 200, body
    sid = headers.get("X-Session-ID") or headers.get("x-session-id")
    events = [json.loads(l) for l in body.splitlines() if l.strip()]
    assert events[0]["node"] == "start" and events[-1]["node"] == "summary", [e["node"] for e in events]
    print("    scans:", events[0]["output"]["vulnerabilities"], "| event order:", [f"{e.get('vulnerability', '-')[:2]}:{e['node']}" for e in events[1:-1]])
    summary = events[-1]["output"]
    for v, s in summary["vulnerabilities"].items():
        print(f"    {s['label']}: {s['status']}" + (f" (confidence {s['confidence']:.0%}, {s['flagged_functions']} function(s) flagged)" if s["confidence"] is not None else f" ({s['error']})"))
    print("    conclusion:", summary["conclusion"], "| manual review:", summary["manual_review"])

    findings = json.loads(call(f"/api/v1/sessions/{sid}/findings", user)[1])
    for f in findings:
        print(f"    finding: [{f['vulnerability']}] {f['function_name']} L{f['lines'][0]}-{f['lines'][1]} ({f['confidence']}) stage={f['stage']}")
        print("      explanation:", (f["explanation"] or "").replace("\n", " ")[:160])
    if not findings:
        print("    no function was flagged: nothing to fix. This is not proof the contract is safe; it needs a manual audit.")
        return

    step(2, "RULE: any user may propose and check a fix, but only an expert can review an alert")
    f0 = next((f for f in findings if key(f) in FIXES), findings[0])
    ident = {"vulnerability": f0["vulnerability"], "function_name": f0["function_name"]}
    status, body, _ = call(f"/api/v1/sessions/{sid}/reviews", user, {**ident, "status": "confirmed"}, "PUT")
    print("    non-expert tries to confirm ->", status)
    assert status == 403, body
    fix = FIXES.get(key(f0))
    if fix:
        v = json.loads(call("/api/v1/refactor/validate", user, {"original_code": "x", "suggested_code": fix, "session_id": sid, **ident})[1])
        print("    user checks a fix before any expert review -> compiled:", v["compiled"], "| recorded:", v["recorded"])
        assert v["compiled"] and v["recorded"], v
        stage = next(x["stage"] for x in json.loads(call(f"/api/v1/sessions/{sid}/findings", user)[1]) if (x["vulnerability"], x["function_name"]) == (f0["vulnerability"], f0["function_name"]))
        print("    the finding still waits for the expert ->", stage)
        assert stage == "awaiting_review", stage

    step(3, "EXPERT REVIEW: each alert is confirmed, rejected or sent to manual review")
    for f in findings:
        ident = {"vulnerability": f["vulnerability"], "function_name": f["function_name"]}
        verdict = VERDICTS.get(key(f), "needs_manual_review")
        status, body, _ = call(f"/api/v1/sessions/{sid}/reviews", expert, {**ident, "status": verdict, "note": "demo"}, "PUT")
        assert status == 200, body
        print(f"    [{f['vulnerability']}] {f['function_name']} -> {verdict}")

    confirmed = [f for f in findings if key(f) in FIXES and VERDICTS.get(key(f)) == "confirmed"]
    for f in confirmed:
        ident = {"vulnerability": f["vulnerability"], "function_name": f["function_name"]}
        step(4, f"FIX + COMPILE/RE-CHECK for [{f['vulnerability']}] {f['function_name']}")
        v = json.loads(call("/api/v1/refactor/validate", user, {"original_code": "x", "suggested_code": BROKEN, "session_id": sid, **ident})[1])
        print("    a broken fix -> compiled:", v["compiled"], "| recorded:", v["recorded"], "|", v["message"])
        status, body, _ = call(f"/api/v1/sessions/{sid}/fixes", expert, {**ident, "suggested_code": BROKEN, "decision": "accepted"}, "PUT")
        print("    expert tries to accept it ->", status, json.loads(body).get("detail") if status != 200 else "")
        assert status == 409, body
        v = json.loads(call("/api/v1/refactor/validate", user, {"original_code": "x", "suggested_code": FIXES[key(f)], "session_id": sid, **ident})[1])
        print("    the prepared fix -> compiled:", v["compiled"], f"(solc {v['solc_version']}) | Slither findings on the function:", len(v["findings_before"]), "->", len(v["findings_after"]), "| recorded:", v["recorded"])
        assert v["compiled"] and v["recorded"], v

        step(5, "EXPERT APPROVAL of the checked fix")
        status, body, _ = call(f"/api/v1/sessions/{sid}/fixes", user, {**ident, "suggested_code": FIXES[key(f)], "decision": "accepted"}, "PUT")
        print("    non-expert tries to accept ->", status)
        assert status == 403, body
        status, body, _ = call(f"/api/v1/sessions/{sid}/fixes", expert, {**ident, "suggested_code": FIXES[key(f)], "decision": "accepted", "note": "state updated before the transfer"}, "PUT")
        assert status == 200, body
        print("    expert accepts ->", status)

    step(6, "RESULT: where every finding stands, and the SARIF export for IDE/CI")
    for f in json.loads(call(f"/api/v1/sessions/{sid}/findings", user)[1]):
        print(f"    [{f['vulnerability']}] {f['function_name']}: {f['stage']}")
    sarif = json.loads(call(f"/api/v1/sessions/{sid}/sarif", user)[1])["runs"][0]
    print("    SARIF:", [(r["ruleId"], r["level"], r.get("properties", {}).get("workflowStage")) for r in sarif["results"]])
    print("\nsession", sid, "- a passing check is not proof of safety: accepted fixes still need the project's own tests and an audit.")


if __name__ == "__main__":
    main()
