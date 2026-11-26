"""Requirement 2: join the scores in out/ with the expert labels -> report.md, results_*.md, summary.json. Run from the repo root."""
import hashlib, json, re, statistics
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).parent
REPO = HERE.parents[1]
DATASET = {"timestamp": "TimestampDependencyDataset", "reentrancy": "ReentrancyDataset"}
KEY = {"timestamp": r"block\s*\.\s*timestamp|\bnow\b", "reentrancy": r"\.call\s*\.\s*value\s*\("}
VN = {"timestamp": "Timestamp dependency", "reentrancy": "Reentrancy"}


def load(name):
    p = HERE / "out" / f"{name}.jsonl"
    return {r["file"]: r for r in map(json.loads, p.read_text().splitlines())} if p.exists() else {}


def train_hashes(vuln):
    out = set()
    for m in (REPO / "assets/datasets/SourceCodeSyntaxDatasetFull" / DATASET[vuln] / "Train").rglob("*_mapping.json"):
        out |= {hashlib.md5("".join(c.split()).encode()).hexdigest() for c in json.loads(m.read_text())["code"].values() if c.strip()}
    return out


def overlap(rows, seen):
    fn = [f for r in rows if r["status"] == "ok" for f in r["functions"] if f["lines"]]
    return {"functions": len(fn), "also_in_train": sum(f["md5"] in seen for f in fn), "share": round(sum(f["md5"] in seen for f in fn) / max(len(fn), 1), 3)}


def flagged(r):
    return [f for f in r.get("functions", []) if f["pred"] == 1]


def pct(a, b):
    return f"{a}/{b} ({a / b:.0%})" if b else "0/0"


summary, md, S = {}, ["# Yêu cầu 2: khả năng khái quát và ca khó", ""], {}
cases = json.loads((REPO / "eval/dappscan/cases.json").read_text())
hard_labels = json.loads((HERE / "hard/labels.json").read_text())
res_d, res_h, res_a = [], [], []

for vuln in ("timestamp", "reentrancy"):
    seen = train_hashes(vuln)
    s = summary[vuln] = {}

    # ---------- A. unseen projects with audit labels (DAppSCAN) + B. size ----------
    rows = load(f"dappscan_{vuln}")
    labels, per_file = [], {}
    for c in cases:
        r = rows.get(f"eval/dappscan/flat/{c['id']}.sol")
        if r is None:
            continue
        per_file[c["id"]] = (c, r)
        for lab in (l for l in c["labels"] if l["kind"] == vuln):
            hit = []
            if r["status"] != "ok":
                verdict = "không dựng được đồ thị"
            elif not lab["flat_lines"]:
                verdict = "nhãn không có số dòng"
            else:
                inside = [f for f in r["functions"] if f["lines"] and any(f["lines"][0] <= b and a <= f["lines"][1] for a, b in lab["flat_lines"])]
                hit = [f for f in inside if f["pred"] == 1]
                verdict = ("dòng nằm ngoài mọi hàm" if not inside else
                           "phát hiện đúng hàm" if hit and r["contract_pred"] else
                           "hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn)" if hit else
                           "bỏ sót (hợp đồng bị xếp không lỗi)" if not r["contract_pred"] else "bỏ sót (hợp đồng có cờ, hàm không)")
            labels.append((c, lab, r, verdict, hit))
            res_d.append(f"| {VN[vuln]} | {c['id']}.sol | {c['audit'][:40]} | {c['pragma'].replace('pragma solidity', '').strip(' ;')} | {lab['function'] or '-'} | {lab['raw_lines']} | "
                         f"{', '.join(f'{a}-{b}' if a != b else str(a) for a, b in lab['flat_lines']) or '-'} | {verdict} | "
                         f"{'; '.join(f['name'] + ' L' + str(f['lines'][0]) + '-' + str(f['lines'][1]) + ' p=' + str(f['p']) for f in hit) or '-'} | {r.get('contract_p', '-')} |")
    v = Counter(x[3] for x in labels)
    ok = [r for _, r in per_file.values() if r["status"] == "ok"]
    alerts = [f for r in ok if r["contract_pred"] for f in flagged(r)]
    matched = {(c["id"], f["name"]) for c, _, r, verdict, hit in labels if verdict == "phát hiện đúng hàm" for f in hit}
    minors = defaultdict(lambda: [0, 0])
    for c, r in per_file.values():
        k = "0." + (re.search(r"0\.(\d+)", c["pragma"]) or [0, "?"])[1]
        minors[k][0] += 1; minors[k][1] += r["status"] == "ok"
    s["dappscan"] = {"files": len(per_file), "graph_built": len(ok), "contract_flagged": sum(r["contract_pred"] for r in ok), "labels": len(labels), "verdicts": dict(v),
                     "alerts_shown": len(alerts), "alerts_matching_an_audit_label": len(matched), "by_solidity": {k: f"{b}/{a}" for k, (a, b) in sorted(minors.items())}, "overlap_with_train": overlap(ok, seen)}
    size = {}
    for name, lo, hi in (("dưới 500 dòng", 0, 500), ("500–2.000 dòng", 500, 2000), ("trên 2.000 dòng", 2000, 10 ** 9)):
        grp = [(c, r) for c, r in per_file.values() if lo <= c["flat_lines"] < hi]
        g_ok = [r for _, r in grp if r["status"] == "ok"]
        lab = [x for x in labels if lo <= x[0]["flat_lines"] < hi and x[2]["status"] == "ok"]
        fn = [f for r in g_ok for f in r["functions"] if f["lines"]]
        size[name] = {"files": len(grp), "graph_built": len(g_ok), "median_functions": int(statistics.median(len(r["functions"]) for r in g_ok)) if g_ok else 0,
                      "median_seconds": round(statistics.median(r["seconds"] for r in g_ok), 1) if g_ok else None, "max_seconds": max((r["seconds"] for r in g_ok), default=None),
                      "functions_over_512_tokens": f"{sum(f['tokens'] > 512 for f in fn)}/{len(fn)}", "labels_found": f"{sum(x[3] == 'phát hiện đúng hàm' for x in lab)}/{len(lab)}"}
    s["size"] = size

    # ---------- C. adversarial rewrites of the Test contracts ----------
    orig = load(f"adv_{vuln}_original")
    label = lambda f: int(Path(f).name.startswith("Vulnerable__"))
    correct = {Path(f).name for f, r in orig.items() if r["status"] == "ok" and r["contract_pred"] == label(f)}
    adv = {}
    for t in ("rename", "comment_pad", "dead_code", "decoy", "split_keyword", "time_wrapper"):
        rows = load(f"adv_{vuln}_{t}")
        if not rows:
            continue
        valid = {Path(f).name: r for f, r in rows.items() if r["status"] == "ok" and Path(f).name in correct}
        o = {n: orig[f"eval/generalization/adversarial/{vuln}/original/{n}"] for n in valid}
        lost = [n for n, r in valid.items() if label(n) == 1 and r["contract_pred"] == 0]
        gained = [n for n, r in valid.items() if label(n) == 0 and r["contract_pred"] == 1]
        pos = [n for n in valid if label(n) == 1]
        adv[t] = {"generated": len(rows), "did_not_compile": sum(r["status"] != "ok" for r in rows.values()), "compared": len(valid),
                  "vulnerable_now_missed": f"{len(lost)}/{len(pos)}", "safe_now_flagged": f"{len(gained)}/{len(valid) - len(pos)}",
                  "flip_rate": round((len(lost) + len(gained)) / max(len(valid), 1), 3), "mean_abs_change_in_p": round(statistics.mean(abs(valid[n]["contract_p"] - o[n]["contract_p"]) for n in valid), 3) if valid else None,
                  "flagged_functions_before_after": f"{sum(len(flagged(o[n])) for n in pos)} -> {sum(len(flagged(valid[n])) for n in pos)}",
                  "decoy_function_flagged": sum(any(f["name"].startswith("ZDecoy") for f in flagged(r)) for r in valid.values()) if t == "decoy" else None}
        for n in lost + gained:
            res_a.append(f"| {VN[vuln]} | {t} | {n} | {label(n)} | {o[n]['contract_pred']} (p={o[n]['contract_p']}) | {valid[n]['contract_pred']} (p={valid[n]['contract_p']}) |")
    s["adversarial"] = {"test_contracts": len(orig), "originally_correct": len(correct), "transforms": adv}

    # ---------- D. hard positives / negatives with manual labels (CGT) ----------
    rows = load(f"hard_{vuln}")
    ok = {f: r for f, r in rows.items() if r["status"] == "ok"}
    lab = lambda f: hard_labels[f.split("hard/")[1]]
    conf = Counter((lab(f)["label"], r["contract_pred"]) for f, r in ok.items())
    by_src = defaultdict(Counter)
    for f, r in ok.items():
        for src in {x.split(":")[0] for x in lab(f)["sources"]}:
            by_src[src][(lab(f)["label"], r["contract_pred"])] += 1
    tp, fn, fp, tn = conf[(1, 1)], conf[(1, 0)], conf[(0, 1)], conf[(0, 0)]
    s["hard"] = {"files": len(rows), "graph_built": len(ok), "positives": tp + fn, "hard_negatives": fp + tn, "found": tp, "missed": fn, "false_alarms": fp, "correctly_cleared": tn,
                 "recall": round(tp / max(tp + fn, 1), 3), "false_alarm_rate_on_hard_negatives": round(fp / max(fp + tn, 1), 3), "precision": round(tp / max(tp + fp, 1), 3),
                 "by_source": {k: {"found": c[(1, 1)], "missed": c[(1, 0)], "false_alarm": c[(0, 1)], "cleared": c[(0, 0)]} for k, c in sorted(by_src.items())},
                 "overlap_with_train": overlap(ok.values(), seen)}
    for f, r in sorted(rows.items()):
        l = lab(f)
        verdict = "không dựng được đồ thị" if r["status"] != "ok" else {(1, 1): "phát hiện đúng", (1, 0): "bỏ sót", (0, 1): "cảnh báo nhầm", (0, 0): "đúng (không cảnh báo)"}[(l["label"], r["contract_pred"])]
        fl = "; ".join(f"{x['name']} L{x['lines'][0]}-{x['lines'][1]} p={x['p']}" for x in flagged(r) if x["lines"])[:300] if r["status"] == "ok" and r["contract_pred"] else "-"
        res_h.append(f"| {VN[vuln]} | {Path(f).name} | {l['address'] or '-'} | {'; '.join(l['sources'])[:70]} | {'có lỗi' if l['label'] else 'không lỗi'} | {verdict} | {r.get('contract_p', '-')} | {fl or '-'} |")

(HERE / "summary.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False))
(HERE / "results_dappscan.md").write_text("\n".join(["# DAppSCAN: từng nhãn audit so với kết quả mô hình", "", "Dòng 'gốc' theo báo cáo audit; dòng 'flatten' là vị trí trong file eval/dappscan/flat/.", "",
    "| Lỗ hổng | File | Báo cáo audit | Solidity | Hàm (audit) | Dòng gốc | Dòng flatten | Kết quả | Hàm mô hình gắn cờ | p hợp đồng |", "|" + "---|" * 10, *res_d]) + "\n")
(HERE / "results_hard.md").write_text("\n".join(["# CGT: ca dương và ca âm khó có nhãn gán tay", "", "File nằm ở eval/generalization/hard/<lỗ hổng>/; nhãn và nguồn ở hard/labels.json.", "",
    "| Lỗ hổng | File | Địa chỉ | Nguồn nhãn | Nhãn chuyên gia | Kết quả | p hợp đồng | Hàm bị gắn cờ (dòng) |", "|" + "---|" * 8, *res_h]) + "\n")
(HERE / "results_adversarial.md").write_text("\n".join(["# Mã đối kháng: các hợp đồng đổi kết luận sau phép biến đổi giữ nguyên ngữ nghĩa", "", "File gốc và file biến đổi ở eval/generalization/adversarial/<lỗ hổng>/<phép>/.", "",
    "| Lỗ hổng | Phép biến đổi | File | Nhãn | Trước | Sau |", "|" + "---|" * 6, *res_a]) + "\n")

for vuln, s in summary.items():
    d, h = s["dappscan"], s["hard"]
    md += [f"## {VN[vuln]}", "", "### A. Dự án chưa thấy (DAppSCAN, nhãn từ báo cáo audit)", "",
           f"- {d['files']} file, dựng được đồ thị {pct(d['graph_built'], d['files'])}; theo phiên bản Solidity: {d['by_solidity']}.",
           f"- {d['overlap_with_train']['also_in_train']}/{d['overlap_with_train']['functions']} hàm ({d['overlap_with_train']['share']:.1%}) trùng nguyên văn với một hàm trong tập huấn luyện.",
           f"- {d['labels']} vị trí audit chỉ ra: " + "; ".join(f"{k}: {n}" for k, n in sorted(d["verdicts"].items(), key=lambda x: -x[1])) + ".",
           f"- Mô hình hiển thị {d['alerts_shown']} hàm bị gắn cờ, trong đó {d['alerts_matching_an_audit_label']} trùng một vị trí audit.", "",
           "### B. Hợp đồng lớn (cùng bộ DAppSCAN, chia theo kích thước sau flatten)", "",
           "| Kích thước | File | Dựng được đồ thị | Số hàm (trung vị) | Giây/file (trung vị) | Giây/file (lớn nhất) | Hàm dài hơn 512 token | Vị trí audit tìm được |", "|" + "---|" * 8]
    md += [f"| {k} | {x['files']} | {x['graph_built']} | {x['median_functions']} | {x['median_seconds']} | {x['max_seconds']} | {x['functions_over_512_tokens']} | {x['labels_found']} |" for k, x in s["size"].items()]
    a = s["adversarial"]
    md += ["", f"### C. Mã đối kháng ({a['originally_correct']}/{a['test_contracts']} hợp đồng test được xếp đúng trước khi biến đổi)", "",
           "| Phép biến đổi | Sinh ra | Không biên dịch được | So sánh được | Có lỗi → bị bỏ sót | Không lỗi → bị cảnh báo | Tỉ lệ đổi kết luận | Thay đổi p trung bình | Hàm bị gắn cờ (trước → sau) |", "|" + "---|" * 9]
    md += [f"| {t} | {x['generated']} | {x['did_not_compile']} | {x['compared']} | {x['vulnerable_now_missed']} | {x['safe_now_flagged']} | {x['flip_rate']:.1%} | {x['mean_abs_change_in_p']} | {x['flagged_functions_before_after']} |" for t, x in a["transforms"].items()]
    if "decoy" in a["transforms"]:
        md += ["", f"Hàm mồi nhử ZDecoy.info bị gắn cờ trong {a['transforms']['decoy']['decoy_function_flagged']} hợp đồng."]
    md += ["", "### D. Ca dương và ca âm khó (CGT, nhãn gán tay)", "",
           f"- {h['files']} hợp đồng, dựng được đồ thị {pct(h['graph_built'], h['files'])}; {h['overlap_with_train']['share']:.1%} số hàm trùng nguyên văn với tập huấn luyện.",
           f"- Ca dương: phát hiện {pct(h['found'], h['positives'])}, bỏ sót {h['missed']}.",
           f"- Ca âm khó (không lỗi nhưng có cú pháp nhạy cảm): cảnh báo nhầm {pct(h['false_alarms'], h['hard_negatives'])}.",
           f"- Precision {h['precision']}, recall {h['recall']}.", "", "| Nguồn nhãn | Phát hiện | Bỏ sót | Cảnh báo nhầm | Đúng (không cảnh báo) |", "|---|---|---|---|---|"]
    md += [f"| {k} | {x['found']} | {x['missed']} | {x['false_alarm']} | {x['cleared']} |" for k, x in h["by_source"].items()] + [""]
analysis = HERE / "analysis.md"
md += analysis.read_text().splitlines() if analysis.exists() else []
(HERE / "report.md").write_text("\n".join(md) + "\n")
print(json.dumps(summary, indent=1, ensure_ascii=False))
