"""Organizations and beneficiaries system

Revision ID: 008
Revises: 007
Create Date: 2025-05-08 00:00:00.000000

"""

from typing import Sequence, Union
from alembic import op

revision: str = "008"
down_revision: Union[str, None] = "007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("""
        DO $$
        BEGIN
            ALTER TABLE user_profiles 
                DROP CONSTRAINT IF EXISTS user_profiles_role_check;
        EXCEPTION WHEN others THEN
            NULL;
        END $$;
        
        ALTER TABLE user_profiles
            ADD CONSTRAINT user_profiles_role_check
            CHECK (role IN ('student', 'admin', 'super_admin', 'partner', 'partner_admin'))
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS partner_organizations (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'cdej' CHECK (type IN ('cdej', 'ong', 'school', 'other')),
            partner_code TEXT UNIQUE,
            description TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            contact_person TEXT,
            address TEXT,
            city TEXT,
            country TEXT DEFAULT 'TOGO',
            is_active BOOLEAN DEFAULT TRUE,
            is_approved BOOLEAN DEFAULT FALSE,
            approved_by UUID REFERENCES user_profiles(id),
            approved_at TIMESTAMPTZ,
            created_by UUID REFERENCES user_profiles(id),
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_partner_organizations_code ON partner_organizations(partner_code)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_partner_organizations_type ON partner_organizations(type)")

    op.execute("""
        ALTER TABLE user_profiles 
        ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES partner_organizations(id)
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_org ON user_profiles(organization_id)")

    op.execute("""
        CREATE TABLE IF NOT EXISTS beneficiary_dossiers (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            organization_id UUID NOT NULL REFERENCES partner_organizations(id) ON DELETE CASCADE,
            dossier_number TEXT UNIQUE,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            date_of_birth DATE,
            gender TEXT CHECK (gender IN ('male', 'female', 'other')),
            place_of_birth TEXT,
            father_name TEXT,
            mother_name TEXT,
            guardian_name TEXT,
            guardian_phone TEXT,
            guardian_relationship TEXT,
            address TEXT,
            city TEXT,
            country TEXT DEFAULT 'TOGO',
            photo_url TEXT,
            notes TEXT,
            status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'transferred', 'completed')),
            referred_at TIMESTAMPTZ DEFAULT NOW(),
            referred_by UUID REFERENCES user_profiles(id),
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_beneficiary_dossiers_org ON beneficiary_dossiers(organization_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_beneficiary_dossiers_number ON beneficiary_dossiers(dossier_number)")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS beneficiary_dossiers CASCADE")
    op.execute("ALTER TABLE user_profiles DROP COLUMN IF EXISTS organization_id")
    op.execute("DROP TABLE IF EXISTS partner_organizations CASCADE")
    op.execute("""
        DO $$
        BEGIN
            ALTER TABLE user_profiles 
                DROP CONSTRAINT IF EXISTS user_profiles_role_check;
        EXCEPTION WHEN others THEN NULL;
        END $$;
        
        ALTER TABLE user_profiles
            ADD CONSTRAINT user_profiles_role_check
            CHECK (role IN ('student', 'admin', 'super_admin'))
    """)