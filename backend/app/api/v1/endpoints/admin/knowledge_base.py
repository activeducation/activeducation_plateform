"""
Admin — Gestion de la base de connaissances AÏDA.

POST /admin/knowledge-base/refresh → Invalide le cache KB (force rechargement depuis Supabase)
GET  /admin/knowledge-base/preview → Affiche le contenu actuel de la KB
"""

from fastapi import APIRouter, Depends

from app.core.security import get_current_admin
from app.repositories.knowledge_base_repository import knowledge_base_repository

router = APIRouter()


@router.post(
    "/refresh",
    summary="Rafraîchir le cache de la base de connaissances AÏDA",
    description=(
        "Invalide le cache Redis et mémoire de la KB. "
        "Le prochain appel à AÏDA rechargera les données depuis Supabase. "
        "Utile après avoir ajouté ou modifié des entrées dans la table knowledge_base."
    ),
)
async def refresh_knowledge_base(
    admin=Depends(get_current_admin),
) -> dict:
    knowledge_base_repository.invalidate_cache()
    return {
        "message": "Cache KB invalidé. La prochaine conversation AÏDA rechargera les données depuis Supabase.",
        "admin": str(admin["user_id"]),
    }


@router.get(
    "/preview",
    summary="Prévisualiser le contenu de la base de connaissances",
)
async def preview_knowledge_base(
    admin=Depends(get_current_admin),
) -> dict:
    content = knowledge_base_repository.get_content()
    return {
        "content": content,
        "length": len(content),
    }
