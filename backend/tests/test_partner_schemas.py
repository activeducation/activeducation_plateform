"""Tests des schemas Pydantic partner — validation gender, status, currency, etc."""
import pytest
from pydantic import ValidationError as PydanticValidationError

from app.schemas.partner import (
    OrganizationCreate,
    OrganizationType,
    BeneficiaryCreate,
    BeneficiaryUpdate,
    BeneficiarySummary,
    BeneficiaryStatus,
    Gender,
)


# =============================================================================
# OrganizationType enum
# =============================================================================


def test_organization_type_is_string_enum():
    """OrganizationType doit être str+Enum pour OpenAPI."""
    assert isinstance(OrganizationType.CDEJ, str)
    assert OrganizationType.CDEJ.value == "cdej"


def test_organization_create_accepts_valid_type():
    org = OrganizationCreate(name="Test CDEJ", type=OrganizationType.ONG)
    assert org.type == OrganizationType.ONG


def test_organization_create_rejects_short_name():
    with pytest.raises(PydanticValidationError):
        OrganizationCreate(name="A", type=OrganizationType.CDEJ)


def test_organization_create_strips_phone_formatting():
    """Phone validation : doit retirer espaces, tirets, parenthèses."""
    org = OrganizationCreate(
        name="Test CDEJ", type=OrganizationType.CDEJ,
        contact_phone="(+228) 90-12 34 56",
    )
    assert org.contact_phone == "+22890123456"


# =============================================================================
# BeneficiaryCreate validators
# =============================================================================


def test_beneficiary_create_titles_names():
    """first_name + last_name doivent être .strip().title()"""
    b = BeneficiaryCreate(first_name="ama  ", last_name="KOFFI")
    assert b.first_name == "Ama"
    assert b.last_name == "Koffi"


def test_beneficiary_create_rejects_invalid_gender():
    with pytest.raises(PydanticValidationError) as exc:
        BeneficiaryCreate(first_name="Ama", last_name="Koffi", gender="alien")
    assert "Genre" in str(exc.value) or "gender" in str(exc.value).lower()


def test_beneficiary_create_accepts_valid_gender():
    for g in Gender.CHOICES:
        b = BeneficiaryCreate(first_name="Ama", last_name="Koffi", gender=g)
        assert b.gender == g


# =============================================================================
# BeneficiaryUpdate — validators ajoutés
# =============================================================================


def test_beneficiary_update_rejects_invalid_status():
    with pytest.raises(PydanticValidationError):
        BeneficiaryUpdate(status="deleted_or_pwned")


def test_beneficiary_update_accepts_valid_status():
    for s in BeneficiaryStatus.CHOICES:
        u = BeneficiaryUpdate(status=s)
        assert u.status == s


def test_beneficiary_update_rejects_invalid_gender():
    with pytest.raises(PydanticValidationError):
        BeneficiaryUpdate(gender="apache_helicopter")


def test_beneficiary_update_allows_no_fields():
    """Un update vide doit être accepté (PATCH partiel)."""
    u = BeneficiaryUpdate()
    assert u.model_dump(exclude_unset=True) == {}


# =============================================================================
# BeneficiarySummary — RGPD : pas de PII sensible exposée
# =============================================================================


def test_beneficiary_summary_excludes_sensitive_pii():
    """Le résumé ne doit PAS contenir date_of_birth, parents, guardian, etc."""
    summary_fields = set(BeneficiarySummary.model_fields.keys())
    sensitive = {
        "date_of_birth", "gender", "place_of_birth",
        "father_name", "mother_name",
        "guardian_name", "guardian_phone", "guardian_relationship",
        "address", "photo_url", "notes",
    }
    leaked = summary_fields & sensitive
    assert not leaked, f"PII sensible exposée dans Summary: {leaked}"


def test_beneficiary_summary_keeps_minimum_useful_fields():
    """Le résumé doit garder: id, org, dossier, prénom/nom, ville, statut, dates."""
    required = {
        "id", "organization_id", "dossier_number",
        "first_name", "last_name", "city",
        "status", "referred_at", "created_at",
    }
    summary_fields = set(BeneficiarySummary.model_fields.keys())
    missing = required - summary_fields
    assert not missing, f"Champs utiles manquants dans Summary: {missing}"
