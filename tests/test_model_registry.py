from src.config.settings import settings
from src.services import model_registry as reg


def test_promote_then_rollback_restores_the_previous_checkpoint(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "MODEL_REGISTRY_PATH", str(tmp_path / "registry.json"))
    original = "src/infrastructure/analysis_model/best_model_GCN_2L_max.pt"
    assert reg.active_graph_path("timestamp", original) == original            # no registry: the original checkpoint
    reg.promote("timestamp", original, default=original)                       # an existing file becomes active
    assert reg.active_graph_path("timestamp", "x") == original
    reg.promote("timestamp", "models/timestamp/missing/graph.pt", report="r.md")
    assert reg.active_graph_path("timestamp", original) == original            # a missing file never gets loaded
    assert reg.rollback("timestamp") == original and reg.read()["timestamp"]["active"] == original


def test_shadow_is_separate_from_the_active_checkpoint(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "MODEL_REGISTRY_PATH", str(tmp_path / "registry.json"))
    original = "src/infrastructure/analysis_model/best_model_GCN_2L_max.pt"
    reg.set_shadow("timestamp", original, report="r.md")
    assert reg.shadow_graph_path("timestamp") == original and reg.active_graph_path("timestamp", "default.pt") == "default.pt"
    reg.set_shadow("timestamp", None)
    assert reg.shadow_graph_path("timestamp") is None
