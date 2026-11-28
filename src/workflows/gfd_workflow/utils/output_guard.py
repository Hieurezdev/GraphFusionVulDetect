"""Checks on an LLM explanation before it is shown (step 1.2 of docs/KE_HOACH_TRIEN_KHAI.md).

The explainer prompt asks the model to cite evidence as `Lx` and never to call the code safe. A prompt is a request,
not a guarantee, and the code under review is untrusted text that may try to steer the answer. These checks make the
two rules hold on the output itself:

  1. every line it cites (`L12`, `L12-L14`, `L12–14`) lies inside the function that was flagged;
  2. it makes no claim that the code is safe / secure / free of vulnerabilities (negated phrases such as
     "không an toàn", "is not safe", "does not mean the code is safe" are allowed).
"""
import re
from typing import List

# L12, L12-L14, L12–14, L12 - L14 (hyphen, en dash, em dash)
_LINE_REF = re.compile(r"(?<![A-Za-z0-9_])L(\d{1,6})(?:\s*[-–—]\s*L?(\d{1,6}))?(?![A-Za-z0-9_])")

# Affirmative safety claims. Each match is rejected only if no negation word appears just before it.
_SAFE_CLAIMS = [
    re.compile(r"(?i)\b(?:is|are|looks|appears|seems|remains?)\s+(?:completely\s+|perfectly\s+|fully\s+|totally\s+|entirely\s+)?(?:safe|secure)\b"),
    re.compile(r"(?i)\b(?:no|free\s+of|free\s+from|without\s+any)\s+(?:known\s+)?vulnerabilit(?:y|ies)\b"),
    re.compile(r"(?i)\bnot\s+vulnerable\b"),
    re.compile(r"(?i)(?:hoàn\s+toàn|tuyệt\s+đối)\s+an\s+toàn|an\s+toàn\s+(?:tuyệt\s+đối|hoàn\s+toàn)"),
    re.compile(r"(?i)\b(?:mã|hàm|hợp\s+đồng|code|contract)(?:\s+này)?\s+(?:là\s+|đã\s+|vẫn\s+)?an\s+toàn\b"),
    re.compile(r"(?i)không\s+(?:có|tồn\s+tại|chứa)\s+(?:bất\s+kỳ\s+)?lỗ\s+hổng"),
]
# A claim preceded (within a few words) by one of these is a negation or a caveat, not a claim.
_NEGATION = re.compile(r"(?i)(?:\bnot\b|n't\b|\bnever\b|\bcannot\b|\bno\s+guarantee\b|\bwithout\s+proof\b|"
                       r"không\b|chưa\b|chẳng\b|đừng\b|không\s+có\s+nghĩa|không\s+thể\s+kết\s+luận)")
_NEGATION_WINDOW = 40  # characters before the claim


_LINE_WORD = re.compile(r"(?i)(?:dòng|line|lines|tại|at)\s*[:`]?\s*$")


def cited_lines(text: str) -> List[int]:
    """Every line number the text cites, ranges expanded to their two ends.

    A citation is `L12` in backticks (the form the prompt asks for) or L12 right after "dòng"/"line"; a bare L2 elsewhere
    is something else ("L2" = layer-2 chain, "L1 gas"), not a line number.
    """
    out = []
    text = text or ""
    for m in _LINE_REF.finditer(text):
        before = text[max(0, m.start() - 12):m.start()]
        if not (before.endswith("`") or _LINE_WORD.search(before)):
            continue
        out.append(int(m.group(1)))
        if m.group(2):
            out.append(int(m.group(2)))
    return out


def safety_claims(text: str) -> List[str]:
    """The affirmative 'this code is safe' phrases in the text."""
    found = []
    for pattern in _SAFE_CLAIMS:
        for m in pattern.finditer(text or ""):
            before = text[max(0, m.start() - _NEGATION_WINDOW):m.start()]
            # "không có lỗ hổng" carries its own negation word: only a second one before it ("không thể nói ...") clears it
            if pattern.pattern.startswith("(?i)không"):
                if _NEGATION.search(before):
                    continue
            elif _NEGATION.search(before) or _NEGATION.search(m.group(0)):
                continue
            found.append(m.group(0))
    return found


def check_explanation(text: str, first_line: int, last_line: int) -> List[str]:
    """Problems found in an explanation of the function spanning [first_line, last_line]; an empty list = it passes."""
    problems = []
    outside = sorted({n for n in cited_lines(text) if not first_line <= n <= last_line})
    if outside:
        problems.append(f"cites lines outside the function (lines {first_line}-{last_line}): "
                        + ", ".join(f"L{n}" for n in outside))
    claims = safety_claims(text)
    if claims:
        problems.append("claims the code is safe: " + "; ".join(f'"{c}"' for c in claims[:3]))
    return problems
