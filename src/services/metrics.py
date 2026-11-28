"""Process metrics in the Prometheus text format, without extra dependencies (step 1.10 of docs/KE_HOACH_TRIEN_KHAI.md).

Counters, gauges and histograms are kept in memory under one lock (the scans and LLM calls run in worker threads) and
rendered by GET /metrics. Labels are kept to a small fixed set (route templates, not raw paths) so the series count
stays bounded over a 48-hour run.
"""
import threading
import time
from collections import defaultdict

_lock = threading.Lock()
_counters = defaultdict(float)     # (name, labels) -> value
_gauges = defaultdict(float)
_hist = {}                         # (name, labels) -> [bucket counts..., sum, count]
_help = {}
START = time.time()

BUCKETS = {
    "http_request_duration_seconds": (0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60),
    "analysis_duration_seconds": (1, 2.5, 5, 10, 20, 30, 60, 120, 300),
    "llm_call_duration_seconds": (0.5, 1, 2, 5, 10, 20, 30, 60),
}


def _key(name, labels):
    return name, tuple(sorted((labels or {}).items()))


def inc(name, value=1.0, help_text="", **labels):
    with _lock:
        _counters[_key(name, labels)] += value
        _help.setdefault(name, (help_text, "counter"))


def gauge_add(name, value, help_text="", **labels):
    with _lock:
        _gauges[_key(name, labels)] += value
        _help.setdefault(name, (help_text, "gauge"))


def observe(name, value, help_text="", **labels):
    buckets = BUCKETS.get(name, (1, 5, 10, 30, 60))
    with _lock:
        h = _hist.setdefault(_key(name, labels), [0] * len(buckets) + [0.0, 0])
        for i, b in enumerate(buckets):
            if value <= b:
                h[i] += 1
        h[-2] += value
        h[-1] += 1
        _help.setdefault(name, (help_text, "histogram"))


def _fmt(labels, extra=None):
    items = list(labels) + list((extra or {}).items())
    return "{" + ",".join(f'{k}="{str(v).replace(chr(34), "")}"' for k, v in items) + "}" if items else ""


def render() -> str:
    """The exposition text served at /metrics."""
    lines = [f"# HELP process_uptime_seconds Seconds since the backend started", "# TYPE process_uptime_seconds gauge",
             f"process_uptime_seconds {time.time() - START:.0f}"]
    with _lock:
        for store, kind in ((_counters, "counter"), (_gauges, "gauge")):
            names = sorted({n for n, _ in store})
            for name in names:
                help_text = _help.get(name, ("", kind))[0]
                lines += [f"# HELP {name} {help_text}", f"# TYPE {name} {kind}"]
                lines += [f"{name}{_fmt(labels)} {value:g}" for (n, labels), value in sorted(store.items()) if n == name]
        for name in sorted({n for n, _ in _hist}):
            buckets = BUCKETS.get(name, (1, 5, 10, 30, 60))
            lines += [f"# HELP {name} {_help.get(name, ('', ''))[0]}", f"# TYPE {name} histogram"]
            for (n, labels), h in sorted(_hist.items()):
                if n != name:
                    continue
                for i, b in enumerate(buckets):
                    lines.append(f"{name}_bucket{_fmt(labels, {'le': b})} {h[i]}")
                lines.append(f"{name}_bucket{_fmt(labels, {'le': '+Inf'})} {h[-1]}")
                lines.append(f"{name}_sum{_fmt(labels)} {h[-2]:.3f}")
                lines.append(f"{name}_count{_fmt(labels)} {h[-1]}")
    return "\n".join(lines) + "\n"


def record_llm_call(seconds: float, ok: bool, response=None, purpose: str = "explanation"):
    """One LLM round trip: latency, outcome and, when the provider reports them, token counts."""
    inc("llm_calls_total", help_text="LLM requests by purpose and outcome", purpose=purpose, outcome="ok" if ok else "error")
    observe("llm_call_duration_seconds", seconds, help_text="LLM request latency", purpose=purpose)
    usage = getattr(response, "usage_metadata", None) or (getattr(response, "response_metadata", None) or {}).get("token_usage") or {}
    for src, kind in (("input_tokens", "input"), ("prompt_tokens", "input"), ("output_tokens", "output"), ("completion_tokens", "output")):
        if usage.get(src):
            inc("llm_tokens_total", usage[src], help_text="LLM tokens by direction", purpose=purpose, direction=kind)
