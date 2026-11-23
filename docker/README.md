# Docker deployment

Run commands from the repository root. Docker Engine/Desktop with Compose v2+ is required. The backend targets **linux/amd64**, Python 3.10 and CPU inference; Apple Silicon uses emulation. Allow at least 6 GB of Docker memory and several GB of free disk space. No host Python or Node installation is needed.

## Configure and start

```sh
cp .env.example .env
# Edit .env: set GEMINI_API_KEY1, SECRET_KEY and JWT_SECRET.
# Generate each signing secret with: openssl rand -hex 32
chmod 600 .env
docker compose up --build -d --wait --wait-timeout 900
```

An existing private `.env` can be reused. The legacy `GEMINI_API_KEY1` name now holds the AstralX OpenAI-compatible API key. `BASE_URL`, `MODEL_NAME` and `CHATBOT_MAX_TOKENS` are read at runtime. Credentials never belong in frontend build arguments or image layers.

Open **http://localhost:8080**. Set `WEB_PORT=18080` when port 8080 is already occupied. Only the web port is published, bound to loopback. For a remote server, keep that binding and forward it over SSH:

```sh
ssh -L 8080:127.0.0.1:8080 user@server
```

The three services are React/Nginx, FastAPI, and local MongoDB 7. MongoDB and the backend are accessible only inside the Compose network. Nginx routes `/api/` to FastAPI with streaming buffering disabled; browser requests use the same origin.

Compose deliberately overrides `MONGODB_URL` and `MONGODB_DATABASE` to use its local `mongodb` service and the `graphfusion` database. It creates a **new** database volume; it does not import or delete an existing host database. Redis, MinIO and Mongo Express are not required by the current app and are not started.

## Models and verification

The two trained GNN checkpoints already tracked under `src/infrastructure/analysis_model/` are mounted read-only. Keep that directory alongside the Compose file when deploying a Git checkout. Model weights, `.env`, user storage and datasets are excluded from the build context. On first startup the configured CodeBERT model is downloaded from Hugging Face into the persistent `app_storage` volume. Internet access is required for this first download and subsequent LLM requests; allow extra startup time.

The backend contains fixed Solidity 0.4.24, 0.8.0 and 0.8.20 binaries copied from official `ethereum/solc` images. It runs as a non-root user without a host Docker socket. Repair verification uses a temporary working directory, a credential-free compiler environment, a 25-second timeout and native CPU/address-space limits. The entire backend has Compose memory/CPU/process limits. This is process-level isolation inside the backend container, not a separate security sandbox per request.

Analysis accepts standalone contracts. Filesystem/network imports are rejected; verification tests may import the supplied virtual `Contract.sol` or `Tests.sol`. Unsupported compiler versions and missing dependencies require manual review. Compilation and assertion tests do not prove security, and expert confirmation is still required before accepting a proposal.

## Operations

```sh
docker compose ps
docker compose logs --tail=100 backend
curl --fail http://localhost:8080/health
curl --fail http://localhost:8080/api/v1/health
docker compose down
```

`down` retains MongoDB and application data. Do not use `down -v` unless you intend to delete those volumes. Back up both `mongodb_data` and `app_storage` before moving hosts. Avoid sharing raw environment/container inspection output because it can contain credentials.

The base Compose file builds production frontend assets. The production override is optional:

```sh
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
```

For backend source reload during development:

```sh
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d
```

The `*.prod.dockerfile` files mirror the default Dockerfiles for compatibility with existing deployment commands.

## Smoke test

After startup, run the packaged compilers, passing/failing EVM assertions and one synthetic trained-detector inference without contacting the LLM provider or creating user records:

```sh
docker compose exec -T backend python < docker/smoke.py
```
