from src.workflows.gfd_workflow.workflow import gfd_workflow

graph_instance = None
configs = {}  # vulnerability -> LangGraph config carrying that vulnerability's models


def build_global_graph():
    global graph_instance
    graph_instance = gfd_workflow.build_pipeline()
    for name, models in gfd_workflow.models.items():
        configs[name] = {"configurable": {**models, "llm": gfd_workflow.llm}}


def get_vulnerabilities() -> list:
    """Vulnerability types whose models are loaded, in scan order."""
    return list(configs)


def get_model_versions() -> dict:
    """vulnerability -> checkpoint version of the models that score it."""
    return {name: gfd_workflow.versions.get(name) for name in configs}


def get_pipeline_fingerprint() -> str:
    """Everything a stored result depends on besides the file and the language: checkpoints, calibration temperatures,
    the explainer prompt, whether retrieval is on, and the size of the knowledge base (a new expert verdict changes the
    explanations of similar functions). The result cache (step 1.5) only replays results with the same fingerprint."""
    import hashlib
    import json
    from src.config.settings import settings
    from src.workflows.gfd_workflow.nodes.func_vul_explainer import PROMPT_VERSION
    from src.services.knowledge import index
    parts = {"versions": get_model_versions(), "temperatures": dict(gfd_workflow.temperatures), "prompt": PROMPT_VERSION,
             "shadow": {n: m.get("shadow_version") for n, m in gfd_workflow.models.items()},
             "rag": settings.RAG_ENABLED and sum(len(v) for v in index.items.values())}
    return hashlib.sha256(json.dumps(parts, sort_keys=True, default=str).encode()).hexdigest()[:16]


def get_app_graph():
    return graph_instance

def get_models_config(vulnerability: str = "timestamp"):
    """None when that vulnerability type is unknown or its checkpoints were not loaded."""
    return configs.get(vulnerability)
