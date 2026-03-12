"""
Tests unitaires pour le service d'authentification (Supabase Auth).
"""

import os
import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import UUID, uuid4

import pytest

# Setup env avant les imports app
os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder_key_for_testing_only_not_real")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder_service_role_key_for_testing")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("DEBUG", "True")

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.exceptions import AuthenticationError, AlreadyExistsError, InvalidTokenError
from app.schemas.auth import LoginRequest, RegisterRequest


# =============================================================================
# FIXTURES
# =============================================================================

FAKE_USER_ID = "11111111-1111-1111-1111-111111111111"
FAKE_EMAIL = "test@example.com"
FAKE_PASSWORD = "SecurePass123!"


def make_fake_supabase_response(user_id=FAKE_USER_ID, email=FAKE_EMAIL, with_session=True):
    """Cree un mock de reponse Supabase Auth."""
    user = MagicMock()
    user.id = user_id
    user.email = email
    user.role = "authenticated"

    response = MagicMock()
    response.user = user

    if with_session:
        session = MagicMock()
        session.access_token = "fake_access_token"
        session.refresh_token = "fake_refresh_token"
        session.expires_in = 3600
        response.session = session
    else:
        response.session = None

    return response


def make_fake_profile(user_id=FAKE_USER_ID, email=FAKE_EMAIL):
    """Cree un mock de profil utilisateur."""
    from datetime import datetime
    return {
        "id": user_id,
        "email": email,
        "first_name": "Jean",
        "last_name": "Dupont",
        "display_name": "Jean Dupont",
        "phone_number": None,
        "avatar_url": None,
        "preferred_language": "fr",
        "created_at": datetime.now().isoformat(),
        "updated_at": None,
    }


# =============================================================================
# LOGIN TESTS
# =============================================================================


@pytest.mark.asyncio
async def test_login_success():
    """Login avec credentials valides retourne AuthResponse."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        # Mock Supabase client
        mock_db = MagicMock()
        mock_db.client.auth.sign_in_with_password.return_value = make_fake_supabase_response()
        mock_db_factory.return_value = mock_db

        # Mock users repo
        mock_repo = MagicMock()
        profile = make_fake_profile()
        mock_repo.get_by_id = AsyncMock(return_value=profile)
        mock_repo.update_last_login = AsyncMock(return_value=True)
        mock_repo_factory.return_value = mock_repo

        service = AuthService()
        result = await service.login(LoginRequest(email=FAKE_EMAIL, password=FAKE_PASSWORD))

        assert result.user.email == FAKE_EMAIL
        assert result.tokens.access_token == "fake_access_token"
        assert result.tokens.refresh_token == "fake_refresh_token"
        assert result.tokens.expires_in == 3600


@pytest.mark.asyncio
async def test_login_invalid_credentials():
    """Login avec mauvais credentials leve AuthenticationError."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        mock_db = MagicMock()
        mock_db.client.auth.sign_in_with_password.side_effect = Exception("Invalid credentials")
        mock_db_factory.return_value = mock_db
        mock_repo_factory.return_value = MagicMock()

        service = AuthService()

        with pytest.raises(AuthenticationError):
            await service.login(LoginRequest(email=FAKE_EMAIL, password="wrongpassword"))


@pytest.mark.asyncio
async def test_login_creates_profile_if_missing():
    """Login cree le profil si il n'existe pas encore."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        mock_db = MagicMock()
        mock_db.client.auth.sign_in_with_password.return_value = make_fake_supabase_response()
        mock_db_factory.return_value = mock_db

        mock_repo = MagicMock()
        profile = make_fake_profile()
        mock_repo.get_by_id = AsyncMock(return_value=None)  # Pas de profil
        mock_repo.create_profile = AsyncMock(return_value=profile)
        mock_repo.update_last_login = AsyncMock(return_value=True)
        mock_repo_factory.return_value = mock_repo

        service = AuthService()
        result = await service.login(LoginRequest(email=FAKE_EMAIL, password=FAKE_PASSWORD))

        # Verifier que create_profile a ete appele
        mock_repo.create_profile.assert_called_once()
        assert result.user.email == FAKE_EMAIL


# =============================================================================
# REGISTER TESTS
# =============================================================================


@pytest.mark.asyncio
async def test_register_success():
    """Inscription reussie retourne AuthResponse."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        mock_db = MagicMock()
        mock_db.client.auth.sign_up.return_value = make_fake_supabase_response()
        mock_db_factory.return_value = mock_db

        mock_repo = MagicMock()
        profile = make_fake_profile()
        mock_repo.create_profile = AsyncMock(return_value=profile)
        mock_repo_factory.return_value = mock_repo

        service = AuthService()
        result = await service.register(RegisterRequest(
            email=FAKE_EMAIL,
            password=FAKE_PASSWORD,
            first_name="Jean",
            last_name="Dupont",
        ))

        assert result.user.email == FAKE_EMAIL
        mock_repo.create_profile.assert_called_once()


@pytest.mark.asyncio
async def test_register_duplicate_email():
    """Inscription avec email existant leve AlreadyExistsError."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        mock_db = MagicMock()
        mock_db.client.auth.sign_up.side_effect = Exception("User already exists")
        mock_db_factory.return_value = mock_db
        mock_repo_factory.return_value = MagicMock()

        service = AuthService()

        with pytest.raises(AlreadyExistsError):
            await service.register(RegisterRequest(
                email=FAKE_EMAIL,
                password=FAKE_PASSWORD,
                first_name="Jean",
                last_name="Dupont",
            ))


# =============================================================================
# TOKEN REFRESH TESTS
# =============================================================================


@pytest.mark.asyncio
async def test_refresh_tokens_success():
    """Refresh de tokens retourne de nouveaux tokens."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        new_session = MagicMock()
        new_session.access_token = "new_access_token"
        new_session.refresh_token = "new_refresh_token"
        new_session.expires_in = 3600

        refresh_response = MagicMock()
        refresh_response.session = new_session

        mock_db = MagicMock()
        mock_db.client.auth.refresh_session.return_value = refresh_response
        mock_db_factory.return_value = mock_db
        mock_repo_factory.return_value = MagicMock()

        service = AuthService()
        result = await service.refresh_tokens("old_refresh_token")

        assert result.access_token == "new_access_token"
        assert result.refresh_token == "new_refresh_token"


@pytest.mark.asyncio
async def test_refresh_tokens_invalid():
    """Refresh avec token invalide leve InvalidTokenError."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        mock_db = MagicMock()
        mock_db.client.auth.refresh_session.side_effect = Exception("Token expired")
        mock_db_factory.return_value = mock_db
        mock_repo_factory.return_value = MagicMock()

        service = AuthService()

        with pytest.raises(InvalidTokenError):
            await service.refresh_tokens("invalid_token")


# =============================================================================
# PASSWORD RESET TESTS
# =============================================================================


@pytest.mark.asyncio
async def test_request_password_reset_always_returns_true():
    """Reset de mot de passe retourne toujours True (securite)."""
    from app.services.auth_service import AuthService

    with patch("app.services.auth_service.get_supabase_client") as mock_db_factory, \
         patch("app.services.auth_service.get_users_repository") as mock_repo_factory:

        mock_db = MagicMock()
        # Meme si email inexistant, toujours True
        mock_db.client.auth.reset_password_for_email.side_effect = Exception("Email not found")
        mock_db_factory.return_value = mock_db
        mock_repo_factory.return_value = MagicMock()

        service = AuthService()
        result = await service.request_password_reset("nonexistent@example.com")

        assert result is True
