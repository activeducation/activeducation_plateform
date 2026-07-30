"""Admin gamification management endpoints."""

from uuid import UUID

from fastapi import APIRouter, Depends, Request

from app.core.exceptions import NotFoundError
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_supabase_client
from ._helpers import log_audit_action

logger = get_logger("api.admin.gamification")

router = APIRouter()


# =========================================================================
# ACHIEVEMENTS
# =========================================================================


@router.get("/achievements")
async def list_achievements(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Liste des achievements."""
    db = get_supabase_client()
    return db.fetch_all(table="achievements", order_by="category.asc")


@router.post("/achievements")
async def create_achievement(
    request: Request,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Creer un achievement."""
    db = get_supabase_client()
    result = db.insert(table="achievements", data=body)
    log_audit_action(admin, "create", "achievement", result[0].get("id") if result else None, body)
    return result[0] if result else body


@router.put("/achievements/{achievement_id}")
async def update_achievement(
    request: Request,
    achievement_id: UUID,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Modifier un achievement."""
    db = get_supabase_client()
    result = db.update(
        table="achievements", id_column="id", id_value=str(achievement_id), data=body
    )
    if not result:
        raise NotFoundError("Achievement", str(achievement_id))
    log_audit_action(admin, "update", "achievement", achievement_id, body)
    return result[0]


@router.delete("/achievements/{achievement_id}")
async def delete_achievement(
    request: Request,
    achievement_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer un achievement."""
    db = get_supabase_client()
    db.delete(table="achievements", id_column="id", id_value=str(achievement_id))
    log_audit_action(admin, "delete", "achievement", achievement_id)
    return {"success": True, "message": "Achievement supprime"}


# =========================================================================
# USER XP / GAMIFICATION PROFILES (ADMIN VIEW)
# =========================================================================


@router.get("/users")
async def list_gamification_users(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des utilisateurs avec leurs stats XP/niveau.

    Audit #7 (2026-07-30) : l'ancienne implementation construisait une
    requete SQL par f-string avec `search`/`per_page`/`offset` interpoles
    dans la clause WHERE / LIMIT / OFFSET. C'etait du SQL injection
    classique. Le code reel utilisait deja le client PostgREST chainable
    ci-dessous, donc la query textuelle etait du dead code. On supprime
    le bloc mort pour eliminer le risque latent : si quelqu'un branche
    cette query sur un `.rpc()` plus tard, plus d'injection possible.
    """
    db = get_supabase_client()
    page = int(request.query_params.get("page", "1"))
    per_page = int(request.query_params.get("per_page", "20"))
    search = request.query_params.get("search", "")

    # Plafonner la pagination pour eviter qu'un admin demande per_page=100000
    per_page = max(1, min(int(per_page), 100))
    page = max(1, int(page))
    offset = (page - 1) * per_page

    from app.db.supabase_client import get_admin_supabase_client
    admin_db = get_admin_supabase_client()

    try:
        # PostgREST ne supporte pas ILIKE parametre cote serveur en chainable,
        # on filtre donc en memoire apres le fetch (le volume reste raisonnable
        # car admin uniquement). Si le besoin evolue, basculer sur un .rpc()
        # avec une fonction SQL parametree.
        users_res = (
            admin_db.client.table("user_profiles")
            .select("id, full_name, email")
            .order("created_at", desc=True)
            .execute()
        )
        users = users_res.data or []

        if search:
            s = search.lower()
            users = [
                u for u in users
                if s in (u.get("full_name") or "").lower()
                or s in (u.get("email") or "").lower()
            ]

        user_ids = [u["id"] for u in users]

        # Charger les profils gamification en batch
        profiles_map = {}
        if user_ids:
            profiles_res = (
                admin_db.client.table("gamification_profiles")
                .select("user_id, total_xp, current_level, current_streak, last_active_at")
                .in_("user_id", user_ids)
                .execute()
            )
            for p in profiles_res.data or []:
                profiles_map[p["user_id"]] = p

        for u in users:
            p = profiles_map.get(u["id"], {})
            u["total_xp"] = p.get("total_xp", 0)
            u["current_level"] = p.get("current_level", 1)
            u["current_streak"] = p.get("current_streak", 0)

        # Trier par XP descendant et paginer
        users.sort(key=lambda u: u.get("total_xp", 0), reverse=True)
        total = len(users)
        users = users[offset:offset + per_page]
    except Exception as e:
        logger.warning(f"Error fetching gamification users: {e}")
        users = []
        total = 0

    return {"items": users, "total": total, "page": page, "per_page": per_page}


@router.post("/users/{user_id}/award-xp")
async def award_xp_to_user(
    request: Request,
    user_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Attribuer manuellement des XP a un utilisateur."""
    body = await request.json()
    amount = int(body.get("amount", 0))
    reason = body.get("reason", "Attribution manuelle")

    if amount <= 0:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Le montant doit etre > 0")

    try:
        from app.db.supabase_client import get_admin_supabase_client
        db = get_admin_supabase_client()
        db.client.rpc("award_xp", {"p_user_id": str(user_id), "p_amount": amount}).execute()
        log_audit_action(admin, "award_xp", "user", user_id, {"amount": amount, "reason": reason})
        return {"success": True, "xp_awarded": amount}
    except Exception as e:
        logger.error(f"award_xp error: {e}")
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")


@router.get("/users/{user_id}/achievements")
async def get_user_achievements(
    request: Request,
    user_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Liste des achievements d'un utilisateur."""
    try:
        from app.db.supabase_client import get_admin_supabase_client
        db = get_admin_supabase_client()
        res = (
            db.client.table("user_achievements")
            .select("*")
            .eq("user_id", str(user_id))
            .order("earned_at", desc=True)
            .execute()
        )
        return res.data or []
    except Exception as e:
        logger.warning(f"Error fetching user achievements: {e}")
        return []


# =========================================================================
# CHALLENGES
# =========================================================================


@router.get("/challenges")
async def list_challenges(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Liste des challenges."""
    db = get_supabase_client()
    return db.fetch_all(table="challenges", order_by="created_at.desc")


@router.post("/challenges")
async def create_challenge(
    request: Request,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Creer un challenge."""
    db = get_supabase_client()
    result = db.insert(table="challenges", data=body)
    log_audit_action(admin, "create", "challenge", result[0].get("id") if result else None, body)
    return result[0] if result else body


@router.put("/challenges/{challenge_id}")
async def update_challenge(
    request: Request,
    challenge_id: UUID,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Modifier un challenge."""
    db = get_supabase_client()
    result = db.update(table="challenges", id_column="id", id_value=str(challenge_id), data=body)
    if not result:
        raise NotFoundError("Challenge", str(challenge_id))
    log_audit_action(admin, "update", "challenge", challenge_id, body)
    return result[0]


@router.delete("/challenges/{challenge_id}")
async def delete_challenge(
    request: Request,
    challenge_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer un challenge."""
    db = get_supabase_client()
    db.delete(table="challenges", id_column="id", id_value=str(challenge_id))
    log_audit_action(admin, "delete", "challenge", challenge_id)
    return {"success": True, "message": "Challenge supprime"}
