import asyncio

from pymongo.errors import DuplicateKeyError

from src.services.label_log import GENESIS, append_label_event, build_label_event, event_hash, verify_events


class _FakeCollection:
    """Enough of a Motor collection for append_label_event: find_one(sort seq desc) + insert_one with a unique seq."""
    def __init__(self, steal_first_seq=False):
        self.docs, self.steal = [], steal_first_seq

    async def find_one(self, sort=None):
        return max(self.docs, key=lambda d: d["seq"]) if self.docs else None

    async def insert_one(self, doc):
        if self.steal:  # another writer appends between our read and our write
            self.steal = False
            self.docs.append({"seq": doc["seq"], "prev_hash": doc["prev_hash"], "x": "other", "hash": "h-other"})
            self.docs[-1]["hash"] = event_hash(self.docs[-1])
        if any(d["seq"] == doc["seq"] for d in self.docs):
            raise DuplicateKeyError("seq")
        self.docs.append(doc)


def _chain(n):
    col = _FakeCollection()
    for i in range(n):
        asyncio.run(append_label_event(col, {"verdict": "confirmed", "i": i}))
    return col.docs


def test_appended_events_form_a_valid_chain():
    docs = _chain(4)
    assert [d["seq"] for d in docs] == [0, 1, 2, 3] and docs[0]["prev_hash"] == GENESIS
    assert verify_events(docs) is None


def test_editing_an_event_is_detected():
    docs = _chain(4)
    docs[2]["verdict"] = "false_positive"
    assert verify_events(docs) == {"seq": 2, "problem": "content changed after it was written"}


def test_deleting_an_event_is_detected():
    docs = _chain(4)
    del docs[1]
    assert verify_events(docs)["seq"] == 2


def test_a_concurrent_writer_does_not_fork_the_chain():
    col = _FakeCollection(steal_first_seq=True)
    asyncio.run(append_label_event(col, {"verdict": "confirmed"}))
    assert [d["seq"] for d in col.docs] == [0, 1] and col.docs[1]["prev_hash"] == col.docs[0]["hash"]


def test_build_label_event_takes_code_graph_and_prediction_from_the_session():
    session = {"_id": "s1", "file_hash": "fh", "file_path": "storage/x/C.sol", "training_consent": True,
               "model_versions": {"reentrancy": "m@abc"},
               "steps": [{"vulnerability": "reentrancy", "result_data": {"fcg_file_path": "g.fcg"}},
                         {"vulnerability": "reentrancy", "result_data": {"predicted_class": "Vulnerable", "confidence_score": 0.8}},
                         {"vulnerability": "reentrancy", "result_data": {"func_vulnerability_predictions": [
                             {"function_name": "C.w()", "function_code": "function w() {}", "lines": [3, 5], "prediction": 1, "confidence": "99%"}]}}]}
    finding = {"vulnerability": "reentrancy", "function_name": "C.w()", "lines": [3, 5]}
    e = build_label_event(session, finding, {"status": "confirmed", "note": "n"}, "expert1")
    assert e["function_code"] == "function w() {}" and e["graph_path"] == "g.fcg" and e["model_version"] == "m@abc"
    assert e["verdict"] == "confirmed" and e["training_consent"] is True and e["contract_prediction"] == "Vulnerable"


def test_consensus_needs_two_agreeing_experts_and_kappa_measures_agreement():
    from src.services.label_log import consensus, disagreements, cohen_kappa, reviewer_rates
    ev = lambda f, r, v: {"session_id": "s", "vulnerability": "timestamp", "function_name": f, "reviewer": r, "verdict": v}
    events = [ev("a", "x", "confirmed"), ev("a", "y", "confirmed"),            # agreed
              ev("b", "x", "confirmed"),                                       # one reviewer only
              ev("c", "x", "confirmed"), ev("c", "y", "false_positive"),       # disagreement
              ev("d", "x", "false_positive"), ev("d", "x", "confirmed"), ev("d", "y", "confirmed"),  # x changed their mind
              ev("e", "x", "needs_manual_review"), ev("e", "y", "needs_manual_review")]            # never a label
    agreed = consensus(events)
    assert agreed == {("s", "timestamp", "a"): "confirmed", ("s", "timestamp", "d"): "confirmed"}
    assert [d["function_name"] for d in disagreements(events)] == ["c"]
    assert cohen_kappa([("confirmed", "confirmed"), ("false_positive", "false_positive")]) == 1.0
    assert cohen_kappa([("confirmed", "false_positive"), ("false_positive", "confirmed")]) < 0
    assert {r["reviewer"] for r in reviewer_rates(events)} == {"x", "y"}
