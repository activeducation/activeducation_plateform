"""
Configuration centralisee du logging pour ActivEducation API.
Support des logs JSON structures pour production.
"""

import logging
import sys
from typing import Any
from datetime import datetime
import json

from app.core.config import settings


class JSONFormatter(logging.Formatter):
    """
    Formatter JSON pour logs structures.
    Ideal pour l'integration avec des outils comme ELK, Datadog, etc.
    """

    # Champs sensibles a masquer dans les logs
    SENSITIVE_FIELDS = {
        "password",
        "token",
        "secret",
        "authorization",
        "api_key",
        "access_token",
        "refresh_token",
        "credit_card",
        "ssn",
    }

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Ajouter les extras du record
        if hasattr(record, "__dict__"):
            for key, value in record.__dict__.items():
                if key not in {
                    "name",
                    "msg",
                    "args",
                    "created",
                    "filename",
                    "funcName",
                    "levelname",
                    "levelno",
                    "lineno",
                    "module",
                    "msecs",
                    "pathname",
                    "process",
                    "processName",
                    "relativeCreated",
                    "stack_info",
                    "exc_info",
                    "exc_text",
                    "thread",
                    "threadName",
                    "taskName",
                    "message",
                }:
                    log_data[key] = self._mask_sensitive(key, value)

        # Ajouter les informations d'exception si presentes
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data, default=str, ensure_ascii=False)

    def _mask_sensitive(self, key: str, value: Any) -> Any:
        """Masque les valeurs sensibles dans les logs."""
        if isinstance(value, str) and any(
            sensitive in key.lower() for sensitive in self.SENSITIVE_FIELDS
        ):
            return "***MASKED***"
        if isinstance(value, dict):
            return {k: self._mask_sensitive(k, v) for k, v in value.items()}
        return value


class ColoredFormatter(logging.Formatter):
    """
    Formatter colore pour le developpement.
    Facilite la lecture des logs en console.
    """

    COLORS = {
        "DEBUG": "\033[36m",  # Cyan
        "INFO": "\033[32m",  # Green
        "WARNING": "\033[33m",  # Yellow
        "ERROR": "\033[31m",  # Red
        "CRITICAL": "\033[35m",  # Magenta
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, self.RESET)

        # Format de base
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        base_msg = f"{color}{timestamp} | {record.levelname:8s}{self.RESET} | {record.name} | {record.getMessage()}"

        # Ajouter les extras pertinents
        extras = []
        for key in ["correlation_id", "method", "path", "status_code", "process_time_ms"]:
            if hasattr(record, key):
                extras.append(f"{key}={getattr(record, key)}")

        if extras:
            base_msg += f" | {' '.join(extras)}"

        # Ajouter l'exception si presente
        if record.exc_info:
            base_msg += f"\n{self.formatException(record.exc_info)}"

        return base_msg


def setup_logging() -> None:
    """
    Configure le systeme de logging global.
    Utilise JSON en production, format colore en developpement.
    """
    # Niveau de log depuis la config
    log_level = getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO)

    # Handler console
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)

    # Choisir le formatter selon l'environnement
    if settings.is_production:
        formatter = JSONFormatter()
    else:
        formatter = ColoredFormatter()

    console_handler.setFormatter(formatter)

    # Configuration du logger racine
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)

    # Supprimer les handlers existants pour eviter les doublons
    root_logger.handlers.clear()
    root_logger.addHandler(console_handler)

    # Configurer les loggers specifiques
    loggers_config = {
        "activeducation": log_level,
        "activeducation.requests": log_level,
        "uvicorn": logging.INFO,
        "uvicorn.access": logging.WARNING if settings.is_production else logging.INFO,
        "uvicorn.error": logging.ERROR,
        "fastapi": logging.INFO,
        "httpx": logging.WARNING,
        "httpcore": logging.WARNING,
    }

    for logger_name, level in loggers_config.items():
        logger = logging.getLogger(logger_name)
        logger.setLevel(level)
        logger.handlers.clear()
        logger.addHandler(console_handler)
        logger.propagate = False


def get_logger(name: str) -> logging.Logger:
    """
    Retourne un logger configure pour le module specifie.

    Usage:
        from app.core.logging import get_logger
        logger = get_logger(__name__)
        logger.info("Message", extra={"user_id": 123})
    """
    return logging.getLogger(f"activeducation.{name}")
