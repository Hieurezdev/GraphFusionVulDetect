"""Continue an approved conversation using actual message roles and history."""
import re
from langchain_core.runnables import RunnableConfig
from src.services.ai_safety import protected_messages, safe_ai_answer
from src.workflows.chatbot_workflow.graph.state import State


def handle_conversation(state: State, config: RunnableConfig) -> State:
    client = config["configurable"]["llm_client"].get_instance()
    messages = protected_messages("Answer the user's question about the finding. If revising a previous proposal, keep the supplied original source as the version and behavior reference. Preserve its Solidity pragma and include it in a complete proposed contract, using a Solidity fenced code block. Explain behavior changes.", state["code"], state.get("conversation_history") or [], state.get("language") or "en")
    reply = client.invoke(messages)
    answer = safe_ai_answer(reply.content, finish_reason=reply.response_metadata.get("finish_reason"))
    blocks = re.findall(r"```(?:solidity|sol)?\s*\n(.*?)```", answer, re.DOTALL)
    proposed = blocks[0].strip() if blocks else None
    return {"bot_message": answer, "suggested_code": proposed, "repair_attempts": 1 if proposed else 0}
