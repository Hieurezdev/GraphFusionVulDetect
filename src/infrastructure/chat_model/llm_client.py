# File: src/infrastructure/chat_model/llm_client.py

import random
import logging
from typing import List
from langchain_openai import ChatOpenAI

logger = logging.getLogger(__name__)

class LLMClient:
    """
    A wrapper class that maintains a pool of ChatOpenAI clients.
    It provides random access to instances and allows removal of faulty clients.
    """
    def __init__(self, api_keys: List[str], base_url: str, model: str, temperature: float = 0.5, max_tokens: int | None = None, top_p: float = 1.0):
        if not api_keys or not isinstance(api_keys, list):
            raise ValueError("api_keys must be a non-empty list of strings.")

        logger.info(f"Initializing LLMClient with {len(api_keys)} API key(s)")
        logger.info(f"Config - Model: {model}, Base URL: {base_url}")
        logger.info(f"Config - Temperature: {temperature}, Max Tokens: {max_tokens}, Top P: {top_p}")
        
        self.base_url = base_url
        self.model = model
        self.temperature = temperature
        self.top_p = top_p
        self.max_tokens = max_tokens
        
        # Only send an output limit when the operator explicitly configures one.
        self.clients = []
        for idx, key in enumerate(api_keys):
            logger.debug("Creating LLM client", extra={"client_number": idx + 1})
            client = ChatOpenAI(
                api_key=key,
                base_url=self.base_url,
                model=self.model,
                temperature=self.temperature,
                top_p=self.top_p,
                extra_body={"max_tokens": self.max_tokens} if self.max_tokens is not None else None,
                timeout=120,
                max_retries=1,
            )
            self.clients.append(client)
        
        logger.info(f"LLMClient initialized successfully with {len(self.clients)} client(s)")

    def get_instance(self) -> ChatOpenAI:
        """
        Returns a random ChatOpenAI client instance from the active pool.
        """
        if not self.clients:
            logger.error("No active clients available in the pool!")
            raise ValueError("No active clients available in the pool.")
        
        logger.debug(f"Selecting random client from pool of {len(self.clients)}")
        return random.choice(self.clients)

    def remove_instance(self, client_instance: ChatOpenAI) -> None:
        """
        Removes a specific client instance from the pool (e.g., when it fails/expires).
        """
        if client_instance in self.clients:
            self.clients.remove(client_instance)
            logger.warning(f"Removed faulty client from pool. Remaining: {len(self.clients)}")
        else:
            logger.warning(f"Attempted to remove client not in pool")
