"""System health snapshot for the administrator dashboard."""

from __future__ import annotations

import time
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from .. import __version__
from ..database import get_db
from ..deps import require_admin
from ..models import HealthCheck, ModelVersion, User, Variety
from ..schemas import HealthOut

router = APIRouter(prefix="/health", tags=["health"])

STARTED_AT = time.monotonic()


@router.get("", response_model=HealthOut)
def health(db: Session = Depends(get_db)) -> HealthOut:
    checked_at = datetime.now(timezone.utc)
    api_up = True
    model_up = True
    error: str | None = None

    started = time.perf_counter()
    try:
        db.execute(text("SELECT 1"))
    except Exception:  # pragma: no cover - only when the DB is unreachable
        api_up = False
        error = "Database is unreachable."
    api_latency_ms = max(1, int((time.perf_counter() - started) * 1000))

    model = db.scalar(select(ModelVersion).where(ModelVersion.is_active.is_(True)))
    if model is None:
        model_up = False
        model_version = "—"
        architecture = "—"
        accuracy = 0.0
        model_latency_ms = 0
    else:
        model_version = model.version
        architecture = model.architecture
        accuracy = float(model.accuracy)
        model_latency_ms = 180  # mocked inference warm-up

    active_varieties = db.scalar(
        select(func.count(Variety.id)).where(Variety.active.is_(True))
    ) or 0

    record = HealthCheck(
        api_up=api_up,
        model_up=model_up,
        api_latency_ms=api_latency_ms,
        model_latency_ms=model_latency_ms,
        error=error,
        checked_at=checked_at,
    )
    db.add(record)
    db.commit()

    checks = db.scalar(select(func.count(HealthCheck.id))) or 0

    return HealthOut(
        api_up=api_up,
        model_up=model_up,
        checked_at=checked_at,
        api_version=__version__,
        model_version=model_version,
        architecture=architecture,
        api_latency_ms=api_latency_ms,
        model_latency_ms=model_latency_ms,
        uptime_seconds=int(time.monotonic() - STARTED_AT),
        accuracy=accuracy,
        active_varieties=active_varieties,
        checks=checks,
        error=error,
    )


@router.get("/history", response_model=list[HealthOut])
def health_history(
    limit: int = Query(default=20, ge=1, le=200),
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> list[HealthOut]:
    rows = db.scalars(
        select(HealthCheck).order_by(HealthCheck.checked_at.desc()).limit(limit)
    ).all()
    return [
        HealthOut(
            api_up=row.api_up,
            model_up=row.model_up,
            checked_at=row.checked_at,
            api_version=__version__,
            model_version="—",
            architecture="—",
            api_latency_ms=row.api_latency_ms,
            model_latency_ms=row.model_latency_ms,
            uptime_seconds=0,
            accuracy=0.0,
            active_varieties=0,
            checks=0,
            error=row.error,
        )
        for row in rows
    ]
