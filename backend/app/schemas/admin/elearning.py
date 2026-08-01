"""Admin e-learning schemas for request/response validation."""

from typing import Literal, Optional

from pydantic import BaseModel, Field


class CourseCreate(BaseModel):
    """Schema for creating a course."""

    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    thumbnail_url: Optional[str] = None
    difficulty: str = "debutant"


class CourseUpdate(BaseModel):
    """Schema for updating a course."""

    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    thumbnail_url: Optional[str] = None
    difficulty: Optional[str] = None
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
    lesson_type: Literal["text", "video", "quiz", "pdf", "article", "challenge"] = "text"
    content: Optional[str] = None
    video_url: Optional[str] = None
    video_provider: Optional[str] = None
    markdown_body: Optional[str] = None
    challenge_instructions: Optional[str] = None
    challenge_starter_code: Optional[str] = None
    challenge_language: Optional[str] = None
    display_order: int = 0


class LessonUpdate(BaseModel):
    """Schema for updating a lesson."""

    title: Optional[str] = Field(None, min_length=1, max_length=200)
    lesson_type: Optional[Literal["text", "video", "quiz", "pdf", "article", "challenge"]] = None
    content: Optional[str] = None
    video_url: Optional[str] = None
    video_provider: Optional[str] = None
    markdown_body: Optional[str] = None
    challenge_instructions: Optional[str] = None
    challenge_starter_code: Optional[str] = None
    challenge_language: Optional[str] = None
    display_order: Optional[int] = None
