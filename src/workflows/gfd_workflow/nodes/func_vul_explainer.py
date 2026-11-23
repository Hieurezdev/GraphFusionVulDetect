"""Finish local detection without sending source to an external LLM."""
from langchain_core.runnables import RunnableConfig
from src.workflows.gfd_workflow.graph.state import State


def explain_vulnerability_func(state: State, config: RunnableConfig) -> State:
    # External explanations are only available through the reviewed RefactorBot API.
    return {"func_vulnerability_explanations": [], "external_ai_review_required": True}
