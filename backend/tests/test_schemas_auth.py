"""
Tests unitaires pour les validators Pydantic de schemas/auth.py.

Couvre les branches non-triviales :
- RegisterRequest.validate_password (5 contraintes)
- RegisterRequest.validate_name (caracteres speciaux)
- RegisterRequest.validate_phone (formats varies)
- ResetPasswordRequest.validate_password (inclut caractere special)
- ChangePasswordRequest.validate_password (4 contraintes)
"""

import pytest
from pydantic import ValidationError

from app.schemas.auth import (
    ChangePasswordRequest,
    RegisterRequest,
    ResetPasswordRequest,
)


# =============================================================================
# RegisterRequest.validate_password
# =============================================================================


def _base_register_payload(**overrides) -> dict:
    payload = {
        "email": "user@example.com",
        "password": "SecurePass1",
        "first_name": "Jean",
        "last_name": "Dupont",
    }
    payload.update(overrides)
    return payload


def test_register_password_valid():
    req = RegisterRequest(**_base_register_payload())
    assert req.password == "SecurePass1"


def test_register_password_too_short():
    with pytest.raises(ValidationError) as exc:
        RegisterRequest(**_base_register_payload(password="Ab1"))
    assert "8 caracteres" in str(exc.value) or "at least 8" in str(exc.value).lower()


def test_register_password_no_uppercase():
    with pytest.raises(ValidationError) as exc:
        RegisterRequest(**_base_register_payload(password="securepass1"))
    assert "majuscule" in str(exc.value).lower()


def test_register_password_no_lowercase():
    with pytest.raises(ValidationError) as exc:
        RegisterRequest(**_base_register_payload(password="SECUREPASS1"))
    assert "minuscule" in str(exc.value).lower()


def test_register_password_no_digit():
    with pytest.raises(ValidationError) as exc:
        RegisterRequest(**_base_register_payload(password="SecurePass"))
    assert "chiffre" in str(exc.value).lower()


# =============================================================================
# RegisterRequest.validate_name
# =============================================================================


def test_register_name_accepts_hyphen_and_space():
    req = RegisterRequest(**_base_register_payload(first_name="Jean-Luc", last_name="De Villiers"))
    assert req.first_name == "Jean-Luc"
    assert req.last_name == "De Villiers"


def test_register_name_rejects_digits():
    with pytest.raises(ValidationError) as exc:
        RegisterRequest(**_base_register_payload(first_name="Jean123"))
    assert "lettres" in str(exc.value).lower()


def test_register_name_title_cased():
    """validate_name applique .strip().title()."""
    req = RegisterRequest(**_base_register_payload(first_name="  jean  ", last_name="dupont"))
    assert req.first_name == "Jean"
    assert req.last_name == "Dupont"


# =============================================================================
# RegisterRequest.validate_phone
# =============================================================================


def test_register_phone_none_stays_none():
    req = RegisterRequest(**_base_register_payload(phone_number=None))
    assert req.phone_number is None


def test_register_phone_empty_string_becomes_none():
    req = RegisterRequest(**_base_register_payload(phone_number=""))
    assert req.phone_number is None


def test_register_phone_with_formatting_accepted():
    req = RegisterRequest(**_base_register_payload(phone_number="+33 (6) 12-34-56-78"))
    assert req.phone_number == "+33 (6) 12-34-56-78"


# =============================================================================
# ResetPasswordRequest.validate_password
# =============================================================================


def test_reset_password_valid_with_special():
    req = ResetPasswordRequest(token="abc", new_password="SecurePass1!")
    assert req.new_password == "SecurePass1!"


def test_reset_password_missing_special_char():
    with pytest.raises(ValidationError) as exc:
        ResetPasswordRequest(token="abc", new_password="SecurePass1")
    assert "special" in str(exc.value).lower()


def test_reset_password_too_short():
    with pytest.raises(ValidationError) as exc:
        ResetPasswordRequest(token="abc", new_password="Ab1!")
    assert "8" in str(exc.value)


# =============================================================================
# ChangePasswordRequest.validate_password
# =============================================================================


def test_change_password_valid():
    req = ChangePasswordRequest(current_password="old", new_password="NewPass99")
    assert req.new_password == "NewPass99"


def test_change_password_no_uppercase():
    with pytest.raises(ValidationError) as exc:
        ChangePasswordRequest(current_password="old", new_password="newpass99")
    assert "majuscule" in str(exc.value).lower()


def test_change_password_no_digit():
    with pytest.raises(ValidationError) as exc:
        ChangePasswordRequest(current_password="old", new_password="NewPassword")
    assert "chiffre" in str(exc.value).lower()
