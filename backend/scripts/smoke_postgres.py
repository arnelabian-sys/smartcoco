r"""Smoke test against the real PostgreSQL database.

Run after creating `smartcoco`/`smartcoco` in pgAdmin:

    .\scripts\smoke_postgres.py
"""

from __future__ import annotations

import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import inspect, text  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.database import engine  # noqa: E402
from app.main import app  # noqa: E402

settings = get_settings()


def main() -> int:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))

    with TestClient(app) as client:
        root = client.get("/").json()
        health = client.get("/api/v1/health").json()
        login = client.post(
            f"{settings.api_prefix}/auth/admin/login",
            json={
                "email": settings.admin_email,
                "password": settings.admin_password,
            },
        )
        print(f"service      : {root['name']} v{root['version']}")
        print(f"health       : api_up={health['api_up']} model={health['model_version']}")
        print(f"admin login  : HTTP {login.status_code}")

        if login.status_code == 200:
            token = login.json()["access_token"]
            varieties = client.get(
                f"{settings.api_prefix}/varieties",
                headers={"Authorization": f"Bearer {token}"},
            ).json()
            print("varieties    :", ", ".join(item["code"] for item in varieties))

    tables = inspect(engine).get_table_names()
    print(f"tables ({len(tables)})   :", ", ".join(sorted(tables)))
    return 0 if login.status_code == 200 else 1


if __name__ == "__main__":
    raise SystemExit(main())
