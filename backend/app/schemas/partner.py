"""
Schemas Pydantic pour les organisations partenaires et bénéficiaires.

Définit les structures de données pour:
- Organisation partenaire (CDEJ, ONG, etc.)
- Dossier bénéficiaire (enfant/orienté)
"""

import re
from datetime import datetime, date
from typing import Optional
from uuid import UUID

from enum import Enum
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class OrganizationType(str, Enum):
    CDEJ = "cdej"
    ONG = "ong"
    SCHOOL = "school"
    OTHER = "other"


class BeneficiaryStatus:
    ACTIVE = "active"
    INACTIVE = "inactive"
    TRANSFERRED = "transferred"
    COMPLETED = "completed"

    CHOICES = [ACTIVE, INACTIVE, TRANSFERRED, COMPLETED]


class Gender:
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"

    CHOICES = [MALE, FEMALE, OTHER]


class OrganizationBase(BaseModel):
    """Base schema for organizations."""

    name: str = Field(..., min_length=2, max_length=200)
    type: OrganizationType = Field(default=OrganizationType.CDEJ)
    description: Optional[str] = Field(None, max_length=1000)
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = Field(None, max_length=20)
    contact_person: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    country: str = Field(default="TOGO", max_length=100)


class OrganizationCreate(OrganizationBase):
    """Schema for creating an organization."""

    @field_validator("contact_phone", mode="before")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v.strip() == "":
            return None
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        return cleaned if cleaned else v


class OrganizationUpdate(BaseModel):
    """Schema for updating an organization."""

    name: Optional[str] = Field(None, min_length=2, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = Field(None, max_length=20)
    contact_person: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    is_active: Optional[bool] = None


class OrganizationResponse(OrganizationBase):
    """Schema for organization response."""

    id: UUID
    partner_code: Optional[str] = None
    is_active: bool
    is_approved: bool
    approved_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class OrganizationListResponse(BaseModel):
    """Schema for paginated organization list."""

    organizations: list[OrganizationResponse]
    total: int
    page: int
    page_size: int


class BeneficiaryBase(BaseModel):
    """Base schema for beneficiaries."""

    first_name: str = Field(..., min_length=2, max_length=100)
    last_name: str = Field(..., min_length=2, max_length=100)
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    place_of_birth: Optional[str] = Field(None, max_length=200)
    father_name: Optional[str] = Field(None, max_length=200)
    mother_name: Optional[str] = Field(None, max_length=200)
    guardian_name: Optional[str] = Field(None, max_length=200)
    guardian_phone: Optional[str] = Field(None, max_length=20)
    guardian_relationship: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    country: str = Field(default="TOGO", max_length=100)
    photo_url: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=2000)


class BeneficiaryCreate(BeneficiaryBase):
    """Schema for creating a beneficiary dossier."""

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in Gender.CHOICES:
            raise ValueError(f"Genre doit être parmi: {', '.join(Gender.CHOICES)}")
        return v

    @field_validator("guardian_phone", mode="before")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v.strip() == "":
            return None
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        return cleaned if cleaned else v

    @field_validator("first_name", "last_name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        return v.strip().title()


class BeneficiaryUpdate(BaseModel):
    """Schema for updating a beneficiary dossier."""

    first_name: Optional[str] = Field(None, min_length=2, max_length=100)
    last_name: Optional[str] = Field(None, min_length=2, max_length=100)
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    place_of_birth: Optional[str] = Field(None, max_length=200)
    father_name: Optional[str] = Field(None, max_length=200)
    mother_name: Optional[str] = Field(None, max_length=200)
    guardian_name: Optional[str] = Field(None, max_length=200)
    guardian_phone: Optional[str] = Field(None, max_length=20)
    guardian_relationship: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    photo_url: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=2000)
    status: Optional[str] = None

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in Gender.CHOICES:
            raise ValueError(f"Genre doit être parmi: {', '.join(Gender.CHOICES)}")
        return v

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in BeneficiaryStatus.CHOICES:
            raise ValueError(f"Statut doit être parmi: {', '.join(BeneficiaryStatus.CHOICES)}")
        return v


class BeneficiaryResponse(BeneficiaryBase):
    """Schema for beneficiary response."""

    id: UUID
    organization_id: UUID
    dossier_number: Optional[str] = None
    status: str
    referred_at: datetime
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class BeneficiaryListResponse(BaseModel):
    """Schema for paginated beneficiary list."""

    beneficiaries: list[BeneficiaryResponse]
    total: int
    page: int
    page_size: int


class OrganizationWithStats(BaseModel):
    """Organization with beneficiary statistics."""

    organization: OrganizationResponse
    total_beneficiaries: int
    active_beneficiaries: int
    completed_beneficiaries: int