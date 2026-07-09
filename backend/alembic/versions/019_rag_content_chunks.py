"""Fondations RAG TutorAI : pgvector + content_chunks + recherche semantique.

Active l'extension pgvector et cree la table `content_chunks` (unite de
recherche : un fragment de contenu de cours + son embedding). Ajoute la
fonction `match_content_chunks` pour la recherche par similarite cosinus
(le client Python ne peut pas exprimer l'operateur `<=>` directement, on
passe donc par un RPC Postgres).

Dimension du vecteur : 768 (Ollama nomic-embed-text). Doit rester alignee
avec settings.EMBEDDING_DIM.

SECURITE : RLS verrouillee, acces via service_role cote backend. Tables et
fonction dormantes tant que TUTOR_RAG_ENABLED est desactive.

Revision ID: 019
Revises: 018
Create Date: 2026-07-09
"""
from alembic import op

revision = '019'
down_revision = '018'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Extension pgvector (idempotent).
    op.execute("CREATE EXTENSION IF NOT EXISTS vector;")

    # 2. Table des fragments de contenu indexes.
    op.execute("""
        CREATE TABLE IF NOT EXISTS content_chunks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            source_type TEXT NOT NULL,          -- 'lesson' | 'knowledge_base' | ...
            source_id   UUID,                   -- id de la source (nullable)
            subject     TEXT,                    -- matiere, pour filtrer la recherche
            title       TEXT,                    -- titre affichable (citation)
            chunk_index INTEGER NOT NULL DEFAULT 0,
            chunk_text  TEXT NOT NULL,
            embedding   vector(768),             -- Ollama nomic-embed-text
            metadata    JSONB NOT NULL DEFAULT '{}',
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)

    # Index de similarite cosinus (HNSW : bon rappel, requetes rapides).
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_content_chunks_embedding
            ON content_chunks USING hnsw (embedding vector_cosine_ops);
    """)
    # Index pour la re-ingestion / suppression par source.
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_content_chunks_source
            ON content_chunks(source_type, source_id);
    """)

    # 3. RLS verrouillee (acces backend via service_role uniquement).
    op.execute("ALTER TABLE content_chunks ENABLE ROW LEVEL SECURITY;")

    # 4. Fonction de recherche par similarite cosinus.
    #    Retourne les chunks les plus proches, filtrables par matiere/source,
    #    au-dessus d'un seuil de similarite (1 - distance cosinus).
    op.execute("""
        CREATE OR REPLACE FUNCTION match_content_chunks(
            query_embedding vector(768),
            match_count int DEFAULT 4,
            min_similarity float DEFAULT 0.3,
            filter_subject text DEFAULT NULL,
            filter_source_id uuid DEFAULT NULL
        )
        RETURNS TABLE (
            id uuid,
            source_type text,
            source_id uuid,
            subject text,
            title text,
            chunk_text text,
            similarity float
        )
        LANGUAGE sql STABLE
        AS $$
            SELECT
                c.id, c.source_type, c.source_id, c.subject, c.title, c.chunk_text,
                1 - (c.embedding <=> query_embedding) AS similarity
            FROM content_chunks c
            WHERE c.embedding IS NOT NULL
              AND (filter_subject IS NULL OR c.subject = filter_subject)
              AND (filter_source_id IS NULL OR c.source_id = filter_source_id)
              AND 1 - (c.embedding <=> query_embedding) >= min_similarity
            ORDER BY c.embedding <=> query_embedding
            LIMIT match_count;
        $$;
    """)


def downgrade() -> None:
    op.execute("DROP FUNCTION IF EXISTS match_content_chunks(vector, int, float, text, uuid);")
    op.execute("DROP TABLE IF EXISTS content_chunks CASCADE;")
    # L'extension vector est laissee en place (potentiellement utilisee ailleurs).
