"""Espace mentorat : demande, decision, seances.

Pourquoi
--------
Les mentors n'etaient qu'un annuaire : on les consultait, sans jamais pouvoir
les solliciter. Les tables `mentor_relationships` et `mentor_availability`
existent depuis le schema.sql historique mais aucun code ne les lit, et le
front declare deja des routes (`/mentors/{id}/request`,
`/mentor-relationships`) que le backend n'implemente pas.

Contrainte structurante
-----------------------
Aucun mentor n'a de compte utilisateur (verifie en production : 4 mentors,
0 `user_id`). Un espace ou le mentor se connecte pour accepter, discuter et
planifier serait donc construit pour un cote qui ne peut pas se connecter.
Le modele retenu ne suppose pas de compte cote mentor : la relation est
identifiee par la paire (mentor, eleve), les actions du mentor passent par un
lien signe envoye par email, et le canal des seances est celui qui existe
reellement au Togo — WhatsApp, telephone, presentiel — plutot que la visio.

Ce que fait la migration
------------------------
1. complete `mentor_relationships` : objectif de l'eleve, horodatage de la
   decision, motif de refus, canal souhaite ;
2. cree `mentor_sessions` : une seance proposee, confirmee, tenue ou annulee ;
3. pose les index de lecture (relations d'un eleve, seances d'une relation).

Rien n'est detruit et tout est garde par IF NOT EXISTS : la base de production
vient d'un schema.sql que les migrations ne declarent pas, son etat exact ne
se suppose pas.

Revision ID: 030
Revises: 029
Create Date: 2026-08-31
"""
from alembic import op

revision = '030'
down_revision = '029'
branch_labels = None
depends_on = None


# Canaux de seance. La visio n'est pas le defaut : la bande passante au Togo
# rend WhatsApp et le telephone plus fiables, et c'est deja la ou se font les
# echanges.
CHANNELS = ("whatsapp", "telephone", "presentiel", "visio")


def upgrade() -> None:
    channels = ", ".join(f"'{c}'" for c in CHANNELS)

    # --- 1. Relations mentor / eleve -----------------------------------------
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentor_relationships (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            mentor_id UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
            mentee_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            status TEXT NOT NULL DEFAULT 'pending',
            message TEXT,
            started_at TIMESTAMPTZ,
            ended_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(mentor_id, mentee_id)
        );
    """)
    op.execute(f"""
        ALTER TABLE mentor_relationships
            ADD COLUMN IF NOT EXISTS goal TEXT,
            ADD COLUMN IF NOT EXISTS preferred_channel TEXT,
            ADD COLUMN IF NOT EXISTS decided_at TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS decline_reason TEXT,
            ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    """)
    op.execute(f"""
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'mentor_relationships_preferred_channel_check'
    ) THEN
        ALTER TABLE mentor_relationships
            ADD CONSTRAINT mentor_relationships_preferred_channel_check
            CHECK (preferred_channel IS NULL OR preferred_channel IN ({channels}));
    END IF;
END $$;
""")

    # --- 2. Seances -----------------------------------------------------------
    op.execute(f"""
        CREATE TABLE IF NOT EXISTS mentor_sessions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            relationship_id UUID NOT NULL
                REFERENCES mentor_relationships(id) ON DELETE CASCADE,
            scheduled_at TIMESTAMPTZ NOT NULL,
            duration_min INTEGER NOT NULL DEFAULT 45,
            channel TEXT NOT NULL CHECK (channel IN ({channels})),
            status TEXT NOT NULL DEFAULT 'proposed'
                CHECK (status IN ('proposed', 'confirmed', 'done', 'cancelled')),
            proposed_by TEXT NOT NULL DEFAULT 'mentee'
                CHECK (proposed_by IN ('mentee', 'mentor')),
            topic TEXT,
            notes TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    """)

    # --- 3. Index de lecture --------------------------------------------------
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_relationships_mentee
            ON mentor_relationships(mentee_id, status);
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_relationships_mentor
            ON mentor_relationships(mentor_id, status);
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_sessions_relationship
            ON mentor_sessions(relationship_id, scheduled_at DESC);
    """)

    # --- 4. RLS ---------------------------------------------------------------
    # Le backend interroge ces tables avec service_role, qui contourne RLS, et
    # ne transmet jamais le JWT de l'eleve a Supabase : `auth.uid()` y est
    # toujours NULL, donc une politique par utilisateur ne filtrerait rien.
    # RLS actif SANS politique = personne d'autre ne lit. C'est la bonne
    # configuration pour des donnees personnelles.
    op.execute("ALTER TABLE mentor_relationships ENABLE ROW LEVEL SECURITY;")
    op.execute("ALTER TABLE mentor_sessions ENABLE ROW LEVEL SECURITY;")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS mentor_sessions;")
    # mentor_relationships preexistait au schema.sql : on retire seulement ce
    # que cette migration a ajoute, sans supprimer la table ni les demandes.
    op.execute("""
        ALTER TABLE mentor_relationships
            DROP CONSTRAINT IF EXISTS mentor_relationships_preferred_channel_check,
            DROP COLUMN IF EXISTS goal,
            DROP COLUMN IF EXISTS preferred_channel,
            DROP COLUMN IF EXISTS decided_at,
            DROP COLUMN IF EXISTS decline_reason;
    """)
