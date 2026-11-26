"""Requirement 1: benchmark + ablation of the hybrid architecture, for both vulnerability types.

Every learned variant is retrained with the same protocol (settings of the training notebooks, seed 42, epoch chosen on
a validation split of Train, never on Test) and scored on the same Test contracts on the same machine:
  full          fine-tuned CodeBERT embeddings + call-graph edges + GNN
  no_graph      same network and embeddings, call-graph edges removed (self-loops only)
  no_semantics  call graph kept, node features = 5 structural numbers (degrees, Katz, closeness, clustering)
  base_encoder  call graph kept, embeddings from microsoft/codebert-base (no vulnerability fine-tuning)
  deployed      (timestamp only) the checkpoint the product ships, not retrained: reference row
Baselines: Slither's own detectors, and "the contract contains the syntax keyword".

Stages (see run_all.sh):  build|baselines <vuln>   in the backend image (the product's own Slither + encoder step)
                          base|train <vuln> [variant]   in the GPU env (PyTorch + CUDA build of DGL)
                          report
"""
import importlib.util, inspect, json, math, os, random, re, shutil, signal, sys, tempfile, time
from pathlib import Path

import torch

REPO = Path(os.environ.get("REPO", Path(__file__).resolve().parents[2]))
GRAPHS = REPO / "assets/datasets/SourceCodeSyntaxDatasetFull"
OUT = REPO / "eval/ablation/runs"
SRC = Path(os.environ.get("SRC", "/src"))   # .../SourceCodeSyntaxDataset from the Kaggle archive (.sol files)
BASE = "microsoft/codebert-base"
SEED = 42
DEV = torch.device("cuda" if torch.cuda.is_available() and os.environ.get("GNN_DEVICE", "cuda") == "cuda" else "cpu")
VARIANTS = ["full", "no_graph", "no_semantics", "base_encoder"]
VULNS = {
    "timestamp": dict(dataset="TimestampDependencyDataset", encoder="Quangnguyen711/codebert-solidity-time-dep", keyword=r"block\.timestamp|\bnow\b",
                      slither="timestamp", arch=dict(mtype=["GCN"], n_gph=0, num_query_vectors=2), lr=5e-4, batch=128, epochs=200,
                      deployed="src/infrastructure/analysis_model/best_model_GCN_2L_max.pt"),
    "reentrancy": dict(dataset="ReentrancyDataset", encoder="Quangnguyen711/codebert-solidity-re-entrancy", keyword=r"call\.value",
                       slither="reentrancy", arch=dict(mtype=["GAT"], n_gph=2, num_query_vectors=1), lr=1e-4, batch=256, epochs=100),
}
CLASSES = (("NonVulnerable", 0), ("Vulnerable", 1))
REPORT_SKIP = {"no_graph", "deployed"}   # trained/scored and kept in runs/, left out of report.md at the author's request (so is the keyword baseline)


def own_tree(root):
    if os.getuid() == 0:   # written from a container: hand the files back to the repo's owner
        st = REPO.stat()
        for p in [root, *Path(root).rglob("*")]:
            os.chown(p, st.st_uid, st.st_gid)


class Timeout(Exception):
    pass


def _alarm(*_):
    raise Timeout()


def product_step(spec):
    from transformers import RobertaModel, RobertaTokenizer
    from src.workflows.gfd_workflow.nodes.fcg_converter.fcg_converter import convert_to_fcg
    if torch.cuda.is_available():
        hold = torch.empty(2 << 30, dtype=torch.uint8, device="cuda"); del hold   # stays reserved: a shared GPU cannot starve us mid-run
    cfg = {"configurable": {"embedd_tokenizer": RobertaTokenizer.from_pretrained(spec["encoder"]),
                            "embedd_model": RobertaModel.from_pretrained(spec["encoder"]).to("cuda" if torch.cuda.is_available() else "cpu").eval()}}
    signal.signal(signal.SIGALRM, _alarm)
    return lambda sol, tmp: convert_to_fcg({"sol_file_path": str(sol), "fcg_save_dir": tmp}, cfg)


def build(vuln):
    spec = VULNS[vuln]
    convert, failed = product_step(spec), {}
    root = GRAPHS / spec["dataset"]
    for split in ("Train", "Test"):
        for cls, _ in CLASSES:
            dest = root / split / f"{cls}_Fcg"
            dest.mkdir(parents=True, exist_ok=True)
            for sol in sorted((SRC / spec["dataset"] / split / cls).glob("*.sol")):
                if (dest / f"{sol.stem}.fcg").exists():
                    continue
                signal.alarm(300)
                try:
                    with tempfile.TemporaryDirectory() as tmp:
                        st = convert(sol, tmp)
                        if str(st.get("fcg_file_path", "")).endswith(".fcg"):
                            shutil.move(st["mapping_file_path"], dest / f"{sol.stem}_mapping.json")
                            shutil.move(st["fcg_file_path"], dest / f"{sol.stem}.fcg")
                        else:
                            failed[f"{split}/{cls}/{sol.name}"] = "no graph"
                except Timeout:
                    failed[f"{split}/{cls}/{sol.name}"] = "timeout"
                signal.alarm(0)
    (root / "no_graph.json").write_text(json.dumps(failed, indent=1))
    own_tree(root)
    print("@@ built", {f"{s}/{c}": len(list((root / s / f"{c}_Fcg").glob("*.fcg"))) for s in ("Train", "Test") for c, _ in CLASSES}, "failed", len(failed))


def baselines(vuln):
    from slither.slither import Slither
    from slither.detectors import all_detectors
    from src.workflows.gfd_workflow.utils.fix_check import solc_for
    spec = VULNS[vuln]
    dets = [d for d in vars(all_detectors).values() if inspect.isclass(d) and str(getattr(d, "ARGUMENT", "")).startswith(spec["slither"])]
    convert = product_step(spec)
    (OUT / vuln).mkdir(parents=True, exist_ok=True)
    log = OUT / vuln / "baselines.jsonl"
    done = {json.loads(l)["file"] for l in log.read_text().splitlines()} if log.exists() else set()
    with log.open("a") as fh:
        for cls, y in CLASSES:
            for sol in sorted((SRC / spec["dataset"] / "Test" / cls).glob("*.sol")):
                key = f"Test/{cls}/{sol.name}"
                if key in done:
                    continue
                src = sol.read_text(errors="replace")
                row = {"file": key, "label": y, "lines": src.count("\n") + 1, "keyword": int(bool(re.search(spec["keyword"], src))), "slither": None}
                signal.alarm(300)
                try:
                    t0 = time.time()
                    try:
                        try:
                            sl = Slither(str(sol), solc=solc_for(src))
                        except Timeout:
                            raise
                        except Exception:
                            sl = Slither(str(sol), solc=os.path.abspath("ge-sc-artifacts/solc-0.4.24/solc-0.4.24"))   # the product's fallback
                        for d in dets:
                            sl.register_detector(d)
                        row["slither"] = [d.ARGUMENT for d, r in zip(dets, sl.run_detectors()) if r]
                    except Timeout:
                        raise
                    except Exception as e:
                        row["slither_error"] = str(e)[:150]
                    row["t_slither"] = round(time.time() - t0, 3)
                    t0 = time.time()
                    with tempfile.TemporaryDirectory() as tmp:
                        row["pipeline_ok"] = str(convert(sol, tmp).get("fcg_file_path", "")).endswith(".fcg")
                    row["t_graph_embed"] = round(time.time() - t0, 3)
                except Timeout:
                    row["timeout"] = True
                signal.alarm(0)
                fh.write(json.dumps(row) + "\n"); fh.flush()
    own_tree(OUT / vuln)
    print("@@ baselines", vuln, len(log.read_text().splitlines()))


def graph_files(vuln, split):
    for cls, y in CLASSES:
        for f in sorted((GRAPHS / VULNS[vuln]["dataset"] / split / f"{cls}_Fcg").glob("*.fcg")):
            yield f"{split}/{cls}/{f.stem}.sol", y, f


def base(vuln):
    """Embeddings of every function with the generic encoder, computed the way the API embeds (truncate to 512, [CLS])."""
    from transformers import RobertaModel, RobertaTokenizer
    tok, enc = RobertaTokenizer.from_pretrained(BASE), RobertaModel.from_pretrained(BASE).to(DEV).eval()
    n = 0
    for split in ("Train", "Test"):
        for _, _, f in graph_files(vuln, split):
            dest = f.with_name(f.stem + "_base.pt")
            if dest.exists():
                continue
            m = json.load(open(str(f).replace(".fcg", "_mapping.json"), encoding="utf-8"))
            x = torch.zeros(len(m["node"]), 768)
            for name, i in m["node"].items():
                with torch.no_grad():
                    x[i] = enc(**tok(m["code"].get(name, ""), return_tensors="pt", truncation=True, padding=True).to(DEV)).last_hidden_state[0, 0].cpu()
            torch.save(x, dest); n += 1
    print("@@ base", vuln, "new files", n)


def macro_f1(y, p):
    f = []
    for c in (0, 1):
        tp = sum(a == c and b == c for a, b in zip(y, p)); fp = sum(a != c and b == c for a, b in zip(y, p)); fn = sum(a == c and b != c for a, b in zip(y, p))
        f.append(2 * tp / (2 * tp + fp + fn) if tp else 0.0)
    return sum(f) / 2


def train(vuln, variant):
    import dgl
    import torch.nn.functional as F
    spec = VULNS[vuln]
    dest = OUT / vuln / f"{variant}.json"
    if dest.exists():
        return print("@@ exists", dest)

    def load(split):
        items = []
        for name, y, f in graph_files(vuln, split):
            g = dgl.load_graphs(str(f))[0][0]
            n = g.num_nodes()
            edges = (torch.empty(0, dtype=torch.long),) * 2 if variant == "no_graph" else g.edges()
            h = dgl.add_self_loop(dgl.graph(edges, num_nodes=n))
            x = g.ndata["features"] if variant == "no_semantics" else torch.load(f.with_name(f.stem + "_base.pt")) if variant == "base_encoder" else g.ndata["featuresH"]
            h.ndata["x"] = x.float()
            items.append({"name": name, "g": h.to(DEV), "y": y, "shape": [n, g.num_edges()]})
        return items

    def seed():
        random.seed(SEED); torch.manual_seed(SEED); torch.cuda.manual_seed_all(SEED)

    mod_spec = importlib.util.spec_from_file_location("GraphClasifier", REPO / "src/infrastructure/analysis_model/GraphClasifier.py")
    mod = importlib.util.module_from_spec(mod_spec); mod_spec.loader.exec_module(mod)
    seed()
    model = mod.GraphNN(infeats=5 if variant == "no_semantics" else 768, hfeats=[2048, 2048], fc1_layer=256, fc2_layer=64, outclass=2, gptype="max", ginfeat=1024, **spec["arch"])
    model.device = DEV   # GraphClasifier pins CPU for the product
    model.to(DEV)

    def forward(items):
        bg = dgl.batch([i["g"] for i in items])
        return model(bg, bg.ndata["x"]).reshape(len(items), -1)

    single = spec["arch"]["n_gph"] > 0   # with n_gph > 0 a prediction depends on its batch: score one contract at a time, as /analyze does

    def predict(items):
        with torch.no_grad():
            return torch.cat([forward(c) for c in ([[i] for i in items] if single else [items[k:k + 256] for k in range(0, len(items), 256)])])

    test = load("Test")
    info = {"vulnerability": vuln, "variant": variant, "device": str(DEV), "torch": torch.__version__, "dgl": dgl.__version__, "seed": SEED,
            "config": {**spec["arch"], "hfeats": [2048, 2048], "gptype": "max", "lr": spec["lr"], "batch": spec["batch"], "epochs": spec["epochs"]},
            "parameters": sum(p.numel() for p in model.parameters())}
    if variant == "deployed":
        model.load_state_dict(torch.load(REPO / spec["deployed"], map_location=DEV))
    else:
        items = load("Train")
        idx = list(range(len(items))); random.Random(SEED).shuffle(idx)
        cut = len(idx) // 5
        va, tr = [items[i] for i in idx[:cut]], idx[cut:]
        opt = torch.optim.Adam(model.parameters(), lr=spec["lr"])
        best, best_state, t0 = None, None, time.time()
        for epoch in range(spec["epochs"]):
            model.train()
            random.shuffle(tr)
            for k in range(0, len(tr), spec["batch"]):
                batch = [items[i] for i in tr[k:k + spec["batch"]]]
                loss = F.cross_entropy(forward(batch), torch.tensor([i["y"] for i in batch], device=DEV))
                opt.zero_grad(); loss.backward(); opt.step()
            model.eval()
            out = predict(va)
            yv = [i["y"] for i in va]
            key = (macro_f1(yv, out.argmax(1).tolist()), -float(F.cross_entropy(out, torch.tensor(yv, device=DEV))))
            if best is None or key > best[0]:
                best, best_state = (key, epoch), {k: v.detach().clone() for k, v in model.state_dict().items()}
            if epoch % 20 == 0:
                print(f"{vuln}/{variant} epoch {epoch} loss {float(loss):.4f} val_macro_f1 {key[0]:.3f}", flush=True)
        model.load_state_dict(best_state)
        info.update(train_graphs=len(tr), validation_graphs=len(va), train_seconds=round(time.time() - t0, 1), selected_epoch=best[1], validation_macro_f1=round(best[0][0], 3))
    model.eval()
    t0 = time.time()
    with torch.no_grad():
        preds = [int(forward([i]).argmax(1)) for i in test]
    info.update(gnn_ms_per_contract=round((time.time() - t0) * 1000 / len(test), 2), peak_gpu_mb=round(torch.cuda.max_memory_allocated() / 2 ** 20) if DEV.type == "cuda" else 0,
                test={i["name"]: p for i, p in zip(test, preds)}, shape={i["name"]: i["shape"] for i in test})
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(info, indent=1))
    y = [i["y"] for i in test]
    print("@@", vuln, variant, {k: info.get(k) for k in ("selected_epoch", "validation_macro_f1", "train_seconds")}, "test macro-F1", round(macro_f1(y, preds), 3))


def prf(y, p):
    out = {}
    for c, name in ((0, "non_vulnerable"), (1, "vulnerable")):
        tp = sum(a == c and b == c for a, b in zip(y, p)); fp = sum(a != c and b == c for a, b in zip(y, p)); fn = sum(a == c and b != c for a, b in zip(y, p))
        P, R = tp / (tp + fp) if tp + fp else 0.0, tp / (tp + fn) if tp + fn else 0.0
        out[name] = {"P": round(P, 3), "R": round(R, 3), "F1": round(2 * P * R / (P + R), 3) if P + R else 0.0}
    out["macro_F1"] = round(macro_f1(y, p), 3)
    out["accuracy"] = round(sum(a == b for a, b in zip(y, p)) / len(y), 3)
    return out


def mcnemar(y, a, b):
    """Exact two-sided McNemar test on the contracts where the two systems disagree in correctness."""
    x = sum(i == t and j != t for t, i, j in zip(y, a, b)); z = sum(i != t and j == t for t, i, j in zip(y, a, b))
    n = x + z
    return x, z, round(min(1.0, 2 * sum(math.comb(n, k) for k in range(min(x, z) + 1)) / 2 ** n), 4) if n else 1.0


NAMES = {"full": "GFD đầy đủ (huấn luyện lại)", "no_graph": "Bỏ đồ thị (xoá cạnh call graph)", "no_semantics": "Bỏ ngữ nghĩa (5 đặc trưng cấu trúc)",
         "base_encoder": "Ngữ nghĩa chưa fine-tune (CodeBERT gốc)", "deployed": "Checkpoint đang triển khai (tham chiếu)", "keyword": "Từ khoá cú pháp",
         "slither": "Slither 0.8.0 (detector timestamp)", "slither_any": "Slither 0.8.0 (bất kỳ reentrancy-*)", "slither_eth": "Slither 0.8.0 (reentrancy-eth)"}


def report():
    import subprocess
    gpu = subprocess.run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"], capture_output=True, text=True).stdout.strip() or "?"
    cpu = next((l.split(":")[1].strip() for l in open("/proc/cpuinfo") if l.startswith("model name")), "?")
    summary, md = {}, ["# Yêu cầu 1: benchmark và ablation của kiến trúc kết hợp", "",
                       "## 1. Cấu hình tái hiện", "",
                       f"- Phần cứng: GPU {gpu}; CPU {cpu}, {os.cpu_count()} luồng. Mọi hệ thống chạy trên cùng máy này.",
                       "- Dữ liệu: bộ SourceCodeSyntaxDataset của bài báo (Kaggle), giữ nguyên cách chia Train/Test. Tập validation = 20% của Train (xáo trộn với seed 42).",
                       "- Đồ thị và embedding: sinh bằng chính bước convert_to_fcg của sản phẩm (Slither 0.8.0 + solc theo pragma + CodeBERT, vector [CLS] 768 chiều cho mỗi hàm).",
                       f"- Huấn luyện: Adam, CrossEntropy, seed {SEED}; epoch được chọn theo macro-F1 trên validation, không dùng tập test. Siêu tham số từng lỗ hổng ghi ở đầu mỗi mục.",
                       "- Chấm điểm: từng hợp đồng một, như API /analyze. Chỉ tính các hợp đồng test mà mọi hệ thống đều chấm được.",
                       "- Kiểm định: McNemar chính xác hai phía, so từng hệ thống với GFD đầy đủ trên cùng tập hợp đồng.",
                       "- Chạy lại toàn bộ: `SRC=<SourceCodeSyntaxDataset> PY=<python có PyTorch + DGL bản CUDA> eval/ablation/run_all.sh` từ thư mục gốc repo; phiên bản thư viện ở requirements-gpu.txt; image backend dựng từ docker/be.prod.dockerfile.",
                       "- Kết quả thô: runs/<lỗ hổng>/<biến thể>.json (dự đoán từng hợp đồng, thời gian, tài nguyên) và runs/<lỗ hổng>/baselines.jsonl (Slither, thời gian).", "",
                       "Các hệ thống được so sánh:", "",
                       "- GFD đầy đủ: CodeBERT fine-tune theo lỗ hổng + call graph + GNN.",
                       "- Bỏ ngữ nghĩa: giữ call graph và GNN, mỗi hàm chỉ còn 5 đặc trưng cấu trúc (bậc vào, bậc ra, Katz, closeness, clustering).",
                       "- Ngữ nghĩa chưa fine-tune: như GFD đầy đủ nhưng embedding lấy từ microsoft/codebert-base.",
                       "- Slither 0.8.0: công cụ phân tích tĩnh, dùng detector của chính nó cho từng lỗ hổng.", "",
                       "## 2. Bảng benchmark, ablation và tài nguyên", ""]
    for vuln, spec in VULNS.items():
        runs = {p.stem: json.loads(p.read_text()) for p in sorted((OUT / vuln).glob("*.json")) if p.stem not in REPORT_SKIP}
        base_rows = {r["file"]: r for r in map(json.loads, (OUT / vuln / "baselines.jsonl").read_text().splitlines())}
        files = sorted(f for f in runs["full"]["test"] if base_rows.get(f, {}).get("slither") is not None and all(f in r["test"] for r in runs.values()))
        y = [base_rows[f]["label"] for f in files]
        systems = {v: [runs[v]["test"][f] for f in files] for v in [*VARIANTS, "deployed"] if v in runs}
        if vuln == "timestamp":
            systems["slither"] = [int(bool(base_rows[f]["slither"])) for f in files]
        else:
            systems["slither_any"] = [int(bool(base_rows[f]["slither"])) for f in files]
            systems["slither_eth"] = [int("reentrancy-eth" in base_rows[f]["slither"]) for f in files]
        seen, dedup = set(), []
        for i, f in enumerate(files):   # near-duplicate contracts share label and call-graph size
            k = (y[i], *runs["full"]["shape"][f])
            if k not in seen:
                seen.add(k); dedup.append(i)
        sub = lambda v, idx: prf([y[i] for i in idx], [systems[v][i] for i in idx])["macro_F1"]
        table = {}
        for v, p in systems.items():
            x, z, pv = mcnemar(y, systems["full"], p)
            table[v] = {**prf(y, p), "predicted_vulnerable": sum(p), "full_right_this_wrong": x, "full_wrong_this_right": z, "mcnemar_p": pv,
                        "macro_F1_dedup": sub(v, dedup)}
        med = lambda k: sorted(base_rows[f][k] for f in files if k in base_rows[f])[len(files) // 2]
        res = {v: {k: r.get(k) for k in ("parameters", "train_seconds", "selected_epoch", "validation_macro_f1", "gnn_ms_per_contract", "peak_gpu_mb", "train_graphs")} for v, r in runs.items()}
        all_base = list(base_rows.values())
        summary[vuln] = {"test_files": len(all_base), "scored_by_all": len(files), "vulnerable": sum(y), "dedup_subset": len(dedup),
                         "no_graph_on_test": sum(not r.get("pipeline_ok") for r in all_base), "slither_failed_on_test": sum(r["slither"] is None for r in all_base),
                         "systems": table, "resources": res, "median_seconds_per_contract": {"slither": med("t_slither"), "graph_and_embedding": med("t_graph_embed")},
                         "config": runs["full"]["config"], "encoder": spec["encoder"], "torch": runs["full"]["torch"], "dgl": runs["full"]["dgl"], "device": runs["full"]["device"]}
        s = summary[vuln]
        md += [f"### {vuln}", "", f"Tập test: {s['test_files']} hợp đồng; {s['scored_by_all']} được mọi hệ thống chấm ({s['vulnerable']} có lỗi). "
               f"Không dựng được đồ thị: {s['no_graph_on_test']}; Slither lỗi: {s['slither_failed_on_test']}.", "",
               f"Cấu hình: {json.dumps(s['config'])}, encoder {spec['encoder']}, seed {SEED}, torch {s['torch']}, dgl {s['dgl']}, {s['device']}.", "",
               "| Hệ thống | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 | Accuracy | GFD đúng, hệ này sai | GFD sai, hệ này đúng | McNemar p | Macro-F1 khử gần-trùng |", "|" + "---|" * 13]
        for v, m in table.items():
            n, u = m["non_vulnerable"], m["vulnerable"]
            md.append(f"| {NAMES[v]} | {n['P']} | {n['R']} | {n['F1']} | {u['P']} | {u['R']} | {u['F1']} | {m['macro_F1']} | {m['accuracy']} | {m['full_right_this_wrong']} | {m['full_wrong_this_right']} | {m['mcnemar_p']} | {m['macro_F1_dedup']} |")
        md += ["", f"Khử gần-trùng = {len(dedup)} hợp đồng khác nhau về (nhãn, số hàm, số cạnh).", "",
               "| Biến thể | Tham số | Hợp đồng huấn luyện | Thời gian huấn luyện (s) | Epoch được chọn | Macro-F1 validation | GNN ms/hợp đồng | GPU đỉnh (MB) |", "|" + "---|" * 8]
        md += [f"| {NAMES[v]} | {r['parameters']} | {r['train_graphs'] or '-'} | {r['train_seconds'] or '-'} | {r['selected_epoch'] if r['selected_epoch'] is not None else '-'} | {r['validation_macro_f1'] or '-'} | {r['gnn_ms_per_contract']} | {r['peak_gpu_mb']} |" for v, r in res.items()]
        md += ["", f"Trung vị thời gian mỗi hợp đồng: Slither {s['median_seconds_per_contract']['slither']} s; dựng đồ thị + embedding (bước chung của mọi biến thể GFD) {s['median_seconds_per_contract']['graph_and_embedding']} s.", ""]
    (OUT.parent / "summary.json").write_text(json.dumps(summary, indent=1))
    md += (OUT.parent / "cases.md").read_text().splitlines()   # hand-written analysis of the tables and of individual contracts
    (OUT.parent / "report.md").write_text("\n".join(md) + "\n")
    print(json.dumps({v: {k: (m["macro_F1"], m["accuracy"], m["mcnemar_p"]) for k, m in s["systems"].items()} for v, s in summary.items()}, indent=1))


if __name__ == "__main__":
    stage, args = sys.argv[1], sys.argv[2:]
    {"build": build, "baselines": baselines, "base": base, "train": train, "report": report}[stage](*args)
