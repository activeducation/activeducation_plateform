"""Shared helpers for admin endpoints.

Audit #16 (2026-07-30) : 11 admin endpoint files used to redefine the
exact same `_log_audit` helper (78 occurrences total). Extracted here
to a single source of truth so policy changes (audit-failure tolerance,
schema evolution, telemetry) live in one place.

Pattern d'appel : `log_audit_action(admin, action, entity_type, entity_id, changes=None)`
- admin : dict (from get_current_admin) OU str/UUID directement (upload use case)
- action : str (create, update, delete, verify, etc.)
- entity_type : str (snake_case du type de ressource)
- entity_id : UUID ou str de la ressource affectee
- changes : dict optionnel des champs modifies (avant/apres)

La fonction swallow les exceptions volontairement : on ne veut JAMAIS
qu'un echec d'audit log bloque une mutation qui a deja ete appliquee.
Failing to record the audit trail is bad, failing the user request is
worse (audit #4).
"""

from __future__ import annotations

from typing import Any, Optional, Union
from uuid import UUID

from app.core.logging import get_logger

logger = get_logger("api.admin.helpers")


def log_audit_action(
    admin: Union[dict, str, UUID],
    action: str,
    entity_type: str,
    entity_id: Optional[Union[str, UUID]] = None,
    changes: Optional[Any] = None,
) -> None:
    """Insert a row into admin_audit_log. Best-effort, never raises."""
    if isinstance(admin, dict):
        admin_id = admin.get("user_id")
    else:
        admin_id = admin
    if admin_id is None:
        # Pas d'admin identifie : on log un warning mais on ne raise pas
        logger.warning(
            "log_audit_action called without admin identity (action=%s entity=%s)",
            action,
            entity_type,
        )
        return

    try:
        from app.db.supabase_client import get_admin_supabase_client

        db = get_admin_supabase_client()
        db.client.table("admin_audit_log").insert(
            {
                "admin_id": str(admin_id),
                "action": action,
                "entity_type": entity_type,
                "entity_id": str(entity_id) if entity_id else None,
                "changes": changes,
            }
        ).execute()
    except Exception:
        logger.warning(
            "Audit log failed (action already applied): %s on %s/%s",
            action,
            entity_type,
            entity_id,
            exc_info=True,
        )