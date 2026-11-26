"""Send every flattened case through the deployed /api/v1/analyze and keep the raw NDJSON stream.

SCANGUARD_USER=... SCANGUARD_PASS=... python3 run_analyze.py [base_url]
Resumable: cases with a file in results/ are skipped.
"""
import json, os, sys, time, urllib.error, urllib.request, uuid
from pathlib import Path

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:18510"
HERE = Path(__file__).parent
OUT = HERE / "results"


def call(path, data=None, headers=None, timeout=900):
    req = urllib.request.Request(BASE + path, data=data, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:  # timeout / dropped stream: record it, it is a result too
        return 0, f"{type(e).__name__}: {e}"


def main():
    OUT.mkdir(exist_ok=True)
    status, body = call("/api/v1/auth/login", json.dumps({"username": os.environ["SCANGUARD_USER"], "password": os.environ["SCANGUARD_PASS"]}).encode(),
                        {"Content-Type": "application/json"})
    assert status == 200, body
    auth = {"Authorization": "Bearer " + json.loads(body)["access_token"]}
    pid_file = OUT / "_project_id"
    if not pid_file.exists():  # sessions without a project break GET /sessions, so park them in one
        status, body = call("/api/v1/projects/", json.dumps({"name": "DAppSCAN benchmark", "description": "eval/dappscan: audit-labelled SWC-116 / SWC-107 files"}).encode(),
                            {**auth, "Content-Type": "application/json"})
        assert status == 200, body
        pid_file.write_text(json.loads(body)["id"])
    pid = pid_file.read_text().strip()

    for sol in sorted((HERE / "flat").glob("*.sol")):
        dest = OUT / f"{sol.stem}.json"
        if dest.exists():
            continue
        if time.time() > float(os.environ.get("_TOKEN_T0", 0)) + 1200:  # tokens last 30 min
            status, body = call("/api/v1/auth/login", json.dumps({"username": os.environ["SCANGUARD_USER"], "password": os.environ["SCANGUARD_PASS"]}).encode(),
                                {"Content-Type": "application/json"})
            auth = {"Authorization": "Bearer " + json.loads(body)["access_token"]}
            os.environ["_TOKEN_T0"] = str(time.time())
        b = uuid.uuid4().hex
        form = b"".join([
            f'--{b}\r\nContent-Disposition: form-data; name="project_id"\r\n\r\n{pid}\r\n'.encode(),
            f'--{b}\r\nContent-Disposition: form-data; name="language"\r\n\r\nen\r\n'.encode(),
            f'--{b}\r\nContent-Disposition: form-data; name="file"; filename="{sol.name}"\r\nContent-Type: text/plain\r\n\r\n'.encode(),
            sol.read_bytes(), f"\r\n--{b}--\r\n".encode()])
        t0 = time.time()
        status, body = call("/api/v1/analyze", form, {**auth, "Content-Type": f"multipart/form-data; boundary={b}"})
        events = []
        for line in body.splitlines():
            try:
                events.append(json.loads(line))
            except ValueError:
                pass
        dest.write_text(json.dumps({"id": sol.stem, "http": status, "seconds": round(time.time() - t0, 1), "events": events,
                                    "raw": body[:2000] if not events else ""}, ensure_ascii=False))
        print(sol.stem, status, round(time.time() - t0, 1), flush=True)


if __name__ == "__main__":
    main()
