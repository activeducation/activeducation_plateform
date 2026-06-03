"""Examens QCM par cours + badge a la reussite (>= passing_score).

Ajoute :
- course_exams : 1 examen par cours (titre, score de passage defaut 80,
  badge offert a la reussite, XP bonus).
- exam_questions : questions QCM (texte + options JSONB avec is_correct).
- user_exam_attempts : tentatives d'un etudiant (score, passed).

Le badge reutilise le systeme existant user_achievements (insere a la
reussite par le backend). Aucune table de badge dediee.

Idempotent (IF NOT EXISTS). RLS : examens lisibles par les etudiants
(lecture seule des questions sans la bonne reponse cote API), tentatives
gerees cote backend (service_role).

Revision ID: 016
Revises: 015
Create Date: 2026-06-03
"""
from alembic import op

revision = '016'
down_revision = '015'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Examen (1 par cours)
    op.execute("""
        CREATE TABLE IF NOT EXISTS course_exams (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            course_id     UUID NOT NULL UNIQUE
                          REFERENCES elearning_courses(id) ON DELETE CASCADE,
            title         TEXT NOT NULL DEFAULT 'Examen final',
            description   TEXT,
            passing_score INTEGER NOT NULL DEFAULT 80,   -- % requis pour reussir
            xp_reward     INTEGER NOT NULL DEFAULT 100,  -- XP bonus a la reussite
            badge_title   TEXT,                          -- ex: "Expert Python"
            badge_icon    TEXT,                          -- emoji ou URL
            is_active     BOOLEAN NOT NULL DEFAULT TRUE,
            created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)

    # 2. Questions QCM
    op.execute("""
        CREATE TABLE IF NOT EXISTS exam_questions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            exam_id       UUID NOT NULL REFERENCES course_exams(id) ON DELETE CASCADE,
            question      TEXT NOT NULL,
            options       JSONB NOT NULL DEFAULT '[]',
                          -- [{"text": "...", "is_correct": true/false}, ...]
            points        INTEGER NOT NULL DEFAULT 1,
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_exam_questions_exam
            ON exam_questions(exam_id, display_order);
    """)

    # 3. Tentatives etudiant
    op.execute("""
        CREATE TABLE IF NOT EXISTS user_exam_attempts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id     UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            exam_id     UUID NOT NULL REFERENCES course_exams(id) ON DELETE CASCADE,
            course_id   UUID REFERENCES elearning_courses(id) ON DELETE CASCADE,
            score       INTEGER NOT NULL,        -- pourcentage 0..100
            passed      BOOLEAN NOT NULL DEFAULT FALSE,
            answers     JSONB,                   -- {question_id: option_index}
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_user_exam_attempts
            ON user_exam_attempts(user_id, exam_id, created_at DESC);
    """)

    # 4. RLS verrouillee (acces via service_role cote backend)
    op.execute("ALTER TABLE course_exams ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE user_exam_attempts ENABLE ROW LEVEL SECURITY;")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS user_exam_attempts CASCADE;")
    op.execute("DROP TABLE IF EXISTS exam_questions CASCADE;")
    op.execute("DROP TABLE IF EXISTS course_exams CASCADE;")
