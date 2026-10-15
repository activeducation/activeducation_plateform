"""Politiques de lecture publique pour les tables laissees sans policy.

Contexte
--------
Un audit de la production a revele 24 tables avec RLS actif et AUCUNE
politique : en PostgreSQL, cela ne veut pas dire "tout est permis" mais
"personne ne peut lire", hormis les roles qui contournent RLS (service_role).
Elles proviennent du schema.sql historique, qui a active RLS sans ecrire les
politiques ; les migrations ne les declarent pas.

Toutes ne necessitent pas une politique. Le backend a ete audite table par
table pour determiner quelle clef Supabase interroge chacune :

  - 14 tables ne sont lues qu'avec `service_role`, qui contourne RLS :
    beneficiary_dossiers, chat_messages, chat_sessions, content_chunks,
    course_exams, exam_questions, lesson_skills, mentor_applications,
    mentor_tasks, partner_organizations, skills, student_orientation_profile,
    user_exam_attempts, user_skill_mastery.
    Elles fonctionnent deja et contiennent pour la plupart des donnees
    personnelles : RLS ferme est ici la bonne configuration, on n'y touche pas.

  - 5 tables ne sont interrogees par aucun code : alembic_version (utilisee par
    Alembic via une connexion postgres directe), conversations,
    leaderboard_weekly, mentor_availability, mentor_contact_requests.
    Rien a ouvrir tant qu'aucune fonctionnalite ne les lit.

  - 4 tables sont lues avec la clef ANON et sont donc actuellement vides cote
    application. Ce sont celles traitees ici.

Le backend ne transmet jamais le JWT de l'eleve a Supabase (aucun `set_auth`) :
`auth.uid()` y est toujours NULL. Une politique du type `user_id = auth.uid()`
ne peut donc rien filtrer ici — c'est le backend qui joue ce role. Les
politiques ci-dessous ne couvrent par consequent que des donnees publiques.

Revision ID: 027
Revises: 026
Create Date: 2026-08-21
"""
from alembic import op

revision = '027'
down_revision = '026'
branch_labels = None
depends_on = None

# Cles de app_settings reellement exposees par GET /settings/public.
# La liste est dupliquee depuis PUBLIC_SETTINGS_KEYS (endpoints/settings.py) :
# le code filtre APRES avoir tout lu, ce qui suffit via l'API mais laisserait
# fuiter les autres reglages a qui interroge PostgREST directement avec la
# clef anon — celle-ci etant embarquee dans l'application.
PUBLIC_SETTINGS_KEYS = ("maintenance_mode", "default_language", "welcome_message")

# Colonnes servies par les endpoints publics d'opportunities (liste + detail,
# filtres et tri compris). PostgreSQL exige le privilege SELECT sur toute
# colonne referencee, pas seulement sur celles retournees.
OPPORTUNITY_COLUMNS = (
    "id", "title", "opportunity_type", "organization_name", "organization_logo",
    "location", "remote_type", "description", "duration", "requirements",
    "benefits", "salary_min", "salary_max", "salary_currency", "application_url",
    "application_deadline", "is_published", "is_featured", "created_at",
    "updated_at",
)

# Colonnes servies par GET /mentors/{id}/reviews.
REVIEW_COLUMNS = (
    "id", "mentor_id", "rating", "comment", "created_at",
    # Colonne d'auteur : le nom varie selon les bases et n'est pas garanti.
    # L'intersection avec information_schema ne gardera que celle qui existe ;
    # PostgREST en a besoin pour resoudre la jointure vers user_profiles.
    "user_id", "student_id", "author_id", "profile_id",
)


def _policy(table: str, name: str, using: str, columns: tuple[str, ...] | None = None) -> None:
    """Pose une politique de lecture et, si demande, restreint les colonnes.

    Les colonnes sont INTERSECTEES avec celles reellement presentes : la base
    de production diverge des migrations (elle vient d'un schema.sql
    historique), et une liste codee en dur echoue des qu'une colonne supposee
    n'existe pas — c'est ce qui est arrive avec mentor_reviews.user_id. On
    interroge donc le catalogue plutot que de supposer.
    """
    op.execute(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY")
    op.execute(f"DROP POLICY IF EXISTS {name} ON {table}")
    op.execute(f"""
        CREATE POLICY {name} ON {table}
            FOR SELECT
            TO anon, authenticated
            USING ({using});
    """)

    if not columns:
        return

    wanted = ", ".join(f"'{c}'" for c in columns)
    op.execute(f"""
DO $$
DECLARE
    existing_columns text;
BEGIN
    SELECT string_agg(quote_ident(column_name), ', ')
      INTO existing_columns
      FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name = '{table}'
       AND column_name IN ({wanted});

    IF existing_columns IS NOT NULL THEN
        EXECUTE 'REVOKE SELECT ON TABLE {table} FROM anon, authenticated';
        EXECUTE 'GRANT SELECT (' || existing_columns
                || ') ON TABLE {table} TO anon, authenticated';
    END IF;
END $$;
""")


def upgrade() -> None:
    # --- Opportunites : seules les offres publiees ---------------------------
    _policy(
        "opportunities",
        "opportunities_public_read",
        "is_published IS TRUE",
        OPPORTUNITY_COLUMNS,
    )

    # --- Defis : catalogue public, aucune donnee personnelle -----------------
    # gamification.py (cote eleve) lit `challenges` avec la clef anon et un
    # SELECT *. On accorde donc la table entiere plutot que des colonnes.
    _policy("challenges", "challenges_public_read", "is_active IS TRUE")

    # --- Avis sur les mentors : publics par nature ---------------------------
    _policy(
        "mentor_reviews",
        "mentor_reviews_public_read",
        "TRUE",
        REVIEW_COLUMNS,
    )

    # --- Reglages : UNIQUEMENT les cles declarees publiques ------------------
    keys = ", ".join(f"'{k}'" for k in PUBLIC_SETTINGS_KEYS)
    _policy(
        "app_settings",
        "app_settings_public_read",
        f"key IN ({keys})",
        ("key", "value"),
    )


def downgrade() -> None:
    for table, name in (
        ("opportunities", "opportunities_public_read"),
        ("challenges", "challenges_public_read"),
        ("mentor_reviews", "mentor_reviews_public_read"),
        ("app_settings", "app_settings_public_read"),
    ):
        op.execute(f"DROP POLICY IF EXISTS {name} ON {table}")
    # Les privileges de colonnes ne sont pas restaures : rendre a nouveau
    # lisibles toutes les colonnes a anon exposerait des donnees que la
    # situation d'origine n'exposait pas non plus (aucune politique = aucune
    # lecture).
