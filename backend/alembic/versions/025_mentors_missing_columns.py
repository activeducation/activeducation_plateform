"""Colonnes manquantes sur mentors : l'approbation d'une candidature echouait.

Le probleme
-----------
approve_application() cree un mentor a partir de la candidature et ecrit,
entre autres, `expertise_areas` et `is_verified`. Or aucune migration n'ajoute
ces deux colonnes a la table `mentors` :

  - 012 ajoute full_name, bio, avatar_url, years_experience, available_slots,
    location, linkedin_url, specialty, hourly_rate ;
  - 015 ajoute is_active, email, phone, source.

create_mentor() inserant le dictionnaire brut, toute cle sans colonne
correspondante fait echouer la requete. Le back-office affichait alors
"Action impossible" sans plus de detail.

A noter : la table `mentors` n'est CREEE par aucune migration, seulement
alteree. Elle provient d'un schema.sql historique non suivi par Alembic — la
migration 007 le documente deja pour `schools.is_verified`. C'est la source des
divergences repetees entre la production et les migrations, d'ou l'usage
systematique de ADD COLUMN IF NOT EXISTS.

`expertise_areas` est declaree TEXT[] pour correspondre au type de la colonne
homonyme de `mentor_applications`, d'ou la valeur est recopiee.

Revision ID: 025
Revises: 024
Create Date: 2026-08-21
"""
from alembic import op

revision = '025'
down_revision = '024'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE mentors
            ADD COLUMN IF NOT EXISTS expertise_areas TEXT[],
            ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT FALSE;
    """)

    # Ecrite par approve_application pour tracer le mentor cree ; declaree par
    # la migration 015 mais absente si la table preexistait au suivi Alembic.
    op.execute("""
        ALTER TABLE mentor_applications
            ADD COLUMN IF NOT EXISTS created_mentor_id UUID,
            ADD COLUMN IF NOT EXISTS review_note TEXT,
            ADD COLUMN IF NOT EXISTS reviewed_by UUID,
            ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
    """)


def downgrade() -> None:
    # Pas de suppression : retirer ces colonnes detruirait les donnees des
    # mentors deja approuves.
    pass
