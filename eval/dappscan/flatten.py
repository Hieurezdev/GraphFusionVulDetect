"""Flatten DAppSCAN files that carry an SWC-116 / SWC-107 audit label into single .sol files.

The labelled file is emitted last with its line count intact, so
flattened_line = audit_line + offset. Usage: flatten.py <DAppSCAN-source dir> <deps dir> <out dir>
"""
import json, os, re, sys
from pathlib import Path

SRC, DEPS, OUT = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
IMPORT = re.compile(r'^\s*import\s+(?:[^"\']*?\sfrom\s+)?["\']([^"\']+)["\']', re.M)
PRAGMA = re.compile(r'^\s*pragma\s+solidity[^;]*;', re.M)
OTHER_PRAGMA = re.compile(r'^\s*pragma\s+(experimental|abicoder)\s+[^;]*;', re.M)
SWCS = {"SWC-116": "timestamp", "SWC-107": "reentrancy"}


def oz_dir(minor):  # shortcut: OpenZeppelin release guessed from the pragma minor, upgrade to the project's lockfile version if one ships
    return {"8": "oz4", "7": "oz3", "6": "oz3", "5": "oz2", "4": "oz1"}.get(minor, "oz4")


def resolve(spec, cur, project, minor):
    if spec.startswith("."):
        p = (cur.parent / spec).resolve()
        return p if p.is_file() else None
    for base in (cur.parent, project, *[d for d in project.rglob("node_modules") if d.is_dir()], *[d for d in project.rglob("lib") if d.is_dir()]):
        if (base / spec).is_file():
            return (base / spec).resolve()
    tail = spec.split("/", 2)[-1] if spec.startswith("@") else spec.split("/", 1)[-1]   # path inside the package
    hits = [p for p in project.rglob(Path(spec).name) if str(p).endswith(tail)]
    if len(hits) == 1:
        return hits[0].resolve()
    pkg = {"@openzeppelin/contracts/": "contracts", "@openzeppelin/contracts-upgradeable/": "contracts-upgradeable",
           "openzeppelin-solidity/contracts/": "contracts", "zeppelin-solidity/contracts/": "contracts"}
    for prefix, sub in pkg.items():
        if spec.startswith(prefix):
            p = DEPS / oz_dir(minor) / sub / spec[len(prefix):]
            return p.resolve() if p.is_file() else None
    p = DEPS / "npm" / spec   # other npm packages, unpacked as <deps>/npm/<package>/...
    return p.resolve() if p.is_file() else None


def flatten(target, project):
    text = target.read_text(encoding="utf-8", errors="replace")
    m = PRAGMA.search(text)
    pragma = m.group(0).strip() if m else ""
    minor = (re.search(r"0\.(\d+)", pragma) or [None, "4"])[1]
    seen, parts, unresolved, extra = set(), [], [], []

    def strip(body):
        body = IMPORT.sub(lambda mm: "// [flatten] import inlined", body)   # one line in, one line out
        body = PRAGMA.sub("// [flatten] version pragma removed", body)
        extra.extend(" ".join(m.group(0).split()) for m in OTHER_PRAGMA.finditer(body))   # solc rejects repeats, keep one of each at the top
        body = OTHER_PRAGMA.sub("// [flatten] pragma hoisted", body)
        return re.sub(r"^.*SPDX-License-Identifier.*$", "// [flatten] spdx removed", body, flags=re.M)

    def visit(path):
        if path in seen:
            return
        seen.add(path)
        body = path.read_text(encoding="utf-8", errors="replace")
        for spec in IMPORT.findall(body):
            dep = resolve(spec, path, project, minor)
            if dep is None:
                unresolved.append(spec)
            else:
                visit(dep)
        if path != target.resolve():
            parts.append(strip(body).rstrip("\n"))

    visit(target.resolve())
    body = strip(text)
    head = "\n".join([pragma or "// no pragma in the labelled file", *dict.fromkeys(extra), *parts])
    offset = head.count("\n") + 1
    return head + "\n" + body, offset, pragma, sorted(set(unresolved)), len(seen) - 1


def lines_of(raw):  # "L351,369,388" / "L70 - L105" / "430" / "All" -> [[start, end], ...]
    out = []
    for part in re.sub(r"[Ll]", "", raw).split(","):
        nums = [int(n) for n in re.findall(r"\d+", part)]
        if nums:
            out.append([nums[0], nums[-1]])
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    cases = []
    for jf in sorted((SRC / "SWCsource").rglob("*.json")):
        swcs = json.loads(jf.read_text(encoding="utf-8", errors="replace")).get("SWCs", [])
        labels = [{"swc": k, "kind": SWCS[k], "function": s.get("function", "").strip(), "raw_lines": s.get("lineNumber", ""),
                   "lines": lines_of(s.get("lineNumber", ""))} for s in swcs for k in SWCS if s.get("category", "").startswith(k)]
        if not labels:
            continue
        rel = jf.relative_to(SRC / "SWCsource").with_suffix(".sol")
        target = SRC / "contracts" / rel
        project = SRC / "contracts" / Path(*rel.parts[:2])
        flat, offset, pragma, unresolved, ndeps = flatten(target, project)
        cid = f"{len(cases):03d}_{target.stem}"
        (OUT / f"{cid}.sol").write_text(flat, encoding="utf-8")
        for lab in labels:
            lab["flat_lines"] = [[a + offset, b + offset] for a, b in lab["lines"]]
        cases.append({"id": cid, "source": str(rel), "audit": rel.parts[0], "pragma": pragma, "orig_lines": target.read_text(errors="replace").count("\n") + 1,
                      "flat_lines": flat.count("\n") + 1, "offset": offset, "deps_inlined": ndeps, "unresolved_imports": unresolved, "labels": labels})
    (OUT.parent / "cases.json").write_text(json.dumps(cases, indent=1, ensure_ascii=False), encoding="utf-8")
    print(len(cases), "cases;", sum(bool(c["unresolved_imports"]) for c in cases), "with unresolved imports")


if __name__ == "__main__":
    assert lines_of("L351,369,388") == [[351, 351], [369, 369], [388, 388]] and lines_of("L70 - L105") == [[70, 105]] and lines_of("All") == []
    main()
