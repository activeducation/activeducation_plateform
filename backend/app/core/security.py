"""
Module de securite pour l'authentification via Supabase Auth.

Gere:
- Validation des tokens Supabase JWT
- Dependencies FastAPI pour l'authentification
- Cache des tokens valides (evite d'appeler Supabase a chaque requete)
"""

import re
import time
from threading import Lock
from typing import Any, Optional
from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import settings
from app.core.logging import get_logger
from app.core.exceptions import (
    AuthenticationError,
    TokenExpiredError,
    InvalidTokenError,
)

logger = get_logger("core.security")


# =============================================================================
# TOKEN CACHE (evite d'appeler Supabase a chaque requete)
# =============================================================================

_token_cache: dict[str, tuple[dict, float]] = {}
_cache_lock = Lock()
_CACHE_TTL_SECONDS = 60  # Cache valide 60 secondes


def _get_cached_user(token: str) -> Optional[dict]:
    """Retourne l'utilisateur si le token est en cache et non expire."""
    with _cache_lock:
        cached = _token_cache.get(token)
        if cached:
            user_data, expires_at = cached
            if time.time() < expires_at:
                return user_data
            else:
                del _token_cache[token]
    return None


def _cache_user(token: str, user_data: dict) -> None:
    """Met en cache les donnees utilisateur pour ce token."""
    with _cache_lock:
        # Eviter que le cache grossisse trop
        if len(_token_cache) > 1000:
            _token_cache.clear()
        _token_cache[token] = (user_data, time.time() + _CACHE_TTL_SECONDS)


# =============================================================================
# VALIDATION TOKEN SUPABASE
# =============================================================================


def _validate_token_via_supabase(token: str) -> dict[str, Any]:
    """
    Valide un token JWT aupres de Supabase et retourne les donnees utilisateur.

    Essaie d'abord la validation locale (si SUPABASE_JWT_SECRET est configure),
    sinon appelle l'API Supabase.

    Args:
        token: Token JWT Supabase

    Returns:
        Dict avec user_id, email, role

    Raises:
        TokenExpiredError: Si le token est expire
        InvalidTokenError: Si le token est invalide
    """
    # Tentative de validation locale (performante, 0 reseau)
    if settings.SUPABASE_JWT_SECRET:
        try:
            from jose import JWTError, jwt as jose_jwt
            from jose.exceptions import ExpiredSignatureError

            payload = jose_jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                audience="authenticated",
            )
            return {
                "user_id": payload["sub"],
                "email": payload.get("email"),
                "role": payload.get("role", "authenticated"),
            }
        except ExpiredSignatureError:
            raise TokenExpiredError()
        except JWTError as e:
            logger.warning(f"Local JWT validation failed, trying Supabase API: {e}")
            # Fallback vers l'API Supabase

    # Validation via API Supabase (si pas de JWT secret local)
    try:
        from app.db.supabase_client import get_supabase_client
        db = get_supabase_client()
        response = db.client.auth.get_user(token)

        if not response or not response.user:
            raise InvalidTokenError("Token invalide")

        return {
            "user_id": response.user.id,
            "email": response.user.email,
            "role": response.user.role,
        }

    except (TokenExpiredError, InvalidTokenError):
        raise
    except Exception as e:
        error_msg = str(e).lower()
        if "expired" in error_msg or "jwt expired" in error_msg:
            raise TokenExpiredError()
        logger.warning(f"Token validation error: {e}")
        raise InvalidTokenError("Token invalide ou expire")


def get_user_from_token(token: str) -> dict[str, Any]:
    """
    Valide un token et retourne les donnees utilisateur (avec cache).

    Args:
        token: Token JWT Supabase

    Returns:
        Dict avec user_id (str), email, role

    Raises:
        TokenExpiredError, InvalidTokenError
    """
    cached = _get_cached_user(token)
    if cached:
        return cached

    user_data = _validate_token_via_supabase(token)
    _cache_user(token, user_data)
    return user_data


# =============================================================================
# FASTAPI DEPENDENCIES
# =============================================================================

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> UUID:
    """
    Dependency pour obtenir l'ID de l'utilisateur courant (Supabase Auth).

    Usage:
        @router.get("/me")
        async def get_me(user_id: UUID = Depends(get_current_user_id)):
            ...

    Raises:
        AuthenticationError: Si pas de token ou token invalide
    """
    if credentials is None:
        raise AuthenticationError("Token d'authentification requis")

    try:
        user_data = get_user_from_token(credentials.credentials)
        return UUID(user_data["user_id"])
    except (TokenExpiredError, InvalidTokenError) as e:
        raise e
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise AuthenticationError("Token invalide")


async def get_current_user_id_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> Optional[UUID]:
    """
    Dependency optionnelle pour l'authentification.
    Retourne None si pas de token au lieu de lever une exception.
    """
    if credentials is None:
        return None

    try:
        user_data = get_user_from_token(credentials.credentials)
        return UUID(user_data["user_id"])
    except Exception:
        return None


# =============================================================================
# ADMIN DEPENDENCIES
# =============================================================================


async def get_current_admin(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> dict:
    """
    Dependency pour verifier que l'utilisateur est admin ou super_admin.

    Returns:
        dict avec user_id (UUID) et role (str)
    """
    if credentials is None:
        raise AuthenticationError("Token d'authentification requis")

    try:
        user_data = get_user_from_token(credentials.credentials)
        user_id = UUID(user_data["user_id"])
    except (TokenExpiredError, InvalidTokenError) as e:
        raise e
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise AuthenticationError("Token invalide")

    from app.db.supabase_client import get_supabase_client
    db = get_supabase_client()
    user = db.fetch_one(table="user_profiles", id_column="id", id_value=str(user_id))

    if not user:
        raise AuthenticationError("Utilisateur non trouve")

    role = user.get("role", "student")
    if role not in ("admin", "super_admin"):
        from app.core.exceptions import AuthorizationError
        raise AuthorizationError("Acces reserve aux administrateurs")

    if not user.get("is_active", True):
        raise AuthenticationError("Compte desactive")

    return {"user_id": user_id, "role": role, "email": user.get("email")}


async def get_current_super_admin(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> dict:
    """
    Dependency pour verifier que l'utilisateur est super_admin.

    Returns:
        dict avec user_id (UUID) et role (str)
    """
    admin = await get_current_admin(credentials)

    if admin["role"] != "super_admin":
        from app.core.exceptions import AuthorizationError
        raise AuthorizationError("Acces reserve aux super administrateurs")

    return admin


# =============================================================================
# PASSWORD VALIDATION (utilisee dans les schemas Pydantic)
# =============================================================================


def validate_password_strength(password: str) -> tuple[bool, list[str]]:
    """
    Valide la force d'un mot de passe.

    Returns:
        Tuple (is_valid, list_of_errors)
    """
    errors = []

    if len(password) < 8:
        errors.append("Le mot de passe doit contenir au moins 8 caracteres")
    if not any(c.isupper() for c in password):
        errors.append("Le mot de passe doit contenir au moins une majuscule")
    if not any(c.islower() for c in password):
        errors.append("Le mot de passe doit contenir au moins une minuscule")
    if not any(c.isdigit() for c in password):
        errors.append("Le mot de passe doit contenir au moins un chiffre")
    if not re.search(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]', password):
        errors.append("Le mot de passe doit contenir au moins un caractere special")

    return len(errors) == 0, errors
