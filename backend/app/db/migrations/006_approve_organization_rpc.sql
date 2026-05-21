-- Migration 006: RPC function for atomic organization approval
-- Ensures org approval + creator promotion happen in one transaction

CREATE OR REPLACE FUNCTION approve_organization(
    p_org_id UUID,
    p_approved_by UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org RECORD;
    v_creator_id UUID;
    v_result JSONB;
BEGIN
    -- Lock the org row
    SELECT * INTO v_org
    FROM partner_organizations
    WHERE id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organization not found: %', p_org_id
            USING HINT = 'check_org_id';
    END IF;

    -- Update org status
    UPDATE partner_organizations
    SET
        is_approved = TRUE,
        approved_by = p_approved_by::TEXT,
        approved_at = NOW()
    WHERE id = p_org_id;

    -- Promote creator if not already admin/super_admin
    IF v_org.created_by IS NOT NULL THEN
        UPDATE user_profiles
        SET
            role = 'partner_admin',
            organization_id = p_org_id::TEXT
        WHERE id = v_org.created_by::TEXT
          AND role NOT IN ('admin', 'super_admin');
    END IF;

    -- Return updated org
    SELECT jsonb_agg(to_jsonb(t.*)) INTO v_result
    FROM (SELECT * FROM partner_organizations WHERE id = p_org_id) t;

    RETURN v_result -> 0;
END;
$$;
