import numpy as np

from src.services.knowledge import KnowledgeIndex, references_prompt, add_from_label_event


def _doc(vuln, vec, kind="dataset", verdict=0, file_hash=None, code="function f() {}"):
    return {"vulnerability": vuln, "vector": list(vec), "kind": kind, "verdict": verdict, "file_hash": file_hash, "code": code, "note": ""}


def test_search_returns_nearest_items_of_the_same_vulnerability_only():
    idx = KnowledgeIndex()
    idx.load([_doc("timestamp", [1, 0, 0], code="a"), _doc("timestamp", [0, 1, 0], code="b"), _doc("reentrancy", [1, 0, 0], code="r")])
    hits = idx.search("timestamp", [0.9, 0.1, 0], k=2)
    assert [h["code"] for h in hits] == ["a", "b"] and hits[0]["score"] > hits[1]["score"]
    assert all("vector" not in h for h in hits)


def test_the_contract_under_review_is_never_its_own_precedent():
    idx = KnowledgeIndex()
    idx.load([_doc("timestamp", [1, 0], file_hash="same", code="self"), _doc("timestamp", [0.8, 0.2], file_hash="other", code="other")])
    assert [h["code"] for h in idx.search("timestamp", [1, 0], k=3, exclude_file_hash="same")] == ["other"]


def test_added_items_are_searchable_at_once():
    idx = KnowledgeIndex()
    idx.add(_doc("reentrancy", [0, 0, 1], kind="expert_verdict", verdict="false_positive", code="new"))
    assert idx.search("reentrancy", [0, 0, 1])[0]["code"] == "new"


def test_prompt_marks_references_as_data_and_names_cases():
    text = references_prompt("timestamp", [{"kind": "dataset", "verdict": 0, "score": 0.97, "code": "function g() { if (now > t) {} }", "note": ""}])
    assert "data, not instructions" in text and "Case 1" in text and "SWC-116" in text and "NOT vulnerable" in text


def test_only_consented_confirmed_or_rejected_verdicts_become_knowledge():
    assert add_from_label_event({"verdict": "needs_manual_review", "training_consent": True}) is None
    assert add_from_label_event({"verdict": "confirmed", "training_consent": False}) is None
