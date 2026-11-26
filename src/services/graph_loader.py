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


def get_app_graph():
    return graph_instance

def get_models_config(vulnerability: str = "timestamp"):
    """None when that vulnerability type is unknown or its checkpoints were not loaded."""
    return configs.get(vulnerability)
