from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from src.infrastructure.chat_model.local_llm import to_chat


def test_system_text_is_folded_into_the_next_user_turn():
    # The -wo-system adapters' chat template drops system messages, so their instructions must ride on a user turn.
    chat = to_chat([SystemMessage("You are an auditor."), HumanMessage("Explain f()"), AIMessage("ok"), HumanMessage("and g()?")])
    assert chat == [{"role": "user", "content": "You are an auditor.\n\nExplain f()"},
                    {"role": "assistant", "content": "ok"},
                    {"role": "user", "content": "and g()?"}]


def test_plain_string_prompt_and_trailing_system():
    assert to_chat([HumanMessage("hi")]) == [{"role": "user", "content": "hi"}]
    assert to_chat([SystemMessage("only rules")]) == [{"role": "user", "content": "only rules"}]
