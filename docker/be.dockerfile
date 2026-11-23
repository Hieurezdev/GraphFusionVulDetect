# The trained CPU pipeline and the fixed Solidity binaries target Linux x86_64.
FROM ethereum/solc:0.4.24 AS solc424
FROM ethereum/solc:0.8.0 AS solc800
FROM ethereum/solc:0.8.20 AS solc820
FROM python:3.10-slim-bookworm
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources \
    && apt-get -o Acquire::https::Timeout=30 -o Acquire::Retries=3 update && apt-get install -y --no-install-recommends libgomp1 util-linux \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir uv==0.8.15
WORKDIR /graphfusion
ENV SOLIDITY_NATIVE=1 UV_LINK_MODE=copy PATH="/graphfusion/.venv/bin:$PATH" PYTHONUNBUFFERED=1 PYTHONPATH=/graphfusion
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --python /usr/local/bin/python
COPY --from=solc424 /usr/bin/solc /graphfusion/ge-sc-artifacts/solc-0.4.24/solc-0.4.24
COPY --from=solc800 /usr/bin/solc /graphfusion/ge-sc-artifacts/solc-0.8.0/solc-0.8.0
COPY --from=solc820 /usr/bin/solc /graphfusion/ge-sc-artifacts/solc-0.8.20/solc-0.8.20
COPY src ./src
RUN useradd --uid 10001 --create-home app && mkdir storage && chown app:app storage
USER app
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "src.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
