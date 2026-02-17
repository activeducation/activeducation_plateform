"""
Systeme d'exceptions personnalisees pour ActivEducation API.

Fournit des exceptions typees qui sont automatiquement converties
en reponses HTTP appropriees par le handler global.
"""

from typing import Any, Optional
from fastapi import HTTPException, status


class AppException(Exception):
    """
    Exception de base pour l'application.
    Toutes les exceptions metier heritent de cette classe.
    """

    def __init__(
        self,
        message: str,
        code: str = "app_error",
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: Optional[dict[str, Any]] = None,
    ):
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)

    def to_dict(self) -> dict[str, Any]:
        """Convertit l'exception en dictionnaire pour la reponse JSON."""
        result = {
            "error": self.code,
            "message": self.message,
        }
        if self.details:
            result["details"] = self.details
        return result

    def to_http_exception(self) -> HTTPException:
        """Convertit en HTTPException FastAPI."""
        return HTTPException(
            status_code=self.status_code,
            detail=self.to_dict(),
        )


# =============================================================================
# EXCEPTIONS D'AUTHENTIFICATION
# =============================================================================


class AuthenticationError(AppException):
    """Erreur d'authentification (credentials invalides)."""

    def __init__(
        self,
        message: str = "Authentification echouee",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            code="authentication_error",
            status_code=status.HTTP_401_UNAUTHORIZED,
            details=details,
        )


class AuthorizationError(AppException):
    """Erreur d'autorisation (permissions insuffisantes)."""

    def __init__(
        self,
        message: str = "Acces non autorise",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            code="authorization_error",
            status_code=status.HTTP_403_FORBIDDEN,
            details=details,
        )


class TokenExpiredError(AuthenticationError):
    """Token JWT expire."""

    def __init__(self, message: str = "Token expire"):
        super().__init__(message=message, details={"reason": "token_expired"})


class InvalidTokenError(AuthenticationError):
    """Token JWT invalide."""

    def __init__(self, message: str = "Token invalide"):
        super().__init__(message=message, details={"reason": "invalid_token"})


# =============================================================================
# EXCEPTIONS DE RESSOURCES
# =============================================================================


class NotFoundError(AppException):
    """Ressource non trouvee."""

    def __init__(
        self,
        resource: str = "Ressource",
        resource_id: Optional[str] = None,
        message: Optional[str] = None,
    ):
        if message is None:
            message = f"{resource} non trouve(e)"
            if resource_id:
                message = f"{resource} avec ID '{resource_id}' non trouve(e)"

        super().__init__(
            message=message,
            code="not_found",
            status_code=status.HTTP_404_NOT_FOUND,
            details={"resource": resource, "resource_id": resource_id},
        )


class AlreadyExistsError(AppException):
    """Ressource existe deja."""

    def __init__(
        self,
        resource: str = "Ressource",
        field: Optional[str] = None,
        value: Optional[str] = None,
    ):
        message = f"{resource} existe deja"
        if field and value:
            message = f"{resource} avec {field}='{value}' existe deja"

        super().__init__(
            message=message,
            code="already_exists",
            status_code=status.HTTP_409_CONFLICT,
            details={"resource": resource, "field": field, "value": value},
        )


# =============================================================================
# EXCEPTIONS DE VALIDATION
# =============================================================================


class ValidationError(AppException):
    """Erreur de validation des donnees."""

    def __init__(
        self,
        message: str = "Donnees invalides",
        errors: Optional[list[dict[str, Any]]] = None,
    ):
        super().__init__(
            message=message,
            code="validation_error",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"errors": errors or []},
        )


class InvalidInputError(ValidationError):
    """Entree utilisateur invalide."""

    def __init__(self, field: str, message: str):
        super().__init__(
            message=f"Champ '{field}' invalide: {message}",
            errors=[{"field": field, "message": message}],
        )


# =============================================================================
# EXCEPTIONS DE BASE DE DONNEES
# =============================================================================


class DatabaseError(AppException):
    """Erreur de base de donnees."""

    def __init__(
        self,
        message: str = "Erreur de base de donnees",
        operation: Optional[str] = None,
        details: Optional[dict[str, Any]] = None,
    ):
        error_details = details or {}
        if operation:
            error_details["operation"] = operation

        super().__init__(
            message=message,
            code="database_error",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details=error_details,
        )


class ConnectionError(DatabaseError):
    """Erreur de connexion a la base de donnees."""

    def __init__(self, message: str = "Impossible de se connecter a la base de donnees"):
        super().__init__(message=message, operation="connect")


class QueryError(DatabaseError):
    """Erreur lors de l'execution d'une requete."""

    def __init__(self, message: str = "Erreur lors de l'execution de la requete"):
        super().__init__(message=message, operation="query")


# =============================================================================
# EXCEPTIONS METIER
# =============================================================================


class TestNotFoundError(NotFoundError):
    """Test d'orientation non trouve."""

    def __init__(self, test_id: str):
        super().__init__(resource="Test d'orientation", resource_id=test_id)


class TestSessionError(AppException):
    """Erreur liee a une session de test."""

    def __init__(
        self,
        message: str = "Erreur de session de test",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            code="test_session_error",
            status_code=status.HTTP_400_BAD_REQUEST,
            details=details,
        )


class TestAlreadyCompletedError(TestSessionError):
    """Test deja complete."""

    def __init__(self, session_id: str):
        super().__init__(
            message="Ce test a deja ete complete",
            details={"session_id": session_id},
        )


class InvalidTestResponseError(ValidationError):
    """Reponse de test invalide."""

    def __init__(self, question_id: str, reason: str):
        super().__init__(
            message=f"Reponse invalide pour la question '{question_id}': {reason}",
            errors=[{"question_id": question_id, "reason": reason}],
        )


class CareerNotFoundError(NotFoundError):
    """Carriere non trouvee."""

    def __init__(self, career_id: str):
        super().__init__(resource="Carriere", resource_id=career_id)


# =============================================================================
# EXCEPTIONS EXTERNES
# =============================================================================


class ExternalServiceError(AppException):
    """Erreur de service externe."""

    def __init__(
        self,
        service: str,
        message: str = "Service externe indisponible",
        details: Optional[dict[str, Any]] = None,
    ):
        error_details = details or {}
        error_details["service"] = service

        super().__init__(
            message=message,
            code="external_service_error",
            status_code=status.HTTP_502_BAD_GATEWAY,
            details=error_details,
        )


class SupabaseError(ExternalServiceError):
    """Erreur specifique a Supabase."""

    def __init__(
        self,
        message: str = "Erreur Supabase",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(service="supabase", message=message, details=details)
