"""Authentication endpoints: register, login, admin login, me, logout."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import client_ip, current_session, get_current_user
from ..models import AuthSession, User
from ..schemas import (
    LoginRequest,
    MessageResponse,
    RegisterRequest,
    TokenResponse,
    UserOut,
)
from ..security import (
    create_access_token,
    hash_password,
    new_token_id,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _issue_token(db: Session, user: User, request: Request) -> TokenResponse:
    token_id = new_token_id()
    token, expires_at = create_access_token(
        subject=str(user.id), role=user.role, token_id=token_id
    )
    db.add(
        AuthSession(
            user_id=user.id,
            token_id=token_id,
            ip_address=client_ip(request),
            user_agent=(request.headers.get("user-agent") or "")[:255] or None,
            expires_at=expires_at,
        )
    )
    user.login_count += 1
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)
    return TokenResponse(
        access_token=token,
        expires_in=(expires_at - datetime.now(timezone.utc)).seconds,
        user=UserOut.model_validate(user),
    )


def _find_by_email(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(func.lower(User.email) == email.lower().strip()))


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(
    payload: RegisterRequest, request: Request, db: Session = Depends(get_db)
) -> TokenResponse:
    if _find_by_email(db, payload.email) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="duplicate_email"
        )

    user = User(
        first_name=payload.first_name.strip(),
        last_name=payload.last_name.strip(),
        email=payload.email.lower().strip(),
        password_hash=hash_password(payload.password),
        role=payload.role,
        birthday=payload.birthday,
        gender=payload.gender,
        status="active",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_token(db, user, request)


@router.post("/login", response_model=TokenResponse)
def login(
    payload: LoginRequest, request: Request, db: Session = Depends(get_db)
) -> TokenResponse:
    user = _find_by_email(db, payload.email)
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid_credentials"
        )
    if user.status != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="account_disabled"
        )
    if user.role == "admin":
        # Administrators use the dedicated portal.
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="admin_portal_required"
        )
    return _issue_token(db, user, request)


@router.post("/admin/login", response_model=TokenResponse)
def admin_login(
    payload: LoginRequest, request: Request, db: Session = Depends(get_db)
) -> TokenResponse:
    user = _find_by_email(db, payload.email)
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid_credentials"
        )
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="not_administrator"
        )
    if user.status != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="account_disabled"
        )
    return _issue_token(db, user, request)


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(user)


@router.post("/logout", response_model=MessageResponse)
def logout(
    pair: tuple[User, AuthSession] = Depends(current_session),
    db: Session = Depends(get_db),
) -> MessageResponse:
    _, session = pair
    session.revoked_at = datetime.now(timezone.utc)
    db.commit()
    return MessageResponse(detail="logged_out")
