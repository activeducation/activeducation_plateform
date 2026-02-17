"""
Security Headers Middleware.
Ajoute les headers de securite recommandes par OWASP.
"""

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from app.core.config import settings


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Middleware ajoutant les headers de securite HTTP.

    Headers ajoutes:
    - X-Content-Type-Options: Empeche le MIME sniffing
    - X-Frame-Options: Protection contre le clickjacking
    - X-XSS-Protection: Protection XSS (legacy mais toujours utile)
    - Strict-Transport-Security: Force HTTPS (en production)
    - Content-Security-Policy: Politique de securite du contenu
    - Referrer-Policy: Controle les informations de referrer
    - Permissions-Policy: Controle les fonctionnalites du navigateur
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)

        # Headers de securite de base
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Permissions Policy - desactive les fonctionnalites non necessaires
        response.headers["Permissions-Policy"] = (
            "accelerometer=(), "
            "camera=(), "
            "geolocation=(), "
            "gyroscope=(), "
            "magnetometer=(), "
            "microphone=(), "
            "payment=(), "
            "usb=()"
        )

        # Headers supplementaires en production
        if settings.is_production:
            # HSTS - Force HTTPS pendant 1 an
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains; preload"
            )

            # CSP restrictif pour API
            response.headers["Content-Security-Policy"] = (
                "default-src 'none'; "
                "frame-ancestors 'none'; "
                "base-uri 'none'; "
                "form-action 'none'"
            )

        # Cache control pour les reponses API
        if "Cache-Control" not in response.headers:
            response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"

        return response
