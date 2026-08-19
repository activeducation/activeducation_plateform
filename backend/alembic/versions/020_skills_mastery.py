"""Fondations Phase 3 TutorAI : graphe de competences + suivi de maitrise (BKT).

Ajoute la notion de competence (absente jusqu'ici : la progression etait
binaire lecon/examen) :
- skills : referentiel de competences par matiere, avec prerequis.
- lesson_skills : lie une lecon existante a une ou plusieurs competences.
- user_skill_mastery : probabilite de maitrise par (utilisateur, competence),
  mise a jour par Bayesian Knowledge Tracing.

SECURITE : RLS verrouillee, acces via service_role. Dormant tant que
TUTOR_MASTERY_ENABLED est desactive.

Revision ID: 020
Revises: 019
Create Date: 2026-07-13
"""
from alembic import op

revision = '020'
down_revision = '019'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Referentiel de competences.
    op.execute("""
        CREATE TABLE IF NOT EXISTS skills (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            subject      TEXT NOT NULL,
            code         TEXT NOT NULL,          -- ex: 'MATH.FRAC.ADD'
            title        TEXT NOT NULL,
            description  TEXT,
            prerequisite_skill_ids UUID[] NOT NULL DEFAULT '{}',
            created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (subject, code)
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_skills_subject ON skills(subject);
    """)

    # 2. Lien lecon <-> competence (une lecon peut couvrir plusieurs skills).
    op.execute("""
        CREATE TABLE IF NOT EXISTS lesson_skills (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            lesson_id UUID NOT NULL
                      REFERENCES elearning_lessons(id) ON DELETE CASCADE,
            skill_id  UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
            weight    REAL NOT NULL DEFAULT 1.0,   -- poids de la competence dans la lecon
            UNIQUE (lesson_id, skill_id)
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_lesson_skills_skill
            ON lesson_skills(skill_id);
    """)

    # 3. Maitrise par (utilisateur, competence) — score BKT.
    op.execute("""
        CREATE TABLE IF NOT EXISTS user_skill_mastery (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id     UUID NOT NULL
                        REFERENCES user_profiles(id) ON DELETE CASCADE,
            skill_id    UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
            p_mastery   REAL NOT NULL DEFAULT 0.3,   -- probabilite de maitrise [0,1]
            attempts    INTEGER NOT NULL DEFAULT 0,
            correct     INTEGER NOT NULL DEFAULT 0,
            last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (user_id, skill_id)
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_user_skill_mastery_user
            ON user_skill_mastery(user_id, p_mastery);
    """)

    # 4. RLS verrouillee (acces backend service_role).
    op.execute("ALTER TABLE skills ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE lesson_skills ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE user_skill_mastery ENABLE ROW LEVEL SECURITY;")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS user_skill_mastery CASCADE;")
    op.execute("DROP TABLE IF EXISTS lesson_skills CASCADE;")
    op.execute("DROP TABLE IF EXISTS skills CASCADE;")
