"""Pytest fixtures: an isolated SQLite database + API client.

The production database is PostgreSQL; the tests run on SQLite so they need no
server. The models are portable, so both behave the same.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.config import get_settings  # noqa: E402

settings = get_settings()
settings.auto_create_tables = False
settings.seed_demo_data = False
settings.uploads_dir = tempfile.mkdtemp(prefix="smartcoco-uploads-")
settings.admin_email = "admin@smartcoco.ph"
settings.admin_password = "Admin123"
settings.admin_name = "Admin User"

from app import models  # noqa: E402,F401  (registers the tables)
from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import ModelVersion, User, Variety  # noqa: E402
from app.security import hash_password  # noqa: E402

engine = create_engine(
    "sqlite+pysqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(
    bind=engine, autoflush=False, expire_on_commit=False, future=True
)

ADMIN_EMAIL = "admin@smartcoco.ph"
ADMIN_PASSWORD = "Admin123"


@pytest.fixture(autouse=True)
def database() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestingSessionLocal() as db:
        db.add(
            User(
                first_name="Admin",
                last_name="User",
                email=ADMIN_EMAIL,
                password_hash=hash_password(ADMIN_PASSWORD),
                role="admin",
                status="active",
            )
        )
        db.add_all(
            [
                Variety(
                    code="TALL",
                    name="Tall",
                    description="Tall coconut variety used for copra.",
                ),
                Variety(
                    code="DWARF",
                    name="Dwarf",
                    description="Short stature, early bearing coconut.",
                ),
                Variety(
                    code="HYBRID",
                    name="Hybrid",
                    description="Cross of Tall and Dwarf, high yield.",
                ),
            ]
        )
        db.add(
            ModelVersion(
                version="cnn-v1.0.0",
                architecture="MobileNetV3-Small",
                accuracy=0.9421,
                is_active=True,
            )
        )
        db.commit()
    yield


@pytest.fixture
def client() -> TestClient:
    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def admin_headers(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/admin/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
    )
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def register_user(
    client: TestClient,
    *,
    email: str = "juan@smartcoco.ph",
    password: str = "Password123",
    first_name: str = "Juan",
    last_name: str = "Dela Cruz",
    role: str = "farmer",
) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "password": password,
            "role": role,
            "gender": "Male",
            "birthday": "2000-01-15",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def user_headers(client: TestClient, **kwargs) -> dict[str, str]:
    payload = register_user(client, **kwargs)
    return {"Authorization": f"Bearer {payload['access_token']}"}
