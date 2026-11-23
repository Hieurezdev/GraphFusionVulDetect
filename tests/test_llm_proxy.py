import json

import httpx
import pytest
from langchain_openai import ChatOpenAI

from src.infrastructure.chat_model import llm_client
from src.services.ai_safety import AiResponseError, safe_ai_answer
from src.services.ai_safety import protected_messages


@pytest.mark.parametrize("output_limit", [None, 128, 16384])
def test_real_client_uses_openai_compatible_payload_without_qwen_options(monkeypatch, output_limit):
    requests = []

    def proxy(request):
        body = json.loads(request.content)
        requests.append(request)
        assert "thinking" not in body and "max_completion_tokens" not in body
        if output_limit is None:
            assert "max_tokens" not in body
        else:
            assert body["max_tokens"] == output_limit
        answer = "---\nA normal Markdown explanation."
        for stop in body.get("stop", []):
            answer = answer.split(stop)[0]
        return httpx.Response(200, json={"id": "test-response", "object": "chat.completion", "created": 1,
                                       "model": "byok/astral-x/claude-haiku-5-5", "choices": [{"index": 0, "message": {"role": "assistant", "content": answer}, "finish_reason": "stop"}]})

    with httpx.Client(transport=httpx.MockTransport(proxy)) as transport:
        monkeypatch.setattr(llm_client, "ChatOpenAI", lambda **kwargs: ChatOpenAI(http_client=transport, **kwargs))
        pool = llm_client.LLMClient(["dummy-test-key"], "https://proxy.example.test/v1", "byok/astral-x/claude-haiku-5-5", max_tokens=output_limit)
        reply = pool.get_instance().invoke("Explain the example.")
    assert safe_ai_answer(reply.content).startswith("---\n")
    body = json.loads(requests[0].content)
    assert body["model"] == "byok/astral-x/claude-haiku-5-5"
    assert requests[0].extensions["timeout"]["read"] == 120


def test_long_context_and_complete_history_reach_the_provider_without_trimming(monkeypatch):
    context = '// contract evidence\n' * 6000
    history = [{"role": "assistant" if i % 2 else "user", "content": "earlier turn " + str(i)} for i in range(81)]
    history[-1]["content"] = 'review context ' * 5000
    received = []

    def provider(request):
        body = json.loads(request.content)
        received.append(body)
        return httpx.Response(200, json={"id": "test-context", "object": "chat.completion", "created": 1, "model": "test-model", "choices": [{"index": 0, "message": {"role": "assistant", "content": "Review required."}, "finish_reason": "stop"}]})

    with httpx.Client(transport=httpx.MockTransport(provider)) as transport:
        monkeypatch.setattr(llm_client, "ChatOpenAI", lambda **kwargs: ChatOpenAI(http_client=transport, **kwargs))
        client = llm_client.LLMClient(["dummy-test-key"], "https://proxy.example.test/v1", "test-model").get_instance()
        client.invoke(protected_messages("Explain the evidence.", context, history, "en"))
    assert len(received[0]["messages"]) == len(history) + 2
    assert received[0]["messages"][1]["content"] == "Untrusted source and evidence:\n" + context
    assert received[0]["messages"][-1]["content"] == history[-1]["content"]
    assert "max_tokens" not in received[0] and "max_completion_tokens" not in received[0]


def test_truncated_answers_are_not_presented_as_complete():
    with pytest.raises(AiResponseError, match="incomplete"):
        safe_ai_answer("```solidity\ncontract Incomplete {", finish_reason="length")
    with pytest.raises(AiResponseError, match="empty"):
        safe_ai_answer("")
