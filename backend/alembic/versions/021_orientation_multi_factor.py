"""Moteur d'orientation multi-criteres : profil eleve + donnees cout/matieres.

Complete les tests d'orientation existants (RIASEC/MBTI) par des criteres
concrets :
- student_orientation_profile : notes, matieres preferees, centres d'interet,
  budget annuel, projet professionnel.
- school_programs.tuition_annual_fcfa / is_public : rend le critere budget
  exploitable (aucune donnee de cout n'existait).
- careers.key_subjects : matieres scolaires cles d'un metier, pour exploiter
  les notes de l'eleve.

SECURITE : RLS verrouillee sur le profil eleve (donnees personnelles), acces
via service_role avec filtrage user_id applicatif.

Revision ID: 021
Revises: 020
Create Date: 2026-07-13
"""
from alembic import op

revision = '021'
down_revision = '020'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Profil d'orientation de l'eleve (1 par utilisateur).
    op.execute("""
        CREATE TABLE IF NOT EXISTS student_orientation_profile (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL UNIQUE
                    REFERENCES user_profiles(id) ON DELETE CASCADE,
            grades              JSONB NOT NULL DEFAULT '{}',
                                -- {"Mathematiques": 14.5, "Physique": 12} sur 20
            favorite_subjects   TEXT[] NOT NULL DEFAULT '{}',
            interests           TEXT[] NOT NULL DEFAULT '{}',
            budget_annual_fcfa  INTEGER,      -- budget max annuel pour les etudes
            career_project      TEXT,          -- projet professionnel (texte libre)
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("ALTER TABLE student_orientation_profile ENABLE ROW LEVEL SECURITY;")

    # 2. Cout des formations : rend le critere budget exploitable.
    op.execute("""
        ALTER TABLE school_programs
            ADD COLUMN IF NOT EXISTS tuition_annual_fcfa INTEGER;
    """)
    op.execute("""
        ALTER TABLE school_programs
            ADD COLUMN IF NOT EXISTS is_public BOOLEAN;
    """)

    # 3. Matieres cles par metier : relie les notes de l'eleve aux carrieres.
    op.execute("""
        ALTER TABLE careers
            ADD COLUMN IF NOT EXISTS key_subjects TEXT[] NOT NULL DEFAULT '{}';
    """)


def downgrade() -> None:
    op.execute("ALTER TABLE careers DROP COLUMN IF EXISTS key_subjects;")
    op.execute("ALTER TABLE school_programs DROP COLUMN IF EXISTS is_public;")
    op.execute("ALTER TABLE school_programs DROP COLUMN IF EXISTS tuition_annual_fcfa;")
    op.execute("DROP TABLE IF EXISTS student_orientation_profile CASCADE;")
