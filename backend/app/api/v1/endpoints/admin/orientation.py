"""Admin orientation tests management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin, get_current_super_admin
from app.repositories.admin.tests_repository import get_tests_admin_repository
from app.schemas.admin.orientation import (
    TestListResponse,
    TestDetail,
    TestCreate,
    TestUpdate,
    QuestionCreate,
    QuestionUpdate,
    OptionCreate,
    OptionUpdate,
)


logger = get_logger("api.admin.orientation")

router = APIRouter()


def _log_audit(admin, action, entity_type, entity_id, changes=None):
    try:
        from app.db.supabase_client import get_supabase_client
        db = get_supabase_client()
        db.insert(table="admin_audit_log", data={
            "admin_id": str(admin["user_id"]),
            "action": action,
            "entity_type": entity_type,
            "entity_id": str(entity_id) if entity_id else None,
            "changes": changes,
        })
    except Exception as e:
        logger.warning(f"Audit log failed: {e}")


# =========================================================================
# TESTS CRUD
# =========================================================================

@router.get("", response_model=TestListResponse)

async def list_tests(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    test_type: Optional[str] = Query(None, alias="type"),
    is_active: Optional[bool] = Query(None),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des tests."""
    repo = get_tests_admin_repository()
    return await repo.list_tests(
        page=page, per_page=per_page, search=search,
        test_type=test_type, is_active=is_active,
    )


@router.get("/{test_id}", response_model=TestDetail)

async def get_test(
    request: Request,
    test_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Detail d'un test avec questions et options."""
    repo = get_tests_admin_repository()
    return await repo.get_test_detail(test_id)


@router.post("", response_model=TestDetail)

async def create_test(
    request: Request,
    body: TestCreate,
    admin: dict = Depends(get_current_admin),
):
    """Creer un test."""
    logger.info(f"Creating test with payload: {body.model_dump()}")
    try:
        repo = get_tests_admin_repository()
        result = await repo.create_test(body)
        _log_audit(admin, "create", "test", result.id, body.model_dump())
        return result
    except Exception as e:
        logger.error(f"Error creating test: {e}", exc_info=True)
        raise e


@router.put("/{test_id}", response_model=TestDetail)

async def update_test(
    request: Request,
    test_id: UUID,
    body: TestUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier un test."""
    repo = get_tests_admin_repository()
    result = await repo.update_test(test_id, body)
    _log_audit(admin, "update", "test", test_id, body.model_dump(exclude_unset=True))
    return result


@router.delete("/{test_id}")

async def delete_test(
    request: Request,
    test_id: UUID,
    admin: dict = Depends(get_current_super_admin),
):
    """Supprimer un test (super_admin)."""
    repo = get_tests_admin_repository()
    await repo.delete_test(test_id)
    _log_audit(admin, "delete", "test", test_id)
    return {"success": True, "message": "Test supprime"}


@router.post("/{test_id}/duplicate", response_model=TestDetail)

async def duplicate_test(
    request: Request,
    test_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Dupliquer un test avec toutes ses questions et options."""
    repo = get_tests_admin_repository()
    result = await repo.duplicate_test(test_id)
    _log_audit(admin, "duplicate", "test", result.id, {"source_test_id": str(test_id)})
    return result


# =========================================================================
# QUESTIONS
# =========================================================================

@router.post("/{test_id}/questions")

async def add_question(
    request: Request,
    test_id: UUID,
    body: QuestionCreate,
    admin: dict = Depends(get_current_admin),
):
    """Ajouter une question a un test."""
    repo = get_tests_admin_repository()
    result = await repo.add_question(test_id, body)
    _log_audit(admin, "create", "question", result.get("id"))
    return result


@router.put("/{test_id}/questions/{question_id}")

async def update_question(
    request: Request,
    test_id: UUID,
    question_id: UUID,
    body: QuestionUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier une question."""
    repo = get_tests_admin_repository()
    result = await repo.update_question(question_id, body)
    _log_audit(admin, "update", "question", question_id)
    return result


@router.delete("/{test_id}/questions/{question_id}")

async def delete_question(
    request: Request,
    test_id: UUID,
    question_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une question."""
    repo = get_tests_admin_repository()
    await repo.delete_question(question_id)
    _log_audit(admin, "delete", "question", question_id)
    return {"success": True, "message": "Question supprimee"}


@router.patch("/{test_id}/questions/reorder")

async def reorder_questions(
    request: Request,
    test_id: UUID,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Reordonner les questions d'un test. Body: {"order": ["id1", "id2", ...]}"""
    repo = get_tests_admin_repository()
    await repo.reorder_questions(test_id, body.get("order", []))
    return {"success": True}


# =========================================================================
# OPTIONS
# =========================================================================

@router.post("/{test_id}/questions/{question_id}/options")

async def add_option(
    request: Request,
    test_id: UUID,
    question_id: UUID,
    body: OptionCreate,
    admin: dict = Depends(get_current_admin),
):
    """Ajouter une option a une question."""
    repo = get_tests_admin_repository()
    result = await repo.add_option(question_id, body)
    return result


@router.put("/{test_id}/questions/{question_id}/options/{option_id}")

async def update_option(
    request: Request,
    test_id: UUID,
    question_id: UUID,
    option_id: UUID,
    body: OptionUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier une option."""
    repo = get_tests_admin_repository()
    result = await repo.update_option(option_id, body)
    return result


@router.delete("/{test_id}/questions/{question_id}/options/{option_id}")

async def delete_option(
    request: Request,
    test_id: UUID,
    question_id: UUID,
    option_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une option."""
    repo = get_tests_admin_repository()
    await repo.delete_option(option_id)
    return {"success": True, "message": "Option supprimee"}
