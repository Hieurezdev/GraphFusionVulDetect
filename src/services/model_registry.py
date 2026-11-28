"""Versioned contract-level checkpoints: which one is active, which ones came before (step 1.9).

models/registry.json:
  {"timestamp": {"active": "models/timestamp/<version>/graph.pt", "history": [{"path": ..., "activated_at": ..., "report": ...}]}}
The backend loads the active checkpoint when the registry names one that exists, else the path from settings (the
original checkpoint). Promotion and rollback only rewrite this file; a restart picks the change up. Old checkpoints are
never deleted, so going back is always possible.
"""
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parents[2]


def registry_path() -> Path:
    from src.config.settings import settings
    return REPO / settings.MODEL_REGISTRY_PATH


def read() -> dict:
    p = registry_path()
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


def active_graph_path(vulnerability: str, default: str) -> str:
    """Checkpoint the backend should load for this vulnerability's contract-level model."""
    entry = read().get(vulnerability) or {}
    path = entry.get("active")
    return path if path and os.path.exists(REPO / path) else default


def promote(vulnerability: str, checkpoint: str, report: Optional[str] = None, default: Optional[str] = None) -> dict:
    """Make `checkpoint` the active model; the previous active one stays in history for rollback."""
    data = read()
    entry = data.setdefault(vulnerability, {"active": default, "history": []})
    if entry.get("active"):
        entry["history"].append({"path": entry["active"], "replaced_at": datetime.now(timezone.utc).isoformat()})
    entry["active"] = checkpoint
    entry["activated_at"] = datetime.now(timezone.utc).isoformat()
    entry["report"] = report
    registry_path().parent.mkdir(parents=True, exist_ok=True)
    registry_path().write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return entry


def rollback(vulnerability: str) -> Optional[str]:
    """Reactivate the checkpoint that was active before the current one."""
    data = read()
    entry = data.get(vulnerability) or {}
    if not entry.get("history"):
        return None
    previous = entry["history"].pop()["path"]
    entry["active"] = previous
    entry["activated_at"] = datetime.now(timezone.utc).isoformat()
    entry["report"] = "rollback"
    registry_path().write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return previous


# ---- Step 2.7: shadow mode ----------------------------------------------------------------------------------------
def shadow_graph_path(vulnerability: str):
    """Checkpoint scored silently next to the active one, or None."""
    path = (read().get(vulnerability) or {}).get("shadow")
    return path if path and os.path.exists(REPO / path) else None


def set_shadow(vulnerability: str, checkpoint: Optional[str], report: Optional[str] = None) -> dict:
    """Put a candidate that passed the gate in shadow mode (None clears it). Promote it later with promote()."""
    data = read()
    entry = data.setdefault(vulnerability, {"active": None, "history": []})
    entry["shadow"] = checkpoint
    entry["shadow_since"] = datetime.now(timezone.utc).isoformat() if checkpoint else None
    entry["shadow_report"] = report
    registry_path().parent.mkdir(parents=True, exist_ok=True)
    registry_path().write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return entry
