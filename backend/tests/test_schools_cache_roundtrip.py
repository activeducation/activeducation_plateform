"""Regression : la liste et le detail des ecoles doivent survivre au cache Redis.

CacheClient.set serialise avec json.dumps(..., default=str). Passer un modele
Pydantic tel quel produisait donc une CHAINE (la repr du modele) ; au coup
suivant json.loads rendait cette chaine et la validation du response_model
echouait en 500. Symptome observe en production : le 1er appel sur une cle
repondait 200, tous les suivants 500.

Ces tests rejouent l'aller-retour de serialisation reellement effectue par
Redis, sans Redis.
"""

import json

import pytest

from app.schemas.schools import SchoolListPublicResponse, SchoolPublicSummary


def _sample_response() -> SchoolListPublicResponse:
    return SchoolListPublicResponse(
        items=[
            SchoolPublicSummary(
                id="f343009a-37fa-4fb3-a206-a5229443dc5a",
                name="Adaptation Finance Academy (AFA)",
                type="institut",
                city="Lomé",
                accreditations=["MESR 2026-2027"],
                programs_count=0,
            )
        ],
        total=118,
        page=1,
        per_page=20,
    )


def _redis_roundtrip(value):
    """Reproduit exactement ce que CacheClient fait avec Redis."""
    return json.loads(json.dumps(value, default=str))


def test_model_dumped_response_survives_cache_roundtrip():
    """Le payload cache doit se revalider en modele apres aller-retour JSON."""
    cached = _redis_roundtrip(_sample_response().model_dump(mode="json"))

    assert isinstance(cached, dict), "le cache doit rendre un dict, pas une chaine"
    restored = SchoolListPublicResponse.model_validate(cached)
    assert restored.total == 118
    assert restored.items[0].accreditations == ["MESR 2026-2027"]


def test_raw_model_would_be_corrupted_by_cache():
    """Garde-fou : cacher le modele brut degrade en chaine (le bug d'origine)."""
    corrupted = _redis_roundtrip(_sample_response())

    assert isinstance(corrupted, str)
    with pytest.raises(Exception):
        SchoolListPublicResponse.model_validate(corrupted)


def test_endpoint_caches_a_serialisable_payload(monkeypatch):
    """L'endpoint doit deposer dans le cache un objet qui passe le round-trip."""
    import asyncio
    from app.api.v1.endpoints import schools as endpoint

    stored: dict = {}

    class _Cache:
        def get(self, _key):
            return None

        def set(self, key, value, ttl=None):
            stored[key] = value

    class _Repo:
        async def list_schools(self, **_kw):
            return _sample_response()

    monkeypatch.setattr(endpoint, "get_cache", lambda: _Cache())
    monkeypatch.setattr(endpoint, "get_schools_public_repository", lambda: _Repo())

    asyncio.run(endpoint.list_schools(
        search=None, city=None, type=None, page=1, per_page=20
    ))

    assert stored, "l'endpoint doit avoir alimente le cache"
    (payload,) = stored.values()
    restored = SchoolListPublicResponse.model_validate(_redis_roundtrip(payload))
    assert restored.total == 118
