"""Run inside the backend image: can the product's own Slither step build a call graph for each flattened file?

docker run --rm -v $PWD:/bench:ro -w /graphfusion -e PYTHONPATH=/graphfusion --entrypoint .venv/bin/python scanguard-backend /bench/graph_check.py
Prints one "@@ {json}" line per case.
"""
import json, os, re, signal, subprocess, sys, time
from pathlib import Path

from src.workflows.gfd_workflow.nodes.fcg_converter.graph_converter import get_call_graph

ART = "ge-sc-artifacts"


def product_solc(path):  # mirrors get_call_graph: first x.y.z on the first pragma line, else 0.4.24
    for line in open(path, errors="replace"):
        if "pragma solidity" in line:
            m = re.findall(r"\d.\d.\d+", line)
            return m[0] if m else "0.4.24"
    return "0.4.24"


def compiles(path, version):
    solc = f"{ART}/solc-{version}/solc-{version}"
    if not os.path.exists(solc):
        return None, "no such solc"
    try:
        r = subprocess.run([solc, path], capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return False, "solc timeout"
    err = next((l for l in r.stderr.splitlines() if "Error" in l), "")
    return r.returncode == 0, err[:200]


def newest(minor):
    vs = sorted((tuple(map(int, d[5:].split("."))) for d in os.listdir(ART) if d.startswith(f"solc-0.{minor}.")), reverse=True)
    return [".".join(map(str, v)) for v in vs]


class Timeout(Exception):
    pass


def alarm(*_):
    raise Timeout()


signal.signal(signal.SIGALRM, alarm)
for f in sorted(Path("/bench/flat").glob("*.sol")):
    v = product_solc(f)
    ok, err = compiles(str(f), v)
    best = v if ok else None
    if not ok:  # would any shipped compiler of that minor accept it?
        for cand in newest(v.split(".")[1])[:40]:
            ok2, _ = compiles(str(f), cand)
            if ok2:
                best = cand
                break
    t0, nodes, slither_err = time.time(), None, None
    signal.alarm(300)
    try:
        g = get_call_graph(str(f))
        nodes = len(g.nodes()) if g is not None else None
    except Timeout:
        slither_err = "timeout 300s"
    except Exception as e:
        slither_err = str(e)[:200]
    signal.alarm(0)
    print("@@ " + json.dumps({"id": f.stem, "product_solc": v, "compiles_with_product_solc": ok, "solc_error": err,
                               "compiles_with": best, "graph_nodes": nodes, "slither_error": slither_err, "graph_seconds": round(time.time() - t0, 1)}), flush=True)
