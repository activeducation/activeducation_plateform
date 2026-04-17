"""
Script pour creer le super_admin via l'API Admin de Supabase Auth.

Ce script cree le compte dans DEUX endroits :
  1. auth.users  -> via supabase.auth.admin.create_user()  (necessaire pour login)
  2. user_profiles -> table custom (necessaire pour le role super_admin)

PREREQUIS:
  - La variable SUPABASE_SERVICE_ROLE_KEY doit etre dans le fichier .env
    (Dashboard Supabase > Settings > API > service_role key)
  - La migration 003_admin_tables.sql doit avoir ete executee

Usage:
    cd backend
    python -m scripts.create_super_admin

Credentials:
    Email:    admin@activeducation.com
    Password: Admin@2024!
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

# ─── Credentials du super admin ───────────────────────────────────────────────
ADMIN_EMAIL = "admin@activeducation.com"
ADMIN_PASSWORD = "Admin@2024!"
ADMIN_FIRST_NAME = "Super"
ADMIN_LAST_NAME = "Admin"
# ──────────────────────────────────────────────────────────────────────────────


def get_admin_client():
    """
    Retourne un client Supabase avec la service_role key (pouvoirs admin).
    Necessite SUPABASE_SERVICE_ROLE_KEY dans le .env
    """
    from supabase import create_client

    service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY
    if not service_role_key:
        print("\n[ERREUR] SUPABASE_SERVICE_ROLE_KEY manquante dans le .env !")
        print("  → Recuperer depuis : Supabase Dashboard > Settings > API > service_role")
        sys.exit(1)

    return create_client(settings.SUPABASE_URL, service_role_key)


def create_super_admin():
    client = get_admin_client()

    print(f"[1/3] Verification si le compte existe dans Supabase Auth...")

    # ── Etape 1 : Verifier / creer dans auth.users ────────────────────────────
    auth_user_id = None

    try:
        # Lister les utilisateurs et chercher par email
        users_response = client.auth.admin.list_users()
        existing_auth_user = next(
            (u for u in users_response if u.email == ADMIN_EMAIL),
            None,
        )

        if existing_auth_user:
            auth_user_id = existing_auth_user.id
            print(f"   ✓ Compte Auth existant : {auth_user_id}")

            # Mettre a jour le mot de passe au cas ou
            client.auth.admin.update_user_by_id(
                auth_user_id,
                {"password": ADMIN_PASSWORD, "email_confirm": True},
            )
            print("   ✓ Mot de passe re-synchronise dans Supabase Auth")
        else:
            print(f"[2/3] Creation du compte dans Supabase Auth...")
            response = client.auth.admin.create_user(
                {
                    "email": ADMIN_EMAIL,
                    "password": ADMIN_PASSWORD,
                    "email_confirm": True,  # Pas besoin de verification email
                    "user_metadata": {
                        "first_name": ADMIN_FIRST_NAME,
                        "last_name": ADMIN_LAST_NAME,
                    },
                }
            )
            auth_user_id = response.user.id
            print(f"   ✓ Compte Auth cree : {auth_user_id}")

    except Exception as e:
        print(f"\n[ERREUR] Impossible d'acceder a Supabase Auth Admin : {e}")
        print("  → Verifiez que SUPABASE_SERVICE_ROLE_KEY est correct")
        sys.exit(1)

    # ── Etape 2 : Synchroniser user_profiles ──────────────────────────────────
    print(f"[3/3] Synchronisation dans user_profiles...")

    try:
        existing_profile = (
            client.table("user_profiles")
            .select("id, role")
            .eq("id", auth_user_id)
            .execute()
        )

        profile_data = {
            "id": auth_user_id,
            "email": ADMIN_EMAIL,
            "first_name": ADMIN_FIRST_NAME,
            "last_name": ADMIN_LAST_NAME,
            "display_name": f"{ADMIN_FIRST_NAME} {ADMIN_LAST_NAME}",
            "role": "super_admin",
            "is_active": True,
            "preferred_language": "fr",
        }

        if existing_profile.data:
            # Mettre a jour le role
            client.table("user_profiles").update(
                {"role": "super_admin", "is_active": True}
            ).eq("id", auth_user_id).execute()
            print("   ✓ Profil existant mis a jour (role=super_admin)")
        else:
            # Inserer le profil
            client.table("user_profiles").insert(profile_data).execute()
            print("   ✓ Profil cree dans user_profiles")

    except Exception as e:
        print(f"\n[ERREUR] Impossible de synchroniser user_profiles : {e}")
        print("  → Verifiez que la migration 003_admin_tables.sql a ete executee")
        sys.exit(1)

    # ── Resume ────────────────────────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  Super Admin cree avec succes !")
    print("=" * 55)
    print(f"  Email    : {ADMIN_EMAIL}")
    print(f"  Password : {ADMIN_PASSWORD}")
    print(f"  UUID     : {auth_user_id}")
    print(f"  Role     : super_admin")
    print("=" * 55)
    print("\n  → Vous pouvez maintenant vous connecter sur le dashboard.\n")


if __name__ == "__main__":
    print("=" * 55)
    print("  ActivEducation — Creation du Super Admin")
    print("=" * 55 + "\n")
    create_super_admin()
