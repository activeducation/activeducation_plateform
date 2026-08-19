"""Etoffe le questionnaire RIASEC : 18 -> 60 items (10 par dimension).

Pourquoi
--------
Le test d'interets professionnels ne comptait que 3 items par dimension. Sur
une echelle de Likert 1-5, un score de dimension ne pouvait alors prendre que
13 valeurs, et une seule reponse deplacait le resultat d'un tiers : la mesure
etait dominee par le bruit. Un instrument RIASEC exploitable demande 8 a 10
items par dimension.

Cette migration :
  1. corrige l'orthographe des 18 items existants et du titre du test (le seed
     initial avait ete ecrit sans aucun accent : "Interets", "reparer"...) ;
  2. ajoute 42 items (7 par dimension) pour atteindre 60 items, 10 par
     dimension ;
  3. cree les 5 options de Likert pour toute question qui en est depourvue ;
  4. reordonne les 60 items en ENTRELACANT les dimensions (R, I, A, S, E, C,
     R, I, ...) : dix questions consecutives sur la meme dimension induisent un
     biais de halo, l'eleve devinant ce qui est mesure et repondant en bloc ;
  5. repartit les items en 6 sections de 10 pour la barre de progression.

Aucune suppression : question_options et test_responses referencent
test_questions en ON DELETE CASCADE, supprimer une question detruirait les
reponses deja enregistrees par les eleves. Les items existants sont donc
conserves et seulement corriges.

Idempotente : chaque insertion est gardee par un NOT EXISTS sur le texte.

Revision ID: 023
Revises: 022
Create Date: 2026-08-19
"""
from alembic import op

revision = '023'
down_revision = '022'
branch_labels = None
depends_on = None


# Le test RIASEC est resolu par son type plutot que par un identifiant en dur,
# pour rester valable si le test est recree.
TEST_ID = "(SELECT id FROM orientation_tests WHERE type = 'riasec' ORDER BY created_at LIMIT 1)"


def q(text: str) -> str:
    """Echappe une chaine pour SQL (les apostrophes francaises sont partout)."""
    return "'" + text.replace("'", "''") + "'"


# --- Corrections orthographiques des items existants (UPDATE, sans risque) ---
ACCENT_FIXES = [
    ("J'ai une imagination debordante et j'aime creer.",
     "J'ai une imagination débordante et j'aime créer."),
    ("Je prefere m'exprimer de maniere creative plutot que suivre des regles.",
     "Je préfère m'exprimer de manière créative plutôt que de suivre des règles."),
    ("J'aime organiser des dossiers et des donnees de maniere ordonnee.",
     "J'aime organiser des dossiers et des données de manière ordonnée."),
    ("Je prefere suivre des procedures etablies et claires.",
     "Je préfère suivre des procédures établies et claires."),
    ("Je suis minutieux et attentif aux details.",
     "Je suis minutieux et attentif aux détails."),
    ("J'aime diriger une equipe et prendre des decisions.",
     "J'aime diriger une équipe et prendre des décisions."),
    ("Je suis motive par la reussite et les defis ambitieux.",
     "Je suis motivé par la réussite et les défis ambitieux."),
    ("J'aime convaincre et negocier avec les autres.",
     "J'aime convaincre et négocier avec les autres."),
    ("J'aime resoudre des problemes mathematiques complexes.",
     "J'aime résoudre des problèmes mathématiques complexes."),
    ("J'aime mener des experiences et analyser des donnees.",
     "J'aime mener des expériences et analyser des données."),
    ("J'aime reparer des appareils electriques ou mecaniques.",
     "J'aime réparer des appareils électriques ou mécaniques."),
    ("Je prefere travailler avec des outils et des machines.",
     "Je préfère travailler avec des outils et des machines."),
    ("Je suis a l'aise pour parler en public ou animer des groupes.",
     "Je suis à l'aise pour parler en public ou animer des groupes."),
    ("Je me soucie du bien-etre des autres et j'aime les conseiller.",
     "Je me soucie du bien-être des autres et j'aime les conseiller."),
]

# --- 42 nouveaux items : 7 par dimension ---
# Formules variees, centrees sur des PREFERENCES d'activite (et non des
# competences auto-evaluees), et ancrees dans des situations concretes.
NEW_QUESTIONS = [
    # ---------------- Realiste (R) ----------------
    ("Realistic", "Je préfère un travail en extérieur plutôt qu'assis à un bureau."),
    ("Realistic", "J'aime comprendre comment fonctionne un moteur ou une machine."),
    ("Realistic", "Cultiver un jardin ou m'occuper d'animaux m'intéresse."),
    ("Realistic", "Je me sers volontiers d'outils pour réparer ce qui est cassé."),
    ("Realistic", "J'apprécie les activités physiques qui demandent de l'endurance."),
    ("Realistic", "Monter un meuble ou installer un équipement me plaît."),
    ("Realistic", "Je préfère voir un résultat concret à la fin de ma journée."),

    # ---------------- Investigateur (I) ----------------
    ("Investigative", "J'aime poser des questions jusqu'à comprendre en profondeur."),
    ("Investigative", "Les découvertes scientifiques m'intéressent beaucoup."),
    ("Investigative", "Je cherche la cause d'un problème avant d'essayer de le régler."),
    ("Investigative", "Résoudre une énigme ou un casse-tête me procure du plaisir."),
    ("Investigative", "J'aime lire des articles ou regarder des documentaires scientifiques."),
    ("Investigative", "Je préfère les questions complexes aux tâches simples et répétitives."),
    ("Investigative", "Comparer des données pour en tirer une conclusion me plaît."),

    # ---------------- Artistique (A) ----------------
    ("Artistic", "J'aime inventer des histoires, des chansons ou des poèmes."),
    ("Artistic", "Je remarque facilement les couleurs, les formes et l'harmonie."),
    ("Artistic", "J'aime décorer ou personnaliser mon espace."),
    ("Artistic", "Improviser me met plus à l'aise que suivre un plan strict."),
    ("Artistic", "La photo, la vidéo ou le montage m'attirent."),
    ("Artistic", "J'aime les activités où je peux exprimer ma personnalité."),
    ("Artistic", "Je préfère un travail où chaque journée est différente."),

    # ---------------- Social (S) ----------------
    ("Social", "J'aime expliquer à un camarade ce qu'il n'a pas compris."),
    ("Social", "On vient facilement me confier ses problèmes."),
    ("Social", "M'occuper d'une personne malade ou âgée ne me dérange pas."),
    ("Social", "J'aime participer à des actions communautaires ou associatives."),
    ("Social", "Travailler en équipe me motive plus que travailler seul."),
    ("Social", "J'aime accompagner quelqu'un qui apprend quelque chose de nouveau."),
    ("Social", "Aider deux personnes à régler un désaccord me semble naturel."),

    # ---------------- Entrepreneur (E) ----------------
    ("Enterprising", "J'aime lancer des projets et entraîner les autres avec moi."),
    ("Enterprising", "Vendre un produit ou défendre une idée ne me fait pas peur."),
    ("Enterprising", "J'aimerais créer ma propre entreprise un jour."),
    ("Enterprising", "Je prends facilement la parole pour défendre une position."),
    ("Enterprising", "Prendre des risques réfléchis ne m'effraie pas."),
    ("Enterprising", "J'aime organiser un événement et coordonner les participants."),
    ("Enterprising", "Être responsable d'un résultat me stimule."),

    # ---------------- Conventionnel (C) ----------------
    ("Conventional", "J'aime garder mes affaires et mes documents bien rangés."),
    ("Conventional", "Vérifier des chiffres ou des comptes ne m'ennuie pas."),
    ("Conventional", "Je préfère savoir exactement ce qu'on attend de moi."),
    ("Conventional", "J'aime planifier mon travail à l'avance."),
    ("Conventional", "Respecter les délais et les consignes est important pour moi."),
    ("Conventional", "Classer et tenir à jour des informations me convient bien."),
    ("Conventional", "Je repère facilement une erreur dans une liste ou un tableau."),
]

# Options de Likert, identiques a celles deja utilisees par le test.
LIKERT_OPTIONS = [
    ("Pas du tout", "1", 0),
    ("Un peu", "2", 1),
    ("Moyennement", "3", 2),
    ("Beaucoup", "4", 3),
    ("Passionnément", "5", 4),
]

# Ordre de rotation des dimensions pour l'entrelacement.
DIMENSION_ORDER = [
    "Realistic", "Investigative", "Artistic",
    "Social", "Enterprising", "Conventional",
]


def upgrade() -> None:
    # ------------------------------------------------------------------
    # 0. Colonnes requises par cette migration
    # ------------------------------------------------------------------
    # La base de production diverge de ce que declare la migration 001 :
    # plusieurs colonnes y ont ete ajoutees a la main, d'autres jamais creees.
    # order_index est absente en production alors que 001 la declare. On ne
    # suppose donc rien et on s'assure de la presence de ce qu'on utilise.
    # ADD COLUMN IF NOT EXISTS est sans effet si la colonne est deja la.
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0")
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS section_title TEXT")
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW()")
    op.execute("ALTER TABLE question_options ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0")
    # Utilisee par la sous-requete qui resout le test RIASEC.
    op.execute("ALTER TABLE orientation_tests ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW()")

    # ------------------------------------------------------------------
    # 1. Orthographe des items existants et du titre du test
    # ------------------------------------------------------------------
    for old, new in ACCENT_FIXES:
        op.execute(
            f"UPDATE test_questions SET question_text = {q(new)} "
            f"WHERE test_id = {TEST_ID} AND question_text = {q(old)}"
        )

    old_name = "Test d'Interets Professionnels (RIASEC)"
    new_name = "Test d'Intérêts Professionnels (RIASEC)"
    op.execute(
        f"UPDATE orientation_tests SET name = {q(new_name)} "
        f"WHERE type = 'riasec' AND name = {q(old_name)}"
    )

    op.execute(
        "UPDATE question_options SET option_text = 'Passionnément' "
        "WHERE option_text = 'Passionnement'"
    )

    # ------------------------------------------------------------------
    # 2. Nouveaux items (garde NOT EXISTS : rejouable sans doublon)
    # ------------------------------------------------------------------
    for category, text in NEW_QUESTIONS:
        op.execute(f"""
INSERT INTO test_questions (test_id, question_text, question_type, category, order_index)
SELECT {TEST_ID}, {q(text)}, 'likert', {q(category)}, 0
WHERE NOT EXISTS (
    SELECT 1 FROM test_questions
    WHERE test_id = {TEST_ID} AND question_text = {q(text)}
)
""")

    # ------------------------------------------------------------------
    # 3. Options de Likert pour toute question qui n'en a pas
    # ------------------------------------------------------------------
    values = ", ".join(
        f"({q(text)}, {q(value)}, {idx})" for text, value, idx in LIKERT_OPTIONS
    )
    op.execute(f"""
INSERT INTO question_options (question_id, option_text, option_value, order_index)
SELECT tq.id, o.option_text, o.option_value, o.order_index
FROM test_questions tq
CROSS JOIN (VALUES {values}) AS o(option_text, option_value, order_index)
WHERE tq.test_id = {TEST_ID}
  AND NOT EXISTS (
      SELECT 1 FROM question_options qo WHERE qo.question_id = tq.id
  )
""")

    # ------------------------------------------------------------------
    # 4. Entrelacement des dimensions + 5. sections de 10
    # ------------------------------------------------------------------
    rank_cases = " ".join(
        f"WHEN {q(dim)} THEN {i}" for i, dim in enumerate(DIMENSION_ORDER)
    )
    op.execute(f"""
WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY created_at NULLS LAST, id) AS position_in_dimension,
        CASE category {rank_cases} ELSE 99 END AS dimension_rank
    FROM test_questions
    WHERE test_id = {TEST_ID}
)
UPDATE test_questions tq
SET order_index = (r.position_in_dimension - 1) * 6 + r.dimension_rank,
    section_title = 'Partie ' || ((((r.position_in_dimension - 1) * 6 + r.dimension_rank) / 10) + 1) || ' sur 6'
FROM ranked r
WHERE tq.id = r.id AND r.dimension_rank <> 99
""")


def downgrade() -> None:
    # Retire uniquement les items ajoutes par cette migration. Les corrections
    # orthographiques et l'ordre ne sont pas annules : ils ne cassent rien.
    for _, text in NEW_QUESTIONS:
        op.execute(
            f"DELETE FROM test_questions WHERE test_id = {TEST_ID} AND question_text = {q(text)}"
        )
