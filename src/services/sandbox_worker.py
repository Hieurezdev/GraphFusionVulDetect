"""Child side of src/services/sandbox.py: read {"fn", "args"} as JSON on stdin, run an allow-listed function, print
"@@RESULT <json>" on stdout. Only the functions below can be called; anything else is refused."""
import json
import sys


def _check_fix(source_path, span, new_code):
    from src.workflows.gfd_workflow.utils.fix_check import check_fix
    return check_fix(source_path, span, new_code)


def _sleep(seconds):  # used by the tests to check the time limit
    import time
    time.sleep(seconds)
    return "woke"


def _allocate(megabytes):  # used by the tests to check the memory limit (Linux)
    return len(bytearray(megabytes * 2 ** 20))


ALLOWED = {"check_fix": _check_fix, "sleep": _sleep, "allocate": _allocate}


def main():
    try:
        req = json.loads(sys.stdin.read())
        fn = ALLOWED.get(req.get("fn"))
        if fn is None:
            raise ValueError(f"function not allowed: {req.get('fn')}")
        out = {"ok": True, "result": fn(*req.get("args", []))}
    except BaseException as e:
        out = {"ok": False, "error": f"{type(e).__name__}: {str(e)[:500]}"}
    sys.stdout.write("@@RESULT " + json.dumps(out, default=str) + "\n")
    sys.stdout.flush()


if __name__ == "__main__":
    main()
