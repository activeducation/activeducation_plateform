"""Admin careers schemas."""

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class SectorResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    display_order: int = 0


class SectorCreate(BaseModel):
    name: str = Field(..., min_length=2)
    description: Optional[str] = None
    icon: Optional[str] = None
    display_order: int = 0


class SectorUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    display_order: Optional[int] = None


class CareerSummary(BaseModel):
    id: UUID
    name: str
    sector_name: str
    job_demand: Optional[str] = None
    growth_trend: Optional[str] = None
    salary_avg_fcfa: Optional[int] = None
    is_active: bool = True
    image_url: Optional[str] = None


class CareerListResponse(BaseModel):
    items: list[CareerSummary] = []
    total: int = 0
    page: int = 1
    per_page: int = 20


class CareerDetail(BaseModel):
    id: UUID
    name: str
    description: str
    sector_id: Optional[UUID] = None
    sector_name: str
    image_url: Optional[str] = None
    required_skills: list[str] = []
    related_traits: list[str] = []
    education_path: Any = {}
    salary_min_fcfa: Optional[int] = None
    salary_max_fcfa: Optional[int] = None
    salary_avg_fcfa: Optional[int] = None
    salary_note: Optional[str] = None
    job_demand: Optional[str] = None
    growth_trend: Optional[str] = None
    outlook_description: Optional[str] = None
    top_employers: list[str] = []
    entrepreneurship_potential: bool = False
    is_active: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class CareerCreate(BaseModel):
    name: str = Field(..., min_length=2)
    description: str = Field(..., min_length=10)
    sector_id: Optional[UUID] = None
    sector_name: str
    image_url: Optional[str] = None
    required_skills: list[str] = []
    related_traits: list[str] = []
    education_path: Any = {}
    salary_min_fcfa: Optional[int] = None
    salary_max_fcfa: Optional[int] = None
    salary_avg_fcfa: Optional[int] = None
    salary_note: Optional[str] = None
    job_demand: Optional[str] = None
    growth_trend: Optional[str] = None
    outlook_description: Optional[str] = None
    top_employers: list[str] = []
    entrepreneurship_potential: bool = False


class CareerUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    sector_id: Optional[UUID] = None
    sector_name: Optional[str] = None
    image_url: Optional[str] = None
    required_skills: Optional[list[str]] = None
    related_traits: Optional[list[str]] = None
    education_path: Optional[Any] = None
    salary_min_fcfa: Optional[int] = None
    salary_max_fcfa: Optional[int] = None
    salary_avg_fcfa: Optional[int] = None
    salary_note: Optional[str] = None
    job_demand: Optional[str] = None
    growth_trend: Optional[str] = None
    outlook_description: Optional[str] = None
    top_employers: Optional[list[str]] = None
    entrepreneurship_potential: Optional[bool] = None
    is_active: Optional[bool] = None
