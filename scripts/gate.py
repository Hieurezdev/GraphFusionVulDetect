"""Decide whether a retrained checkpoint may replace the active one (step 1.9 of docs/KE_HOACH_TRIEN_KHAI.md).

Scores the active model and the candidate on (a) the standard test set and (b) the feedback holdout of the candidate's
dataset snapshot, contract by contract. The candidate passes only if:
  1. the holdout has at least --min-holdout contracts (small sets make F1 differences noise);
  2. on both sets, the F1 of EACH class drops by at most --max-drop;
  3. on the test set, McNemar does not show the candidate significantly worse (p < --alpha with fewer correct).
--promote activates a passing candidate in models/registry.json (the old one stays in history for rollback).
Writes report.md / gate.json next to the candidate.
Usage: uv run python scripts/gate.py timestamp models/timestamp/<version> [--promote]
"""
import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import rootutils

rootutils.setup_root(__file__, indicator=".project-root", pythonpath=True)
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "eval/retrain"))
import torch  # noqa: E402

from common import REPO, SPECS, index, load_item, mcnemar, new_model, predict, prf  # noqa: E402
from src.services import model_registry  # noqa: E402


def load_model(vuln, path):
    m = new_model(vuln)
    m.load_state_dict(torch.load(REPO / path, map_location="cpu"))
    return m.eval()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vuln")
    ap.add_argument("candidate")
    ap.add_argument("--max-drop", type=float, default=0.02)
    ap.add_argument("--min-holdout", type=int, default=20)
    ap.add_argument("--alpha", type=float, default=0.05)
    ap.add_argument("--promote", action="store_true")
    ap.add_argument("--shadow", action="store_true", help="put a passing candidate in shadow mode instead of activating it")
    args = ap.parse_args()
    cand_dir = REPO / args.candidate
    meta = json.loads((cand_dir / "meta.json").read_text(encoding="utf-8"))
    snap = json.loads((REPO / meta["dataset"]).read_text(encoding="utf-8")) if not Path(meta["dataset"]).is_absolute() else json.loads(Path(meta["dataset"]).read_text(encoding="utf-8"))
    current_path = model_registry.active_graph_path(args.vuln, SPECS[args.vuln]["deployed"])
    current, candidate = load_model(args.vuln, current_path), load_model(args.vuln, cand_dir / "graph.pt")

    sets = {"test": [load_item(r) for r in index(args.vuln, "Test") if r["status"] == "ok"],
            "feedback_holdout": [load_item(r) for r in snap["feedback_holdout"]]}
    results, checks = {}, []
    for name, items in sets.items():
        y = [i["y"] for i in items]
        pc, pn = predict(current, items, args.vuln), predict(candidate, items, args.vuln)
        a_only, b_only, p = mcnemar(y, pc, pn)
        results[name] = {"n": len(items), "current": prf(y, pc), "candidate": prf(y, pn),
                         "mcnemar": {"current_right_only": a_only, "candidate_right_only": b_only, "p": p}}
        for cls in ("non_vulnerable", "vulnerable"):
            drop = results[name]["current"][cls]["F1"] - results[name]["candidate"][cls]["F1"]
            checks.append((f"{name}: F1 {cls} drops by at most {args.max_drop}", drop <= args.max_drop + 1e-9,
                           f"{results[name]['current'][cls]['F1']:.3f} -> {results[name]['candidate'][cls]['F1']:.3f}"))
    checks.insert(0, (f"feedback holdout has at least {args.min_holdout} contracts", results["feedback_holdout"]["n"] >= args.min_holdout,
                      str(results["feedback_holdout"]["n"])))
    t = results["test"]["mcnemar"]
    worse = t["candidate_right_only"] < t["current_right_only"] and t["p"] < args.alpha
    checks.append((f"test: McNemar does not show the candidate significantly worse (alpha {args.alpha})", not worse,
                   f"current-only {t['current_right_only']}, candidate-only {t['candidate_right_only']}, p = {t['p']}"))
    accepted = all(ok for _, ok, _ in checks)

    lines = [f"# Cổng thay mô hình – {args.vuln}", "",
             f"- Ứng viên: `{args.candidate}` ({meta['mode']}, epoch chọn {meta['selected_epoch']}, macro-F1 validation {meta['validation_macro_f1']}, "
             f"{meta['train_contracts']} hợp đồng huấn luyện, {meta['train_seconds']} giây trên CPU)",
             f"- Đang chạy: `{current_path}`",
             f"- Dữ liệu: `{meta['dataset']}` (sha256 {snap['sha256'][:12]}…): {snap['counts']}", "",
             f"## Kết luận: {'**CHẤP NHẬN**' if accepted else '**TỪ CHỐI**'}", "",
             "| Điều kiện | Đạt | Giá trị |", "|---|---|---|"]
    lines += [f"| {c} | {'có' if ok else '**không**'} | {v} |" for c, ok, v in checks]
    lines += ["", "| Tập | n | Hệ thống | F1 không lỗi | F1 có lỗi | Macro-F1 | Accuracy |", "|---|---|---|---|---|---|---|"]
    for name, r in results.items():
        for who in ("current", "candidate"):
            m = r[who]
            lines.append(f"| {name} | {r['n']} | {'đang chạy' if who == 'current' else 'ứng viên'} | {m['non_vulnerable']['F1']} | {m['vulnerable']['F1']} | {m['macro_F1']} | {m['accuracy']} |")
    promoted = None
    if accepted and args.shadow:
        promoted = model_registry.set_shadow(args.vuln, str((cand_dir / "graph.pt").relative_to(REPO)).replace("\\", "/"),
                                             report=str((cand_dir / "report.md").relative_to(REPO)).replace("\\", "/"))
        lines += ["", "Đã đưa vào chế độ chạy bóng: chấm song song, không hiển thị. Xem `scripts/shadow_report.py` trước khi kích hoạt."]
    elif accepted and args.promote:
        promoted = model_registry.promote(args.vuln, str((cand_dir / "graph.pt").relative_to(REPO)).replace("\\", "/"),
                                          report=str((cand_dir / "report.md").relative_to(REPO)).replace("\\", "/"), default=SPECS[args.vuln]["deployed"])
        lines += ["", f"Đã kích hoạt trong `models/registry.json`; bản trước ở `history` để quay lại. Khởi động lại backend để dùng. "
                      "Nhiệt độ hiệu chỉnh của checkpoint cũ không áp dụng cho checkpoint mới (cần chạy lại bước 1.7)."]
    (cand_dir / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (cand_dir / "gate.json").write_text(json.dumps({"accepted": accepted, "checks": checks, "results": results, "promoted": promoted,
                                                    "decided_at": datetime.now(timezone.utc).isoformat()}, indent=1, ensure_ascii=False), encoding="utf-8")
    print("\n".join(lines))
    return 0 if accepted else 2


if __name__ == "__main__":
    sys.exit(main())
