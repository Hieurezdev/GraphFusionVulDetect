"""Semantics-preserving rewrites of the Test contracts, to see whether a verdict survives them.

  rename         every user function gets a new name (standard token/builtin names and names used in string literals are kept)
  comment_pad    a long neutral comment at the top of every function that holds the syntax keyword (pushes its body past CodeBERT's 512 tokens)
  dead_code      ten no-op statements at the top of every such function
  decoy          an extra contract whose only function mentions the keyword in a comment
  split_keyword  a line break inside the keyword: block<newline>.timestamp, .call<newline>.value(
  time_wrapper   (timestamp) now / block.timestamp read through a library function instead of inline

usage: gen_adversarial.py <timestamp|reentrancy> <dir with original .sol> <out dir>   -> out/<transform>/<same name>.sol
"""
import re, sys
from pathlib import Path

KEY = {"timestamp": r"block\s*\.\s*timestamp|\bnow\b", "reentrancy": r"\.call\s*\.\s*value\s*\("}
KEEP = set("transfer transferFrom approve balanceOf totalSupply allowance send call delegatecall callcode name symbol decimals owner mint burn fallback constructor "
           "tokenFallback receiveApproval onERC721Received supportsInterface ownerOf safeTransferFrom setApprovalForAll getApproved isApprovedForAll".split())
PAD = "    /* " + " ".join(f"note {i}: this routine is part of the contract and is documented here for maintainers." for i in range(60)) + " */\n"
DEAD = "".join(f"    uint256 zpad{i} = {i}; zpad{i} = zpad{i} + 1;\n" for i in range(10))


def functions(src):
    """(index just after the opening brace, body text) of every function that has a body."""
    for m in re.finditer(r"\bfunction\b[^{;]*\{", src):
        depth, i = 1, m.end()
        while i < len(src) and depth:
            depth += {"{": 1, "}": -1}.get(src[i], 0); i += 1
        yield m.end(), src[m.end():i]


def insert_in_keyword_functions(src, key, text):
    for pos, body in sorted(functions(src), reverse=True):
        if re.search(key, body):
            src = src[:pos] + "\n" + text + src[pos:]
    return src


def rename(src, key):
    contracts = set(re.findall(r"\b(?:contract|library|interface)\s+(\w+)", src))
    quoted = set(re.findall(r"\w+", " ".join(re.findall(r'"[^"\n]*"|\'[^\'\n]*\'', src))))
    for name in sorted(set(re.findall(r"\bfunction\s+(\w+)\s*\(", src)) - contracts - KEEP - quoted):
        src = re.sub(rf"\b{name}\b", f"{name}_r", src)
    return src


def time_wrapper(src, key):
    view = "constant" if re.search(r"pragma\s+solidity[^;]*0\.4\.", src) or "pragma" not in src else "view"
    lib = f"\nlibrary ZTime {{ function get() internal {view} returns (uint) {{ return block.timestamp; }} }}\n"
    body = re.sub(r"block\s*\.\s*timestamp|\bnow\b", "ZTime.get()", src)
    m = re.search(r"pragma\s+solidity[^;]*;", body)
    return body[:m.end()] + lib + body[m.end():] if m else lib + body


TRANSFORMS = {
    "rename": rename,
    "comment_pad": lambda s, k: insert_in_keyword_functions(s, k, PAD),
    "dead_code": lambda s, k: insert_in_keyword_functions(s, k, DEAD),
    "decoy": lambda s, k: s + "\ncontract ZDecoy {\n  function info() public returns (uint) {\n    // not used: block.timestamp, now, msg.sender.call.value(1)()\n    return 1;\n  }\n}\n",
    "split_keyword": lambda s, k: re.sub(r"\.call\s*\.\s*value\s*\(", ".call\n        .value(", re.sub(r"block\s*\.\s*timestamp", "block\n        .timestamp", s)),
    "time_wrapper": time_wrapper,
}

if __name__ == "__main__":
    assert [b for _, b in functions("contract C { function f() { if (now > 1) { x = 1; } } function g(); }")] == [" if (now > 1) { x = 1; } }"]
    assert "f_r()" in rename("contract C { function f() {} function transfer() { f(); } }", "") and "transfer_r" not in rename("contract C { function transfer() {} }", "")
    vuln, src_dir, out = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])
    for name, fn in TRANSFORMS.items():
        if name == "time_wrapper" and vuln != "timestamp":
            continue
        (out / name).mkdir(parents=True, exist_ok=True)
        n = 0
        for sol in sorted(src_dir.glob("*.sol")):
            src = sol.read_text(errors="replace")
            new = fn(src, KEY[vuln])
            if new != src:   # unchanged files are not adversarial cases
                (out / name / sol.name).write_text(new); n += 1
        print(vuln, name, n)
