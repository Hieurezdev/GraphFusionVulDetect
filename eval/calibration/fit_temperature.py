"""Fit the contract-level temperature of each model and report ECE honestly (step 1.7 of docs/KE_HOACH_TRIEN_KHAI.md).

Input: eval/calibration/probs_<vuln>_test.jsonl (collect_probs.py). The team's validation graphs are not available on
this machine, so the test set is used, with 2-fold cross-fitting for the reported numbers: T is fitted on one half and
ECE measured on the other half, then the halves swap. The temperature written for the product is then fitted on the
whole set. Temperature scaling never changes the predicted class, so accuracy and F1 are unchanged by construction.

Writes src/infrastructure/analysis_model/calibration.json and eval/calibration/report.md.
"""
import json
import math
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from calib_utils import ece, fit_t  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "eval/calibration"
CALIB = REPO / "src/infrastructure/analysis_model/calibration.json"


def p_from_logits(z, t=1.0):
    d = (z[1] - z[0]) / t
    return 1 / (1 + math.exp(-d))


def bins(before, after, labels, n=5):
    """Reliability table, binned by the confidence shown before calibration: count, mean confidence before,
    accuracy (unchanged by calibration), and mean confidence after calibration of the same contracts."""
    conf = lambda p: max(p, 1 - p)
    rows = []
    for b in range(n):
        lo, hi = 0.5 + b * 0.5 / n, 0.5 + (b + 1) * 0.5 / n
        idx = [i for i, p in enumerate(before) if lo <= conf(p) < hi or (b == n - 1 and conf(p) >= hi)]
        if idx:
            rows.append((f"{lo:.1f}–{hi:.1f}", len(idx),
                         sum(conf(before[i]) for i in idx) / len(idx),
                         sum((before[i] >= 0.5) == bool(labels[i]) for i in idx) / len(idx),
                         sum(conf(after[i]) for i in idx) / len(idx)))
    return rows


def fit_logit_t(zs, ys):
    """Same NLL fit as calib_utils.fit_t, on probabilities computed from the logits."""
    return fit_t([p_from_logits(z) for z in zs], ys)


def main():
    calib = json.loads(CALIB.read_text(encoding="utf-8")) if CALIB.exists() else {}
    lines = [f"# Hiệu chỉnh độ tin cậy (bước 1.7)", "",
             f"Chạy ngày {date.today().isoformat()} trên máy chỉ có CPU; xác suất tính lại bằng `collect_probs.py` với đúng mô hình đang chạy.",
             "Tập validation của nhóm không có sẵn ở máy này, nên dùng tập test với **cross-fitting 2 phần**: nhiệt độ tìm trên một nửa, ECE đo trên nửa còn lại, rồi đổi vai. "
             "Nhiệt độ đưa vào sản phẩm được tìm trên toàn tập test. Hiệu chỉnh nhiệt độ không đổi lớp dự đoán, nên accuracy và F1 không đổi.", ""]
    for vuln in ("timestamp", "reentrancy"):
        path = OUT / f"probs_{vuln}_test.jsonl"
        if not path.exists():
            continue
        rows = [json.loads(l) for l in open(path, encoding="utf-8")]
        ok = sorted((r for r in rows if r["status"] == "ok"), key=lambda r: r["file"])
        zs, ys = [r["logits"] for r in ok], [r["label"] for r in ok]
        p0 = [p_from_logits(z) for z in zs]
        acc = sum((p >= 0.5) == bool(y) for p, y in zip(p0, ys)) / len(ys)
        # 2-fold cross-fitting, folds stratified by label (alternate within each class)
        folds = [[], []]
        for label in (0, 1):
            members = [i for i, y in enumerate(ys) if y == label]
            for k, i in enumerate(members):
                folds[k % 2].append(i)
        held_before, held_after, ts = [], [], []
        for k in (0, 1):
            fit_idx, eval_idx = folds[k], folds[1 - k]
            t = fit_logit_t([zs[i] for i in fit_idx], [ys[i] for i in fit_idx])
            ts.append(t)
            held_before += [(p0[i], ys[i]) for i in eval_idx]
            held_after += [(p_from_logits(zs[i], t), ys[i]) for i in eval_idx]
        ece_before = ece([p for p, _ in held_before], [y for _, y in held_before])
        ece_after = ece([p for p, _ in held_after], [y for _, y in held_after])
        t_fit = fit_logit_t(zs, ys)
        # Applied only if it helps on data it was not fitted on: otherwise the model keeps T = 1 (no change).
        applied = ece_after < ece_before
        t_all = t_fit if applied else 1.0
        p_all = [p_from_logits(z, t_all) for z in zs]
        version = ok[0]["model_version"]
        calib[vuln] = {"model_version": version, "temperature": round(t_all, 4), "fitted_temperature": round(t_fit, 4), "applied": applied,
                       "fitted_on": f"test set ({len(ys)} contracts), {date.today().isoformat()}",
                       "ece_before_crossfit": round(ece_before, 4), "ece_after_crossfit": round(ece_after, 4)}
        mean_conf = sum(max(p, 1 - p) for p in p0) / len(p0)
        lines += [f"## {vuln}", "",
                  f"- {len(ys)} hợp đồng chấm được / {len(rows)} (còn lại không dựng được đồ thị). Accuracy {acc:.3f}, độ tin cậy trung bình trước hiệu chỉnh {mean_conf:.3f}.",
                  f"- Nhiệt độ hai lần cross-fit: {ts[0]:.3f} và {ts[1]:.3f}; tìm trên toàn tập: {t_fit:.3f}.",
                  f"- **ECE trên nửa giữ riêng: {ece_before:.3f} → {ece_after:.3f}.**",
                  (f"- **Áp dụng T = {t_all:.3f}** ({'mô hình tự tin thấp hơn thực tế, hiệu chỉnh làm xác suất sắc hơn' if t_all < 1 else 'mô hình tự tin quá mức, hiệu chỉnh làm xác suất mềm hơn'})."
                   if applied else "- **Không áp dụng** (giữ T = 1): hiệu chỉnh làm ECE trên phần giữ riêng tệ hơn, và hai nhiệt độ cross-fit chênh nhau nhiều, tức ước lượng không ổn định trên số mẫu này."), "",
                  "| Khoảng độ tin cậy | Số hợp đồng | Độ tin cậy TB (trước) | Accuracy | Độ tin cậy TB (sau) |", "|---|---|---|---|---|"]
        for label, n, conf_before, acc_b, conf_after in bins(p0, p_all, ys):
            lines.append(f"| {label} | {n} | {conf_before:.3f} | {acc_b:.3f} | {conf_after:.3f} |")
        lines.append("")
    CALIB.write_text(json.dumps(calib, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (OUT / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(calib, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
