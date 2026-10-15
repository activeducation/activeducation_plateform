"""Tests du filtre d'agrement MESR de l'annuaire public des ecoles.

Le repository est teste contre un faux client Supabase qui enregistre les
appels de filtrage : on verifie QUE le bon filtre est pose (et avec quel
millesime), sans dependre de la base.
"""

import pytest

from app.repositories.schools_repository import SchoolsPublicRepository


class _FakeQuery:
    """Enregistre les filtres poses par le repository."""

    def __init__(self, recorder):
        self.rec = recorder

    def eq(self, column, value):
        self.rec["eq"].append((column, value))
        return self

    def contains(self, column, value):
        self.rec["contains"].append((column, value))
        return self

    def or_(self, expr):
        self.rec["or_"].append(expr)
        return self

    def order(self, *_a, **_kw):
        return self

    def range(self, *_a, **_kw):
        return self

    def execute(self):
        return type("Res", (), {"data": [], "count": 0})()


class _FakeTable:
    def __init__(self, recorder):
        self.rec = recorder

    def select(self, *_a, **_kw):
        return _FakeQuery(self.rec)


class _FakeClient:
    def __init__(self, recorder):
        self.rec = recorder

    def table(self, name):
        self.rec["tables"].append(name)
        return _FakeTable(self.rec)


class _FakeDb:
    def __init__(self, recorder):
        self.client = _FakeClient(recorder)


@pytest.fixture
def repo_and_rec(monkeypatch):
    rec = {"eq": [], "contains": [], "or_": [], "tables": []}
    repo = SchoolsPublicRepository.__new__(SchoolsPublicRepository)
    repo._db = _FakeDb(rec)
    return repo, rec


def _label(monkeypatch, value="MESR 2026-2027", default_only=True):
    """Force le millesime et le defaut de configuration."""
    from app.core import config

    settings = config.get_settings()
    monkeypatch.setattr(settings, "SCHOOLS_ACCREDITATION_LABEL", value, raising=False)
    monkeypatch.setattr(settings, "SCHOOLS_ACCREDITED_ONLY", default_only, raising=False)


@pytest.mark.asyncio
async def test_default_applies_accreditation_filter(repo_and_rec, monkeypatch):
    """Sans parametre, le defaut de configuration (True) restreint aux agreees."""
    repo, rec = repo_and_rec
    _label(monkeypatch)

    await repo.list_schools()

    assert ("accreditations", ["MESR 2026-2027"]) in rec["contains"]


@pytest.mark.asyncio
async def test_accredited_only_false_removes_restriction(repo_and_rec, monkeypatch):
    """accredited_only=False signifie "ne pas restreindre", pas "les non agreees"."""
    repo, rec = repo_and_rec
    _label(monkeypatch)

    await repo.list_schools(accredited_only=False)

    assert rec["contains"] == []


@pytest.mark.asyncio
async def test_accredited_only_true_forces_filter_even_if_default_off(repo_and_rec, monkeypatch):
    repo, rec = repo_and_rec
    _label(monkeypatch, default_only=False)

    await repo.list_schools(accredited_only=True)

    assert ("accreditations", ["MESR 2026-2027"]) in rec["contains"]


@pytest.mark.asyncio
async def test_default_off_lists_everything(repo_and_rec, monkeypatch):
    repo, rec = repo_and_rec
    _label(monkeypatch, default_only=False)

    await repo.list_schools()

    assert rec["contains"] == []


@pytest.mark.asyncio
async def test_label_comes_from_settings_not_hardcoded(repo_and_rec, monkeypatch):
    """Changer le millesime en configuration doit changer le filtre pose."""
    repo, rec = repo_and_rec
    _label(monkeypatch, value="MESR 2027-2028")

    await repo.list_schools()

    assert ("accreditations", ["MESR 2027-2028"]) in rec["contains"]


@pytest.mark.asyncio
async def test_active_filter_still_applied(repo_and_rec, monkeypatch):
    """Le filtre d'agrement ne remplace pas le filtre is_active."""
    repo, rec = repo_and_rec
    _label(monkeypatch)

    await repo.list_schools()

    assert ("is_active", True) in rec["eq"]


@pytest.mark.asyncio
async def test_other_filters_combine_with_accreditation(repo_and_rec, monkeypatch):
    repo, rec = repo_and_rec
    _label(monkeypatch)

    await repo.list_schools(city="Lomé", school_type="institut")

    assert ("city", "Lomé") in rec["eq"]
    assert ("type", "institut") in rec["eq"]
    assert ("accreditations", ["MESR 2026-2027"]) in rec["contains"]
