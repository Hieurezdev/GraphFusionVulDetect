import logging
import posixpath
import requests
import json
import os
import re
from typing import List, Dict, Optional, Any
from pathlib import Path

class RateLimited(RuntimeError):
    """The public token directory (CoinGecko free tier) refused the call: too many requests in the last minute."""


logger = logging.getLogger(__name__)


class TokenNotFound(RuntimeError):
    """The token directory has no coin with that id."""


class SourceNotVerified(RuntimeError):
    """The explorer knows the address but its source code was never published."""


_IMPORT = re.compile(r'^[ \t]*import\b[^;"\']*["\']([^"\']+)["\'][^;]*;', re.M)
_ONCE = re.compile(r'^.*SPDX-License-Identifier.*$|^[ \t]*pragma\s+(?:experimental|abicoder)\b[^;]*;', re.M)


def flatten_sources(sources: Dict[str, str]) -> str:
    """One compilable file from an explorer's multi-file source: every file after the files it imports, imports removed.
    shortcut: aliased imports (import "x" as A / {B as C}) are not rewritten, flatten with solc's own resolver if such contracts matter."""
    done, parts, seen_once = set(), [], set()

    def resolve(spec: str, current: str) -> Optional[str]:
        path = posixpath.normpath(posixpath.join(posixpath.dirname(current), spec)) if spec.startswith(".") else spec
        if path in sources:
            return path
        # Remapped imports ("@openzeppelin/contracts/x.sol" stored as "lib/openzeppelin-contracts/contracts/x.sol"):
        # match on the longest trailing part of the path that names exactly one file.
        parts = path.lstrip("./").split("/")
        for i in range(len(parts)):
            hits = [name for name in sources if name == "/".join(parts[i:]) or name.endswith("/" + "/".join(parts[i:]))]
            if len(hits) == 1:
                return hits[0]
            if hits and i == len(parts) - 1:   # same file name in several folders: prefer the one closest to the importer
                return max(hits, key=lambda n: len(posixpath.commonprefix([n, current])))
        return None

    def once(match):  # solc rejects a second SPDX line or a repeated experimental pragma in one file
        key = " ".join(match.group(0).split())
        if key in seen_once or "SPDX" in key and any("SPDX" in k for k in seen_once):
            return ""
        seen_once.add(key)
        return match.group(0)

    def visit(name: str):
        if name in done:
            return
        done.add(name)
        for spec in _IMPORT.findall(sources[name]):
            dep = resolve(spec, name)
            if dep:
                visit(dep)
        body = _IMPORT.sub(lambda m: "\n" * m.group(0).count("\n"), sources[name])  # keep the file's own line count
        parts.append(f"// File: {name}\n\n{_ONCE.sub(once, body)}\n")

    for name in sources:
        visit(name)
    return "\n".join(parts)


class TokenService:
    COINGECKO_BASE = "https://api.coingecko.com/api/v3"
    _details: Dict[str, Any] = {}
    
    # Ethereum only: the detection models were trained on Ethereum contracts, so other chains are not offered.
    # Map friendly chain names -> CoinGecko 'platforms' keys and explorer API base
    CHAIN_META = {
        "ethereum": {
            "cg_key": "ethereum",
            "chainid": "1",
            "explorer_api": "https://api.etherscan.io/v2/api",
            "api_key_env": "ETHERSCAN_API_KEY"
        }
    }

    def search_token(self, query: str) -> List[Dict[str, Any]]:
        """
        Search CoinGecko for the token name/symbol.
        Returns a list of simplified token objects.
        """
        r = requests.get(f"{self.COINGECKO_BASE}/search", params={"query": query}, timeout=10)
        if r.status_code == 429:  # say so: an empty list would read as "no such token"
            raise RateLimited("Token directory rate limit reached")
        r.raise_for_status()
        return r.json().get("coins", [])

    def supported_platforms(self, platforms: Dict[str, str]) -> Dict[str, str]:
        """Only the chains we can fetch source for, keyed as CoinGecko names them, and only where the token has an address."""
        known = {meta["cg_key"] for meta in self.CHAIN_META.values()}
        return {chain: address for chain, address in (platforms or {}).items() if chain in known and address}

    def get_token_details(self, coin_id: str) -> Dict[str, Any]:
        """
        Get detailed info (platforms/addresses) for a specific coin.
        """
        if coin_id in self._details:  # a token's contract addresses do not change: ask the rate-limited directory once per token
            return self._details[coin_id]
        url = f"{self.COINGECKO_BASE}/coins/{coin_id}"
        try:
            r = requests.get(url, params={"localization": "false", "tickers": "false", "community_data": "false", "developer_data": "false"}, timeout=10)
            if r.status_code == 429:
                raise RateLimited("Token directory rate limit reached")
            if r.status_code == 404:
                raise TokenNotFound(coin_id)
            r.raise_for_status()
            if len(self._details) > 2000:
                self._details.clear()
            # Keep only what is used: the full coin record is ~30 KB (descriptions, links, market data).
            self._details[coin_id] = {"platforms": r.json().get("platforms") or {}}
            return self._details[coin_id]
        except (RateLimited, TokenNotFound):
            raise
        except Exception as e:
            raise RuntimeError(f"Error fetching coin details: {e}")

    def fetch_source_code(self, address: str, chain: str) -> Dict[str, Any]:
        """
        Fetch contract source code from the appropriate explorer.
        Returns a dict with 'source_code', 'file_name', etc.
        """
        chain_key = chain.lower()
        if chain_key not in self.CHAIN_META:
            # The UI sends CoinGecko's platform key ("polygon-pos", "arbitrum-one"); never guess Ethereum for an unknown chain.
            chain_key = next((k for k, meta in self.CHAIN_META.items() if meta["cg_key"] == chain_key), None)
            if chain_key is None:
                raise ValueError(f"Unsupported chain: {chain}")

        meta = self.CHAIN_META[chain_key]
        base_url = meta.get("explorer_api")
        # For V2 APIs or different explorers, structure might vary slightly but 
        # 'module=contract&action=getsourcecode' is standard for Etherscan clones.
        
        params = {
            "module": "contract",
            "action": "getsourcecode",
            "address": address
        }
        
        # Add chainid for Etherscan V2 API
        if "etherscan.io" in base_url and meta.get("chainid"):
            params["chainid"] = meta.get("chainid")

        # Add API Key if available
        api_key_env = meta.get("api_key_env")
        if api_key_env:
            api_key = os.getenv(api_key_env)
            if api_key:
                params["apikey"] = api_key

        try:
            resp = requests.get(base_url, params=params, timeout=20)
            resp.raise_for_status()
            data = resp.json()
            
            status = str(data.get("status", ""))
            result = data.get("result")
            message = data.get("message")

            # Etherscan can return status 0 with message "NOTOK" if invalid params or rate limited
            if status != "1" or not result:
                  # Special handling for V2 API which might return result but status 0 if error matches
                 raise RuntimeError(f"Explorer API error: status={status}, message={message}, result={result}")

            # Result is usually a list
            if isinstance(result, list) and len(result) > 0:
                contract_data = result[0]
                return self._process_contract_data(contract_data, address)
            
            raise RuntimeError("No source code found in explorer response.")

        except SourceNotVerified:
            raise
        except Exception as e:
            # Add more context to error
            raise RuntimeError(f"Failed to fetch source code from {chain}: {e}")

    def _process_contract_data(self, data: Dict[str, Any], address: str) -> Dict[str, Any]:
        """
        Normalize the explorer result into a single source string or dict of files.
        """
        source_code = data.get("SourceCode", "")
        contract_name = data.get("ContractName", "UnknownContract")
        
        if not source_code:
            raise SourceNotVerified("Contract source code is empty or not verified.")

        # Handle multi-file source (JSON format)
        if source_code.startswith("{{") and source_code.endswith("}}"):
             source_code = source_code[1:-1] # Remove double braces quirk of some APIs

        final_source = source_code
        try:
            if source_code.startswith("{"):
                parsed = json.loads(source_code)
                files = parsed.get("sources", parsed)  # standard JSON input, or a flat {path: {content}} dict
                final_source = flatten_sources({name: node["content"] for name, node in files.items()
                                                if isinstance(node, dict) and "content" in node}) or source_code
        except json.JSONDecodeError:
            pass

        # The pipeline picks solc from the first pragma. A flattened file carries one pragma per source ("^0.8.0" next to
        # "^0.8.20"), so lead with the compiler the contract was actually deployed with.
        deployed = re.search(r"v?(\d+\.\d+\.\d+)", data.get("CompilerVersion") or "")
        if deployed:
            final_source = f"pragma solidity {deployed.group(1)}; // compiler recorded by the explorer\n" + final_source

        return {
            "name": contract_name,
            "address": address,
            "source_code": final_source,
            "abi": data.get("ABI", "[]"),
            "compiler_version": data.get("CompilerVersion", "")
        }

token_service = TokenService()
