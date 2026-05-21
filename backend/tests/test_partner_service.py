"""Tests pour le partner_service — vérifie IDOR, RBAC et flow d'approbation."""
from unittest.mock import AsyncMock, MagicMock
from uuid import UUID, uuid4

import pytest

from app.core.exceptions import AuthorizationError, NotFoundError
from app.services.partner_service import PartnerService
from app.schemas.partner import (
    OrganizationCreate,
    OrganizationType,
    BeneficiaryCreate,
)


def _make_service(user_role: str = "student", user_org_id: str | None = None) -> PartnerService:
    """Factory: crée un PartnerService avec users_repo + partner_repo mockés."""
    svc = PartnerService.__new__(PartnerService)
    svc._partner_repo = MagicMock()
    svc._users_repo = MagicMock()
    svc._cache = MagicMock()

    svc._users_repo.get_by_id = AsyncMock(
        return_value={"id": "u1", "role": user_role, "organization_id": user_org_id}
    )
    svc._users_repo.update_profile = AsyncMock(return_value=None)
    return svc


# =============================================================================
# IDOR / RBAC
# =============================================================================


@pytest.mark.asyncio
async def test_get_beneficiary_blocks_student_from_other_org():
    """Un étudiant ne doit PAS pouvoir lire un bénéficiaire d'une org tierce."""
    svc = _make_service(user_role="student", user_org_id=None)
    target_org_id = uuid4()
    svc._partner_repo.get_beneficiary_by_id = AsyncMock(
        return_value={"id": "b1", "organization_id": str(target_org_id)}
    )

    with pytest.raises(AuthorizationError):
        await svc.get_beneficiary(uuid4(), uuid4())


@pytest.mark.asyncio
async def test_get_beneficiary_allows_partner_admin_of_same_org():
    """Le partner_admin de l'org peut lire ses bénéficiaires."""
    target_org_id = uuid4()
    svc = _make_service(user_role="partner_admin", user_org_id=str(target_org_id))
    svc._partner_repo.get_beneficiary_by_id = AsyncMock(
        return_value={
            "id": str(uuid4()),
            "organization_id": str(target_org_id),
            "first_name": "Ama",
            "last_name": "Koffi",
            "status": "active",
            "referred_at": "2026-05-20T00:00:00+00:00",
            "created_at": "2026-05-20T00:00:00+00:00",
        }
    )

    result = await svc.get_beneficiary(uuid4(), uuid4())
    assert result.first_name == "Ama"


@pytest.mark.asyncio
async def test_list_beneficiaries_blocks_student():
    """Un étudiant ne peut pas lister les bénéficiaires d'une organisation."""
    svc = _make_service(user_role="student")
    svc._partner_repo.get_organization_by_id = AsyncMock(return_value={"id": "o1"})

    with pytest.raises(AuthorizationError):
        await svc.list_beneficiaries(uuid4(), uuid4())


@pytest.mark.asyncio
async def test_get_organization_with_stats_blocks_unauthorized():
    """Un user random ne peut pas voir les stats d'une org partenaire."""
    svc = _make_service(user_role="student")
    svc._partner_repo.get_organization_by_id = AsyncMock(return_value={"id": "o1"})

    with pytest.raises(AuthorizationError):
        await svc.get_organization_with_stats(uuid4(), uuid4())


@pytest.mark.asyncio
async def test_admin_role_accepted_by_assert_org_access():
    """Le rôle `admin` doit avoir accès à toute organisation (parité super_admin)."""
    svc = _make_service(user_role="admin")
    # Ne doit PAS lever d'exception
    await svc._assert_org_access(uuid4(), uuid4())


@pytest.mark.asyncio
async def test_super_admin_role_accepted_by_assert_org_access():
    svc = _make_service(user_role="super_admin")
    await svc._assert_org_access(uuid4(), uuid4())


# =============================================================================
# Privilege escalation : promotion partner_admin uniquement à l'approbation
# =============================================================================


@pytest.mark.asyncio
async def test_create_organization_does_not_promote_creator():
    """create_organization ne doit PAS poser role=partner_admin sur le créateur."""
    svc = _make_service(user_role="student")
    svc._partner_repo.create_organization = AsyncMock(
        return_value={
            "id": str(uuid4()),
            "name": "CDEJ Lomé",
            "type": "cdej",
            "partner_code": "CDEJ-ABC123",
            "is_active": True,
            "is_approved": False,
            "created_at": "2026-05-20T00:00:00+00:00",
        }
    )

    creator_id = uuid4()
    data = OrganizationCreate(name="CDEJ Lome", type=OrganizationType.CDEJ)
    await svc.create_organization(data, creator_id)

    # update_profile a été appelé : on vérifie qu'il NE contient PAS "role"
    call_args = svc._users_repo.update_profile.call_args
    assert call_args is not None
    update_payload = call_args[0][1] if len(call_args[0]) > 1 else call_args.kwargs.get("data", {})
    assert "role" not in update_payload, (
        f"create_organization a tenté de promouvoir le user : {update_payload}"
    )
    assert "organization_id" in update_payload


@pytest.mark.asyncio
async def test_approve_organization_promotes_creator_to_partner_admin():
    """approve_organization doit promouvoir le créateur en partner_admin."""
    svc = _make_service(user_role="super_admin")
    creator_id = uuid4()
    svc._partner_repo.get_organization_by_id = AsyncMock(
        return_value={
            "id": str(uuid4()),
            "created_by": str(creator_id),
            "name": "Org",
            "type": "cdej",
        }
    )
    svc._partner_repo.approve_organization = AsyncMock(
        return_value={
            "id": str(uuid4()),
            "name": "Org",
            "type": "cdej",
            "is_active": True,
            "is_approved": True,
            "created_at": "2026-05-20T00:00:00+00:00",
        }
    )

    await svc.approve_organization(uuid4(), uuid4())

    # Vérifie que update_profile a été appelé avec role=partner_admin
    assert svc._users_repo.update_profile.called
    call = svc._users_repo.update_profile.call_args
    payload = call[0][1] if len(call[0]) > 1 else call.kwargs.get("data", {})
    assert payload.get("role") == "partner_admin"


# =============================================================================
# Niveau XP (gamification) — formule O(1)
# =============================================================================


def test_calculate_level_zero_xp():
    from app.api.v1.endpoints.gamification import _calculate_level
    level, _, _ = _calculate_level(0)
    assert level == 1


def test_calculate_level_negative_xp_clamped():
    from app.api.v1.endpoints.gamification import _calculate_level
    level, _, _ = _calculate_level(-500)
    assert level == 1


def test_calculate_level_high_xp_capped_at_100():
    from app.api.v1.endpoints.gamification import _calculate_level
    level, _, _ = _calculate_level(10_000_000_000)
    assert level == 100


def test_calculate_level_monotonic():
    """Plus d'XP = niveau >= ancien niveau."""
    from app.api.v1.endpoints.gamification import _calculate_level
    prev = 0
    for xp in (0, 100, 300, 600, 1000, 5000, 50000):
        level, _, _ = _calculate_level(xp)
        assert level >= prev
        prev = level


# =============================================================================
# Sentry security event tracking sur IDOR
# =============================================================================


@pytest.mark.asyncio
async def test_idor_attempt_logged_to_sentry(monkeypatch):
    """Un refus _assert_org_access doit émettre un événement Sentry tagué."""
    from app.services import partner_service as svc_module

    captured = []

    class FakeSentry:
        def set_tag(self, k, v): captured.append(("tag", k, v))
        def set_context(self, k, v): captured.append(("context", k, v))
        def capture_message(self, msg, level="info"):
            captured.append(("message", msg, level))

    # Monkey-patch sentry_sdk au moment de l'import dynamique
    import sys
    fake = FakeSentry()
    sys.modules["sentry_sdk"] = fake  # type: ignore

    svc = _make_service(user_role="student")

    with pytest.raises(Exception):  # AuthorizationError
        await svc._assert_org_access(uuid4(), uuid4())

    tags = [c for c in captured if c[0] == "tag"]
    messages = [c for c in captured if c[0] == "message"]
    assert any(t[1] == "security_event" and t[2] == "idor_attempt" for t in tags)
    assert any("idor_attempt" in m[1] for m in messages)


# =============================================================================
# Approve organization atomique via RPC
# =============================================================================


@pytest.mark.asyncio
async def test_approve_organization_calls_rpc(monkeypatch):
    """approve_organization doit appeler le RPC postgres atomique."""
    from app.services import partner_service as svc_module

    svc = _make_service(user_role="super_admin")
    org_id = uuid4()
    approved_by = uuid4()

    fake_db = MagicMock()
    rpc_result = {
        "id": str(org_id), "name": "CDEJ Lome", "type": "cdej",
        "partner_code": "CDEJ-XYZ",
        "is_active": True, "is_approved": True,
        "approved_at": "2026-05-21T00:00:00+00:00",
        "created_at": "2026-05-20T00:00:00+00:00",
    }
    fake_db.rpc = MagicMock(return_value=rpc_result)

    monkeypatch.setattr(
        "app.services.partner_service.get_supabase_client", lambda: fake_db
    )

    result = await svc.approve_organization(org_id, approved_by)

    # Vérifie que le RPC a été appelé avec les bons params
    fake_db.rpc.assert_called_once()
    call_args = fake_db.rpc.call_args
    assert call_args.args[0] == "approve_partner_organization"
    assert call_args.args[1]["p_org_id"] == str(org_id)
    assert call_args.args[1]["p_approved_by"] == str(approved_by)
    assert result.is_approved is True
