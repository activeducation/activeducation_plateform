"""Garde-fous sur la creation d'un mentor lors de l'approbation.

La table `mentors` vient d'un schema.sql historique que les migrations ne
declarent pas : ses contraintes ne sont visibles qu'en interrogeant la base.
L'approbation a echoue trois fois en production pour cette raison. Ces tests
figent le contrat observe sur le schema reel.
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

from app.api.v1.endpoints.admin.mentor_applications import (  # noqa: E402
    MENTOR_REQUIRED_FIELDS,
    build_mentor_data,
)


def test_required_columns_are_always_present():
    """profession et bio sont NOT NULL sans defaut : jamais absentes du payload."""
    minimal = {"full_name": "Test User", "specialty": "Dev", "email": "a@b.c"}
    data = build_mentor_data(minimal)
    for field in MENTOR_REQUIRED_FIELDS:
        assert field in data, f"{field} est NOT NULL et doit toujours etre fourni"


def test_bio_absente_ne_disparait_pas_du_payload():
    """Le filtre des valeurs nulles retirait une bio absente -> insertion KO."""
    data = build_mentor_data({"full_name": "Sans Bio", "specialty": "Dev"})
    assert data["bio"] == ""
    assert data["bio"] is not None


def test_bio_reprend_la_motivation_a_defaut():
    """Mieux vaut la motivation du candidat qu'une bio vide."""
    data = build_mentor_data({
        "specialty": "Dev",
        "motivation": "J'aime partager mon experience",
    })
    assert data["bio"] == "J'aime partager mon experience"


def test_profession_reprend_la_specialite():
    """La candidature ne connait que `specialty` ; `profession` en decoule."""
    data = build_mentor_data({"specialty": "Ingenierie mecanique"})
    assert data["profession"] == "Ingenierie mecanique"
    assert data["specialty"] == "Ingenierie mecanique"


def test_profession_a_un_repli_si_la_specialite_manque():
    data = build_mentor_data({"full_name": "Anonyme"})
    assert data["profession"] == "Mentor"


def test_le_compte_est_lie_par_user_id_pas_par_id():
    """`id` est la cle primaire ; le lien au compte passe par `user_id`.

    Ecrire l'identifiant du compte dans `id` laissait `user_id` vide et aurait
    viole la cle primaire en approuvant deux candidatures du meme compte.
    """
    data = build_mentor_data({"specialty": "Dev", "user_id": "11111111-2222-3333-4444-555555555555"})
    assert data["user_id"] == "11111111-2222-3333-4444-555555555555"
    assert "id" not in data


def test_pas_de_user_id_quand_le_candidat_na_pas_de_compte():
    data = build_mentor_data({"specialty": "Dev"})
    assert "user_id" not in data


def test_la_photo_de_candidature_devient_l_avatar():
    """La photo jointe par le candidat suit jusqu'au profil du mentor."""
    data = build_mentor_data({
        "specialty": "Dev",
        "photo_url": "https://exemple.supabase.co/storage/v1/object/public/avatars/x.jpg",
    })
    assert data["avatar_url"].endswith("/avatars/x.jpg")


def test_sans_photo_aucun_avatar_nest_force():
    """Sans photo, la colonne n'est pas envoyee (elle est nullable)."""
    data = build_mentor_data({"specialty": "Dev"})
    assert "avatar_url" not in data


def test_le_mentor_cree_est_actif_et_verifie():
    """Une candidature approuvee produit un mentor visible dans l'app."""
    data = build_mentor_data({"specialty": "Dev"})
    assert data["is_active"] is True
    assert data["is_verified"] is True
    assert data["source"] == "application"


@pytest.mark.parametrize("field", ["email", "phone", "linkedin_url", "years_experience"])
def test_les_champs_facultatifs_absents_sont_omis(field):
    """Les colonnes nullables ne sont pas forcees a None inutilement."""
    data = build_mentor_data({"specialty": "Dev"})
    assert field not in data
