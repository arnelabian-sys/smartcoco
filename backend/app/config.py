"""Application settings.

Every value can be overridden with an environment variable prefixed with
``SMARTCOCO_`` or with a ``.env`` file next to this package (see ``.env.example``).
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="SMARTCOCO_",
        extra="ignore",
    )

    app_name: str = "SmartCoco API"
    api_prefix: str = "/api/v1"
    debug: bool = False

    # PostgreSQL by default. Tests override this with SQLite.
    database_url: str = (
        "postgresql+psycopg://smartcoco:smartcoco@localhost:5432/smartcoco"
    )
    auto_create_tables: bool = True
    seed_demo_data: bool = True

    # Auth
    secret_key: str = "change-this-secret-in-production"
    algorithm: str = "HS256"
    access_token_ttl_minutes: int = 60 * 8  # 8 hours

    # The single administrator that is provisioned in the database
    # (the mobile/web app no longer ships a demo account).
    admin_name: str = "Admin User"
    admin_email: str = "admin@smartcoco.ph"
    admin_password: str = "Admin123"

    # Uploads
    uploads_dir: str = "uploads"
    max_upload_mb: int = 8

    # CORS (comma separated). "*" allows every origin during development.
    cors_origins: str = "*"

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
