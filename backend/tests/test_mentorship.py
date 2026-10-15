"""Tests de l'espace mentorat : jeton d'invitation et suggestions.

Le mentor n'a pas de compte : son seul moyen d'agir est un lien signe. Le jeton
est donc le controle d'acces de tout le cote mentor, et merite d'etre teste
comme tel. Les suggestions, elles, doivent rester deterministes : une liste qui
change a chaque ouverture donne l'impression d'un tirage au sort.
"""

import os
import sys
from pathlib import Path

import pytest

os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder_key")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder")
os.environ.setdefault("SECRET_KEY", "test_secret_key_with_at_least_32_characters")
os.environ.setdefault("ENVIRONMENT", "development")

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.api.v1.endpoints.mentorship import invitation_token  # noqa: E402
from app.repositories.mentorship_repository import (  # noqa: E402
    MentorshipRepository,
    _terms,
)

REL_A = "11111111-1111-1111-1111-111111111111"
REL_B = "22222222-2222-2222-2222-222222222222"


# ── Jeton d'invitation ──────────────────────────────────────────────────────

def test_le_jeton_est_stable_pour_une_meme_relation():
    """Le mentor peut rouvrir son email trois jours plus tard."""
    assert invitation_token(REL_A) == invitation_token(REL_A)


def test_deux_relations_ont_des_jetons_differents():
    """Sinon un mentor pourrait repondre a la demande d'un autre."""
    assert invitation_token(REL_A) != invitation_token(REL_B)


def test_le_jeton_ne_contient_pas_l_identifiant():
    """Un jeton derive, pas un encodage : on ne doit pas pouvoir le fabriquer."""
    assert REL_A not in invitation_token(REL_A)
    assert REL_A.replace("-", "") not in invitation_token(REL_A)


def test_le_jeton_depend_de_la_cle_secrete(monkeypatch):
    """Une rotation de SECRET_KEY doit invalider les liens deja envoyes."""
    from app.core import config

    avant = invitation_token(REL_A)
    settings = config.get_settings()
    monkeypatch.setattr(settings, "SECRET_KEY", "une_autre_cle_de_plus_de_32_caracteres")
    assert invitation_token(REL_A) != avant


# ── Normalisation des termes ────────────────────────────────────────────────

def test_les_accents_et_la_casse_sont_ignores():
    assert _terms("Génie Électrique") == {"genie", "electrique"}


def test_les_mots_vides_sont_ecartes():
    """Sans cela, "de" et "sciences" rapprocheraient n'importe quoi."""
    assert _terms("Sciences de la Gestion") == {"gestion"}


# ── Suggestions ─────────────────────────────────────────────────────────────

class _FakeQuery:
    def __init__(self, rows):
        self.rows = rows

    def eq(self, *_a, **_kw):
        return self

    def execute(self):
        return type("Res", (), {"data": self.rows, "count": len(self.rows)})()


class _FakeTable:
    def __init__(self, rows):
        self.rows = rows

    def select(self, *_a, **_kw):
        return _FakeQuery(self.rows)


class _FakeDb:
    def __init__(self, rows):
        self.client = type("C", (), {"table": lambda _s, _n: _FakeTable(rows)})()


MENTORS = [
    {"id": "1", "full_name": "Ama", "specialty": "Génie électrique",
     "expertise_areas": ["énergie solaire"], "rating_avg": 3.0,
     "max_mentees": 5, "current_mentees": 1},
    {"id": "2", "full_name": "Kodjo", "specialty": "Gestion d'entreprise",
     "expertise_areas": ["comptabilité"], "rating_avg": 5.0,
     "max_mentees": 5, "current_mentees": 5},
    {"id": "3", "full_name": "Afi", "specialty": "Informatique",
     "expertise_areas": [], "rating_avg": 4.0,
     "max_mentees": 5, "current_mentees": 0},
]


def _repo(rows=MENTORS):
    repo = MentorshipRepository.__new__(MentorshipRepository)
    repo._db = _FakeDb(rows)
    return repo


def test_le_profil_fait_remonter_le_mentor_pertinent():
    """L'eleve interesse par l'electricite ne doit pas voir Kodjo en tete."""
    profile = {"interests": ["Électricité"], "favorite_subjects": ["Génie"],
               "career_project": ""}
    items = _repo().suggest(profile, 10)
    assert items[0]["full_name"] == "Ama"
    assert "genie" in items[0]["match_terms"]


def test_sans_profil_le_classement_suit_la_note():
    """Aucune donnee ne justifie un ordre thematique : on prend les mieux notes."""
    items = _repo().suggest(None, 10)
    assert [m["full_name"] for m in items] == ["Kodjo", "Afi", "Ama"]


def test_le_classement_est_deterministe():
    """Deux appels identiques donnent le meme ordre — pas de tirage au sort."""
    profile = {"interests": ["Informatique"]}
    assert ([m["id"] for m in _repo().suggest(profile, 10)]
            == [m["id"] for m in _repo().suggest(profile, 10)])


def test_les_places_restantes_sont_calculees():
    """Un mentor complet doit pouvoir etre signale avant que l'eleve ecrive."""
    par_nom = {m["full_name"]: m for m in _repo().suggest(None, 10)}
    assert par_nom["Kodjo"]["slots_left"] == 0
    assert par_nom["Afi"]["slots_left"] == 5


def test_la_limite_est_respectee():
    assert len(_repo().suggest(None, 2)) == 2


@pytest.mark.parametrize("profile", [None, {}, {"interests": []}])
def test_un_profil_vide_ne_fait_pas_echouer(profile):
    """Un eleve qui n'a pas fait le test d'orientation voit quand meme la liste."""
    assert len(_repo().suggest(profile, 10)) == 3
