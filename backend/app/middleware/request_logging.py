"""
Request Logging Middleware.
Log toutes les requetes avec correlation IDs pour le tracing.
"""

import time
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
import logging
from typing import Callable

from app.core.config import settings

logger = logging.getLogger("activeducation.requests")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware de logging des requetes HTTP.

    Fonctionnalites:
    - Genere un correlation ID unique par requete
    - Log les details de la requete et reponse
    - Mesure le temps de traitement
    - Masque les donnees sensibles
    """

    # Paths a exclure du logging detaille
    EXCLUDED_PATHS = {"/health", "/", "/docs", "/openapi.json", "/redoc"}

    # Headers sensibles a masquer
    SENSITIVE_HEADERS = {"authorization", "cookie", "x-api-key"}

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Generer un correlation ID unique
        correlation_id = request.headers.get("X-Correlation-ID") or str(uuid.uuid4())

        # Stocker dans request.state pour acces dans les handlers
        request.state.correlation_id = correlation_id

        # Mesurer le temps de traitement
        start_time = time.perf_counter()

        # Log de la requete entrante (sauf paths exclus)
        if request.url.path not in self.EXCLUDED_PATHS:
            self._log_request(request, correlation_id)

        try:
            response = await call_next(request)
        except Exception as e:
            # Log des erreurs non gerees
            process_time = time.perf_counter() - start_time
            logger.error(
                "Request failed",
                extra={
                    "correlation_id": correlation_id,
                    "method": request.method,
                    "path": request.url.path,
                    "error": str(e),
                    "process_time_ms": round(process_time * 1000, 2),
                },
            )
            raise

        # Calculer le temps de traitement
        process_time = time.perf_counter() - start_time

        # Ajouter les headers de tracing
        response.headers["X-Correlation-ID"] = correlation_id
        response.headers["X-Process-Time"] = f"{process_time * 1000:.2f}ms"

        # Log de la reponse (sauf paths exclus)
        if request.url.path not in self.EXCLUDED_PATHS:
            self._log_response(request, response, correlation_id, process_time)

        return response

    def _log_request(self, request: Request, correlation_id: str) -> None:
        """Log les details de la requete entrante."""
        # Masquer les headers sensibles
        safe_headers = {
            k: "***MASKED***" if k.lower() in self.SENSITIVE_HEADERS else v
            for k, v in request.headers.items()
        }

        log_data = {
            "correlation_id": correlation_id,
            "type": "request",
            "method": request.method,
            "path": request.url.path,
            "query_params": dict(request.query_params),
            "client_ip": self._get_client_ip(request),
            "user_agent": request.headers.get("user-agent", "unknown"),
        }

        if settings.DEBUG:
            log_data["headers"] = safe_headers

        logger.info(f"Incoming {request.method} {request.url.path}", extra=log_data)

    def _log_response(
        self,
        request: Request,
        response: Response,
        correlation_id: str,
        process_time: float,
    ) -> None:
        """Log les details de la reponse."""
        log_data = {
            "correlation_id": correlation_id,
            "type": "response",
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "process_time_ms": round(process_time * 1000, 2),
        }

        # Niveau de log selon le status code
        if response.status_code >= 500:
            logger.error(f"Response {response.status_code}", extra=log_data)
        elif response.status_code >= 400:
            logger.warning(f"Response {response.status_code}", extra=log_data)
        else:
            logger.info(f"Response {response.status_code}", extra=log_data)

    def _get_client_ip(self, request: Request) -> str:
        """Extrait l'IP client en tenant compte des proxies."""
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()

        x_real_ip = request.headers.get("X-Real-IP")
        if x_real_ip:
            return x_real_ip

        return request.client.host if request.client else "unknown"
