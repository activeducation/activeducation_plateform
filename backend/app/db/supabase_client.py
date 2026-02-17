"""
Client Supabase avec gestion robuste des connexions.

Caracteristiques:
- Singleton thread-safe
- Retry avec backoff exponentiel
- Health checks
- Gestion des erreurs avec exceptions typees
"""

import time
from functools import wraps
from threading import Lock
from typing import Any, Callable, Optional, TypeVar

from supabase import create_client, Client
from postgrest.exceptions import APIError

from app.core.config import settings
from app.core.logging import get_logger
from app.core.exceptions import (
    SupabaseError,
    ConnectionError as DBConnectionError,
    QueryError,
)

logger = get_logger("db.supabase")

T = TypeVar("T")


def with_retry(
    max_retries: int = 3,
    base_delay: float = 0.5,
    max_delay: float = 10.0,
    exponential_base: float = 2.0,
):
    """
    Decorateur pour retry avec backoff exponentiel.

    Args:
        max_retries: Nombre maximum de tentatives
        base_delay: Delai initial en secondes
        max_delay: Delai maximum en secondes
        exponential_base: Base pour le calcul exponentiel
    """

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        def wrapper(*args, **kwargs) -> T:
            last_exception = None
            delay = base_delay

            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except (APIError, Exception) as e:
                    last_exception = e
                    if attempt < max_retries:
                        logger.warning(
                            f"Attempt {attempt + 1}/{max_retries + 1} failed: {e}. "
                            f"Retrying in {delay:.2f}s..."
                        )
                        time.sleep(delay)
                        delay = min(delay * exponential_base, max_delay)
                    else:
                        logger.error(
                            f"All {max_retries + 1} attempts failed for {func.__name__}"
                        )

            raise last_exception

        return wrapper

    return decorator


class SupabaseClient:
    """
    Client Supabase singleton thread-safe.

    Usage:
        from app.db.supabase_client import get_supabase, supabase_client

        # Obtenir le client brut
        client = get_supabase()
        result = client.table("users").select("*").execute()

        # Ou utiliser les methodes helper
        result = supabase_client.query("users", {"id": "eq.123"})
    """

    _instance: Optional["SupabaseClient"] = None
    _lock: Lock = Lock()
    _client: Optional[Client] = None
    _initialized: bool = False
    _key: Optional[str] = None
    _url: Optional[str] = None

    def __init__(self, url: Optional[str] = None, key: Optional[str] = None):
        self._url = url or settings.SUPABASE_URL
        self._key = key or settings.SUPABASE_KEY
        self._initialize_client()

    def _initialize_client(self) -> None:
        """Initialise le client Supabase."""
        try:
            # Mask key for logging
            masked_key = f"{self._key[:5]}...{self._key[-5:]}" if self._key else "None"
            logger.info(
                "Initializing Supabase client",
                extra={"url": self._url, "key": masked_key},
            )

            self._client = create_client(self._url, self._key)
            self._initialized = True

            logger.info("Supabase client initialized successfully")

        except Exception as e:
            logger.error(f"Failed to initialize Supabase client: {e}")
            raise DBConnectionError(
                f"Impossible d'initialiser le client Supabase: {str(e)}"
            )

    @property
    def client(self) -> Client:
        """Retourne le client Supabase."""
        if self._client is None:
            raise DBConnectionError("Client Supabase non initialise")
        return self._client

    def is_connected(self) -> bool:
        """Verifie si le client est connecte."""
        return self._client is not None and self._initialized

    @with_retry(max_retries=2, base_delay=0.3)
    def health_check(self) -> dict[str, Any]:
        """
        Verifie la sante de la connexion Supabase.

        Returns:
            dict avec le statut et les details
        """
        try:
            # Tente une requete simple pour verifier la connexion
            start_time = time.perf_counter()

            # Essayer de lister les tables (verification basique)
            result = self.client.table("orientation_tests").select("id").limit(1).execute()

            latency_ms = (time.perf_counter() - start_time) * 1000

            return {
                "status": "healthy",
                "latency_ms": round(latency_ms, 2),
                "connected": True,
            }

        except APIError as e:
            if "does not exist" in str(e) or "relation" in str(e).lower():
                return {
                    "status": "healthy",
                    "connected": True,
                    "note": "Database connected but tables may not exist yet",
                }
            raise SupabaseError(f"Health check failed: {str(e)}")

        except Exception as e:
            return {
                "status": "unhealthy",
                "connected": False,
                "error": str(e),
            }

    # =========================================================================
    # METHODES HELPER POUR LES OPERATIONS COURANTES
    # =========================================================================

    @with_retry(max_retries=2)
    def fetch_all(
        self,
        table: str,
        columns: str = "*",
        filters: Optional[dict[str, Any]] = None,
        order_by: Optional[str] = None,
        limit: Optional[int] = None,
    ) -> list[dict[str, Any]]:
        """Recupere tous les enregistrements."""
        try:
            query = self.client.table(table).select(columns)

            if filters:
                for key, value in filters.items():
                    query = query.eq(key, value)

            if order_by:
                col, direction = order_by.split(".") if "." in order_by else (order_by, "asc")
                query = query.order(col, desc=(direction == "desc"))

            if limit:
                query = query.limit(limit)

            result = query.execute()
            return result.data

        except APIError as e:
            logger.error(f"Query error on table {table}: {e}")
            raise QueryError(f"Erreur lors de la requete sur {table}: {str(e)}")

    @with_retry(max_retries=2)
    def fetch_one(
        self,
        table: str,
        id_column: str,
        id_value: Any,
        columns: str = "*",
    ) -> Optional[dict[str, Any]]:
        """Recupere un seul enregistrement par ID."""
        try:
            result = (
                self.client.table(table)
                .select(columns)
                .eq(id_column, id_value)
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None

        except APIError as e:
            logger.error(f"Query error on table {table}: {e}")
            raise QueryError(f"Erreur lors de la requete sur {table}: {str(e)}")

    @with_retry(max_retries=2)
    def insert(
        self,
        table: str,
        data: dict[str, Any] | list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        """Insere un ou plusieurs enregistrements."""
        try:
            result = self.client.table(table).insert(data).execute()
            return result.data

        except APIError as e:
            logger.error(f"Insert error on table {table}: {e}")
            raise QueryError(f"Erreur lors de l'insertion dans {table}: {str(e)}")

    @with_retry(max_retries=2)
    def update(
        self,
        table: str,
        id_column: str,
        id_value: Any,
        data: dict[str, Any],
    ) -> list[dict[str, Any]]:
        """Met a jour un enregistrement."""
        try:
            result = (
                self.client.table(table)
                .update(data)
                .eq(id_column, id_value)
                .execute()
            )
            return result.data

        except APIError as e:
            logger.error(f"Update error on table {table}: {e}")
            raise QueryError(f"Erreur lors de la mise a jour dans {table}: {str(e)}")

    @with_retry(max_retries=2)
    def delete(
        self,
        table: str,
        id_column: str,
        id_value: Any,
    ) -> list[dict[str, Any]]:
        """Supprime un enregistrement."""
        try:
            result = (
                self.client.table(table)
                .delete()
                .eq(id_column, id_value)
                .execute()
            )
            return result.data

        except APIError as e:
            logger.error(f"Delete error on table {table}: {e}")
            raise QueryError(f"Erreur lors de la suppression dans {table}: {str(e)}")


# Instance singleton globale (Standard / Anon)
supabase_client = SupabaseClient()

# Instance singleton Admin (Service Role) - Lazy loading prefere mais ici simple
admin_supabase_client: Optional[SupabaseClient] = None

def get_supabase_client() -> SupabaseClient:
    """Retourne l'instance SupabaseClient standard (Anon)."""
    return supabase_client

def get_admin_supabase_client() -> SupabaseClient:
    """
    Retourne l'instance SupabaseClient Admin (Service Role).
    Utilise le SERVICE_ROLE_KEY si disponible, sinon fallback sur Anon (et risque d'erreur RLS).
    """
    global admin_supabase_client
    if admin_supabase_client is None:
        key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_KEY
        admin_supabase_client = SupabaseClient(key=key)
        logger.warning("Initialized Admin Supabase Client explicitly.")
    
    return admin_supabase_client

def get_supabase() -> Client:
    """Retourne le client brut standard."""
    return supabase_client.client
