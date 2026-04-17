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
    from app.core.security import _cache_user, _get_cached_user
    from app.core.cache import get_cache

    get_cache().clear()

    token = "test_token_abc"
    user_data = {"user_id": "11111111-1111-1111-1111-111111111111", "email": "test@example.com"}

    _cache_user(token, user_data)
    cached = _get_cached_user(token)

    assert cached == user_data


def test_token_cache_miss_returns_none():
    """Un token jamais cache retourne None."""
    from app.core.security import _get_cached_user
    from app.core.cache import get_cache

    get_cache().clear()

    assert _get_cached_user("token_jamais_vu") is None


def test_token_cache_key_hashes_token():
    """La cle de cache ne contient pas le token brut (SHA256)."""
    from app.core.security import _token_cache_key

    token = "super_secret_jwt"
    key = _token_cache_key(token)

    assert token not in key
    assert key.startswith("auth:token:")
    assert len(key) == len("auth:token:") + 64  # hex SHA256


# =============================================================================
# TOKEN VALIDATION TESTS (mocks Supabase)
# =============================================================================


def test_get_user_from_token_via_supabase_api():
    """Validation de token via API Supabase quand JWT secret absent."""
    from app.core.security import _validate_token_via_supabase
    from app.core.cache import get_cache

    get_cache().clear()

    fake_user = MagicMock()
    fake_user.id = "11111111-1111-1111-1111-111111111111"
    fake_user.email = "test@example.com"
    fake_user.role = "authenticated"

    fake_response = MagicMock()
    fake_response.user = fake_user

    with patch("app.core.security.settings") as mock_settings, \
         patch("app.db.supabase_client.get_supabase_client") as mock_db_factory:

        mock_settings.SUPABASE_JWT_SECRET = None  # Pas de JWT secret local
        mock_db = MagicMock()
        mock_db.client.auth.get_user.return_value = fake_response
        mock_db_factory.return_value = mock_db

        result = _validate_token_via_supabase("fake_token")

        assert result["user_id"] == "11111111-1111-1111-1111-111111111111"
        assert result["email"] == "test@example.com"


def test_get_user_from_token_invalid():
    """Token invalide leve InvalidTokenError."""
    from app.core.security import _validate_token_via_supabase
    from app.core.cache import get_cache
    from app.core.exceptions import InvalidTokenError

    get_cache().clear()

    with patch("app.core.security.settings") as mock_settings, \
         patch("app.db.supabase_client.get_supabase_client") as mock_db_factory:

        mock_settings.SUPABASE_JWT_SECRET = None
        mock_db = MagicMock()
        mock_db.client.auth.get_user.side_effect = Exception("JWT is invalid")
        mock_db_factory.return_value = mock_db

        with pytest.raises(InvalidTokenError):
            _validate_token_via_supabase("invalid_token")


def test_get_user_from_token_expired():
    """Token expire leve TokenExpiredError."""
    from app.core.security import _validate_token_via_supabase
    from app.core.cache import get_cache
    from app.core.exceptions import TokenExpiredError

    get_cache().clear()

    with patch("app.core.security.settings") as mock_settings, \
         patch("app.db.supabase_client.get_supabase_client") as mock_db_factory:

        mock_settings.SUPABASE_JWT_SECRET = None
        mock_db = MagicMock()
        mock_db.client.auth.get_user.side_effect = Exception("jwt expired")
        mock_db_factory.return_value = mock_db

        with pytest.raises(TokenExpiredError):
            _validate_token_via_supabase("expired_token")
