"""
Endpoints API pour la gamification utilisateur.
"""

from uuid import UUID
import math
from datetime import datetime

from fastapi import APIRouter, Depends, Request, Query

from functools import lru_cache

from app.core.logging import get_logger
from app.core.security import get_current_user_id
from app.core.cache import get_cache, CacheClient, TTL_GAMIFICATION, TTL_LEADERBOARD
from app.db.supabase_client import get_supabase_client
from app.middleware.rate_limiter import standard_limit
from app.schemas.gamification import (
    GamificationProfile,
    GamificationStats,
    Achievement,
    UserChallenge,
)

logger = get_logger("api.gamification")

router = APIRouter()


@lru_cache(maxsize=1)
def _cache() -> CacheClient:
    """Retourne l'instance (unique) du cache."""
    return get_cache()


def _calculate_level(total_xp: int) -> tuple[int, int, int]:
    """Calcule le niveau en O(1). Cap à 100."""
    total_xp = max(0, total_xp)
    level = max(1, int((1 + math.sqrt(1 + 8 * total_xp / 100)) / 2))
    level = min(level, 100)
    next_level_xp = level * (level + 1) // 2 * 100
    xp_to_next = max(0, next_level_xp - total_xp)
    return level, next_level_xp, xp_to_next


@router.get("/profile", response_model=GamificationProfile)
async def get_my_gamification(
    request: Request,
    user_id: UUID = Depends(get_current_user_id),
):
    """
    Recupere les donnees de gamification de l'utilisateur connecte.
    """
    # Cache par utilisateur (court TTL car données personnalisées)
    cache_key = f"gamification:profile:{user_id}"
    cached = _cache().get(cache_key)
    if cached is not None:
        return GamificationProfile(**cached)

    db = get_supabase_client()
    user_id_str = str(user_id)
    
    user_profile = db.fetch_one(
        table="user_profiles",
        id_column="id",
        id_value=user_id_str,
    )
    
    achievements = db.fetch_all(
        table="user_achievements",
        filters={"user_id": user_id_str},
        order_by="earned_at.desc",
    )
    
    user_challenges = db.fetch_all(
        table="user_challenges",
        filters={"user_id": user_id_str},
    )
    
    challenges = db.fetch_all(table="challenges", filters={"is_active": True})
    challenges_map = {str(c["id"]): c for c in challenges}
    
    completed_achievements = [a for a in achievements] if achievements else []
    completed_challenges = [
        uc for uc in (user_challenges or [])
        if uc.get("status") == "completed"
    ]
    
    total_xp = user_profile.get("total_xp", 0) if user_profile else 0
    current_streak = user_profile.get("current_streak", 0) if user_profile else 0
    longest_streak = user_profile.get("longest_streak", 0) if user_profile else 0
    
    current_level, next_level_xp, xp_to_next = _calculate_level(total_xp)
    
    leaderboard_rank = None
    try:
        rank_result = db.client.rpc(
            "get_leaderboard_rank", {"p_user_id": user_id_str}
        ).execute()
        if rank_result.data:
            leaderboard_rank = rank_result.data[0]["rank"]
    except Exception:
        pass

    stats = GamificationStats(
        total_xp=total_xp,
        current_level=current_level,
        current_streak=current_streak,
        longest_streak=longest_streak,
        total_achievements=len(completed_achievements),
        completed_challenges=len(completed_challenges),
        leaderboard_rank=leaderboard_rank,
    )
    
    achievement_models = [
        Achievement(
            id=a["id"],
            achievement_type=a.get("achievement_type", "unknown"),
            achievement_data=a.get("achievement_data", {}),
            earned_at=a.get("earned_at") or datetime.now(),
        )
        for a in completed_achievements
    ]
    
    active_challenges = []
    for uc in (user_challenges or []):
        if uc.get("status") in ("not_started", "in_progress"):
            challenge = challenges_map.get(str(uc.get("challenge_id")))
            if challenge:
                active_challenges.append(
                    UserChallenge(
                        id=uc["id"],
                        challenge_id=uc["challenge_id"],
                        title=challenge.get("title", ""),
                        description=challenge.get("description"),
                        points=challenge.get("points", 0),
                        status=uc.get("status", "not_started"),
                        score=uc.get("score"),
                        completed_at=uc.get("completed_at"),
                    )
                )
    
    result = GamificationProfile(
        stats=stats,
        achievements=achievement_models[:10],
        active_challenges=active_challenges[:5],
        next_level_xp=next_level_xp,
        xp_to_next_level=xp_to_next,
    )

    # Cache le résultat
    _cache().set(cache_key, result.model_dump(mode="json"), ttl=TTL_GAMIFICATION)
    return result


@router.get("/leaderboard")
@standard_limit()
async def get_leaderboard(
    request: Request,
    user_id: str = Depends(get_current_user_id),
    limit: int = Query(10, ge=1, le=50),
):
    """
    Recupere le classement des utilisateurs.
    """
    # Cache leaderboard (court TTL car change fréquemment)
    cache_key = f"gamification:leaderboard:l{limit}"
    cached = _cache().get(cache_key)
    if cached is not None:
        return cached

    db = get_supabase_client()

    profiles = db.fetch_all(
        table="user_profiles",
        order_by="total_xp.desc",
        limit=limit,
    )

    data = [
        {
            "display_name": p.get("display_name") or f"{p.get('first_name', '')} {p.get('last_name', '')}".strip(),
            "avatar_url": p.get("avatar_url"),
            "total_xp": p.get("total_xp", 0),
            "current_level": _calculate_level(p.get("total_xp", 0))[0],
        }
        for p in (profiles or [])
    ]

    _cache().set(cache_key, data, ttl=TTL_LEADERBOARD)
    return data