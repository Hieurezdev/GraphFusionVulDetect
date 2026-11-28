"""Step 1.6 check: an analysis keeps running when its client disconnects, and a client can reattach from any event.

1. start an analysis, read only the first 2 events, close the connection;
2. wait until the session is completed (the job ran on without a client);
3. follow GET /sessions/{id}/events from 0 and from 3: the events must equal the stored steps.
Usage: uv run python eval/baseline/detach_check.py <file.sol>
"""
import json
import sys
import time

import requests

API = "http://localhost:8000/api/v1"


def token(user="demo_user@example.com"):
    return requests.post(f"{API}/auth/login", json={"username": user, "password": "Demo@12345"}, timeout=30).json()["access_token"]


def main(path):
    h = {"Authorization": f"Bearer {token()}"}
    with open(path, "rb") as f:
        r = requests.post(f"{API}/analyze", headers=h, files={"file": (path.split("/")[-1], f)}, data={"language": "vi"}, stream=True, timeout=600)
    sid = r.headers["X-Session-ID"]
    first = []
    for line in r.iter_lines(decode_unicode=True):
        if line:
            first.append(json.loads(line))
        if len(first) == 2:
            break
    r.close()  # the client goes away after 2 events
    print("session", sid, "| read", [e["node"] for e in first], "then disconnected")

    t0 = time.time()
    while True:
        s = requests.get(f"{API}/sessions/{sid}", headers=h, timeout=30).json()
        if s["status"] in ("completed", "failed") or time.time() - t0 > 600:
            break
        time.sleep(1)
    print("status after disconnect:", s["status"], f"(+{time.time() - t0:.1f}s)", "| stored steps:", len(s["steps"]), "| error:", s.get("error_message"))

    def follow(start):
        out = []
        with requests.get(f"{API}/sessions/{sid}/events", headers=h, params={"start": start}, stream=True, timeout=120) as rr:
            for line in rr.iter_lines(decode_unicode=True):
                if line:
                    out.append(json.loads(line))
        return out

    all_events, tail = follow(0), follow(3)
    stored = [st["step_name"] for st in s["steps"]]
    print("follow from 0:", len(all_events), "events, nodes match stored steps:", [e["node"] for e in all_events] == stored)
    print("follow from 3:", len(tail), "events, equals events[3:]:", tail == all_events[3:])
    print("first 2 events identical to the live stream:", all_events[:2] == first)
    other = requests.get(f"{API}/sessions/{sid}/events", headers={"Authorization": f"Bearer {token('demo_expert@example.com')}"}, timeout=30)
    print("expert may follow:", other.status_code)
    return 0 if s["status"] == "completed" and tail == all_events[3:] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
