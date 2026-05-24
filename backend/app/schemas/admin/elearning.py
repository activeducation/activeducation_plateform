"""Admin e-learning schemas for request/response validation."""

from typing import Optional, Literal
from pydantic import BaseModel, Field


class CourseCreate(BaseModel):
    """Schema for creating a course."""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    school_id: Optional[str] = None
    thumbnail_url: Optional[str] = None
    level: str = "beginner"


class CourseUpdate(BaseModel):
    """Schema for updating a course."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    thumbnail_url: Optional[str] = None
    level: Optional[str] = None
    is_published: Optional[bool] = None


class ModuleCreate(BaseModel):
    """Schema for creating a module."""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    display_order: int = 0


class ModuleUpdate(BaseModel):
    """Schema for updating a module."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    display_order: Optional[int] = None


class LessonCreate(BaseModel):
    """Schema for creating a lesson."""
    title: str = Field(..., min_length=1, max_length=200)
    lesson_type: Literal["text", "video", "quiz", "pdf"] = "text"
    content: Optional[str] = None
    video_url: Optional[str] = None
    display_order: int = 0


class LessonUpdate(BaseModel):
    """Schema for updating a lesson."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    lesson_type: Optional[Literal["text", "video", "quiz", "pdf"]] = None
    content: Optional[str] = None
    video_url: Optional[str] = None
    display_order: Optional[int] = None