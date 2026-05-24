"""Row Level Security pour partner_organizations et beneficiary_dossiers.

Revision ID: 010
Revises: 009
Create Date: 2026-05-20
"""
from alembic import op

revision = '010'
down_revision = '009'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Activer RLS sur les tables partner
    op.execute("ALTER TABLE partner_organizations ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE beneficiary_dossiers ENABLE ROW LEVEL SECURITY")

    # Organisations : lecture uniquement des organisations approuvées via clé anon
    op.execute("""
        CREATE POLICY "public_read_approved_orgs"
        ON partner_organizations FOR SELECT
        USING (is_approved = TRUE AND is_active = TRUE)
    """)

    # Organisations : écriture réservée au service_role (bypass auto)
    op.execute("""
        CREATE POLICY "service_role_full_access_orgs"
        ON partner_organizations FOR ALL
        USING (auth.role() = 'service_role')
        WITH CHECK (auth.role() = 'service_role')
    """)

    # Bénéficiaires : aucun accès direct via clé anon
    op.execute("""
        CREATE POLICY "service_role_full_access_beneficiaries"
        ON beneficiary_dossiers FOR ALL
        USING (auth.role() = 'service_role')
        WITH CHECK (auth.role() = 'service_role')
    """)


def downgrade() -> None:
    op.execute("DROP POLICY IF EXISTS public_read_approved_orgs ON partner_organizations")
    op.execute("DROP POLICY IF EXISTS service_role_full_access_orgs ON partner_organizations")
    op.execute("DROP POLICY IF EXISTS service_role_full_access_beneficiaries ON beneficiary_dossiers")
    op.execute("ALTER TABLE partner_organizations DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE beneficiary_dossiers DISABLE ROW LEVEL SECURITY")
