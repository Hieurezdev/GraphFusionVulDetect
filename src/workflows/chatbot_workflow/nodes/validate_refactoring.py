"""Check model proposals with an isolated deterministic compiler."""
from langchain_core.runnables import RunnableConfig
from src.services.solidity_validation import validate_solidity
from src.workflows.chatbot_workflow.graph.state import State


def validate_refactoring(state: State, config: RunnableConfig) -> State:
    result = validate_solidity(state.get("suggested_code") or "", state.get("code"))
    return {"validation_result": result.model_dump()}
