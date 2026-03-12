"""
Tests unitaires pour le module de securite (Supabase Auth).
"""

import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch
from uuid import UUID

import pytest

# Setup env avant les imports app
os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder_key_for_testing_only_not_real")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder_service_role_key")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("DEBUG", "True")

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


# =============================================================================
# TOKEN CACHE TESTS
# =============================================================================


def test_token_cache_stores_and_retrieves():
    """Le cache token stocke et recupere les donnees correctement."""
    from app.core.security import _cache_user, _get_cached_user, _token_cache

    _token_cache.clear()

    token = "test_token_abc"
    user_data = {"user_id": "11111111-1111-1111-1111-111111111111", "email": "test@example.com"}

    _cache_user(token, user_data)
    cached = _get_cached_user(token)

    assert cached == user_data


def test_token_cache_expires():
    """Le cache token expire correctement."""
    import time
    from app.core.security import _cache_user, _get_cached_user, _token_cache, _cache_lock

    _token_cache.clear()

    token = "test_expiring_token"
    user_data = {"user_id": "test-id"}

    # Forcer une expiration immediate
    with _cache_lock:
        _token_cache[token] = (user_data, time.time() - 1)

    cached = _get_cached_user(token)
    assert cached is None  # Doit etre expire


def test_token_cache_clears_when_too_large():
    """Le cache se vide quand il depasse 1000 entrees."""
    from app.core.security import _cache_user, _token_cache

    _token_cache.clear()

    # Remplir le cache a 1001 entrees
    for i in range(1001):
        _cache_user(f"token_{i}", {"user_id": f"user_{i}"})

    # Le cache doit avoir ete vide puis rempli avec 1 entree
    # (clear() + 1 nouvelle entree)
    assert len(_token_cache) <= 1


# =============================================================================
# PASSWORD VALIDATION TESTS
# =============================================================================


def test_validate_password_strength_valid():
    """Mot de passe fort valide correctement."""
    from app.core.security import validate_password_strength

    is_valid, errors = validate_password_strength("SecurePass123!")
    assert is_valid is True
    assert len(errors) == 0


def test_validate_password_strength_too_short():
    """Mot de passe trop court retourne erreur."""
    from app.core.security import validate_password_strength

    is_valid, errors = validate_password_strength("Ab1!")
    assert is_valid is False
    assert any("8" in e for e in errors)


def test_validate_password_strength_no_uppercase():
    """Mot de passe sans majuscule retourne erreur."""
    from app.core.security import validate_password_strength

    is_valid, errors = validate_password_strength("securepass123!")
    assert is_valid is False
    assert any("majuscule" in e for e in errors)


def test_validate_password_strength_no_digit():
    """Mot de passe sans chiffre retourne erreur."""
    from app.core.security import validate_password_strength

    is_valid, errors = validate_password_strength("SecurePassWord!")
    assert is_valid is False
    assert any("chiffre" in e for e in errors)


def test_validate_password_strength_no_special():
    """Mot de passe sans caractere special retourne erreur."""
    from app.core.security import validate_password_strength

    is_valid, errors = validate_password_strength("SecurePass123")
    assert is_valid is False
    assert any("special" in e for e in errors)


# =============================================================================
# TOKEN VALIDATION TESTS (mocks Supabase)
# =============================================================================


def test_get_user_from_token_via_supabase_api():
    """Validation de token via API Supabase quand JWT secret absent."""
    from app.core.security import _validate_token_via_supabase, _token_cache

    _token_cache.clear()

    fake_user = MagicMock()
    fake_user.id = "11111111-1111-1111-1111-111111111111"
    fake_user.email = "test@example.com"
    fake_user.role = "authenticated"

    fake_response = MagicMock()
    fake_response.user = fake_user

    with patch("app.core.security.settings") as mock_settings, \
         patch("app.core.security.get_supabase_client") as mock_db_factory:

        mock_settings.SUPABASE_JWT_SECRET = None  # Pas de JWT secret local
        mock_db = MagicMock()
        mock_db.client.auth.get_user.return_value = fake_response
        mock_db_factory.return_value = mock_db

        result = _validate_token_via_supabase("fake_token")

        assert result["user_id"] == "11111111-1111-1111-1111-111111111111"
        assert result["email"] == "test@example.com"


def test_get_user_from_token_invalid():
    """Token invalide leve InvalidTokenError."""
    from app.core.security import _validate_token_via_supabase, _token_cache
    from app.core.exceptions import InvalidTokenError

    _token_cache.clear()

    with patch("app.core.security.settings") as mock_settings, \
         patch("app.core.security.get_supabase_client") as mock_db_factory:

        mock_settings.SUPABASE_JWT_SECRET = None
        mock_db = MagicMock()
        mock_db.client.auth.get_user.side_effect = Exception("JWT is invalid")
        mock_db_factory.return_value = mock_db

        with pytest.raises(InvalidTokenError):
            _validate_token_via_supabase("invalid_token")


def test_get_user_from_token_expired():
    """Token expire leve TokenExpiredError."""
    from app.core.security import _validate_token_via_supabase, _token_cache
    from app.core.exceptions import TokenExpiredError

    _token_cache.clear()

    with patch("app.core.security.settings") as mock_settings, \
         patch("app.core.security.get_supabase_client") as mock_db_factory:

        mock_settings.SUPABASE_JWT_SECRET = None
        mock_db = MagicMock()
        mock_db.client.auth.get_user.side_effect = Exception("jwt expired")
        mock_db_factory.return_value = mock_db

        with pytest.raises(TokenExpiredError):
            _validate_token_via_supabase("expired_token")
