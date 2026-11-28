import json

from langchain_core.messages import AIMessage

import src.services.fix_agent as fa
import src.services.sandbox as sb

FIX = "function withdraw(uint a) public { balances[msg.sender] -= a; require(msg.sender.call.value(a)()); }"
FINDING = {"vulnerability": "reentrancy", "function_name": "Bank.withdraw(uint256)", "span": [0, 10]}


class _FakeLLM:
    """bind_tools() returns itself; invoke() replays scripted AI messages."""
    def __init__(self, *messages):
        self.messages = list(messages)
        self.seen = []

    def bind_tools(self, tools):
        self.tools = [t.name for t in tools]
        return self

    def invoke(self, messages):
        self.seen.append(messages)
        return self.messages.pop(0) if self.messages else AIMessage(content="done")


def _call(name, args, i):
    return AIMessage(content="", tool_calls=[{"name": name, "args": args, "id": f"c{i}"}],
                     usage_metadata={"input_tokens": 100, "output_tokens": 20, "total_tokens": 120})


def _patch(monkeypatch, tmp_path, compiled=True, still_flagged=False):
    src = tmp_path / "Bank.sol"
    src.write_text("pragma solidity ^0.4.24;\ncontract Bank {}\n", encoding="utf-8")
    monkeypatch.setattr(sb, "run_isolated", lambda name, *a, **k: {"compiled": compiled, "solc_version": "0.4.24", "compiler_output": "",
                                                                  "findings_before": [{"check": "reentrancy-eth"}], "findings_after": []})
    monkeypatch.setattr(fa, "rescan", lambda *a, **k: {"graph_built": True, "contract_verdict": "Non-Vulnerable", "function_still_flagged": still_flagged})
    return str(src)


def test_agent_checks_then_submits_and_the_system_verifies(monkeypatch, tmp_path):
    path = _patch(monkeypatch, tmp_path)
    llm = _FakeLLM(_call("compile_and_slither", {"fixed_function": FIX}, 1), _call("rescan_model", {"fixed_function": FIX}, 2),
                   _call("submit_fix", {"fixed_function": FIX, "summary": "state update before the call"}, 3))
    r = fa.run_agent(llm, FINDING, "function withdraw(uint a) public {}", path, max_rounds=4)
    assert llm.tools == ["compile_and_slither", "rescan_model", "similar_cases", "submit_fix"]
    assert r["stopped"] == "submitted" and r["fix"] == FIX and r["tool_calls"] == 3 and r["tokens"] == 360
    assert r["verification"]["holds"] is True and r["first_attempt_compiled"] is True


def test_the_systems_own_check_overrides_the_agent(monkeypatch, tmp_path):
    path = _patch(monkeypatch, tmp_path, still_flagged=True)   # the model still flags the "fixed" function
    llm = _FakeLLM(_call("submit_fix", {"fixed_function": FIX, "summary": "fixed"}, 1))
    r = fa.run_agent(llm, FINDING, "x", path)
    assert r["fix"] == FIX and r["verification"]["holds"] is False


def test_round_limit_stops_an_agent_that_never_submits(monkeypatch, tmp_path):
    path = _patch(monkeypatch, tmp_path)
    llm = _FakeLLM(*[_call("compile_and_slither", {"fixed_function": FIX}, i) for i in range(10)])
    r = fa.run_agent(llm, FINDING, "x", path, max_rounds=2)
    assert r["stopped"] == "round limit" and r["fix"] is None and "verification" not in r and r["rounds"] <= 3
