"""Dashboard admin schemas."""

from typing import Optional
from pydantic import BaseModel


class StatCard(BaseModel):
    label: str
    value: int
    change: Optional[float] = None  # pourcentage de changement


class WeeklyUsersPoint(BaseModel):
    week: str
    count: int


class TestsByType(BaseModel):
    type: str
    count: int


class RecentActivity(BaseModel):
    id: str
    user_name: str
    action: str
    entity: str
    created_at: str


class DashboardStats(BaseModel):
    total_users: int = 0
    total_tests_completed: int = 0
    total_schools: int = 0
    total_mentors: int = 0
    new_users_weekly: list[WeeklyUsersPoint] = []
    tests_by_type: list[TestsByType] = []
    recent_activity: list[RecentActivity] = []
