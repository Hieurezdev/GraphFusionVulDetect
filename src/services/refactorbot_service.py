"""Refactoring operations for reviewed, redacted payloads."""
import hashlib
from src.models.ai_safety import VerificationResult
from src.services.solidity_validation import validate_solidity
from src.workflows.chatbot_workflow.workflow import chatbot_workflow
from src.workflows.chatbot_workflow.graph.state import State


class RefactorBotService:
    def __init__(self):
        self.workflow = chatbot_workflow

    async def get_refactoring_advice(self, code: str, issue_description: str, language: str = "en") -> State:
        return await self.workflow.arun(code=code, issue_description=issue_description, language=language)

    async def get_code_fix_conversation(self, conversation_history: list[dict[str, str]], current_code: str, language: str = "en") -> State:
        return await self.workflow.arun(code=current_code, conversation_history=conversation_history, language=language)

    def validate_suggested_refactoring(self, original_code: str, suggested_code: str, test_source: str | None = None) -> VerificationResult:
        if original_code == suggested_code:
            return VerificationResult(status="not_run", message="The proposed code is identical to the original.", source_sha256=hashlib.sha256(suggested_code.encode()).hexdigest())
        return validate_solidity(suggested_code, original_code, test_source)
