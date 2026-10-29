"""Pydantic schemas (request/response bodies)."""

from __future__ import annotations

from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

Role = Literal["user", "student", "farmer", "agriculturist", "researcher", "admin"]
PublicRole = Literal["user", "student", "farmer", "agriculturist"]
PredictionStatus = Literal["success", "empty", "error"]

ROLE_LABELS = {
    "researcher": "Extension Worker / Researcher",
    "admin": "Administrator",
    "student": "Student",
    "farmer": "Farmer",
    "agriculturist": "Agriculturist",
}


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------------------------- #
# Auth
# --------------------------------------------------------------------------- #
class RegisterRequest(BaseModel):
    first_name: str = Field(min_length=2, max_length=60)
    last_name: str = Field(min_length=2, max_length=60)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    birthday: date | None = None
    gender: str | None = Field(default=None, max_length=20)
    role: PublicRole = "user"

    @field_validator("password")
    @classmethod
    def password_needs_letter_and_number(cls, value: str) -> str:
        if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
            raise ValueError("Password must contain a letter and a number.")
        return value


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserOut(ORMModel):
    id: int
    first_name: str
    last_name: str
    name: str = ""
    email: EmailStr
    role: str
    role_label: str = ""
    birthday: date | None = None
    gender: str | None = None
    status: str
    login_count: int
    last_login_at: datetime | None = None
    created_at: datetime

    @model_validator(mode="after")
    def _fill_labels(self) -> "UserOut":
        if not self.name:
            object.__setattr__(
                self, "name", f"{self.first_name} {self.last_name}".strip()
            )
        if not self.role_label:
            object.__setattr__(
                self, "role_label", ROLE_LABELS.get(self.role, "Registered User")
            )
        return self


class UserAdminOut(UserOut):
    online: bool = False


class UserUpdate(BaseModel):
    first_name: str | None = Field(default=None, min_length=2, max_length=60)
    last_name: str | None = Field(default=None, min_length=2, max_length=60)
    email: EmailStr | None = None
    gender: str | None = Field(default=None, max_length=20)
    birthday: date | None = None


class PasswordChange(BaseModel):
    current_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8, max_length=128)
    confirm_password: str | None = None

    @field_validator("new_password")
    @classmethod
    def password_needs_letter_and_number(cls, value: str) -> str:
        if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
            raise ValueError("Password must contain a letter and a number.")
        return value


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserOut


class MessageResponse(BaseModel):
    detail: str


# --------------------------------------------------------------------------- #
# Users (admin)
# --------------------------------------------------------------------------- #
class UserStatusUpdate(BaseModel):
    status: Literal["active", "disabled"]


class UserRoleUpdate(BaseModel):
    role: Role


class UserStats(BaseModel):
    total_accounts: int
    online_now: int
    total_logins: int
    admins: int
    researchers: int
    by_role: dict[str, int]


# --------------------------------------------------------------------------- #
# Varieties
# --------------------------------------------------------------------------- #
class VarietyBase(BaseModel):
    code: str = Field(min_length=2, max_length=20, pattern=r"^[A-Za-z0-9_\-]+$")
    name: str = Field(min_length=2, max_length=80)
    local_name: str | None = Field(default=None, max_length=80)
    description: str = Field(min_length=5, max_length=2000)
    reference_image: str | None = Field(default=None, max_length=255)
    active: bool = True


class VarietyCreate(VarietyBase):
    pass


class VarietyUpdate(BaseModel):
    code: str | None = Field(default=None, min_length=2, max_length=20, pattern=r"^[A-Za-z0-9_\-]+$")
    name: str | None = Field(default=None, min_length=2, max_length=80)
    local_name: str | None = Field(default=None, max_length=80)
    description: str | None = Field(default=None, min_length=5, max_length=2000)
    reference_image: str | None = Field(default=None, max_length=255)
    active: bool | None = None


class VarietyOut(ORMModel):
    id: int
    code: str
    name: str
    local_name: str | None = None
    description: str
    reference_image: str | None = None
    active: bool
    created_at: datetime
    updated_at: datetime


# --------------------------------------------------------------------------- #
# Predictions
# --------------------------------------------------------------------------- #
class PredictionOut(ORMModel):
    id: int
    user_id: int
    variety: VarietyOut | None = None
    confidence: float | None = None
    image_path: str
    status: PredictionStatus
    error_message: str | None = None
    latency_ms: int | None = None
    created_at: datetime


class VarietyScore(BaseModel):
    variety_id: int | None = None
    code: str
    name: str
    count: int


class PredictionStats(BaseModel):
    total: int
    success: int
    empty: int
    error: int
    average_confidence: float | None = None
    by_variety: list[VarietyScore] = []


# --------------------------------------------------------------------------- #
# Health
# --------------------------------------------------------------------------- #
class HealthOut(BaseModel):
    api_up: bool
    model_up: bool
    checked_at: datetime
    api_version: str
    model_version: str
    architecture: str
    api_latency_ms: int
    model_latency_ms: int
    uptime_seconds: int
    accuracy: float
    active_varieties: int
    checks: int
    error: str | None = None
