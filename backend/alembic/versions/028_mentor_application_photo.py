"""Photo de profil dans la candidature mentor.

Les candidats peuvent joindre une photo depuis l'application. L'URL renvoyee
par POST /mentors/apply/photo est stockee ici, puis recopiee dans
`mentors.avatar_url` lors de l'approbation.

`ADD COLUMN IF NOT EXISTS` par principe : la base de production vient d'un
schema.sql historique et ne correspond pas toujours a ce que declarent les
migrations. On ne suppose donc jamais l'etat d'une table.

Revision ID: 028
Revises: 027
Create Date: 2026-08-21
"""
from alembic import op

revision = '028'
down_revision = '027'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE mentor_applications
            ADD COLUMN IF NOT EXISTS photo_url TEXT;
    """)

    # `avatar_url` existe deja sur mentors (verifie sur le schema de
    # production), mais la garde ne coute rien et protege une base reconstruite
    # uniquement depuis les migrations, ou la colonne n'est declaree nulle part.
    op.execute("""
        ALTER TABLE mentors
            ADD COLUMN IF NOT EXISTS avatar_url TEXT;
    """)


def downgrade() -> None:
    # Pas de suppression : retirer la colonne detruirait les photos deja
    # jointes aux candidatures.
    pass
