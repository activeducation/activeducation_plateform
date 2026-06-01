"""Utility to invalidate gamification cache on XP/streak changes."""

from app.core.cache import get_cache
from app.core.logging import get_logger

logger = get_logger("core.gamification_cache")


def invalidate_gamification_profile(user_id: str) -> None:
    """Invalide le cache du profil gamification d'un utilisateur."""
    try:
        cache = get_cache()
        cache.delete(f"gamification:profile:{user_id}")
    except Exception as e:
        logger.warning(f"Could not invalidate gamification cache for user {user_id}: {e}")


def invalidate_leaderboard() -> None:
    """Invalide toutes les clés du leaderboard."""
    try:
        cache = get_cache()
        cache.delete_pattern("gamification:leaderboard:*")
    except Exception as e:
        logger.warning(f"Could not invalidate leaderboard cache: {e}")
