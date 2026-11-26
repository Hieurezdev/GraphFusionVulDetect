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
