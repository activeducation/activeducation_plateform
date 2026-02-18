"""
ActivEducation API - Point d'entree principal.

Application FastAPI avec:
- Securite: CORS, Rate Limiting, Security Headers
- Logging: Structure JSON en production, colore en dev
- Middleware: Request logging avec correlation IDs
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.logging import setup_logging, get_logger
from app.core.exceptions import AppException
from app.api.v1.router import api_router
from app.middleware import (
    limiter,
    rate_limit_exceeded_handler,
    SecurityHeadersMiddleware,
    RequestLoggingMiddleware,
)

# Initialiser le logging
setup_logging()
logger = get_logger("main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application."""
    # Startup
    logger.info(
        "Starting ActivEducation API",
        extra={
            "version": settings.VERSION,
            "environment": settings.ENVIRONMENT,
            "debug": settings.DEBUG,
        },
    )
    yield
    # Shutdown
    logger.info("Shutting down ActivEducation API")


# Creation de l'application FastAPI
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API pour la plateforme d'orientation scolaire et professionnelle gamifiee",
    openapi_url=f"{settings.API_V1_STR}/openapi.json" if settings.DEBUG else None,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan,
)

# ============================================================================
# MIDDLEWARES (ordre important: dernier ajoute = premier execute)
# ============================================================================

# 1. Rate Limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

# 2. CORS - Configure selon l'environnement
# Toutes les origines sont definies dans BACKEND_CORS_ORIGINS (.env)
cors_origins = settings.BACKEND_CORS_ORIGINS if settings.BACKEND_CORS_ORIGINS else []

if cors_origins:
    # Note: allow_credentials=True est incompatible avec allow_origins=["*"]
    # En dev avec wildcard, on desactive credentials pour eviter l'erreur CORS
    is_wildcard = "*" in cors_origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=not is_wildcard,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["X-Correlation-ID", "X-Process-Time"],
    )

# 3. Compression GZip pour les reponses > 1KB
app.add_middleware(GZipMiddleware, minimum_size=1000)

# 4. Security Headers
app.add_middleware(SecurityHeadersMiddleware)

# 5. Request Logging (premier a s'executer, dernier ajoute)
app.add_middleware(RequestLoggingMiddleware)

# ============================================================================
# ROUTES
# ============================================================================

# API v1
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", tags=["Health"])
async def root():
    """Point d'entree racine - verification rapide."""
    return {
        "message": "Bienvenue sur l'API ActivEducation",
        "status": "active",
        "version": settings.VERSION,
    }


@app.get("/health", tags=["Health"])
async def health_check(request: Request):
    """
    Endpoint de sante pour les load balancers et monitoring.
    Retourne l'etat de l'API et des services dependants.
    """
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "correlation_id": getattr(request.state, "correlation_id", None),
    }


# ============================================================================
# EXCEPTION HANDLERS GLOBAUX
# ============================================================================


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    """
    Handler pour les exceptions applicatives personnalisees.
    Convertit les AppException en reponses JSON structurees.
    """
    correlation_id = getattr(request.state, "correlation_id", "unknown")

    logger.warning(
        f"Application error: {exc.code}",
        extra={
            "correlation_id": correlation_id,
            "error_code": exc.code,
            "error_message": exc.message,
            "path": request.url.path,
        },
    )

    response_content = exc.to_dict()
    response_content["correlation_id"] = correlation_id

    return JSONResponse(
        status_code=exc.status_code,
        content=response_content,
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Handler global pour les exceptions non gerees.
    Log l'erreur et retourne une reponse generique.
    """
    correlation_id = getattr(request.state, "correlation_id", "unknown")

    logger.error(
        f"Unhandled exception: {str(exc)}",
        extra={
            "correlation_id": correlation_id,
            "path": request.url.path,
            "method": request.method,
        },
        exc_info=True,
    )

    # En production, ne pas exposer les details de l'erreur
    if settings.is_production:
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "message": "Une erreur interne s'est produite.",
                "correlation_id": correlation_id,
            },
        )

    # En developpement, inclure plus de details
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_server_error",
            "message": str(exc),
            "type": type(exc).__name__,
            "correlation_id": correlation_id,
        },
    )
