"""Load and soak test of the running backend (step 1.10 of docs/KE_HOACH_TRIEN_KHAI.md).

N virtual users loop for D seconds: log in, list their sessions, analyse a contract (drawn from a fixed pool, so repeat
uploads exercise the result cache like real re-uploads do) and follow its stream to the end. Records every request's
latency and status, samples the backend's memory, and writes eval/load/<tag>.json + a summary.
Usage: uv run python eval/load/load_test.py --users 5 --seconds 300 --tag load_5u
"""
import argparse
import json
import os
import random
import statistics
import subprocess
import threading
import time
from pathlib import Path

import requests

API = os.getenv("GFD_API", "http://localhost:8000/api/v1")
REPO = Path(__file__).resolve().parents[2]
POOL = sorted((REPO / "assets/datasets/full/SourceCodeSyntaxDataset/TimestampDependencyDataset/Test").rglob("*.sol"))[:40] + [REPO / "demo/EtherStore.sol"]


def backend_rss_mb():
    """Resident memory of the process listening on :8000 (Windows), or None."""
    try:
        out = subprocess.run(["powershell", "-NoProfile", "-Command",
                              "(Get-Process -Id (Get-NetTCPConnection -LocalPort 8000 -State Listen).OwningProcess).WorkingSet64"],
                             capture_output=True, text=True, timeout=20).stdout.strip().splitlines()
        return round(int(out[0]) / 2 ** 20) if out else None
    except Exception:
        return None


def user(uid, stop_at, log, lock):
    rnd = random.Random(uid)
    s = requests.Session()

    def call(kind, fn):
        t0 = time.perf_counter()
        try:
            r = fn()
            status = r.status_code
            ok = 200 <= status < 300
        except Exception as e:
            r, status, ok = None, f"exc:{type(e).__name__}", False
        with lock:
            log.append({"kind": kind, "t": round(time.perf_counter() - t0, 3), "status": status, "ok": ok, "user": uid})
        return r if ok else None

    while time.time() < stop_at:
        r = call("login", lambda: s.post(f"{API}/auth/login", json={"username": "demo_user@example.com", "password": "Demo@12345"}, timeout=30))
        if not r:
            time.sleep(1)
            continue
        h = {"Authorization": f"Bearer {r.json()['access_token']}"}
        call("list_sessions", lambda: s.get(f"{API}/sessions", headers=h, params={"limit": 20}, timeout=30))
        path = rnd.choice(POOL)

        def analyse():
            with open(path, "rb") as f:
                resp = s.post(f"{API}/analyze", headers=h, files={"file": (path.name, f)}, data={"language": "vi"}, stream=True, timeout=900)
            nodes = [json.loads(l).get("node") for l in resp.iter_lines(decode_unicode=True) if l]
            if "summary" not in nodes:   # a stream that ends without its summary is a failure, whatever the status code
                resp.status_code = 599
            return resp
        call("analyze_full_stream", analyse)
        time.sleep(rnd.uniform(0.5, 2.0))


def pct(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(q * len(xs)))] if xs else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--users", type=int, default=5)
    ap.add_argument("--seconds", type=int, default=300)
    ap.add_argument("--tag", default="load")
    args = ap.parse_args()
    log, lock, mem = [], threading.Lock(), []
    stop_at = time.time() + args.seconds
    threads = [threading.Thread(target=user, args=(u, stop_at, log, lock), daemon=True) for u in range(args.users)]
    t0 = time.time()
    [t.start() for t in threads]
    while any(t.is_alive() for t in threads):
        mem.append({"t": round(time.time() - t0), "rss_mb": backend_rss_mb()})
        time.sleep(15)
    summary = {"users": args.users, "seconds": args.seconds, "requests": len(log), "errors": sum(not r["ok"] for r in log),
               "by_kind": {}, "memory_mb": {"first": mem[0]["rss_mb"] if mem else None, "last": mem[-1]["rss_mb"] if mem else None,
                                           "max": max((m["rss_mb"] or 0) for m in mem) if mem else None}}
    for kind in sorted({r["kind"] for r in log}):
        ts = [r["t"] for r in log if r["kind"] == kind and r["ok"]]
        summary["by_kind"][kind] = {"n": sum(r["kind"] == kind for r in log), "errors": sum(r["kind"] == kind and not r["ok"] for r in log),
                                    "p50_s": pct(ts, 0.5), "p95_s": pct(ts, 0.95), "max_s": max(ts) if ts else None,
                                    "mean_s": round(statistics.mean(ts), 3) if ts else None}
    out = REPO / "eval/load" / f"{args.tag}.json"
    out.write_text(json.dumps({"summary": summary, "memory": mem, "errors": [r for r in log if not r["ok"]][:50]}, indent=1), encoding="utf-8")
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    main()
