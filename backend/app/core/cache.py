"""
Module de cache Redis pour ActivEducation.

Utilise Redis pour cacher les donnees statiques et semi-statiques.
Fallback transparent vers un cache memoire si Redis n'est pas disponible.

TTLs par defaut:
- Listes ecoles/carrieres : 10 minutes
- Details ecole/carriere : 5 minutes
- Tests d'orientation : 30 minutes
- Profils utilisateurs : 2 minutes
"""

import json
import time
from typing import Any, Callable, Optional
from functools import wraps

from app.core.logging import get_logger

_REDIS_RETRY_INTERVAL = 30  # secondes avant de retenter Redis après un échec

logger = get_logger("core.cache")


# =============================================================================
# TTL CONSTANTS (secondes)
# =============================================================================

TTL_LISTS = 600          # 10 min - listes ecoles/carrieres
TTL_DETAIL = 300         # 5 min - detail ecole/carriere
TTL_TESTS = 1800         # 30 min - tests d'orientation (tres statiques)
TTL_USER_PROFILE = 120   # 2 min - profils utilisateurs
TTL_MENTORS = 300        # 5 min - liste mentors (semi-statique)
TTL_OPPORTUNITIES = 300  # 5 min - liste opportunités (semi-statique)
TTL_LEADERBOARD = 120    # 2 min - leaderboard (change fréquemment)
TTL_GAMIFICATION = 60    # 1 min - profil gamification utilisateur


# =============================================================================
# CACHE CLIENT
# =============================================================================


class CacheClient:
    """
    Client cache avec fallback automatique Redis -> memoire.

    En production, utilise Redis.
    En cas d'indisponibilite Redis, bascule silencieusement vers cache memoire.
    """

    def __init__(self):
        self._redis = None
        self._memory_cache: dict[str, tuple[Any, float]] = {}
        self._redis_failed_at: float = 0.0

    def _get_redis(self):
        """
        Obtient ou initialise la connexion Redis.
        Circuit breaker : après un échec, ne retente qu'après _REDIS_RETRY_INTERVAL s.
        """
        if self._redis is not None:
            return self._redis

        # Ne pas retenter trop souvent après un échec
        if self._redis_failed_at and time.time() - self._redis_failed_at < _REDIS_RETRY_INTERVAL:
            return None

        try:
            import redis
            from app.core.config import settings

            redis_url = getattr(settings, "REDIS_URL", None)
            if not redis_url:
                # Pas de Redis configure : fallback memoire silencieux,
                # un seul log pour eviter le spam.
                if not self._redis_failed_at:
                    logger.info("REDIS_URL not set, using memory cache")
                self._redis_failed_at = time.time()
                return None

            client = redis.from_url(
                redis_url,
                decode_responses=True,
                socket_connect_timeout=2,
                socket_timeout=2,
            )
            client.ping()
            self._redis = client
            self._redis_failed_at = 0.0
            logger.info(f"Redis connected: {redis_url}")
            return self._redis
        except Exception as e:
            self._redis_failed_at = time.time()
            logger.warning(f"Redis unavailable, using memory cache: {e}")
            return None

    def get(self, key: str) -> Optional[Any]:
        """
        Recupere une valeur du cache.

        Args:
            key: Cle de cache

        Returns:
            Valeur deserialisee ou None si absent/expire
        """
        redis = self._get_redis()

        if redis:
            try:
                value = redis.get(key)
                if value:
                    return json.loads(value)
                return None
            except Exception as e:
                logger.warning(f"Redis get error for '{key}': {e}")
                self._redis = None
                self._redis_failed_at = time.time()
                # Fallback vers memoire

        # Cache memoire
        cached = self._memory_cache.get(key)
        if cached:
            value, expires_at = cached
            if time.time() < expires_at:
                return value
            else:
                del self._memory_cache[key]

        return None

    def set(self, key: str, value: Any, ttl: int = TTL_LISTS) -> None:
        """
        Stocke une valeur dans le cache.

        Args:
            key: Cle de cache
            value: Valeur a cacher (doit etre serialisable JSON)
            ttl: Duree de vie en secondes
        """
        redis = self._get_redis()

        if redis:
            try:
                redis.setex(key, ttl, json.dumps(value, default=str))
                return
            except Exception as e:
                logger.warning(f"Redis set error for '{key}': {e}")
                self._redis = None
                self._redis_failed_at = time.time()
                # Fallback vers memoire

        # Cache memoire (eviter overflow)
        if len(self._memory_cache) > 500:
            self._memory_cache.clear()
        self._memory_cache[key] = (value, time.time() + ttl)

    def delete(self, key: str) -> None:
        """Supprime une cle du cache."""
        redis = self._get_redis()

        if redis:
            try:
                redis.delete(key)
            except Exception as e:
                logger.warning(f"Redis delete error for '{key}': {e}")

        self._memory_cache.pop(key, None)

    def delete_pattern(self, pattern: str) -> int:
        """
        Supprime toutes les cles correspondant au pattern.

        Args:
            pattern: Pattern glob (ex: "schools:*")

        Returns:
            Nombre de cles supprimees
        """
        redis = self._get_redis()
        count = 0

        if redis:
            try:
                keys = redis.keys(pattern)
                if keys:
                    count = redis.delete(*keys)
                return count
            except Exception as e:
                logger.warning(f"Redis delete_pattern error for '{pattern}': {e}")

        # Fallback memoire: supprimer les cles correspondantes
        prefix = pattern.rstrip("*")
        to_delete = [k for k in self._memory_cache if k.startswith(prefix)]
        for k in to_delete:
            del self._memory_cache[k]
        return len(to_delete)

    def clear(self) -> None:
        """Vide completement le cache (utiliser avec precaution)."""
        redis = self._get_redis()
        if redis:
            try:
                redis.flushdb()
            except Exception:
                pass
        self._memory_cache.clear()


# Singleton global
_cache = CacheClient()


def get_cache() -> CacheClient:
    """Retourne l'instance du client cache."""
    return _cache


# =============================================================================
# DECORATEUR CACHE
# =============================================================================


def cached(key_prefix: str, ttl: int = TTL_LISTS, key_builder: Optional[Callable] = None):
    """
    Decorateur pour cacher le resultat d'une fonction async.

    Usage:
        @cached("schools:list", ttl=TTL_LISTS)
        async def list_schools(page: int, city: str = None):
            ...

    Args:
        key_prefix: Prefixe de la cle de cache
        ttl: Duree de vie en secondes
        key_builder: Fonction optionnelle pour construire la cle depuis les args
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            cache = get_cache()

            # Construire la cle de cache
            if key_builder:
                cache_key = key_builder(*args, **kwargs)
            else:
                # Cle basee sur les arguments
                args_str = "_".join(str(a) for a in args[1:] if not hasattr(a, '__dict__'))
                kwargs_str = "_".join(f"{k}={v}" for k, v in sorted(kwargs.items()))
                suffix = f"{args_str}_{kwargs_str}".strip("_") or "all"
                cache_key = f"{key_prefix}:{suffix}"

            # Verifier le cache
            cached_value = cache.get(cache_key)
            if cached_value is not None:
                logger.debug(f"Cache HIT: {cache_key}")
                return cached_value

            # Appeler la fonction originale
            logger.debug(f"Cache MISS: {cache_key}")
            result = await func(*args, **kwargs)

            # Cacher le resultat (si serialisable)
            if result is not None:
                try:
                    cache.set(cache_key, result, ttl)
                except Exception as e:
                    logger.warning(f"Could not cache result for '{cache_key}': {e}")

            return result

        return wrapper
    return decorator


def invalidate_cache(pattern: str) -> int:
    """
    Invalide les entrees de cache correspondant au pattern.

    Usage apres mutation de donnees:
        invalidate_cache("schools:*")

    Returns:
        Nombre de cles invalidees
    """
    cache = get_cache()
    count = cache.delete_pattern(pattern)
    if count:
        logger.info(f"Invalidated {count} cache entries matching '{pattern}'")
    return count
