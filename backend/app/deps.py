"""Shared FastAPI dependencies (current user, role guards, sessions)."""

from __future__ import annotations

from datetime import datetime, timezone

import jwt
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import get_db
from .models import AuthSession, User
from .security import decode_access_token

bearer_scheme = HTTPBearer(auto_error=False)

CREDENTIALS_ERROR = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="invalid_token",
    headers={"WWW-Authenticate": "Bearer"},
)


def current_session(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> tuple[User, AuthSession]:
    if credentials is None:
        raise CREDENTIALS_ERROR
    try:
        payload = decode_access_token(credentials.credentials)
        user_id = int(payload.get("sub", "0"))
        token_id = payload.get("sid")
    except (jwt.PyJWTError, ValueError):
        raise CREDENTIALS_ERROR from None

    session = db.scalar(select(AuthSession).where(AuthSession.token_id == token_id))
    now = datetime.now(timezone.utc)
    if session is None or session.revoked_at is not None:
        raise CREDENTIALS_ERROR
    expires_at = session.expires_at
    if expires_at.tzinfo is None:  # SQLite stores naive timestamps
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at <= now:
        raise CREDENTIALS_ERROR

    user = db.get(User, user_id)
    if user is None:
        raise CREDENTIALS_ERROR
    if user.status != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="account_disabled"
        )
    return user, session


def get_current_user(
    pair: tuple[User, AuthSession] = Depends(current_session),
) -> User:
    return pair[0]


def require_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="admin_required"
        )
    return user


def require_staff(user: User = Depends(get_current_user)) -> User:
    """Administrators and researchers can read aggregate statistics."""
    if user.role not in ("admin", "researcher"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="staff_required"
        )
    return user


def client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None
