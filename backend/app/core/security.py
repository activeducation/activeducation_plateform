"""
Module de securite pour l'authentification.

Gere:
- Generation et validation de tokens JWT
- Hashing de mots de passe avec bcrypt
- Dependencies FastAPI pour l'authentification
"""

from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel

from app.core.config import settings
from app.core.logging import get_logger
from app.core.exceptions import (
    AuthenticationError,
    TokenExpiredError,
    InvalidTokenError,
)

logger = get_logger("core.security")

# =============================================================================
# PASSWORD HASHING
# =============================================================================

import bcrypt as _bcrypt

# Context pour le hashing des mots de passe (utilise bcrypt directement)
_BCRYPT_ROUNDS = 12


def _truncate_password(password: str) -> bytes:
    """Tronque le mot de passe a 72 bytes (limite bcrypt) et retourne en bytes."""
    return password.encode('utf-8')[:72]


def hash_password(password: str) -> str:
    """
    Hash un mot de passe avec bcrypt.

    Args:
        password: Mot de passe en clair

    Returns:
        Hash du mot de passe
    """
    pwd_bytes = _truncate_password(password)
    salt = _bcrypt.gensalt(rounds=_BCRYPT_ROUNDS)
    return _bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verifie un mot de passe contre son hash.

    Args:
        plain_password: Mot de passe en clair
        hashed_password: Hash stocke

    Returns:
        True si le mot de passe correspond
    """
    try:
        pwd_bytes = _truncate_password(plain_password)
        return _bcrypt.checkpw(pwd_bytes, hashed_password.encode('utf-8'))
    except Exception as e:
        logger.error(f"Password verification error: {e}")
        return False


# =============================================================================
# JWT TOKENS
# =============================================================================


class TokenPayload(BaseModel):
    """Payload du token JWT."""

    sub: str  # Subject (user_id)
    exp: datetime  # Expiration
    iat: datetime  # Issued at
    type: str  # "access" ou "refresh"
    email: Optional[str] = None


class TokenPair(BaseModel):
    """Paire de tokens (access + refresh)."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # Secondes avant expiration


def create_access_token(
    user_id: str | UUID,
    email: Optional[str] = None,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Cree un token d'acces JWT.

    Args:
        user_id: ID de l'utilisateur
        email: Email de l'utilisateur (optionnel)
        expires_delta: Duree de validite custom

    Returns:
        Token JWT encode
    """
    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    now = datetime.now(timezone.utc)
    expire = now + expires_delta

    payload = {
        "sub": str(user_id),
        "exp": expire,
        "iat": now,
        "type": "access",
    }

    if email:
        payload["email"] = email

    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    logger.debug(
        f"Created access token for user {user_id}",
        extra={"expires_at": expire.isoformat()},
    )

    return token


def create_refresh_token(
    user_id: str | UUID,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Cree un token de rafraichissement JWT.

    Args:
        user_id: ID de l'utilisateur
        expires_delta: Duree de validite custom

    Returns:
        Token JWT encode
    """
    if expires_delta is None:
        expires_delta = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    now = datetime.now(timezone.utc)
    expire = now + expires_delta

    payload = {
        "sub": str(user_id),
        "exp": expire,
        "iat": now,
        "type": "refresh",
    }

    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    return token


def create_token_pair(user_id: str | UUID, email: Optional[str] = None) -> TokenPair:
    """
    Cree une paire de tokens (access + refresh).

    Args:
        user_id: ID de l'utilisateur
        email: Email de l'utilisateur

    Returns:
        TokenPair avec les deux tokens
    """
    access_token = create_access_token(user_id, email)
    refresh_token = create_refresh_token(user_id)

    return TokenPair(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


def decode_token(token: str) -> TokenPayload:
    """
    Decode et valide un token JWT.

    Args:
        token: Token JWT a decoder

    Returns:
        TokenPayload avec les donnees du token

    Raises:
        TokenExpiredError: Si le token a expire
        InvalidTokenError: Si le token est invalide
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )

        return TokenPayload(
            sub=payload["sub"],
            exp=datetime.fromtimestamp(payload["exp"], tz=timezone.utc),
            iat=datetime.fromtimestamp(payload["iat"], tz=timezone.utc),
            type=payload.get("type", "access"),
            email=payload.get("email"),
        )

    except jwt.ExpiredSignatureError:
        raise TokenExpiredError()
    except JWTError as e:
        logger.warning(f"JWT decode error: {e}")
        raise InvalidTokenError()


def verify_access_token(token: str) -> TokenPayload:
    """
    Verifie un token d'acces.

    Args:
        token: Token a verifier

    Returns:
        TokenPayload si valide

    Raises:
        InvalidTokenError: Si ce n'est pas un token d'acces
    """
    payload = decode_token(token)

    if payload.type != "access":
        raise InvalidTokenError("Token type invalide")

    return payload


def verify_refresh_token(token: str) -> TokenPayload:
    """
    Verifie un token de rafraichissement.

    Args:
        token: Token a verifier

    Returns:
        TokenPayload si valide

    Raises:
        InvalidTokenError: Si ce n'est pas un refresh token
    """
    payload = decode_token(token)

    if payload.type != "refresh":
        raise InvalidTokenError("Token type invalide")

    return payload


# =============================================================================
# PASSWORD RESET TOKENS
# =============================================================================


def create_password_reset_token(email: str) -> str:
    """
    Cree un token de reinitialisation de mot de passe.

    Args:
        email: Email de l'utilisateur

    Returns:
        Token de reset (valide 1 heure)
    """
    expire = datetime.now(timezone.utc) + timedelta(hours=1)

    payload = {
        "sub": email,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "password_reset",
    }

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def verify_password_reset_token(token: str) -> str:
    """
    Verifie un token de reinitialisation.

    Args:
        token: Token a verifier

    Returns:
        Email de l'utilisateur

    Raises:
        InvalidTokenError: Si le token est invalide
    """
    payload = decode_token(token)

    if payload.type != "password_reset":
        raise InvalidTokenError("Token type invalide")

    return payload.sub  # L'email est dans le subject


# =============================================================================
# FASTAPI DEPENDENCIES
# =============================================================================

# Bearer token security scheme
bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> UUID:
    """
    Dependency pour obtenir l'ID de l'utilisateur courant.

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
        payload = verify_access_token(credentials.credentials)
        return UUID(payload.sub)
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
    Utile pour les endpoints publics avec fonctionnalites supplementaires pour les users connectes.
    """
    if credentials is None:
        return None

    try:
        payload = verify_access_token(credentials.credentials)
        return UUID(payload.sub)
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
        payload = verify_access_token(credentials.credentials)
        user_id = UUID(payload.sub)
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
# UTILITIES
# =============================================================================


def validate_password_strength(password: str) -> tuple[bool, list[str]]:
    """
    Valide la force d'un mot de passe.

    Args:
        password: Mot de passe a valider

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

    import re
    if not re.search(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]', password):
        errors.append("Le mot de passe doit contenir au moins un caractere special (!@#$%&*...)")

    return len(errors) == 0, errors
