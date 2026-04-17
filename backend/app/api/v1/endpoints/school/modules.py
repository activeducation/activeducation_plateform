"""School admin modules endpoints."""

from fastapi import APIRouter, Depends

from app.core.logging import get_logger
from app.core.security import get_current_school_admin
from app.core.exceptions import NotFoundError
from app.schemas.school_admin import (
    SchoolModuleCreate,
    SchoolModuleUpdate,
    ReorderRequest,
)
from app.repositories.school_admin_repository import get_school_admin_repository

logger = get_logger("api.school.modules")

router = APIRouter()


@router.get("/courses/{course_id}/modules")
async def list_modules(
    course_id: str,
    admin: dict = Depends(get_current_school_admin),
):
    """Liste les modules d'un cours de l'ecole."""
    repo = get_school_admin_repository()
    modules = repo.get_modules(course_id, admin["school_id"])
    return {"modules": modules, "total": len(modules)}


@router.post("/courses/{course_id}/modules", status_code=201)
async def create_module(
    course_id: str,
    body: SchoolModuleCreate,
    admin: dict = Depends(get_current_school_admin),
):
    """Cree un nouveau module dans un cours."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    module = repo.create_module(course_id, admin["school_id"], data)
    if not module:
        raise NotFoundError("Cours", course_id)
    return module


@router.put("/modules/{module_id}")
async def update_module(
    module_id: str,
    body: SchoolModuleUpdate,
    admin: dict = Depends(get_current_school_admin),
):
    """Met a jour un module."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    if not data:
        raise NotFoundError("Module", module_id)
    module = repo.update_module(module_id, admin["school_id"], data)
    if not module:
        raise NotFoundError("Module", module_id)
    return module


@router.delete("/modules/{module_id}")
async def delete_module(
    module_id: str,
    admin: dict = Depends(get_current_school_admin),
):
    """Supprime un module."""
    repo = get_school_admin_repository()
    deleted = repo.delete_module(module_id, admin["school_id"])
    if not deleted:
        raise NotFoundError("Module", module_id)
    return {"success": True, "message": "Module supprime"}


@router.patch("/modules/reorder")
async def reorder_modules(
    body: ReorderRequest,
    admin: dict = Depends(get_current_school_admin),
):
    """Reordonne les modules."""
    repo = get_school_admin_repository()
    repo.reorder_modules(admin["school_id"], [str(uid) for uid in body.ordered_ids])
    return {"success": True, "message": "Modules reordonnes"}
