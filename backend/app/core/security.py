"""
Module de securite pour l'authentification via Supabase Auth.

Gere:
- Validation des tokens Supabase JWT
- Dependencies FastAPI pour l'authentification
- Cache des tokens valides (evite d'appeler Supabase a chaque requete)
"""

import hashlib
from typing import Any, Optional
from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import settings
from app.core.logging import get_logger
from app.core.cache import get_cache
from app.core.exceptions import (
    AuthenticationError,
    TokenExpiredError,
    InvalidTokenError,
)

logger = get_logger("core.security")


# =============================================================================
# TOKEN CACHE (Redis-backed avec fallback memoire)
# =============================================================================
# Evite de revalider un token (JWT local ou API Supabase) a chaque requete.
# Le cache est partage entre workers en production via Redis.

_TOKEN_CACHE_TTL_SECONDS = 60
_ADMIN_LOOKUP_CACHE_TTL_SECONDS = 60


def _token_cache_key(token: str) -> str:
    """Cle de cache deterministe sans exposer le token brut en clair."""
    digest = hashlib.sha256(token.encode("utf-8")).hexdigest()
    return f"auth:token:{digest}"


def _get_cached_user(token: str) -> Optional[dict]:
    """Retourne l'utilisateur si le token est en cache (Redis ou memoire)."""
    try:
        return get_cache().get(_token_cache_key(token))
    except Exception as e:
        logger.warning(f"Token cache read failed: {e}")
        return None


def _cache_user(token: str, user_data: dict) -> None:
    """Met en cache les donnees utilisateur pour ce token."""
    try:
        get_cache().set(_token_cache_key(token), user_data, ttl=_TOKEN_CACHE_TTL_SECONDS)
    except Exception as e:
        logger.warning(f"Token cache write failed: {e}")


def _admin_profile_cache_key(user_id: UUID) -> str:
    return f"auth:admin_profile:{user_id}"


def _get_cached_admin_profile(user_id: UUID) -> Optional[dict]:
    try:
        return get_cache().get(_admin_profile_cache_key(user_id))
    except Exception as e:
        logger.warning(f"Admin profile cache read failed: {e}")
        return None


def _cache_admin_profile(user_id: UUID, profile: dict) -> None:
    try:
        get_cache().set(
            _admin_profile_cache_key(user_id),
            profile,
            ttl=_ADMIN_LOOKUP_CACHE_TTL_SECONDS,
        )
    except Exception as e:
        logger.warning(f"Admin profile cache write failed: {e}")


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

    - Aucun token fourni: retourne None (endpoint accessible en anonyme).
    - Token invalide ou expire: leve l'exception correspondante (le client
      a explicitement tente de s'authentifier, il doit savoir que ca a echoue).
    """
    if credentials is None:
        return None

    try:
        user_data = get_user_from_token(credentials.credentials)
        return UUID(user_data["user_id"])
    except (TokenExpiredError, InvalidTokenError):
        raise
    except Exception as e:
        logger.error(f"Optional authentication error: {e}")
        raise AuthenticationError("Token invalide")


# =============================================================================
# ADMIN DEPENDENCIES
# =============================================================================


async def get_current_admin(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> dict:
    """
    Dependency pour verifier que l'utilisateur est admin ou super_admin.

    Le lookup BD est execute dans un threadpool (client Supabase sync) et
    cache 60s pour eviter de bloquer l'event loop et de hammerer PostgREST.

    Returns:
        dict avec user_id (UUID) et role (str)
    """
    import asyncio

    if credentials is None:
        raise AuthenticationError("Token d'authentification requis")

    try:
        user_data = get_user_from_token(credentials.credentials)
        user_id = UUID(user_data["user_id"])
    except (TokenExpiredError, InvalidTokenError):
        raise
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise AuthenticationError("Token invalide")

    user = _get_cached_admin_profile(user_id)
    if user is None:
        from app.db.supabase_client import get_supabase_client
        db = get_supabase_client()
        user = await asyncio.to_thread(
            db.fetch_one,
            table="user_profiles",
            id_column="id",
            id_value=str(user_id),
        )
        if user:
            _cache_admin_profile(user_id, user)

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
# SCHOOL ADMIN DEPENDENCIES
# =============================================================================


async def get_current_school_admin(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> dict:
    """
    Dependency pour verifier que l'utilisateur est school_admin.

    Les lookups BD sont offloads sur threadpool pour ne pas bloquer l'event loop.

    Returns:
        dict avec user_id (UUID), school_id (str), email (str)
    """
    import asyncio

    if credentials is None:
        raise AuthenticationError("Token d'authentification requis")

    try:
        user_data = get_user_from_token(credentials.credentials)
        user_id = UUID(user_data["user_id"])
    except (TokenExpiredError, InvalidTokenError):
        raise
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise AuthenticationError("Token invalide")

    from app.db.supabase_client import get_supabase_client
    db = get_supabase_client()

    user, admin_profile = await asyncio.gather(
        asyncio.to_thread(
            db.fetch_one,
            table="user_profiles",
            id_column="id",
            id_value=str(user_id),
        ),
        asyncio.to_thread(
            db.fetch_one,
            table="school_admin_profiles",
            id_column="user_id",
            id_value=str(user_id),
        ),
    )

    if not user:
        raise AuthenticationError("Utilisateur non trouve")

    role = user.get("role", "student")
    if role != "school_admin":
        from app.core.exceptions import AuthorizationError
        raise AuthorizationError("Acces reserve aux administrateurs d'ecole")

    if not user.get("is_active", True):
        raise AuthenticationError("Compte desactive")

    if not admin_profile or not admin_profile.get("is_active", False):
        from app.core.exceptions import AuthorizationError
        raise AuthorizationError("Profil school admin inactif ou inexistant")

    return {
        "user_id": user_id,
        "school_id": admin_profile["school_id"],
        "email": user.get("email"),
    }
