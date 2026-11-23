"""Bounded refactoring workflow for source approved at the API boundary."""
import logging
from langsmith import tracing_context
from src.config.settings import settings
from src.infrastructure.chat_model.llm_client import LLMClient
from src.workflows.chatbot_workflow.graph.builder import build_graph
from src.workflows.chatbot_workflow.graph.state import State

logger = logging.getLogger(__name__)


class ChatbotWorkflow:
    def __init__(self):
        self.llm_client = None
        self.graph = None

    def initialize(self):
        keys = [settings.GEMINI_API_KEY1]
        if not all(keys):
            raise ValueError("Configure the external LLM API key before starting the assistant.")
        self.llm_client = LLMClient(api_keys=keys, base_url=settings.BASE_URL, model=settings.MODEL_NAME,
                                   temperature=settings.CHATBOT_TEMPERATURE, max_tokens=settings.CHATBOT_MAX_TOKENS)
        logger.info("Refactoring model initialized")

    def build_pipeline(self):
        if self.llm_client is None:
            raise RuntimeError("Refactoring workflow has not been initialized.")
        if self.graph is None:
            self.graph = build_graph()
        return self.graph

    def _initial_state(self, code: str, issue_description: str | None, conversation_history: list[dict[str, str]] | None, language: str) -> State:
        return {"code": code, "issue_description": issue_description or "", "conversation_history": conversation_history or [],
                "language": language, "analysis_result": None, "refactoring_suggestions": None, "bot_message": None,
                "suggested_code": None, "explanation": None, "validation_result": None, "repair_attempts": 0}

    def run(self, code: str, issue_description: str | None = None, conversation_history: list[dict[str, str]] | None = None, language: str = "en") -> State:
        graph = self.build_pipeline()
        # Approval covers the configured model provider, not third-party tracing services.
        with tracing_context(enabled=False):
            return graph.invoke(self._initial_state(code, issue_description, conversation_history, language), {"configurable": {"llm_client": self.llm_client}, "recursion_limit": 12})

    async def arun(self, code: str, issue_description: str | None = None, conversation_history: list[dict[str, str]] | None = None, language: str = "en") -> State:
        graph = self.build_pipeline()
        with tracing_context(enabled=False):
            return await graph.ainvoke(self._initial_state(code, issue_description, conversation_history, language), {"configurable": {"llm_client": self.llm_client}, "recursion_limit": 12})


chatbot_workflow = ChatbotWorkflow()
