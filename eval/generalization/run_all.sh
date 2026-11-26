#!/usr/bin/env bash
# Scores every list in eval/generalization/lists with the matching model. Resumable. Run from the repo root.
# Optional argument: timestamp or reentrancy, to run only that half (the two halves can run side by side).
set -uo pipefail
IMAGE=${IMAGE:-scanguard-backend}; HF=${HF_HOME:-$HOME/.cache/huggingface}
mkdir -p eval/generalization/out
for list in eval/generalization/lists/*${1:-}*.txt; do
  name=$(basename "$list" .txt)
  case "$name" in *timestamp*) vuln=timestamp;; *) vuln=reentrancy;; esac
  docker run --rm --gpus all -v "$PWD":/repo:ro -v "$PWD/eval/generalization/out":/repo/eval/generalization/out -v "$HF":/hf-cache -e HF_HOME=/hf-cache \
    -e PYTHONPATH=/graphfusion -w /graphfusion --entrypoint .venv/bin/python "$IMAGE" /repo/eval/generalization/score.py "$vuln" "$list" "eval/generalization/out/$name.jsonl" 2>&1 | grep -a -E '^@@|encoder on|Traceback|Error:' | grep -a -v 'Invalid solc compilation'
done
