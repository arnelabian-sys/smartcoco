"""Image classification + history.

The CNN is still simulated (there is no trained model in the repository yet):
the endpoint validates the upload, stores it, and returns a plausible variety
and confidence so the Flutter UI can exercise all of its states
(SUCCESS / EMPTY / ERROR). Swapping in a real model later only requires
replacing :func:`_classify`.
"""

from __future__ import annotations

import hashlib
import random
import uuid
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from ..config import get_settings
from ..database import get_db
from ..deps import get_current_user, require_staff
from ..models import ModelVersion, Prediction, User, Variety
from ..schemas import PredictionOut, PredictionStats, VarietyScore

router = APIRouter(prefix="/predictions", tags=["predictions"])

ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


def _classify(filename: str, payload: bytes, varieties: list[Variety]) -> tuple[str, Variety | None, float | None, str | None]:
    """Very small deterministic stub that mimics the CNN output."""
    lowered = filename.lower()
    if not payload:
        return "empty", None, None, "The uploaded file was empty."
    if "empty" in lowered:
        return "empty", None, None, "No coconut was detected in the image."
    if "error" in lowered:
        return "error", None, None, "The model could not read the image."

    digest = hashlib.sha256(filename.encode("utf-8") + payload[:256]).digest()
    index = digest[0] % len(varieties)
    variety = varieties[index]
    # Keep the confidence inside the range the UI expects (0.72 - 0.99).
    confidence = round(0.72 + (digest[1] / 255) * 0.27, 4)
    return "success", variety, confidence, None


@router.post("", response_model=PredictionOut, status_code=status.HTTP_201_CREATED)
async def create_prediction(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PredictionOut:
    settings = get_settings()
    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="unsupported_file_type",
        )

    payload = await file.read()
    max_bytes = settings.max_upload_mb * 1024 * 1024
    if len(payload) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="file_too_large",
        )

    # 1. Persist the image (only the path goes into the database).
    now = datetime.now(timezone.utc)
    relative_dir = Path("predictions") / f"{now:%Y}" / f"{now:%m}"
    target_dir = Path(settings.uploads_dir) / relative_dir
    target_dir.mkdir(parents=True, exist_ok=True)
    extension = ALLOWED_TYPES[content_type]
    file_name = f"{uuid.uuid4().hex}{extension}"
    target_path = target_dir / file_name
    target_path.write_bytes(payload)
    stored_path = (relative_dir / file_name).as_posix()

    # 2. Run the (mock) classifier.
    varieties = list(db.scalars(select(Variety).where(Variety.active.is_(True))))
    started = datetime.now(timezone.utc)
    result_status = "error"
    if not varieties:
        error_message = "No active varieties configured."
        variety = None
        confidence = None
    else:
        result_status, variety, confidence, error_message = _classify(
            file.filename or "image", payload, varieties
        )
    latency_ms = max(
        120, int((datetime.now(timezone.utc) - started).total_seconds() * 1000) + random.randint(180, 640)
    )

    model_version = db.scalar(
        select(ModelVersion).where(ModelVersion.is_active.is_(True))
    )
    prediction = Prediction(
        user_id=user.id,
        variety_id=variety.id if variety else None,
        confidence=confidence,
        image_path=stored_path,
        status=result_status,
        error_message=None if result_status == "success" else error_message,
        model_version_id=model_version.id if model_version else None,
        latency_ms=latency_ms,
    )
    db.add(prediction)
    db.commit()
    db.refresh(prediction)

    if result_status == "error":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="classification_failed",
        )

    return PredictionOut.model_validate(prediction)


@router.get("", response_model=list[PredictionOut])
def list_predictions(
    status_filter: str | None = Query(default=None, alias="status"),
    variety_id: int | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[PredictionOut]:
    stmt = (
        select(Prediction)
        .options(joinedload(Prediction.variety))
        .order_by(Prediction.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    if user.role != "admin":
        stmt = stmt.where(Prediction.user_id == user.id)
    if status_filter:
        stmt = stmt.where(Prediction.status == status_filter)
    if variety_id is not None:
        stmt = stmt.where(Prediction.variety_id == variety_id)
    return [PredictionOut.model_validate(p) for p in db.scalars(stmt).unique()]


@router.get("/stats", response_model=PredictionStats)
def prediction_stats(
    start: date | None = Query(default=None),
    end: date | None = Query(default=None),
    _: User = Depends(require_staff),
    db: Session = Depends(get_db),
) -> PredictionStats:
    stmt = select(Prediction).options(joinedload(Prediction.variety))
    if start is not None:
        stmt = stmt.where(
            Prediction.created_at
            >= datetime.combine(start, time.min, tzinfo=timezone.utc)
        )
    if end is not None:
        stmt = stmt.where(
            Prediction.created_at
            < datetime.combine(
                end + timedelta(days=1), time.min, tzinfo=timezone.utc
            )
        )
    rows = list(db.scalars(stmt).unique())
    success = [r for r in rows if r.status == "success"]
    confidences = [float(r.confidence) for r in success if r.confidence is not None]

    counts: dict[int, VarietyScore] = {}
    for row in success:
        if row.variety is None:
            continue
        entry = counts.setdefault(
            row.variety.id,
            VarietyScore(
                variety_id=row.variety.id,
                code=row.variety.code,
                name=row.variety.name,
                count=0,
            ),
        )
        entry.count += 1

    return PredictionStats(
        total=len(rows),
        success=len(success),
        empty=len([r for r in rows if r.status == "empty"]),
        error=len([r for r in rows if r.status == "error"]),
        average_confidence=(
            round(sum(confidences) / len(confidences), 4) if confidences else None
        ),
        by_variety=sorted(counts.values(), key=lambda v: v.count, reverse=True),
    )


@router.get("/{prediction_id}", response_model=PredictionOut)
def get_prediction(
    prediction_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PredictionOut:
    prediction = db.get(Prediction, prediction_id)
    if prediction is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    if prediction.user_id != user.id and user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="forbidden")
    return PredictionOut.model_validate(prediction)


@router.get("/{prediction_id}/image")
def get_prediction_image(
    prediction_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    prediction = db.get(Prediction, prediction_id)
    if prediction is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    if prediction.user_id != user.id and user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="forbidden")
    path = Path(get_settings().uploads_dir) / prediction.image_path
    if not path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="image_not_found"
        )
    return FileResponse(path)
