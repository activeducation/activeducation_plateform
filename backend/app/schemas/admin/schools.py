"""Admin schools schemas."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ProgramSummary(BaseModel):
    id: UUID
    name: str
    description: Optional[str] = None
    level: Optional[str] = None
    duration_years: Optional[int] = None
    is_active: bool = True
    display_order: int = 0


class ImageSummary(BaseModel):
    id: UUID
    image_url: str
    caption: Optional[str] = None
    display_order: int = 0


class SchoolSummary(BaseModel):
    id: UUID
    name: str
    type: str
    city: str
    is_public: bool = True
    is_verified: bool = False
    is_active: bool = True
    logo_url: Optional[str] = None
    description: Optional[str] = None
    tuition_range: Optional[str] = None
    accreditations: list[str] = []
    student_count: Optional[int] = None
    founding_year: Optional[int] = None
    programs_count: int = 0
    created_at: Optional[datetime] = None


class SchoolListResponse(BaseModel):
    items: list[SchoolSummary] = []
    total: int = 0
    page: int = 1
    per_page: int = 20


class SchoolDetail(BaseModel):
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
    is_verified: bool = False
    is_active: bool = True
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    tuition_range: Optional[str] = None
    admission_requirements: Optional[str] = None
    accreditations: list[str] = []
    founding_year: Optional[int] = None
    student_count: Optional[int] = None
    programs: list[ProgramSummary] = []
    images: list[ImageSummary] = []
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class SchoolCreate(BaseModel):
    name: str = Field(..., min_length=2)
    type: str = Field(..., pattern="^(university|grande_ecole|institut|centre_formation)$")
    city: str = Field(..., min_length=2)
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
    founding_year: Optional[int] = Field(None, ge=1800, le=2100)
    student_count: Optional[int] = Field(None, ge=0)


class SchoolUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    city: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    programs_offered: Optional[list[str]] = None
    is_public: Optional[bool] = None
    is_active: Optional[bool] = None
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    tuition_range: Optional[str] = None
    admission_requirements: Optional[str] = None
    accreditations: Optional[list[str]] = None
    founding_year: Optional[int] = Field(None, ge=1800, le=2100)
    student_count: Optional[int] = Field(None, ge=0)


class ProgramCreate(BaseModel):
    name: str = Field(..., min_length=2)
    description: Optional[str] = None
    level: Optional[str] = None
    duration_years: Optional[int] = Field(None, ge=1, le=10)
    is_active: bool = True
    display_order: int = 0


class ProgramUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    level: Optional[str] = None
    duration_years: Optional[int] = Field(None, ge=1, le=10)
    is_active: Optional[bool] = None
    display_order: Optional[int] = None


class ImageCreate(BaseModel):
    image_url: str
    caption: Optional[str] = None
    display_order: int = 0
