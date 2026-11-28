"""Cache of CodeBERT function vectors (step 1.5 of docs/KE_HOACH_TRIEN_KHAI.md).

Encoding every function with CodeBERT is the bulk of a scan's model time on CPU, and the same functions come back again
and again (libraries such as SafeMath and Ownable, re-uploads, 15% of DAppSCAN functions are verbatim training
functions). Vectors are keyed by (encoder, sha256 of the comment-stripped code), so a hit returns exactly the vector
the encoder would produce. The RAG knowledge base (step 1.8) reads vectors through the same cache.

SQLite file, one connection per thread (the two vulnerability scans run in worker threads), WAL so they can write at once.
"""
import hashlib
import logging
import os
import sqlite3
import threading

import numpy as np

logger = logging.getLogger(__name__)
_local = threading.local()
_init_lock = threading.Lock()
_initialized = set()


def _connect(path: str) -> sqlite3.Connection:
    # Creating the file and switching it to WAL happen once, under a lock: two scans starting together raced on it
    # ("database is locked") and one of them failed.
    with _init_lock:
        if path not in _initialized:
            os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
            setup = sqlite3.connect(path, timeout=30)
            setup.execute("PRAGMA journal_mode=WAL")
            setup.execute("CREATE TABLE IF NOT EXISTS vectors (encoder TEXT, code_sha TEXT, dim INTEGER, vec BLOB, PRIMARY KEY (encoder, code_sha))")
            setup.commit()
            setup.close()
            _initialized.add(path)
    conn = getattr(_local, "conn", None)
    if conn is None or getattr(_local, "path", None) != path:
        conn = sqlite3.connect(path, timeout=30)
        _local.conn, _local.path = conn, path
    return conn


def encoder_id(model) -> str:
    """Name of the encoder checkpoint (vectors of two encoders are never mixed)."""
    return getattr(getattr(model, "config", None), "_name_or_path", None) or type(model).__name__


def code_sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


class EmbeddingCache:
    def __init__(self, path: str):
        self.path = path
        self.hits = self.misses = 0

    def get(self, encoder: str, text: str):
        row = _connect(self.path).execute("SELECT dim, vec FROM vectors WHERE encoder=? AND code_sha=?", (encoder, code_sha(text))).fetchone()
        if row is None:
            self.misses += 1
            return None
        self.hits += 1
        return np.frombuffer(row[1], dtype=np.float32).reshape(row[0]).copy()

    def put(self, encoder: str, text: str, vec) -> None:
        arr = np.asarray(vec, dtype=np.float32)
        conn = _connect(self.path)
        conn.execute("INSERT OR REPLACE INTO vectors VALUES (?, ?, ?, ?)", (encoder, code_sha(text), arr.shape[0], arr.tobytes()))
        conn.commit()


_cache = None


def get_cache():
    """The process-wide cache, or None when EMBEDDING_CACHE is off."""
    global _cache
    from src.config.settings import settings
    if not settings.EMBEDDING_CACHE:
        return None
    if _cache is None or _cache.path != settings.EMBEDDING_CACHE_PATH:
        _cache = EmbeddingCache(settings.EMBEDDING_CACHE_PATH)
    return _cache


def cached_embeddings(tokenizer, model, text: str, compute):
    """compute(tokenizer, model, text) unless the cache already holds this encoder's vector for this exact code."""
    cache = get_cache()
    if cache is None:
        return compute(tokenizer, model, text)
    enc = encoder_id(model)
    try:
        vec = cache.get(enc, text)
    except sqlite3.Error as e:  # a cache problem must never fail a scan: compute as if there were no cache
        logger.warning(f"embedding cache read failed, computing instead: {e}")
        return compute(tokenizer, model, text)
    from src.services.metrics import inc
    if vec is not None:
        inc("embedding_cache_requests_total", help_text="CodeBERT vector lookups", result="hit")
        return vec
    inc("embedding_cache_requests_total", help_text="CodeBERT vector lookups", result="miss")
    vec = np.asarray(compute(tokenizer, model, text), dtype=np.float32)
    try:
        cache.put(enc, text, vec)
    except sqlite3.Error as e:
        logger.warning(f"embedding cache write failed: {e}")
    return vec
