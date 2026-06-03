"""Mentor applications, mentor tasks, mentors.is_active + notification_email setting.

Ajoute le socle pour :
- les CANDIDATURES mentor envoyees depuis l'app (mentor_applications) ;
- l'ASSIGNATION de taches aux mentors (mentor_tasks) ;
- la colonne mentors.is_active (l'admin filtre dessus mais elle manquait) +
  champs de contact denormalises (email, phone) pour les mentors crees sans
  compte utilisateur ;
- une cle app_settings 'notification_email' (email de reception des
  candidatures, configurable sans redeploiement — PAS code en dur).

Idempotent (IF NOT EXISTS). RLS : ces tables sont gerees cote backend via le
client service_role ; lecture publique interdite par defaut.

Revision ID: 015
Revises: 014
Create Date: 2026-06-02
"""
from alembic import op

revision = '015'
down_revision = '014'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Colonnes manquantes sur mentors
    op.execute("""
        ALTER TABLE mentors
            ADD COLUMN IF NOT EXISTS is_active   BOOLEAN NOT NULL DEFAULT TRUE,
            ADD COLUMN IF NOT EXISTS email       TEXT,
            ADD COLUMN IF NOT EXISTS phone       TEXT,
            ADD COLUMN IF NOT EXISTS source      TEXT DEFAULT 'manual';
    """)

    # 2. Table des candidatures mentor (envoyees depuis l'app)
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentor_applications (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id          UUID REFERENCES auth.users(id) ON DELETE SET NULL,
            full_name        TEXT NOT NULL,
            email            TEXT NOT NULL,
            phone            TEXT,
            specialty        TEXT NOT NULL,
            bio              TEXT,
            years_experience INTEGER,
            expertise_areas  TEXT[],
            linkedin_url     TEXT,
            motivation       TEXT,
            status           TEXT NOT NULL DEFAULT 'pending',
                             -- pending | approved | rejected
            review_note      TEXT,
            reviewed_by      UUID,
            reviewed_at      TIMESTAMPTZ,
            created_mentor_id UUID,
            created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_applications_status
            ON mentor_applications(status, created_at DESC);
    """)

    # 3. Table des taches assignees aux mentors
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentor_tasks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            mentor_id    UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
            title        TEXT NOT NULL,
            description  TEXT,
            status       TEXT NOT NULL DEFAULT 'todo',
                         -- todo | in_progress | done | cancelled
            priority     TEXT NOT NULL DEFAULT 'normal',
                         -- low | normal | high
            due_date     TIMESTAMPTZ,
            assigned_by  UUID,
            completed_at TIMESTAMPTZ,
            created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_tasks_mentor
            ON mentor_tasks(mentor_id, status);
    """)

    # 4. RLS : verrouillee (acces via service_role uniquement cote backend)
    op.execute("ALTER TABLE mentor_applications ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE mentor_tasks ENABLE ROW LEVEL SECURITY;")

    # 5. Seed de la cle de configuration notification_email (non code en dur)
    #    Valeur par defaut : activedutg@gmail.com — modifiable via /admin settings.
    op.execute("""
        INSERT INTO app_settings (key, value)
        VALUES ('notification_email', '"activedutg@gmail.com"')
        ON CONFLICT (key) DO NOTHING;
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS mentor_tasks CASCADE;")
    op.execute("DROP TABLE IF EXISTS mentor_applications CASCADE;")
    op.execute("DELETE FROM app_settings WHERE key = 'notification_email';")
    # On NE retire PAS les colonnes mentors (perte de donnees) — no-op documente.
