"""Propose a minimal patch within the already approved context."""
import json
import re
from langchain_core.runnables import RunnableConfig
from src.services.ai_safety import protected_messages, safe_ai_answer
from src.workflows.chatbot_workflow.graph.state import State


def generate_refactoring_suggestions(state: State, config: RunnableConfig) -> State:
    client = config["configurable"]["llm_client"].get_instance()
    context = json.dumps({"code": state["code"], "finding": state.get("issue_description"), "analysis": state.get("analysis_result"), "previous_proposal": state.get("suggested_code"), "compiler_feedback": state.get("validation_result")}, ensure_ascii=False)
    messages = protected_messages("Propose the smallest useful fix. Repair compiler errors in the previous proposal when supplied. Include one complete Solidity contract when context permits, in a fenced solidity block, preserving the original Solidity pragma. Do not silently upgrade the compiler version. Keep commentary under 200 words, explaining the fix, trade-offs, testing needed and unresolved risks. Do not invent missing dependencies or rewrite unrelated code.", context, state.get("conversation_history") or [], state.get("language") or "en")
    reply = client.invoke(messages)
    answer = safe_ai_answer(reply.content, finish_reason=reply.response_metadata.get("finish_reason"))
    suggestions = _parse_suggestions(answer, state.get("issue_description") or "Finding")
    code = next((item["code"] for item in suggestions if item.get("code")), None)
    return {"refactoring_suggestions": suggestions, "explanation": answer, "bot_message": answer, "suggested_code": code, "repair_attempts": (state.get("repair_attempts") or 0) + 1}


def _parse_suggestions(answer: str, issue_type: str) -> list[dict[str, str]]:
    blocks = re.findall(r"```(?:solidity|sol)?\s*\n(.*?)```", answer, re.DOTALL)
    return [{"type": "code_fix", "description": "Proposed patch: " + issue_type, "code": block.strip()} for block in blocks[:3] if block.strip()]
