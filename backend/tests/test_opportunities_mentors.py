"""Tests endpoints publics opportunities + mentors.

Couvre :
- Filtres et pagination opportunities
- Cache invalidation hint
- Listing mentors (verified+active only)
- Reviews mentors sans exposition de user_id
- Default currency XOF (pas EUR)
"""
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest


@pytest.fixture
def fake_supabase():
    """Mock du Supabase client utilisé par opportunities + mentors."""
    db = MagicMock()
    db.client = MagicMock()
    return db


# =============================================================================
# OPPORTUNITIES
# =============================================================================


@pytest.mark.asyncio
async def test_list_opportunities_filters_published_only(fake_supabase):
    """L'endpoint public ne doit renvoyer que les opportunités is_published=True."""
    from app.api.v1.endpoints import opportunities as opp_module

    # Reset le cache lru
    opp_module._cache.cache_clear()

    query = MagicMock()
    query.eq.return_value = query
    query.order.return_value = query
    query.range.return_value = query
    query.execute.return_value = MagicMock(data=[
        {"id": str(uuid4()), "title": "Stage UX", "opportunity_type": "internship",
         "organization_name": "ActivEdu", "is_published": True, "is_featured": False,
         "created_at": "2026-05-21T00:00:00"},
    ])
    fake_supabase.client.table.return_value.select.return_value = query

    with patch.object(opp_module, "get_supabase_client", return_value=fake_supabase), \
         patch.object(opp_module, "_cache", lambda: MagicMock(get=MagicMock(return_value=None), set=MagicMock())):
        # NB: appel direct sans FastAPI = Query() non résolu → on passe les
        # defaults explicitement pour limit/offset (int) et les filtres (None).
        result = await opp_module.list_opportunities(
            opportunity_type=None, location=None, remote=None, limit=20, offset=0,
        )

    assert isinstance(result, list)
    assert len(result) == 1
    assert result[0]["title"] == "Stage UX"
    # Vérifie qu'on a appelé .eq("is_published", True)
    eq_calls = query.eq.call_args_list
    assert any(call.args == ("is_published", True) for call in eq_calls)


@pytest.mark.asyncio
async def test_list_opportunities_filters_by_type(fake_supabase):
    """Filtre opportunity_type doit se traduire en .eq() sur la query."""
    from app.api.v1.endpoints import opportunities as opp_module

    opp_module._cache.cache_clear()

    query = MagicMock()
    query.eq.return_value = query
    query.order.return_value = query
    query.range.return_value = query
    query.execute.return_value = MagicMock(data=[])
    fake_supabase.client.table.return_value.select.return_value = query

    with patch.object(opp_module, "get_supabase_client", return_value=fake_supabase), \
         patch.object(opp_module, "_cache", lambda: MagicMock(get=MagicMock(return_value=None), set=MagicMock())):
        await opp_module.list_opportunities(
            opportunity_type="scholarship", location=None, remote=None, limit=20, offset=0,
        )

    eq_calls = query.eq.call_args_list
    assert any(call.args == ("opportunity_type", "scholarship") for call in eq_calls)


@pytest.mark.asyncio
async def test_get_opportunity_default_currency_is_xof(fake_supabase):
    """L'opportunité sans salary_currency doit retourner XOF par défaut, pas EUR."""
    from app.api.v1.endpoints import opportunities as opp_module

    opp_module._cache.cache_clear()
    oid = uuid4()

    query = MagicMock()
    query.eq.return_value = query
    query.limit.return_value = query
    query.execute.return_value = MagicMock(data=[{
        "id": str(oid), "title": "Bourse", "opportunity_type": "scholarship",
        "organization_name": "MEN", "salary_currency": None,
        "is_published": True, "is_featured": False,
        "created_at": "2026-05-21T00:00:00", "updated_at": "2026-05-21T00:00:00",
    }])
    fake_supabase.client.table.return_value.select.return_value = query

    with patch.object(opp_module, "get_supabase_client", return_value=fake_supabase), \
         patch.object(opp_module, "_cache", lambda: MagicMock(get=MagicMock(return_value=None), set=MagicMock())):
        result = await opp_module.get_opportunity(oid)

    assert result["salary_currency"] == "XOF"


@pytest.mark.asyncio
async def test_get_opportunity_not_found_raises():
    """Une opportunité inexistante doit lever NotFoundError."""
    from app.api.v1.endpoints import opportunities as opp_module
    from app.core.exceptions import NotFoundError

    opp_module._cache.cache_clear()

    fake_db = MagicMock()
    query = MagicMock()
    query.eq.return_value = query
    query.limit.return_value = query
    query.execute.return_value = MagicMock(data=[])
    fake_db.client.table.return_value.select.return_value = query

    with patch.object(opp_module, "get_supabase_client", return_value=fake_db), \
         patch.object(opp_module, "_cache", lambda: MagicMock(get=MagicMock(return_value=None), set=MagicMock())):
        with pytest.raises(NotFoundError):
            await opp_module.get_opportunity(uuid4())


# =============================================================================
# MENTORS
# =============================================================================


@pytest.mark.asyncio
async def test_list_mentors_filters_active_and_verified():
    """L'endpoint public ne doit lister que mentors actifs ET vérifiés."""
    from app.api.v1.endpoints import mentors as mentors_module

    mentors_module._cache.cache_clear()
    fake_db = MagicMock()
    query = MagicMock()
    query.eq.return_value = query
    query.order.return_value = query
    query.range.return_value = query
    query.execute.return_value = MagicMock(data=[
        {"id": str(uuid4()), "full_name": "Dr. Koffi", "specialty": "Médecine",
         "is_verified": True, "available_slots": 3, "rating_avg": 4.8},
    ])
    fake_db.client.table.return_value.select.return_value = query

    with patch.object(mentors_module, "get_supabase_client", return_value=fake_db), \
         patch.object(mentors_module, "_cache", lambda: MagicMock(get=MagicMock(return_value=None), set=MagicMock())):
        result = await mentors_module.list_mentors(specialty=None, limit=20, offset=0)

    assert len(result) == 1
    assert result[0]["full_name"] == "Dr. Koffi"
    eq_calls = query.eq.call_args_list
    assert any(call.args == ("is_active", True) for call in eq_calls)
    assert any(call.args == ("is_verified", True) for call in eq_calls)


@pytest.mark.asyncio
async def test_get_mentor_reviews_does_not_expose_user_id():
    """Les avis publics ne doivent JAMAIS exposer le user_id du reviewer."""
    from app.api.v1.endpoints import mentors as mentors_module

    fake_db = MagicMock()
    query = MagicMock()
    query.eq.return_value = query
    query.order.return_value = query
    query.limit.return_value = query
    review_id = str(uuid4())
    query.execute.return_value = MagicMock(data=[{
        "id": review_id,
        "rating": 5,
        "comment": "Excellent mentor",
        "created_at": "2026-05-21T00:00:00",
        "user_profiles": {"display_name": "Awa M.", "avatar_url": "https://x/a.png"},
    }])
    fake_db.client.table.return_value.select.return_value = query

    with patch.object(mentors_module, "get_supabase_client", return_value=fake_db):
        result = await mentors_module.get_mentor_reviews(uuid4())

    assert len(result) == 1
    review = result[0]
    # Cle critique : pas de user_id dans la reponse
    assert "user_id" not in review
    assert review["reviewer_name"] == "Awa M."
    assert review["reviewer_avatar"] == "https://x/a.png"


@pytest.mark.asyncio
async def test_get_mentor_reviews_anonymous_fallback():
    """Si user_profiles est null, le reviewer doit être affiché 'Anonyme'."""
    from app.api.v1.endpoints import mentors as mentors_module

    fake_db = MagicMock()
    query = MagicMock()
    query.eq.return_value = query
    query.order.return_value = query
    query.limit.return_value = query
    query.execute.return_value = MagicMock(data=[{
        "id": str(uuid4()), "rating": 3, "comment": "ok",
        "created_at": "2026-05-21T00:00:00",
        "user_profiles": None,
    }])
    fake_db.client.table.return_value.select.return_value = query

    with patch.object(mentors_module, "get_supabase_client", return_value=fake_db):
        result = await mentors_module.get_mentor_reviews(uuid4())

    assert result[0]["reviewer_name"] == "Anonyme"


@pytest.mark.asyncio
async def test_get_mentor_not_found_raises():
    from app.api.v1.endpoints import mentors as mentors_module
    from app.core.exceptions import NotFoundError

    mentors_module._cache.cache_clear()
    fake_db = MagicMock()
    query = MagicMock()
    query.eq.return_value = query
    query.limit.return_value = query
    query.execute.return_value = MagicMock(data=[])
    fake_db.client.table.return_value.select.return_value = query

    with patch.object(mentors_module, "get_supabase_client", return_value=fake_db), \
         patch.object(mentors_module, "_cache", lambda: MagicMock(get=MagicMock(return_value=None), set=MagicMock())):
        with pytest.raises(NotFoundError):
            await mentors_module.get_mentor(uuid4())
