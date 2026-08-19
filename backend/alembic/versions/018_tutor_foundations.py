"""Fondations TutorAI : persistance des conversations AIDA / tuteur.

Remplace le stockage en memoire process (SessionManager) par une
persistance durable, multi-worker safe :

- chat_sessions  : une conversation (proprietaire, contexte, compteurs).
- chat_messages  : les messages d'une conversation (role, contenu).

SECURITE : RLS verrouillee, acces exclusivement via service_role cote
backend. Le user_id est denormalise sur chat_messages pour permettre au
repository d'imposer l'ownership sur CHAQUE requete (le service_role
contourne la RLS, l'ownership doit donc etre applicatif).

Idempotent (IF NOT EXISTS). Tables dormantes tant que le flag
TUTOR_PERSIST_SESSIONS est desactive : cette migration n'a aucun impact
sur le chemin /chat existant.

Revision ID: 018
Revises: 017
Create Date: 2026-07-08
"""
from alembic import op

revision = '018'
down_revision = '017'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Sessions de conversation (une par fil de discussion)
    op.execute("""
        CREATE TABLE IF NOT EXISTS chat_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id         UUID NOT NULL
                            REFERENCES user_profiles(id) ON DELETE CASCADE,
            title           TEXT,                          -- resume court, optionnel
            subject_context JSONB NOT NULL DEFAULT '{}',   -- contexte RIASEC / matiere
            provider        TEXT,                          -- llm provider utilise (groq, ollama...)
            message_count   INTEGER NOT NULL DEFAULT 0,
            last_active_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_sessions_user
            ON chat_sessions(user_id, last_active_at DESC);
    """)

    # 2. Messages d'une conversation
    #    user_id denormalise : permet l'ownership applicatif sans jointure
    #    (le service_role contourne la RLS).
    op.execute("""
        CREATE TABLE IF NOT EXISTS chat_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id  UUID NOT NULL
                        REFERENCES chat_sessions(id) ON DELETE CASCADE,
            user_id     UUID NOT NULL
                        REFERENCES user_profiles(id) ON DELETE CASCADE,
            role        TEXT NOT NULL
                        CHECK (role IN ('user', 'assistant', 'system')),
            content     TEXT NOT NULL,
            token_count INTEGER,
            metadata    JSONB NOT NULL DEFAULT '{}',
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_messages_session
            ON chat_messages(session_id, created_at);
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_messages_user
            ON chat_messages(user_id, created_at DESC);
    """)

    # 3. RLS verrouillee : aucun acces direct client, tout passe par le
    #    backend (service_role) qui impose l'ownership applicativement.
    op.execute("ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS chat_messages CASCADE;")
    op.execute("DROP TABLE IF EXISTS chat_sessions CASCADE;")
