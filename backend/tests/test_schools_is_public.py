"""Garde-fou : ne jamais deduire qu'une ecole est publique.

La colonne `schools.is_public` etait declaree `DEFAULT TRUE` et n'a jamais ete
renseignee par l'import. Le backend repetait ce defaut (`s.get("is_public",
True)`), si bien que les 133 fiches de production ressortaient "publiques" et
que l'application affichait le badge "Publique" sur des etablissements que le
MESR classe en `prive`.

Ces tests figent la regle : une valeur absente reste inconnue.
"""

import pytest

from app.repositories.schools_repository import SchoolsPublicRepository
from app.schemas.schools import SchoolPublicDetail, SchoolPublicSummary


class _FakeQuery:
    def __init__(self, rows):
        self.rows = rows

    def eq(self, *_a, **_kw):
        return self

    def contains(self, *_a, **_kw):
        return self

    def or_(self, *_a, **_kw):
        return self

    def order(self, *_a, **_kw):
        return self

    def range(self, *_a, **_kw):
        return self

    def execute(self):
        return type("Res", (), {"data": self.rows, "count": len(self.rows)})()


class _FakeTable:
    def __init__(self, rows):
        self.rows = rows

    def select(self, *_a, **_kw):
        return _FakeQuery(self.rows)


class _FakeClient:
    def __init__(self, rows):
        self.rows = rows

    def table(self, name):
        # Le comptage des programmes n'est pas l'objet du test ; la requete
        # correspondante echoue et le repository l'absorbe deja.
        return _FakeTable(self.rows if name == "schools" else [])


class _FakeDb:
    def __init__(self, rows):
        self.client = _FakeClient(rows)


def _repo(rows):
    repo = SchoolsPublicRepository.__new__(SchoolsPublicRepository)
    repo._db = _FakeDb(rows)
    return repo


ROW = {
    "id": "11111111-2222-3333-4444-555555555555",
    "name": "Institut Polytechnique Jameson",
    "type": "institut",
    "city": "Lome",
}


def test_le_defaut_du_schema_est_inconnu():
    """Sans valeur, le champ vaut None — jamais True."""
    assert SchoolPublicSummary.model_fields["is_public"].default is None
    assert SchoolPublicDetail.model_fields["is_public"].default is None


@pytest.mark.asyncio
async def test_une_colonne_absente_reste_inconnue():
    result = await _repo([dict(ROW)]).list_schools()
    assert result.items[0].is_public is None


@pytest.mark.asyncio
async def test_un_null_en_base_reste_inconnu():
    """`.get()` rendrait None, mais un defaut le retransformerait en True."""
    result = await _repo([dict(ROW, is_public=None)]).list_schools()
    assert result.items[0].is_public is None


@pytest.mark.asyncio
@pytest.mark.parametrize("value", [True, False])
async def test_une_valeur_renseignee_est_transmise_telle_quelle(value):
    result = await _repo([dict(ROW, is_public=value)]).list_schools()
    assert result.items[0].is_public is value
