FROM python:3.12-slim-trixie

RUN apt-get update && apt-get install -y --no-install-recommends curl build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /graphfusion
ENV PATH=/graphfusion/.venv/bin:$PATH

COPY uv.lock pyproject.toml .python-version ./
# shortcut: dgl==2.0.0 has no Linux wheel on PyPI and data.dgl.ai is unreachable from the server; dgl 2.1.0
# runs on torch 2.8 with old setuptools + torchdata 0.7.1 and graphbolt (unused) skipped. Drop this once the lock pins a Linux-installable dgl.
RUN uv sync --frozen --no-dev --no-install-package dgl \
    && uv pip install --no-deps dgl==2.1.0 torchdata==0.7.1 "setuptools<70" \
    # Slither 0.8.0 (the lock's pin) cannot parse custom errors or user-defined value types, i.e. most 0.8.x tokens. On the paper's
    # test sets 0.9.6 builds the same nodes and gives the same verdicts but one (eval/generalization/out/slither096).
    && uv pip install slither-analyzer==0.9.6 \
    # peft loads LoRA adapters such as the optional local LLM (LOCAL_LLM_MODEL in .env).
    && uv pip install peft==0.17.1 \
    && sed -i 's/^load_graphbolt()$/try:\n    load_graphbolt()\nexcept (FileNotFoundError, ImportError):\n    pass  # no torch 2.8 build; graphbolt is unused here/' \
       .venv/lib/python3.10/site-packages/dgl/graphbolt/__init__.py

# Slither needs one solc per pragma version; graph_converter looks them up in ge-sc-artifacts/solc-X/solc-X.
RUN B=https://binaries.soliditylang.org/linux-amd64 \
    && curl -fsSL $B/list.json | python -c "import json,sys;[print(v,f) for v,f in json.load(sys.stdin)['releases'].items()]" \
    | while read v f; do mkdir -p ge-sc-artifacts/solc-$v \
        && curl -fsSL "$B/$f" -o ge-sc-artifacts/solc-$v/solc-$v && chmod +x ge-sc-artifacts/solc-$v/solc-$v || exit 1; done \
    && test -x ge-sc-artifacts/solc-0.4.24/solc-0.4.24

COPY .project-root ./
COPY src ./src

EXPOSE 8000

CMD ["python", "-m", "src.main"]
