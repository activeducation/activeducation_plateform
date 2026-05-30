"""RPC SECURITY DEFINER pour approbation atomique d'organisation partenaire.

Garantit que l'approbation de l'org + promotion du créateur en partner_admin
arrivent dans la même transaction (impossible avec 2 requêtes supabase-py).

Revision ID: 013
Revises: 012
Create Date: 2026-05-21
"""
from alembic import op

revision = '013'
down_revision = '012'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE OR REPLACE FUNCTION approve_partner_organization(
            p_org_id UUID,
            p_approved_by UUID
        )
        RETURNS JSONB
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $$
        DECLARE
            v_org      RECORD;
            v_result   JSONB;
        BEGIN
            -- Lock the org row
            SELECT * INTO v_org
            FROM partner_organizations
            WHERE id = p_org_id
            FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Organization not found: %', p_org_id
                    USING ERRCODE = 'P0002';
            END IF;

            -- Vérifie idempotence
            IF v_org.is_approved THEN
                SELECT to_jsonb(t.*) INTO v_result
                FROM (SELECT * FROM partner_organizations WHERE id = p_org_id) t;
                RETURN v_result;
            END IF;

            -- Approuve l'org
            UPDATE partner_organizations
            SET
                is_approved = TRUE,
                approved_by = p_approved_by::TEXT,
                approved_at = NOW(),
                updated_at  = NOW()
            WHERE id = p_org_id;

            -- Promouvoit le créateur (sauf si déjà admin/super_admin)
            IF v_org.created_by IS NOT NULL THEN
                UPDATE user_profiles
                SET
                    role            = 'partner_admin',
                    organization_id = p_org_id::TEXT,
                    updated_at      = NOW()
                WHERE id = v_org.created_by::TEXT
                  AND role NOT IN ('admin', 'super_admin');
            END IF;

            -- Retourne l'org mise à jour
            SELECT to_jsonb(t.*) INTO v_result
            FROM (SELECT * FROM partner_organizations WHERE id = p_org_id) t;

            RETURN v_result;
        END;
        $$;
    """)

    # Restreindre l'accès : uniquement service_role peut appeler le RPC
    op.execute("""
        REVOKE ALL ON FUNCTION approve_partner_organization(UUID, UUID) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION approve_partner_organization(UUID, UUID) TO service_role;
    """)


def downgrade() -> None:
    op.execute("DROP FUNCTION IF EXISTS approve_partner_organization(UUID, UUID);")
