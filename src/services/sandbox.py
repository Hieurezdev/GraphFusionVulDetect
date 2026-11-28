"""Run untrusted-input work (compiler + Slither on user-supplied code) in a separate, limited process (step 2.3).

Compiling Solidity does not execute the contract, so the risk is resource abuse rather than code execution: a huge or
pathological input can make solc or Slither run for minutes or eat memory, and Slither runs in-process with no time
limit. Fix checks are the most exposed path (anyone who can open a session may submit any code, any number of times).

run_isolated(name, *args) runs an allow-listed function in a fresh Python process (src/services/sandbox_worker.py,
arguments and result as JSON on stdin/stdout) and returns its result, or raises SandboxError when it:
  - exceeds SANDBOX_TIMEOUT seconds (the process is killed);
  - exceeds SANDBOX_MEMORY_MB of address space or its CPU budget (Linux: resource limits set in the child);
  - crashes (a segfault in a native library no longer takes the backend down).
The child gets no API keys in its environment. Network isolation is not done here (Python 3.10 has no os.unshare): on the
server, run the backend in a container whose fix-check worker has network_mode: none (docs/KE_HOACH_TRIEN_KHAI.md, 2.3).
"""
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SECRET_VARS = ("CLAUDE_API_KEY", "ETHERSCAN_API_KEY", "JWT_SECRET", "SECRET_KEY", "MONGODB_URL", "MONGODB_PASSWORD",
               "MINIO_SECRET_KEY", "SMTP_PASSWORD", "METRICS_TOKEN")


class SandboxError(RuntimeError):
    pass


def _limits(memory_mb: int, cpu_seconds: int):
    """preexec_fn for Linux: caps applied in the child just before it starts."""
    def apply():
        import resource
        resource.setrlimit(resource.RLIMIT_AS, (memory_mb * 2 ** 20, memory_mb * 2 ** 20))
        resource.setrlimit(resource.RLIMIT_CPU, (cpu_seconds, cpu_seconds))
        os.setsid()
    return apply


def run_isolated(name: str, *args, timeout: float = None, memory_mb: int = None):
    from src.config.settings import settings
    timeout = float(timeout or settings.SANDBOX_TIMEOUT)
    memory_mb = int(memory_mb or settings.SANDBOX_MEMORY_MB)
    if not settings.SANDBOX_ENABLED:
        from src.services.sandbox_worker import ALLOWED
        return ALLOWED[name](*args)
    env = {k: v for k, v in os.environ.items() if k not in SECRET_VARS}
    env["PYTHONPATH"] = str(REPO)
    env["PYTHONUTF8"] = "1"
    linux = sys.platform.startswith("linux")
    try:
        proc = subprocess.run([sys.executable, "-m", "src.services.sandbox_worker"], input=json.dumps({"fn": name, "args": list(args)}),
                              capture_output=True, text=True, encoding="utf-8", timeout=timeout, cwd=str(REPO), env=env,
                              preexec_fn=_limits(memory_mb, int(timeout) + 5) if linux else None)
    except subprocess.TimeoutExpired:
        raise SandboxError(f"the check did not finish within {timeout:.0f} s and was stopped")
    lines = [l for l in proc.stdout.splitlines() if l.startswith("@@RESULT ")]
    if proc.returncode != 0 or not lines:
        tail = (proc.stderr or "").strip().splitlines()[-1:] or [f"exit code {proc.returncode}"]
        raise SandboxError(f"the check failed in its isolated process: {tail[0][:300]}")
    out = json.loads(lines[-1][len("@@RESULT "):])
    if not out.get("ok"):
        raise SandboxError(out.get("error", "unknown error"))
    return out["result"]
