import numpy as np

from src.workflows.gfd_workflow.nodes.fcg_converter.embedding_cache import EmbeddingCache, cached_embeddings
import src.workflows.gfd_workflow.nodes.fcg_converter.embedding_cache as ec


def test_round_trip_keeps_the_exact_vector_and_separates_encoders(tmp_path):
    cache = EmbeddingCache(str(tmp_path / "c.sqlite"))
    v = np.random.default_rng(0).standard_normal(768).astype(np.float32)
    cache.put("enc-a", "function f() {}", v)
    assert np.array_equal(cache.get("enc-a", "function f() {}"), v)
    assert cache.get("enc-b", "function f() {}") is None and cache.get("enc-a", "function g() {}") is None


def test_cached_embeddings_computes_once(tmp_path, monkeypatch):
    monkeypatch.setattr(ec, "get_cache", lambda: EmbeddingCache(str(tmp_path / "c.sqlite")) if not hasattr(ec, "_t") else ec._t)
    ec._t = EmbeddingCache(str(tmp_path / "c.sqlite"))
    calls = []
    compute = lambda tok, model, text: calls.append(text) or np.ones(4, dtype=np.float32) * len(text)
    model = type("M", (), {"config": type("C", (), {"_name_or_path": "codebert-x"})()})()
    a = cached_embeddings(None, model, "abc", compute)
    b = cached_embeddings(None, model, "abc", compute)
    assert calls == ["abc"] and np.array_equal(a, b)
    del ec._t


def test_concurrent_first_use_does_not_lock(tmp_path):
    import threading
    ec._initialized.clear()
    cache, errors = EmbeddingCache(str(tmp_path / "race.sqlite")), []

    def work(i):
        try:
            for j in range(20):
                cache.put("enc", f"f{i}-{j}", np.ones(8, dtype=np.float32))
                cache.get("enc", f"f{i}-{j}")
        except Exception as e:
            errors.append(e)

    threads = [threading.Thread(target=work, args=(i,)) for i in range(4)]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert errors == []


def test_a_broken_cache_falls_back_to_computing(monkeypatch):
    import sqlite3

    class Broken:
        def get(self, *a):
            raise sqlite3.OperationalError("database is locked")
    monkeypatch.setattr(ec, "get_cache", lambda: Broken())
    model = type("M", (), {"config": type("C", (), {"_name_or_path": "x"})()})()
    assert cached_embeddings(None, model, "abc", lambda t, m, s: np.zeros(3)).shape == (3,)
