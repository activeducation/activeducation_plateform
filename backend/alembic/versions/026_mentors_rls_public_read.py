"""Lecture publique des mentors : RLS actif mais aucune politique.

Le probleme
-----------
Interrogation de la base de production :

    SELECT relrowsecurity FROM pg_class WHERE relname = 'mentors';  -> true
    SELECT * FROM pg_policies WHERE tablename = 'mentors';          -> 0 ligne

RLS active SANS aucune politique signifie que plus personne ne peut lire la
table, hormis les roles qui contournent RLS (`service_role`). D'ou l'asymetrie
observee : le back-office affichait bien les mentors (clef service_role) tandis
que l'application renvoyait une liste vide (clef anon), alors meme que les
lignes existaient avec is_active et is_verified a true.

La table `mentors` vient du schema.sql historique non suivi par Alembic : ni
elle ni son RLS ne sont declares par les migrations, ce qui explique que ce
trou soit passe inapercu.

Deux protections, distinctes
----------------------------
1. Politique de LIGNES : seuls les mentors actifs ET verifies sont lisibles
   publiquement, comme le fait deja la migration 007 pour `schools`.

2. Privileges de COLONNES : la table contient `email` et `phone`, donnees
   personnelles que les endpoints publics ne lisent jamais. Or la clef anon est
   embarquee dans l'application : sans restriction, n'importe qui pourrait
   interroger PostgREST directement et recuperer les coordonnees des mentors.
   Les roles anon et authenticated ne recoivent donc SELECT que sur les
   colonnes reellement servies par l'API publique (liste, detail, filtres et
   tri compris). `service_role` n'est pas touche.

Revision ID: 026
Revises: 025
Create Date: 2026-08-21
"""
from alembic import op

revision = '026'
down_revision = '025'
branch_labels = None
depends_on = None

# Colonnes servies par les endpoints publics (app/api/v1/endpoints/mentors.py),
# y compris celles utilisees pour filtrer (is_active, is_verified, specialty)
# et trier (rating_avg) : PostgreSQL exige le privilege SELECT sur toute
# colonne referencee, pas seulement sur celles retournees.
PUBLIC_COLUMNS = (
    "id", "full_name", "specialty", "bio", "avatar_url", "years_experience",
    "is_verified", "is_active", "hourly_rate", "available_slots", "rating_avg",
    "location", "linkedin_url",
)


def upgrade() -> None:
    op.execute("ALTER TABLE mentors ENABLE ROW LEVEL SECURITY")

    op.execute("DROP POLICY IF EXISTS mentors_public_read ON mentors")
    op.execute("""
        CREATE POLICY mentors_public_read ON mentors
            FOR SELECT
            TO anon, authenticated
            USING (is_active IS TRUE AND is_verified IS TRUE);
    """)

    columns = ", ".join(PUBLIC_COLUMNS)
    op.execute("REVOKE SELECT ON TABLE mentors FROM anon, authenticated")
    op.execute(f"GRANT SELECT ({columns}) ON TABLE mentors TO anon, authenticated")


def downgrade() -> None:
    op.execute("DROP POLICY IF EXISTS mentors_public_read ON mentors")
    # On ne restaure PAS un SELECT complet pour anon : ce serait exposer
    # email et phone, ce que la situation d'origine ne faisait pas non plus
    # (aucune politique = aucune lecture).
