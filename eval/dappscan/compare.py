"""Join the audit labels (cases.json) with the product's output (results/) line by line -> report.json, report.md."""
import json
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).parent
cases = json.loads((HERE / "cases.json").read_text())
graph = {g["id"]: g for g in json.loads((HERE / "graph_check.json").read_text())}


def overlaps(a, b):
    return a[0] <= b[1] and b[0] <= a[1]


rows, per_case = [], []
for c in cases:
    res_file = HERE / "results" / f"{c['id']}.json"
    res = json.loads(res_file.read_text()) if res_file.exists() else {"http": None, "events": [], "seconds": None}
    ev = {e.get("node"): e.get("output", {}) for e in res["events"]}
    fcg = str(ev.get("convert_to_fcg", {}).get("fcg_file_path", ""))
    preds = ev.get("detect_vulnerability_func", {}).get("func_vulnerability_predictions", [])
    flagged = [p for p in preds if p.get("prediction") == 1]
    if res["http"] is None:
        stage = "not_run"
    elif res["http"] != 200 or not res["events"]:
        stage = "request_failed"
    elif "detect_vulnerability_src" not in ev:
        stage = "no_graph"            # Slither / solc could not build the call graph
    elif ev["detect_vulnerability_src"].get("predicted_class") != "Vulnerable":
        stage = "contract_cleared"    # contract-level model said Non-Vulnerable: function model never runs
    else:
        stage = "functions_scored"
    in_target = [p for p in flagged if p.get("lines") and p["lines"][0] > c["offset"]]
    hit_ids = set()
    for lab in c["labels"]:
        verdict = stage
        if stage == "functions_scored":
            hit = [p for p in flagged if p.get("lines") and any(overlaps(p["lines"], r) for r in lab["flat_lines"])]
            scored = [p for p in preds if p.get("lines") and any(overlaps(p["lines"], r) for r in lab["flat_lines"])]
            hit_ids.update(p["function_name"] for p in hit)
            verdict = "no_line_in_label" if not lab["flat_lines"] else "flagged" if hit else "missed" if scored else "line_outside_any_function"
        rows.append({"case": c["id"], "kind": lab["kind"], "pragma": c["pragma"], "audit": c["audit"], "audit_function": lab["function"],
                     "audit_lines": lab["raw_lines"], "flat_lines": lab["flat_lines"], "verdict": verdict,
                     "product_functions": [f"{p['function_name']} L{p['lines'][0]-c['offset']}-{p['lines'][1]-c['offset']} ({p['confidence']})" for p in (hit if verdict == "flagged" else [])]})
    per_case.append({"case": c["id"], "kinds": sorted({l["kind"] for l in c["labels"]}), "pragma": c["pragma"], "flat_lines": c["flat_lines"], "stage": stage,
                     "seconds": res.get("seconds"), "contract_confidence": ev.get("detect_vulnerability_src", {}).get("confidence_score"),
                     "functions": len(preds), "flagged": len(flagged), "flagged_in_labelled_file": len(in_target),
                     "flagged_matching_a_label": len(hit_ids), "flatten_ok": not c["unresolved_imports"], "graph_nodes": graph.get(c["id"], {}).get("graph_nodes")})

summary = {}
for kind in ("timestamp", "reentrancy"):
    r = [x for x in rows if x["kind"] == kind]
    pc = [x for x in per_case if kind in x["kinds"]]
    v = Counter(x["verdict"] for x in r)
    scored = v["flagged"] + v["missed"]
    summary[kind] = {"files": len(pc), "file_stage": dict(Counter(x["stage"] for x in pc)), "labels": len(r), "label_verdict": dict(v),
                     "recall_all_labels": round(v["flagged"] / len(r), 3) if r else None,
                     "recall_where_functions_scored": round(v["flagged"] / scored, 3) if scored else None,
                     "alerts": sum(x["flagged"] for x in pc), "alerts_in_labelled_file": sum(x["flagged_in_labelled_file"] for x in pc),
                     "alerts_matching_label": sum(x["flagged_matching_a_label"] for x in pc),
                     "functions_scored": sum(x["functions"] for x in pc if x["stage"] == "functions_scored")}
(HERE / "report.json").write_text(json.dumps({"summary": summary, "cases": per_case, "labels": rows}, indent=1, ensure_ascii=False))

md = ["# DAppSCAN vs. deployed pipeline", "", "Labels: audit findings (function + line) from DAppSCAN. An alert on a line no auditor flagged is not proven wrong.", ""]
for kind, s in summary.items():
    md += [f"## {kind}", "", "| | |", "|---|---|"] + [f"| {k} | {v} |" for k, v in s.items()] + [""]
md += ["## Every label", "", "| case | kind | pragma | audit function | audit lines | verdict | product functions |", "|---|---|---|---|---|---|---|"]
md += [f"| {x['case']} | {x['kind']} | {x['pragma'].replace('pragma solidity','').strip(' ;')} | {x['audit_function']} | {x['audit_lines']} | {x['verdict']} | {'; '.join(x['product_functions'])} |" for x in rows]
(HERE / "report.md").write_text("\n".join(md) + "\n")
print(json.dumps(summary, indent=1))
