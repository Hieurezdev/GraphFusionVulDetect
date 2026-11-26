#!/usr/bin/env bash
# Reproduces eval/ablation/report.md. Run from the repo root.
#   SRC   = .../SourceCodeSyntaxDataset unpacked from the Kaggle archive (assets/datasets/archive (3).zip)
#   PY    = python of an env with PyTorch + a CUDA build of DGL (versions: requirements-gpu.txt; DGL from the dglteam conda channel or data.dgl.ai)
#   IMAGE = the backend image (docker/be.prod.dockerfile), which carries Slither, the solc binaries and the product's graph step
set -euo pipefail
: "${SRC:?}" "${PY:?}"; IMAGE=${IMAGE:-scanguard-backend}; HF=${HF_HOME:-$HOME/.cache/huggingface}
mkdir -p eval/ablation/runs assets/datasets/SourceCodeSyntaxDatasetFull
backend() { docker run --rm --gpus all -v "$PWD":/repo:ro -v "$PWD/assets/datasets/SourceCodeSyntaxDatasetFull":/repo/assets/datasets/SourceCodeSyntaxDatasetFull \
  -v "$PWD/eval/ablation/runs":/repo/eval/ablation/runs -v "$SRC":/src:ro -v "$HF":/hf-cache -e HF_HOME=/hf-cache -e PYTHONPATH=/graphfusion \
  -w /graphfusion --entrypoint .venv/bin/python "$IMAGE" /repo/eval/ablation/ablation.py "$@"; }
for v in timestamp reentrancy; do
  backend build "$v"; backend build "$v"      # second pass retries files that failed on a busy GPU
  backend baselines "$v"
  REPO="$PWD" DGLBACKEND=pytorch "$PY" eval/ablation/ablation.py base "$v"
  for k in full no_graph no_semantics base_encoder; do REPO="$PWD" DGLBACKEND=pytorch "$PY" eval/ablation/ablation.py train "$v" "$k"; done
done
REPO="$PWD" DGLBACKEND=pytorch "$PY" eval/ablation/ablation.py train timestamp deployed
REPO="$PWD" "$PY" eval/ablation/ablation.py report
