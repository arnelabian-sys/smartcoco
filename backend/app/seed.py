"""Create the provisioned administrator, reference varieties and model row."""

from __future__ import annotations

import logging

from sqlalchemy import func, select

from .config import get_settings
from .database import SessionLocal
from .models import ModelVersion, User, Variety
from .security import hash_password

logger = logging.getLogger("smartcoco.seed")

DEFAULT_VARIETIES = (
    {
        "code": "TALL",
        "name": "Tall",
        "local_name": "Lubi nga Taas",
        "description": (
            "Tall coconut variety used for copra and buko water. Slow to bear "
            "but long-lived and drought tolerant."
        ),
    },
    {
        "code": "DWARF",
        "name": "Dwarf",
        "local_name": "Lubi nga Mubo",
        "description": (
            "Short-stature, early-bearing coconut popular for tender buko and "
            "backyard planting."
        ),
    },
    {
        "code": "HYBRID",
        "name": "Hybrid",
        "local_name": "Lubi nga Hybrid",
        "description": (
            "Cross between the Tall and Dwarf varieties: high yield, earlier "
            "fruiting, and good copra quality."
        ),
    },
)


def seed_database() -> None:
    settings = get_settings()
    with SessionLocal() as db:
        # 1. Provisioned administrator (not a public demo account).
        admin = db.scalar(
            select(User).where(
                func.lower(User.email) == settings.admin_email.lower()
            )
        )
        if admin is None:
            first, _, last = settings.admin_name.partition(" ")
            admin = User(
                first_name=first or "System",
                last_name=last or "Administrator",
                email=settings.admin_email.lower(),
                password_hash=hash_password(settings.admin_password),
                role="admin",
                status="active",
            )
            db.add(admin)
            logger.info("Provisioned administrator %s", settings.admin_email)
        else:
            logger.info("Administrator %s already exists", settings.admin_email)

        # 2. Reference varieties.
        for item in DEFAULT_VARIETIES:
            exists = db.scalar(
                select(Variety).where(func.upper(Variety.code) == item["code"])
            )
            if exists is None:
                db.add(Variety(**item, active=True))

        # 3. Active model version.
        if db.scalar(select(ModelVersion).limit(1)) is None:
            db.add(
                ModelVersion(
                    version="cnn-v1.0.0",
                    architecture="MobileNetV3-Small (transfer learning)",
                    accuracy=0.9421,
                    is_active=True,
                )
            )

        db.commit()
