"""Explain approved source without executing instructions found inside it."""
from langchain_core.runnables import RunnableConfig
from src.services.ai_safety import protected_messages, safe_ai_answer
from src.workflows.chatbot_workflow.graph.state import State


def analyze_code(state: State, config: RunnableConfig) -> State:
    client = config["configurable"]["llm_client"].get_instance()
    context = state["code"] + "\nFinding reported by the user/model: " + (state.get("issue_description") or "")
    messages = protected_messages("Analyze the finding. Explain evidence, impact, uncertainty and missing context in at most 200 words. Do not generate a code patch in this analysis step.", context, [], state.get("language") or "en")
    reply = client.invoke(messages)
    answer = safe_ai_answer(reply.content, finish_reason=reply.response_metadata.get("finish_reason"))
    return {"analysis_result": {"analysis": answer}, "explanation": answer, "bot_message": answer}
