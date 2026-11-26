import pytest

from src.services.token_service import SourceNotVerified, TokenService

svc = TokenService()


def test_supported_platforms_keeps_only_chains_we_can_fetch():
    platforms = {"ethereum": "0xabc", "polygon-pos": "0xdef", "tron": "T123", "solana": "So1", "base": ""}
    assert svc.supported_platforms(platforms) == {"ethereum": "0xabc"}   # Ethereum only: the models were trained on it
    assert svc.supported_platforms({"": ""}) == {} and svc.supported_platforms(None) == {}


def test_unknown_chain_is_refused_not_sent_to_ethereum():
    with pytest.raises(ValueError):
        svc.fetch_source_code("T123", "tron")
    with pytest.raises(ValueError):
        svc.fetch_source_code("0xdef", "polygon-pos")


def test_unverified_contract_is_its_own_error():
    with pytest.raises(SourceNotVerified):
        svc._process_contract_data({"SourceCode": "", "ContractName": "X"}, "0xabc")


class FakeResponse:
    def __init__(self, status, body=None):
        self.status_code, self._body = status, body or {}

    def json(self):
        return self._body

    def raise_for_status(self):
        if self.status_code >= 400:
            raise RuntimeError(f"HTTP {self.status_code}")


def test_rate_limit_and_missing_token_are_reported(monkeypatch):
    from src.services import token_service as ts
    monkeypatch.setattr(ts.requests, "get", lambda *a, **k: FakeResponse(429))
    with pytest.raises(ts.RateLimited):
        TokenService().search_token("uni")
    monkeypatch.setattr(ts.requests, "get", lambda *a, **k: FakeResponse(404))
    with pytest.raises(ts.TokenNotFound):
        TokenService().get_token_details("no-such-coin-xyz")


def test_details_cache_keeps_only_platforms(monkeypatch):
    from src.services import token_service as ts
    body = {"platforms": {"ethereum": "0xabc"}, "description": {"en": "x" * 30000}}
    monkeypatch.setattr(ts.requests, "get", lambda *a, **k: FakeResponse(200, body))
    assert TokenService().get_token_details("cache-test-coin") == {"platforms": {"ethereum": "0xabc"}}


def test_multi_file_source_is_flattened_in_dependency_order_and_pinned_to_the_deployed_compiler():
    sources = {
        "contracts/Token.sol": {"content": '// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\nimport {Base} from "./lib/Base.sol";\nimport "@oz/Ctx.sol";\ncontract Token is Base {}'},
        "contracts/lib/Base.sol": {"content": '// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\nimport "@oz/Ctx.sol";\ncontract Base is Ctx {}'},
        "@oz/Ctx.sol": {"content": "pragma solidity ^0.8.0;\ncontract Ctx {}"},
    }
    import json
    out = svc._process_contract_data({"SourceCode": "{" + json.dumps({"sources": sources}) + "}", "ContractName": "Token",
                                      "CompilerVersion": "v0.8.24+commit.e11b9ed9"}, "0xabc")["source_code"]
    assert out.startswith("pragma solidity 0.8.24;")
    assert out.index("contract Ctx") < out.index("contract Base") < out.index("contract Token")
    assert "import" not in out and out.count("SPDX-License-Identifier") == 1 and out.count("contract Ctx") == 1


def test_flatten_follows_remapped_imports():
    from src.services.token_service import flatten_sources
    out = flatten_sources({"src/A.sol": 'import "@oz/contracts/utils/B.sol";\ncontract A is B {}',
                           "lib/oz-contracts/contracts/utils/B.sol": "contract B {}"})
    assert out.index("contract B") < out.index("contract A")
