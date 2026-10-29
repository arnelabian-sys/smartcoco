"""Account management (administrator) and self-service profile endpoints."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import current_session, get_current_user, require_admin
from ..models import AuthSession, User
from ..schemas import (
    MessageResponse,
    PasswordChange,
    UserAdminOut,
    UserOut,
    UserRoleUpdate,
    UserStats,
    UserStatusUpdate,
    UserUpdate,
)
from ..security import hash_password, verify_password

router = APIRouter(prefix="/users", tags=["users"])


def _online_user_ids(db: Session) -> set[int]:
    """Accounts with a session that is still open (works on SQLite and PG)."""
    now = datetime.now(timezone.utc)
    ids: set[int] = set()
    for session in db.scalars(
        select(AuthSession).where(AuthSession.revoked_at.is_(None))
    ):
        expires_at = session.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at > now:
            ids.add(session.user_id)
    return ids


# --------------------------------------------------------------------------- #
# Self service
# --------------------------------------------------------------------------- #
@router.patch("/me", response_model=UserOut)
def update_me(
    payload: UserUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserOut:
    if payload.email is not None and payload.email.lower().strip() != user.email.lower():
        exists = db.scalar(
            select(User).where(
                func.lower(User.email) == payload.email.lower().strip(),
                User.id != user.id,
            )
        )
        if exists is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail="duplicate_email"
            )
        user.email = payload.email.lower().strip()

    if payload.first_name is not None:
        user.first_name = payload.first_name.strip()
    if payload.last_name is not None:
        user.last_name = payload.last_name.strip()
    if payload.gender is not None:
        user.gender = payload.gender
    if payload.birthday is not None:
        user.birthday = payload.birthday

    db.commit()
    db.refresh(user)
    return UserOut.model_validate(user)


@router.post("/me/password", response_model=MessageResponse)
def change_my_password(
    payload: PasswordChange,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="wrong_password"
        )
    if payload.confirm_password is not None and payload.confirm_password != payload.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="mismatch_password"
        )
    user.password_hash = hash_password(payload.new_password)
    # Invalidate every other session of this account.
    db.query(AuthSession).filter(
        AuthSession.user_id == user.id, AuthSession.revoked_at.is_(None)
    ).update({AuthSession.revoked_at: datetime.now(timezone.utc)})
    db.commit()
    return MessageResponse(detail="password_updated")


# --------------------------------------------------------------------------- #
# Administrator
# --------------------------------------------------------------------------- #
@router.get("", response_model=list[UserAdminOut])
def list_users(
    q: str | None = Query(default=None, max_length=120),
    role: str | None = Query(default=None),
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> list[UserAdminOut]:
    stmt = select(User).order_by(User.created_at.desc())
    if q:
        like = f"%{q.strip().lower()}%"
        stmt = stmt.where(
            or_(
                func.lower(User.first_name).like(like),
                func.lower(User.last_name).like(like),
                func.lower(User.email).like(like),
            )
        )
    if role:
        stmt = stmt.where(User.role == role)
    if status_filter:
        stmt = stmt.where(User.status == status_filter)
    stmt = stmt.limit(limit).offset(offset)

    online = _online_user_ids(db)
    result: list[UserAdminOut] = []
    for user in db.scalars(stmt):
        item = UserAdminOut.model_validate(user)
        item.online = user.id in online
        result.append(item)
    return result


@router.get("/stats", response_model=UserStats)
def user_stats(
    _: User = Depends(require_admin), db: Session = Depends(get_db)
) -> UserStats:
    users = db.scalars(select(User)).all()
    by_role: dict[str, int] = {}
    for user in users:
        by_role[user.role] = by_role.get(user.role, 0) + 1
    return UserStats(
        total_accounts=len(users),
        online_now=len(_online_user_ids(db)),
        total_logins=sum(u.login_count for u in users),
        admins=by_role.get("admin", 0),
        researchers=by_role.get("researcher", 0),
        by_role=by_role,
    )


@router.get("/{user_id}", response_model=UserAdminOut)
def get_user(
    user_id: int,
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> UserAdminOut:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    item = UserAdminOut.model_validate(user)
    item.online = user.id in _online_user_ids(db)
    return item


@router.patch("/{user_id}/status", response_model=UserAdminOut)
def set_user_status(
    user_id: int,
    payload: UserStatusUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> UserAdminOut:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    if user.id == admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="cannot_disable_self"
        )
    if user.role == "admin" and payload.status == "disabled":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="cannot_disable_administrator",
        )
    user.status = payload.status
    db.commit()
    db.refresh(user)
    return UserAdminOut.model_validate(user)


@router.patch("/{user_id}/role", response_model=UserAdminOut)
def set_user_role(
    user_id: int,
    payload: UserRoleUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
) -> UserAdminOut:
    """Promote/demote an account (e.g. a farmer becoming a researcher)."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    if user.id == admin.id and payload.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="cannot_demote_self"
        )
    user.role = payload.role
    db.commit()
    db.refresh(user)
    return UserAdminOut.model_validate(user)
