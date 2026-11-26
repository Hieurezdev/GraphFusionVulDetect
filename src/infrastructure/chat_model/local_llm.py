"""A Hugging Face causal LM run in-process, behind LangChain's chat-model interface (invoke / astream).

Used instead of the remote API when LOCAL_LLM_MODEL is set in .env. The model id may be a full model or a
PEFT/LoRA adapter (e.g. suzeai/Qwen2.5-Coder-1.5B-explain-vul-wo-system), whose base model is loaded and merged.
"""
import logging
import os
import threading
from functools import lru_cache
from typing import Any, Iterator, List, Optional

from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import AIMessage, AIMessageChunk, BaseMessage
from langchain_core.outputs import ChatGeneration, ChatGenerationChunk, ChatResult

logger = logging.getLogger(__name__)

_ROLES = {"human": "user", "ai": "assistant", "system": "system"}


def to_chat(messages: List[BaseMessage]) -> List[dict]:
    """LangChain messages -> [{role, content}], with system text folded into the next user turn.

    The "-wo-system" fine-tunes were trained without a system role and their chat template drops it,
    so instructions sent as a system message would otherwise be lost.
    """
    chat, pending = [], []
    for m in messages:
        role = _ROLES.get(m.type, "user")
        if role == "system":
            pending.append(m.content)
            continue
        content = "\n\n".join(pending + [m.content]) if role == "user" and pending else m.content
        if role == "user":
            pending = []
        chat.append({"role": role, "content": content})
    if pending:
        chat.append({"role": "user", "content": "\n\n".join(pending)})
    return chat


class LocalChatModel(BaseChatModel):
    model_id: str
    device: str = "cpu"
    max_new_tokens: int = 1024
    max_input_tokens: int = 8192
    temperature: float = 0.7
    top_p: float = 1.0

    @property
    def _llm_type(self) -> str:
        return "local-huggingface"

    def _prompt_ids(self, messages: List[BaseMessage]):
        tokenizer, _, _ = _load(self.model_id, self.device)
        # This template has no add_generation_prompt branch: open the assistant turn by hand.
        text = tokenizer.apply_chat_template(to_chat(messages), tokenize=False) + "<|im_start|>assistant\n"
        ids = tokenizer(text, return_tensors="pt").input_ids
        # shortcut: a prompt longer than max_input_tokens keeps only its end (the latest question), dropping the start;
        # summarise long chats/contracts before sending if that loses needed context.
        return ids[:, -self.max_input_tokens:]

    def _gen_kwargs(self, ids, streamer=None) -> dict:
        tokenizer, model, _ = _load(self.model_id, self.device)
        sample = self.temperature > 0
        return dict(input_ids=ids.to(model.device), attention_mask=ids.new_ones(ids.shape).to(model.device),
                    max_new_tokens=self.max_new_tokens, do_sample=sample, pad_token_id=tokenizer.eos_token_id,
                    **({"temperature": self.temperature, "top_p": self.top_p} if sample else {}),
                    **({"streamer": streamer} if streamer else {}))

    def _generate(self, messages: List[BaseMessage], stop: Optional[List[str]] = None, run_manager=None, **kwargs: Any) -> ChatResult:
        tokenizer, model, lock = _load(self.model_id, self.device)
        ids = self._prompt_ids(messages)
        with lock:
            out = model.generate(**self._gen_kwargs(ids))
        text = tokenizer.decode(out[0, ids.shape[1]:], skip_special_tokens=True).strip()
        return ChatResult(generations=[ChatGeneration(message=AIMessage(content=text))])

    def _stream(self, messages: List[BaseMessage], stop: Optional[List[str]] = None, run_manager=None, **kwargs: Any) -> Iterator[ChatGenerationChunk]:
        from transformers import TextIteratorStreamer
        tokenizer, model, lock = _load(self.model_id, self.device)
        ids = self._prompt_ids(messages)
        streamer = TextIteratorStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True, timeout=600)

        def run():
            with lock:  # one generation at a time: the model and the GPU are shared by every request
                model.generate(**self._gen_kwargs(ids, streamer))

        threading.Thread(target=run, daemon=True).start()
        for piece in streamer:
            if piece:
                yield ChatGenerationChunk(message=AIMessageChunk(content=piece))


@lru_cache(maxsize=None)
def _load(model_id: str, device: str):
    """Tokenizer, model and a generation lock, loaded once per process (shared by the explainer and RefactorBot)."""
    import torch
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from huggingface_hub import file_exists

    dtype = torch.float16 if device.startswith("cuda") else torch.float32
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    is_adapter = (os.path.isfile(os.path.join(model_id, "adapter_config.json")) if os.path.isdir(model_id)
                  else file_exists(model_id, "adapter_config.json"))
    if is_adapter:
        from peft import AutoPeftModelForCausalLM
        model = AutoPeftModelForCausalLM.from_pretrained(model_id, torch_dtype=dtype).merge_and_unload()
    else:
        model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=dtype)
    logger.info(f"Local LLM loaded: {model_id} on {device}")
    return tokenizer, model.to(device).eval(), threading.Lock()


def get_local_llm() -> LocalChatModel:
    from src.config.settings import settings
    return LocalChatModel(model_id=settings.LOCAL_LLM_MODEL, device=settings.DEVICE,
                          max_new_tokens=settings.LOCAL_LLM_MAX_NEW_TOKENS, max_input_tokens=settings.LOCAL_LLM_MAX_INPUT_TOKENS,
                          temperature=settings.CHATBOT_TEMPERATURE, top_p=getattr(settings, "CHATBOT_TOP_P", 1.0))
