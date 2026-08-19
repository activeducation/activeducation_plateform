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
    # Recommande en production : valide les tokens Supabase localement (0 appel reseau)
    # Generer depuis Supabase Dashboard > Settings > API > JWT Secret
    SUPABASE_JWT_SECRET: Optional[str] = None

    # SECRET_KEY : sert a signer les tokens JWT internes (reset mot de passe,
    # tokens de session internes). Generer avec : python -c "import secrets; print(secrets.token_urlsafe(48))"
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Cache Redis
    # None par defaut : evite de tenter une connexion sur un hostname Docker
    # inexistant (ex: Railway, Heroku). Le cache et le rate-limiter savent
    # gerer ce cas (fallback memoire). En production, on exige la valeur
    # explicitement via le validator ci-dessous.
    REDIS_URL: Optional[str] = None

    # LLM - AÏDA / TutorAI
    GROQ_API_KEY: Optional[str] = None

    # Provider LLM actif et parametres de generation.
    # Sortis du code (groq_provider) pour un point de verite unique,
    # configurable par environnement sans redeploiement de code.
    LLM_PROVIDER: str = "groq"              # groq | ollama
    LLM_MODEL: str = "llama-3.1-8b-instant"
    LLM_MAX_TOKENS: int = 800
    LLM_TEMPERATURE: float = 0.7
    LLM_TIMEOUT_SECONDS: float = 30.0

    # Fallback local Ollama (auto-heberge, mode hors-ligne).
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.1:8b"
    OLLAMA_TIMEOUT_SECONDS: float = 90.0

    # TutorAI — bascules de deploiement progressif (strangler fig).
    # TUTOR_PERSIST_SESSIONS : quand True, les conversations sont persistees
    # en base (chat_sessions/chat_messages) au lieu de la memoire process.
    # Defaut False : le chemin /chat existant reste inchange tant que la
    # migration 018 n'est pas appliquee et le flag pas active.
    TUTOR_PERSIST_SESSIONS: bool = False
    # Nombre de messages d'historique injectes dans le contexte LLM.
    TUTOR_SESSION_HISTORY_LIMIT: int = 20

    # TutorAI RAG — recherche semantique sur le contenu de cours.
    # Embeddings via Ollama (nomic-embed-text, 768d) : gratuit, local,
    # coherent avec le repli offline. Ollama + le modele doivent tourner la
    # ou le backend calcule les embeddings (ingestion ET requete de chat).
    # Defaut False : dormant tant que la migration 019 (pgvector) n'est pas
    # appliquee et le flag pas active.
    TUTOR_RAG_ENABLED: bool = False
    EMBEDDING_PROVIDER: str = "ollama"       # ollama (768d)
    EMBEDDING_MODEL: str = "nomic-embed-text"
    EMBEDDING_DIM: int = 768                  # doit matcher vector(N) en base
    EMBEDDING_TIMEOUT_SECONDS: float = 60.0
    # Recherche : nb de chunks injectes dans le prompt + seuil de similarite.
    RAG_TOP_K: int = 4
    RAG_MIN_SIMILARITY: float = 0.3
    # Decoupage du contenu (approximatif, en caracteres).
    RAG_CHUNK_SIZE: int = 2000
    RAG_CHUNK_OVERLAP: int = 200

    # TutorAI Maitrise — suivi par competence via Bayesian Knowledge Tracing.
    # Dormant tant que la migration 020 n'est pas appliquee et le flag off.
    TUTOR_MASTERY_ENABLED: bool = False
    # Parametres BKT (defauts raisonnables, calibrables par matiere plus tard).
    BKT_P_INIT: float = 0.3      # p(maitrise) initiale
    BKT_P_TRANSIT: float = 0.15  # p(apprentissage) a chaque opportunite
    BKT_P_SLIP: float = 0.1      # p(erreur alors que maitrise)
    BKT_P_GUESS: float = 0.2     # p(bonne reponse par chance sans maitrise)
    # Seuil au-dela duquel une competence est consideree maitrisee.
    MASTERY_THRESHOLD: float = 0.6

    # TutorAI Tool-calling — AÏDA appelle elle-meme les outils (quiz,
    # recommandation) pendant la conversation via le function-calling Groq.
    # Defaut False : le chat reste une simple completion. Necessite Groq
    # (llama-3.1-8b) ; sur repli Ollama, les outils sont ignores.
    TUTOR_TOOLS_ENABLED: bool = False
    # Nombre max d'aller-retours d'appels d'outils par tour de conversation.
    TUTOR_TOOLS_MAX_ITERATIONS: int = 3

    # Orientation multi-criteres — poids relatifs des criteres de matching.
    # Un critere sans donnee est exclu et les poids sont renormalises.
    ORIENTATION_WEIGHT_RIASEC: float = 35.0     # tests de la plateforme
    ORIENTATION_WEIGHT_ACADEMIC: float = 25.0   # notes dans les matieres cles
    ORIENTATION_WEIGHT_INTERESTS: float = 20.0  # interets + matieres preferees
    ORIENTATION_WEIGHT_PROJECT: float = 10.0    # projet professionnel
    ORIENTATION_WEIGHT_BUDGET: float = 10.0     # faisabilite financiere

    # Email (notifications candidatures mentor, etc.) — tout optionnel.
    # Si SMTP n'est pas configure, l'envoi est ignore silencieusement (best-effort).
    # L'adresse destinataire des notifications est aussi configurable a chaud via
    # la cle app_settings 'notification_email' (prioritaire sur NOTIFICATION_EMAIL).
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_FROM: Optional[str] = None
    SMTP_USE_TLS: bool = True
    NOTIFICATION_EMAIL: Optional[str] = None  # fallback si app_settings absent

    # CORS - Liste vide par defaut, doit etre configuree
    BACKEND_CORS_ORIGINS: list[str] = []

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # Logging
    LOG_LEVEL: str = "INFO"

    # Monitoring
    SENTRY_DSN: Optional[str] = None

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
        if v == "YOUR_SECRET_KEY_HERE_FOR_DEV":
            raise ValueError("SECRET_KEY par defaut non autorise. Generez une cle securisee.")
        if v.startswith("eyJ"):
            raise ValueError(
                "SECRET_KEY ressemble a un JWT (commence par 'eyJ'). "
                "Utilisez une cle secrete aleatoire, pas un token JWT."
            )
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

            # Refuser les valeurs placeholder heritees du CI (protege contre un
            # deploiement accidentel avec des secrets factices).
            placeholder_markers = ("placeholder", "ci-test", "pytest-dummy")
            suspect_fields = {
                "SUPABASE_URL": self.SUPABASE_URL,
                "SUPABASE_KEY": self.SUPABASE_KEY,
                "SUPABASE_SERVICE_ROLE_KEY": self.SUPABASE_SERVICE_ROLE_KEY or "",
                "SECRET_KEY": self.SECRET_KEY,
            }
            for field_name, value in suspect_fields.items():
                lowered = (value or "").lower()
                if any(marker in lowered for marker in placeholder_markers):
                    raise ValueError(
                        f"{field_name} contient une valeur placeholder non autorisee en production"
                    )
            if not self.SUPABASE_SERVICE_ROLE_KEY:
                raise ValueError(
                    "SUPABASE_SERVICE_ROLE_KEY est requis en production (endpoints admin)"
                )

            # REDIS_URL obligatoire en prod (rate-limiter partage entre workers,
            # cache mutualise). Refuser le hostname Docker hérité qui ne
            # resout pas hors d'un docker-compose local.
            if not self.REDIS_URL:
                raise ValueError(
                    "REDIS_URL est requis en production "
                    "(rate-limiter partage et cache mutualise)"
                )
            if "redis://redis:" in (self.REDIS_URL or ""):
                raise ValueError(
                    "REDIS_URL pointe vers le hostname Docker 'redis' "
                    "(hors docker-compose il ne resout pas). "
                    "Utilisez l'URL fournie par votre provider Redis."
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


def __getattr__(name: str):
    if name == "settings":
        return get_settings()
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
