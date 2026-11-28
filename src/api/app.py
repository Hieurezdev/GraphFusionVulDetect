import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .router import create_router
from src.infrastructure.database import db_manager
from src.services.model_loader import load_all_models
from src.services.graph_loader import build_global_graph

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("SmartContractScanner")

def create_app():
    app = FastAPI(
        title="Smart Contract Vulnerability Scanner API",
        version="1.1.0",
        description="API for Smart Contract Vulnerability Detection using GNN + LLM",
        docs_url="/docs",
        redoc_url="/redoc"
    )

    # ---- CORS ----
    origins = [
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://127.0.0.1",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:3000",
        "null"
    ]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ---- Startup event ----
    async def startup_event():
        logger.info("Connecting to DB...")
        await db_manager.connect()

        # Analyses left 'processing' by a previous server process will never finish: close them (step 1.6)
        from src.api.v1.analyze_router import fail_orphaned_sessions
        closed = await fail_orphaned_sessions()
        if closed:
            logger.info(f"Closed {closed} analysis session(s) left unfinished by a previous run")

        logger.info("Loading all ML/LLM models...")
        await load_all_models()

        logger.info("Building graph workflow...")
        build_global_graph()

        # Step 1.8: judged functions for retrieval-augmented explanations
        from src.services.knowledge import load_index
        n_items = load_index()
        logger.info(f"Knowledge base: {n_items} item(s) loaded")
        print(f"Knowledge base: {n_items} item(s) loaded", flush=True)  # uvicorn's logging setup hides app INFO lines

        logger.info("System initialized successfully.")

    async def shutdown_event():
        logger.info("Disconnecting DB...")
        await db_manager.disconnect()

    app.add_event_handler("startup", startup_event)
    app.add_event_handler("shutdown", shutdown_event)

    # ---- Routers ----
    app.include_router(create_router())

    # ---- Metrics (step 1.10) ----
    import time
    from fastapi import Request, Response, HTTPException
    from src.services import metrics

    @app.middleware("http")
    async def measure(request: Request, call_next):
        t0 = time.perf_counter()
        status = 500
        try:
            response = await call_next(request)
            status = response.status_code
            return response
        finally:
            route = request.scope.get("route")
            path = getattr(route, "path", "unmatched")  # the route template, so /sessions/{session_id} is one series
            metrics.inc("http_requests_total", help_text="HTTP requests by route and status", method=request.method, route=path, status=status)
            # streaming endpoints are timed until their first byte, not until the stream ends
            metrics.observe("http_request_duration_seconds", time.perf_counter() - t0, help_text="HTTP latency until the response starts",
                            method=request.method, route=path)

    @app.get("/metrics", include_in_schema=False)
    async def prometheus_metrics(request: Request):
        """Prometheus scrape endpoint. With METRICS_TOKEN set, a Bearer token is required (keep it off the public site)."""
        from src.config.settings import settings
        if settings.METRICS_TOKEN and request.headers.get("authorization") != f"Bearer {settings.METRICS_TOKEN}":
            raise HTTPException(status_code=401, detail="metrics token required")
        return Response(metrics.render(), media_type="text/plain; version=0.0.4")

    @app.get("/")
    async def root():
        return {
            "message": "Smart Contract Vulnerability Scanner API",
            "status": "running"
        }

    return app

app = create_app()
