"""Admin orientation test schemas."""

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class OptionSummary(BaseModel):
    id: UUID
    option_text: str
    option_value: int
    display_order: int = 0
    icon: Optional[str] = None


class QuestionSummary(BaseModel):
    id: UUID
    question_text: str
    question_type: str
    category: Optional[str] = None
    display_order: int = 0
    is_required: bool = True
    options: list[OptionSummary] = []


class TestSummary(BaseModel):
    id: UUID
    name: str
    type: str
    duration_minutes: int = 15
    image_url: Optional[str] = None
    is_active: bool = True
    display_order: int = 0
    questions_count: int = 0
    sessions_count: int = 0


class TestListResponse(BaseModel):
    items: list[TestSummary] = []
    total: int = 0
    page: int = 1
    per_page: int = 20


class TestDetail(BaseModel):
    id: UUID
    name: str
    description: str
    type: str
    duration_minutes: int = 15
    image_url: Optional[str] = None
    is_active: bool = True
    display_order: int = 0
    questions: list[QuestionSummary] = []
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class TestCreate(BaseModel):
    name: str = Field(..., min_length=2)
    description: str = Field(..., min_length=10)
    type: str = Field(..., pattern="^(riasec|personality|skills|interests|aptitude)$")
    duration_minutes: int = 15
    image_url: Optional[str] = None
    is_active: bool = True
    display_order: int = 0


class TestUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    type: Optional[str] = None
    duration_minutes: Optional[int] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None
    display_order: Optional[int] = None


class QuestionCreate(BaseModel):
    question_text: str = Field(..., min_length=5)
    question_type: str = Field(..., pattern="^(likert|multiple_choice|boolean)$")
    category: Optional[str] = None
    display_order: int = 0
    is_required: bool = True
    options: list[dict] = []


class QuestionUpdate(BaseModel):
    question_text: Optional[str] = None
    question_type: Optional[str] = None
    category: Optional[str] = None
    display_order: Optional[int] = None
    is_required: Optional[bool] = None


class OptionCreate(BaseModel):
    option_text: str
    option_value: int
    display_order: int = 0
    icon: Optional[str] = None


class OptionUpdate(BaseModel):
    option_text: Optional[str] = None
    option_value: Optional[int] = None
    display_order: Optional[int] = None
    icon: Optional[str] = None
