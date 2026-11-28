from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    # Paths
    EMBEDDING_MODEL_PATH: str
    GRAPH_VUL_MODEL_PATH: str
    NODE_VUL_MODEL_PATH: str
    # Reentrancy has its own encoder + GNN pair; it is skipped at startup when a checkpoint file is missing.
    REENTRANCY_EMBEDDING_MODEL_PATH: str = "Quangnguyen711/codebert-solidity-re-entrancy"
    REENTRANCY_GRAPH_VUL_MODEL_PATH: str = "src/infrastructure/analysis_model/best_model_GAT_2L_max_reentrancy.pt"
    REENTRANCY_NODE_VUL_MODEL_PATH: str = "src/infrastructure/analysis_model/best_node_classifier_model_reentrancy.pt"
    
    # LLM: Claude Haiku through an OpenAI-compatible gateway (CLAUDE_API_KEY is the gateway's sk-... key) ...
    CLAUDE_API_KEY: str = ""
    BASE_URL: str = "https://token.astralx.com.vn/v1"
    MODEL_NAME: str = "byok/astral-x/claude-haiku-5-5"
    # ... or, when LOCAL_LLM_MODEL is set, a Hugging Face model run in-process on DEVICE (the API settings are then unused),
    # e.g. suzeai/Qwen2.5-Coder-1.5B-explain-vul-wo-system (a LoRA adapter: needs `peft`)
    LOCAL_LLM_MODEL: str = ""
    LOCAL_LLM_MAX_NEW_TOKENS: int = 1024
    LOCAL_LLM_MAX_INPUT_TOKENS: int = 8192
    CHATBOT_TEMPERATURE: float = 0.7
    CHATBOT_MAX_TOKENS: int = 4096
    # Share of unflagged functions (consenting uploads only) sent to experts at random, to catch false negatives
    RANDOM_AUDIT_RATE: float = 0.05
    # Step 1.5: reuse CodeBERT vectors of functions already seen, and whole results of files already scanned
    EMBEDDING_CACHE: bool = True
    EMBEDDING_CACHE_PATH: str = "storage/embedding_cache.sqlite"
    RESULT_CACHE: bool = True
    # Explanations of the flagged functions of one scan are requested in parallel, at most this many at once
    LLM_MAX_CONCURRENCY: int = 4
    # Step 1.7: temperatures of the contract-level models, keyed by vulnerability and tied to a checkpoint version
    CALIBRATION_PATH: str = "src/infrastructure/analysis_model/calibration.json"
    # Step 1.8: retrieval of similar judged functions for the explanations
    RAG_ENABLED: bool = True
    RAG_TOP_K: int = 3
    RAG_MIN_SCORE: float = 0.0
    # Step 1.9: which retrained contract-level checkpoint is active (absent file = the original checkpoints above)
    MODEL_REGISTRY_PATH: str = "models/registry.json"
    # Step 1.10: when set, GET /metrics requires "Authorization: Bearer <token>"
    METRICS_TOKEN: str = ""
    # Step 2.3: fix checks (compiler + Slither on user code) run in a separate, time- and memory-limited process
    SANDBOX_ENABLED: bool = True
    SANDBOX_TIMEOUT: int = 120
    SANDBOX_MEMORY_MB: int = 2048
    # Step 2.5: browser session cookie (set AUTH_COOKIE_SECURE=true behind HTTPS in production)
    AUTH_COOKIE_NAME: str = "gf_session"
    AUTH_COOKIE_SECURE: bool = False
    AUTH_COOKIE_SAMESITE: str = "strict"

    # Database
    MONGODB_URL: str
    MONGODB_DATABASE: str

    # Security
    SECRET_KEY: str
    JWT_SECRET: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Other configs
    DEVICE: str = "cpu"
    SEED: int = 42

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="allow"      
    )


settings = Settings()
