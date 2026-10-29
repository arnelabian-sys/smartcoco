"""SmartCoco FastAPI application."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware

from . import __version__
from .config import get_settings
from .database import Base, engine
from .routers import auth, health, predictions, users, varieties
from .seed import seed_database

logger = logging.getLogger("smartcoco")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    if settings.auto_create_tables:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables are ready.")
    if settings.seed_demo_data:
        seed_database()
    yield


settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=__version__,
    description=(
        "REST API bridge for the SmartCoco Flutter app: authentication, "
        "user management, coconut varieties, image classification and system health."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(users.router, prefix=settings.api_prefix)
app.include_router(varieties.router, prefix=settings.api_prefix)
app.include_router(predictions.router, prefix=settings.api_prefix)
app.include_router(health.router, prefix=settings.api_prefix)


@app.get("/", tags=["meta"])
def root() -> dict[str, str]:
    return {
        "name": settings.app_name,
        "version": __version__,
        "docs": "/docs",
        "api": settings.api_prefix,
    }


@app.get("/api/version", tags=["meta"])
def version() -> dict[str, str]:
    return {"version": __version__}


@app.get("/health", include_in_schema=False)
def health_alias() -> dict[str, str]:
    """Lightweight liveness probe: {"status": "ok"} (full snapshot: /api/v1/health)."""
    return {"status": "ok"}


@app.get("/favicon.ico", include_in_schema=False)
def favicon() -> Response:
    """Browsers ask for this automatically; answer 204 instead of logging a 404."""
    return Response(status_code=204)


@app.get("/v1/models", include_in_schema=False)
def openai_probe() -> dict[str, object]:
    """Harmless reply for local AI tools that probe port 8000 llama.cpp-style.

    SmartCoco is not an LLM server, so it advertises an empty model list
    instead of logging a 404. The real API lives under /api/v1.
    """
    return {"object": "list", "data": []}
