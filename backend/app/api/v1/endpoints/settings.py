"""Public settings endpoint — exposes non-sensitive app settings."""

from fastapi import APIRouter

from app.core.logging import get_logger
from app.db.supabase_client import get_supabase_client

logger = get_logger("api.settings")

router = APIRouter()


PUBLIC_SETTINGS_KEYS = {"maintenance_mode", "default_language", "welcome_message"}


@router.get("/public")
async def list_public_settings():
    """Retourne les parametres publics (maintenance_mode, etc.)."""
    db = get_supabase_client()
    all_settings = db.fetch_all(table="app_settings", order_by="key.asc")

    result = {}
    for s in all_settings or []:
        key = s.get("key")
        if key in PUBLIC_SETTINGS_KEYS:
            import json

            try:
                result[key] = json.loads(s.get("value", "null"))
            except (json.JSONDecodeError, TypeError):
                result[key] = s.get("value")

    return result
