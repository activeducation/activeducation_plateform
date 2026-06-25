"""
Schemas Pydantic pour la gamification.
"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class Achievement(BaseModel):
    """Achievement/badge obtenu par l'utilisateur."""

    id: UUID
    achievement_type: str
    achievement_data: dict = {}
    earned_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserChallenge(BaseModel):
    """Challenge participation."""

    id: UUID
    challenge_id: UUID
    title: str
    description: Optional[str] = None
    points: int
    status: str
    score: Optional[int] = None
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class GamificationStats(BaseModel):
    """Statistiques de gamification d'un utilisateur."""

    total_xp: int = 0
    current_level: int = 1
    current_streak: int = 0
    longest_streak: int = 0
    total_achievements: int = 0
    completed_challenges: int = 0
    leaderboard_rank: Optional[int] = None


class GamificationProfile(BaseModel):
    """Profil complet de gamification."""

    stats: GamificationStats
    achievements: List[Achievement] = []
    active_challenges: List[UserChallenge] = []
    next_level_xp: int = 1000
    xp_to_next_level: int = 1000
