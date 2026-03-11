from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator, model_validator
from functools import lru_cache
from typing import Optional
import secrets


class Settings(BaseSettings):
    # Environment
    ENVIRONMENT: str = "development"  # development, staging, production
    DEBUG: bool = True

    # Project
    PROJECT_NAME: str = "ActivEducation API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    # Supabase
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = None

    # Supabase Auth JWT Secret pour validation cote serveur
    # Recuperer depuis : Supabase Dashboard → Settings → API → JWT Secret
    SUPABASE_JWT_SECRET: Optional[str] = None

    # Conserve pour retrocompatibilite (legacy - ne plus utiliser en production)
    SECRET_KEY: str = "legacy-placeholder-key-will-be-removed-v2"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Redis cache (facultatif - fallback vers cache memoire si absent)
    # En production: redis://redis:6379/0 (nom du service Docker)
    # En developpement: redis://localhost:6379/0
    REDIS_URL: str = "redis://redis:6379/0"

    # CORS - Liste vide par defaut, doit etre configuree
    BACKEND_CORS_ORIGINS: list[str] = []

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # Logging
    LOG_LEVEL: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("SECRET_KEY doit contenir au moins 32 caracteres")
        return v

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            # Support format: "http://localhost:3000,http://localhost:8080"
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    @model_validator(mode="after")
    def validate_production_settings(self):
        if self.ENVIRONMENT == "production":
            # En production, DEBUG doit etre False
            if self.DEBUG:
                raise ValueError("DEBUG doit etre False en production")
            # En production, CORS ne peut pas etre vide ou contenir "*"
            if not self.BACKEND_CORS_ORIGINS:
                raise ValueError("BACKEND_CORS_ORIGINS doit etre configure en production")
            if "*" in self.BACKEND_CORS_ORIGINS:
                raise ValueError("CORS wildcard '*' interdit en production")
            # En production, SUPABASE_JWT_SECRET est requis pour validation locale des tokens
            if not self.SUPABASE_JWT_SECRET:
                raise ValueError(
                    "SUPABASE_JWT_SECRET requis en production. "
                    "Trouver dans Supabase Dashboard → Settings → API → JWT Secret"
                )
        # En developpement, permettre le wildcard "*"
        if "*" in self.BACKEND_CORS_ORIGINS and self.ENVIRONMENT != "production":
            self.BACKEND_CORS_ORIGINS = ["*"]
        return self

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT == "development"

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"


def generate_secret_key() -> str:
    """Genere une cle secrete securisee de 64 caracteres."""
    return secrets.token_urlsafe(48)


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
