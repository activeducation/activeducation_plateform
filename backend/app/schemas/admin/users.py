"""Admin users schemas."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class AdminUserSummary(BaseModel):
    id: UUID
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    role: str = "student"
    is_active: bool = True
    class_level: Optional[str] = None
    school_name: Optional[str] = None
    created_at: Optional[datetime] = None
    last_login_at: Optional[datetime] = None


class AdminUserListResponse(BaseModel):
    items: list[AdminUserSummary] = []
    total: int = 0
    page: int = 1
    per_page: int = 20


class UserActivitySummary(BaseModel):
    tests_completed: int = 0
    tests_in_progress: int = 0
    favorite_careers: int = 0
    achievements_unlocked: int = 0
    total_points: int = 0
    current_level: int = 1


class AdminUserDetail(BaseModel):
    id: UUID
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    phone_number: Optional[str] = None
    role: str = "student"
    is_active: bool = True
    class_level: Optional[str] = None
    school_name: Optional[str] = None
    date_of_birth: Optional[str] = None
    preferred_language: str = "fr"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    last_login_at: Optional[datetime] = None
    activity: UserActivitySummary = UserActivitySummary()


class AdminUserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    phone_number: Optional[str] = None
    school_name: Optional[str] = None
    class_level: Optional[str] = None
    is_active: Optional[bool] = None


class RoleUpdateRequest(BaseModel):
    role: str = Field(..., pattern="^(student|admin|super_admin)$")
