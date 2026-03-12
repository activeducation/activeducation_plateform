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

    # Redis cache (facultatif - fallback vers cache memoire si absent)
    # En production: redis://:${REDIS_PASSWORD}@redis:6379/0
    # En developpement: redis://localhost:6379/0
    # Si REDIS_PASSWORD est defini, l'URL doit inclure le mot de passe.
    REDIS_URL: str = "redis://redis:6379/0"
    REDIS_PASSWORD: Optional[str] = None

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
