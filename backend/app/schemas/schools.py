"""Schemas publics pour les ecoles."""

from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class SchoolProgramPublic(BaseModel):
    id: UUID
    name: str
    description: Optional[str] = None
    level: Optional[str] = None
    duration_years: Optional[int] = None


class SchoolImagePublic(BaseModel):
    id: UUID
    image_url: str
    caption: Optional[str] = None


class SchoolPublicSummary(BaseModel):
    id: UUID
    name: str
    type: str
    city: str
    is_public: bool = True
    logo_url: Optional[str] = None
    description: Optional[str] = None
    programs_offered: list[str] = []
    accreditations: list[str] = []
    tuition_range: Optional[str] = None
    student_count: Optional[int] = None
    founding_year: Optional[int] = None
    programs_count: int = 0


class SchoolPublicDetail(BaseModel):
    id: UUID
    name: str
    type: str
    city: str
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    programs_offered: list[str] = []
    is_public: bool = True
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    tuition_range: Optional[str] = None
    admission_requirements: Optional[str] = None
    accreditations: list[str] = []
    founding_year: Optional[int] = None
    student_count: Optional[int] = None
    programs: list[SchoolProgramPublic] = []
    images: list[SchoolImagePublic] = []


class SchoolListPublicResponse(BaseModel):
    items: list[SchoolPublicSummary] = []
    total: int = 0
    page: int = 1
    per_page: int = 20
