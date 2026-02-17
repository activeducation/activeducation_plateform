"""
Rate Limiting Middleware pour proteger l'API contre les abus.
Utilise slowapi pour la gestion des limites de requetes.
"""

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request
from fastapi.responses import JSONResponse
from app.core.config import settings


def get_client_ip(request: Request) -> str:
    """
    Extrait l'IP du client en tenant compte des proxies.
    Verifie X-Forwarded-For pour les deployements derriere un load balancer.
    """
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        # Prend la premiere IP de la liste (IP originale du client)
        return forwarded_for.split(",")[0].strip()

    x_real_ip = request.headers.get("X-Real-IP")
    if x_real_ip:
        return x_real_ip

    return get_remote_address(request)


# Initialisation du limiter avec extraction d'IP personnalisee
limiter = Limiter(
    key_func=get_client_ip,
    default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"],
    storage_uri="memory://",  # Utilise la memoire locale (Redis recommande en prod)
    strategy="fixed-window",
)


async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """
    Handler personnalise pour les erreurs de rate limiting.
    Retourne un message JSON structure avec les details.
    """
    return JSONResponse(
        status_code=429,
        content={
            "error": "rate_limit_exceeded",
            "message": "Trop de requetes. Veuillez patienter avant de reessayer.",
            "detail": str(exc.detail),
            "retry_after": getattr(exc, "retry_after", 60),
        },
        headers={
            "Retry-After": str(getattr(exc, "retry_after", 60)),
            "X-RateLimit-Limit": str(settings.RATE_LIMIT_PER_MINUTE),
        },
    )


# Decorateurs de rate limiting pour differents niveaux
def strict_limit(limit: str = "10/minute"):
    """Rate limit strict pour les endpoints sensibles (auth, etc.)"""
    return limiter.limit(limit)


def standard_limit(limit: str = None):
    """Rate limit standard utilisant la configuration globale"""
    if limit is None:
        limit = f"{settings.RATE_LIMIT_PER_MINUTE}/minute"
    return limiter.limit(limit)


def relaxed_limit(limit: str = "200/minute"):
    """Rate limit relaxe pour les endpoints publics a fort trafic"""
    return limiter.limit(limit)
