"""Schemas for opportunities management."""

from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class OpportunityType(str, Enum):
    INTERNSHIP = "internship"
    JOB = "job"
    VOLUNTEER = "volunteer"
    SCHOLARSHIP = "scholarship"


class RemoteType(str, Enum):
    ONSITE = "onsite"
    REMOTE = "remote"
    HYBRID = "hybrid"


class OpportunitySummary(BaseModel):
    id: UUID
    title: str
    opportunity_type: OpportunityType
    organization_name: str
    organization_logo: Optional[str] = None
    location: Optional[str] = None
    remote_type: Optional[RemoteType] = None
    application_deadline: Optional[datetime] = None
    is_published: bool
    is_featured: bool
    school_id: Optional[UUID] = None
    created_at: datetime


class OpportunityDetail(OpportunitySummary):
    description: str
    duration: Optional[str] = None
    requirements: Optional[str] = None
    benefits: Optional[str] = None
    salary_min: Optional[int] = None
    salary_max: Optional[int] = None
    salary_currency: str = "XOF"
    application_url: Optional[str] = None
    created_by: Optional[UUID] = None
    updated_at: datetime


class OpportunityCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(..., min_length=10)
    opportunity_type: OpportunityType
    organization_name: str
    organization_logo: Optional[str] = None
    location: Optional[str] = None
    remote_type: Optional[RemoteType] = None
    duration: Optional[str] = None
    requirements: Optional[str] = None
    benefits: Optional[str] = None
    salary_min: Optional[int] = Field(None, ge=0)
    salary_max: Optional[int] = Field(None, ge=0)
    salary_currency: str = "XOF"
    application_url: Optional[str] = None
    application_deadline: Optional[datetime] = None
    school_id: Optional[UUID] = None

    @field_validator("application_url")
    @classmethod
    def validate_application_url(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        if not v.startswith("https://"):
            raise ValueError("L'URL de candidature doit commencer par https://")
        return v


class OpportunityUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=200)
    description: Optional[str] = Field(None, min_length=10)
    opportunity_type: Optional[OpportunityType] = None
    organization_name: Optional[str] = None
    organization_logo: Optional[str] = None
    location: Optional[str] = None
    remote_type: Optional[RemoteType] = None
    duration: Optional[str] = None
    requirements: Optional[str] = None
    benefits: Optional[str] = None
    salary_min: Optional[int] = Field(None, ge=0)
    salary_max: Optional[int] = Field(None, ge=0)
    salary_currency: Optional[str] = None
    application_url: Optional[str] = None
    application_deadline: Optional[datetime] = None
    is_published: Optional[bool] = None
    is_featured: Optional[bool] = None


class OpportunityListResponse(BaseModel):
    items: List[OpportunitySummary]
    total: int
    page: int
    per_page: int
    total_pages: int
