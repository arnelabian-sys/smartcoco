"""Coconut variety reference data."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user, require_admin
from ..models import User, Variety
from ..schemas import VarietyCreate, VarietyOut, VarietyUpdate

router = APIRouter(prefix="/varieties", tags=["varieties"])


def _get_or_404(db: Session, variety_id: int) -> Variety:
    variety = db.get(Variety, variety_id)
    if variety is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    return variety


@router.get("", response_model=list[VarietyOut])
def list_varieties(
    include_inactive: bool = Query(default=False),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[VarietyOut]:
    stmt = select(Variety).order_by(Variety.name)
    if not (include_inactive and user.role == "admin"):
        stmt = stmt.where(Variety.active.is_(True))
    return [VarietyOut.model_validate(v) for v in db.scalars(stmt)]


@router.get("/{variety_id}", response_model=VarietyOut)
def get_variety(
    variety_id: int,
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> VarietyOut:
    return VarietyOut.model_validate(_get_or_404(db, variety_id))


@router.post("", response_model=VarietyOut, status_code=status.HTTP_201_CREATED)
def create_variety(
    payload: VarietyCreate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> VarietyOut:
    code = payload.code.upper().strip()
    exists = db.scalar(
        select(Variety).where(func.upper(Variety.code) == code)
    )
    if exists is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="duplicate_code"
        )
    variety = Variety(
        code=code,
        name=payload.name.strip(),
        local_name=payload.local_name,
        description=payload.description.strip(),
        reference_image=payload.reference_image,
        active=payload.active,
        created_by=admin.id,
    )
    db.add(variety)
    db.commit()
    db.refresh(variety)
    return VarietyOut.model_validate(variety)


@router.patch("/{variety_id}", response_model=VarietyOut)
def update_variety(
    variety_id: int,
    payload: VarietyUpdate,
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> VarietyOut:
    variety = _get_or_404(db, variety_id)

    if payload.code is not None:
        code = payload.code.upper().strip()
        clash = db.scalar(
            select(Variety).where(
                func.upper(Variety.code) == code, Variety.id != variety.id
            )
        )
        if clash is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail="duplicate_code"
            )
        variety.code = code
    if payload.name is not None:
        variety.name = payload.name.strip()
    if payload.local_name is not None:
        variety.local_name = payload.local_name
    if payload.description is not None:
        variety.description = payload.description.strip()
    if payload.reference_image is not None:
        variety.reference_image = payload.reference_image
    if payload.active is not None:
        variety.active = payload.active

    db.commit()
    db.refresh(variety)
    return VarietyOut.model_validate(variety)


@router.delete("/{variety_id}", response_model=VarietyOut)
def deactivate_variety(
    variety_id: int,
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> VarietyOut:
    """Soft delete: history keeps pointing at the row."""
    variety = _get_or_404(db, variety_id)
    variety.active = False
    db.commit()
    db.refresh(variety)
    return VarietyOut.model_validate(variety)
