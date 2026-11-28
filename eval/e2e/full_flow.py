"""End-to-end check of the whole Bảng C flow against the running stack, as a browser would use it (cookie sessions).

Each check prints PASS/FAIL with evidence; the script exits non-zero if any check fails.
Usage: uv run python eval/e2e/full_flow.py [--api http://127.0.0.1:8081/api/v1]
"""
import argparse
import json
import subprocess
import sys
import time
import uuid
from pathlib import Path

import requests

REPO = Path(__file__).resolve().parents[2]
RESULTS = []
CSRF = {"X-Requested-With": "ScanGuard"}


def check(name, ok, evidence=""):
    RESULTS.append((name, bool(ok), evidence))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  [{evidence}]" if evidence else ""), flush=True)
    return ok


def login(api, user):
    s = requests.Session()
    r = s.post(f"{api}/auth/login", json={"username": user, "password": "Demo@12345"}, timeout=30)
    r.raise_for_status()
    return s, r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--api", default="http://127.0.0.1:8081/api/v1", help="through the frontend's proxy by default")
    ap.add_argument("--metrics", default="http://127.0.0.1:8000/metrics", help="the backend's own /metrics (not proxied)")
    args = ap.parse_args()
    api = args.api

    # A contract nobody has scanned yet (unique comment -> new file hash -> no cache), with a real reentrancy bug.
    source = (REPO / "demo/EtherStore.sol").read_text(encoding="utf-8") + f"\n// e2e run {uuid.uuid4()}\n"
    tmp = REPO / "storage" / "e2e_contract.sol"
    tmp.write_text(source, encoding="utf-8", newline="\n")

    user, r = login(api, "demo_user@example.com")
    check("login sets an httpOnly SameSite=Strict session cookie", "httponly" in r.headers.get("set-cookie", "").lower()
          and "samesite=strict" in r.headers.get("set-cookie", "").lower())
    check("cookie session works without a bearer header", user.get(f"{api}/auth/me", timeout=30).status_code == 200)

    # 1. analyse with consent; disconnect after 2 events; the job must finish anyway (1.6)
    with open(tmp, "rb") as f:
        resp = user.post(f"{api}/analyze", headers=CSRF, files={"file": ("EtherStore_e2e.sol", f)},
                         data={"language": "vi", "training_consent": "true"}, stream=True, timeout=600)
    sid = resp.headers.get("X-Session-ID")
    first = [json.loads(l) for _, l in zip(range(2), (x for x in resp.iter_lines(decode_unicode=True) if x))]
    resp.close()
    check("analysis starts and returns a session id", resp.status_code == 200 and sid, sid)
    t0 = time.time()
    while time.time() - t0 < 600:
        s = user.get(f"{api}/sessions/{sid}", timeout=30).json()
        if s["status"] in ("completed", "failed"):
            break
        time.sleep(2)
    check("analysis finishes after the client disconnected (1.6)", s["status"] == "completed", f"{s['status']} in {time.time() - t0:.0f}s")
    events = [json.loads(l) for l in user.get(f"{api}/sessions/{sid}/events", timeout=60).iter_lines(decode_unicode=True) if l]
    check("reattaching replays every stored event (1.6)", [e["node"] for e in events] == [st["step_name"] for st in s["steps"]] and events[:2] == first,
          f"{len(events)} events")

    src = {e["vulnerability"]: e["output"] for e in events if e["node"] == "detect_vulnerability_src"}
    check("timestamp confidence is calibrated (1.7)", src.get("timestamp", {}).get("confidence_score", 0) > 0.98,
          f"{src.get('timestamp', {}).get('confidence_score'):.3f}")
    check("model versions and pipeline fingerprint recorded (1.3, 1.5)", s.get("model_versions") and s.get("training_consent") is True)
    expl = [x for e in events if e["node"] == "explain_vulnerability_func" for x in e["output"]["explanations"]]
    check("every explanation passed the output guard (1.2)", expl and all(x["guard"]["ok"] for x in expl), f"{len(expl)} explanations")
    check("explanations carry retrieved references (1.8)", expl and all(len(x.get("references", [])) == 3 for x in expl))
    summary = next(e["output"] for e in events if e["node"] == "summary")
    check("both vulnerabilities flagged on the demo contract", all(v["status"] == "flagged" for v in summary["vulnerabilities"].values()),
          json.dumps({k: v["status"] for k, v in summary["vulnerabilities"].items()}))

    # 2. expert review with the cookie: the anti-CSRF header is required (2.5)
    expert, _ = login(api, "demo_expert@example.com")
    body = {"vulnerability": "reentrancy", "function_name": "EtherStore.withdrawFunds(uint256)", "status": "confirmed", "note": "e2e: call before balance update"}
    check("cookie write without anti-CSRF header is refused (2.5)", expert.put(f"{api}/sessions/{sid}/reviews", json=body, timeout=30).status_code == 403)
    check("normal user cannot confirm an alert", user.put(f"{api}/sessions/{sid}/reviews", json=body, headers=CSRF, timeout=30).status_code == 403)
    check("expert confirms the reentrancy alert", expert.put(f"{api}/sessions/{sid}/reviews", json=body, headers=CSRF, timeout=30).status_code == 200)
    out = subprocess.run([sys.executable, "scripts/verify_label_log.py"], capture_output=True, text=True, cwd=REPO).stdout.strip()
    check("label log chain intact after the new verdict (1.3)", out.startswith("OK"), out)

    queue = expert.get(f"{api}/reviews/queue", timeout=60).json()
    check("expert queue lists sessions, unreviewed first (1.7)", isinstance(queue, list) and queue, f"{len(queue)} sessions")
    findings_u = user.get(f"{api}/sessions/{sid}/findings", timeout=30).json()
    findings_e = expert.get(f"{api}/sessions/{sid}/findings", timeout=30).json()
    audits = [f for f in findings_e if f.get("random_audit")]
    check("random audits are visible to experts only (1.4)", not any(f.get("random_audit") for f in findings_u),
          f"{len(audits)} audits for the expert, {len(findings_u)} findings for the user")

    # 3. repair agent, then expert decision on its fix (2.1)
    ag = user.post(f"{api}/refactor/agent", headers=CSRF, json={"session_id": sid, "vulnerability": "reentrancy",
                   "function_name": "EtherStore.withdrawFunds(uint256)", "language": "vi"}, timeout=900).json()
    check("repair agent submits a fix that compiles (2.1)", ag.get("fix") and ag.get("verification", {}).get("compiled"),
          f"{ag.get('rounds')} rounds, {ag.get('tool_calls')} tool calls, holds={ag.get('verification', {}).get('holds')}")
    check("agent fix recorded on the finding", ag.get("recorded") is True)
    dec = expert.put(f"{api}/sessions/{sid}/fixes", headers=CSRF, json={"vulnerability": "reentrancy", "function_name": "EtherStore.withdrawFunds(uint256)",
                     "decision": "accepted", "suggested_code": ag.get("fix") or "", "note": "e2e accept"}, timeout=60)
    check("expert accepts the compiled fix of a confirmed alert", dec.status_code == 200, dec.status_code)
    sarif = user.get(f"{api}/sessions/{sid}/sarif", timeout=30).json()
    check("SARIF export works", sarif.get("version") == "2.1.0", f"{sum(len(r['results']) for r in sarif['runs'])} results")

    dis = expert.get(f"{api}/reviews/disagreements", timeout=30)
    check("disagreement / agreement endpoint answers experts (2.6)", dis.status_code == 200, json.dumps({k: v for k, v in dis.json().items() if k != 'disagreements'})[:160])
    check("disagreement endpoint refuses normal users", user.get(f"{api}/reviews/disagreements", timeout=30).status_code == 403)
    chat = user.post(f"{api}/refactor/conversation", headers=CSRF, json={"code": source, "conversation_history": [{"role": "user", "content": "Tóm tắt lỗi chính trong một câu."}],
                     "language": "vi"}, timeout=300)
    check("RefactorBot answers through the cookie session (2.2)", chat.status_code == 200 and chat.json().get("bot_message"))
    metrics = requests.get(args.metrics, timeout=30).text
    check("metrics endpoint exposes analyses and LLM calls (1.10)", "analysis_jobs_total" in metrics and "llm_calls_total" in metrics)
    lo = user.post(f"{api}/auth/logout", headers=CSRF, timeout=30)
    check("logout clears the session", lo.status_code == 200 and user.get(f"{api}/auth/me", timeout=30).status_code == 401)

    failed = [n for n, ok, _ in RESULTS if not ok]
    print(f"\n{len(RESULTS) - len(failed)}/{len(RESULTS)} checks passed" + (f"; failed: {failed}" if failed else ""))
    tmp.unlink(missing_ok=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
