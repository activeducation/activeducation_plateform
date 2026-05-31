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
    # Avec un mot de passe choisi :
    ADMIN_EMAIL=admin@activeducation.com ADMIN_PASSWORD='VotreMotDePasse!' \
        python -m scripts.create_super_admin

    # Ou sans ADMIN_PASSWORD : un mot de passe fort est genere et affiche.
    python -m scripts.create_super_admin

Credentials (configurables via variables d'environnement) :
    ADMIN_EMAIL      (defaut: admin@activeducation.com)
    ADMIN_PASSWORD   (si absent : genere aleatoirement, affiche une fois)
    ADMIN_FIRST_NAME (defaut: Super)
    ADMIN_LAST_NAME  (defaut: Admin)
"""

import sys
import os
import secrets
import string

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings


def _generate_password(length: int = 16) -> str:
    """Genere un mot de passe fort : maj + min + chiffre + symbole garantis."""
    symbols = "!@#$%^&*-_"
    alphabet = string.ascii_letters + string.digits + symbols
    while True:
        pwd = "".join(secrets.choice(alphabet) for _ in range(length))
        if (
            any(c.islower() for c in pwd)
            and any(c.isupper() for c in pwd)
            and any(c.isdigit() for c in pwd)
            and any(c in symbols for c in pwd)
        ):
            return pwd


# ─── Credentials du super admin (lus depuis l'environnement) ──────────────────
# Aucun secret en dur dans le code source. Le mot de passe vient de la variable
# ADMIN_PASSWORD ; s'il est absent, on en genere un fort et on l'affiche une fois.
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@activeducation.com")
ADMIN_FIRST_NAME = os.environ.get("ADMIN_FIRST_NAME", "Super")
ADMIN_LAST_NAME = os.environ.get("ADMIN_LAST_NAME", "Admin")

_env_password = os.environ.get("ADMIN_PASSWORD")
PASSWORD_WAS_GENERATED = _env_password is None
ADMIN_PASSWORD = _env_password or _generate_password()
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
    if PASSWORD_WAS_GENERATED:
        print("\n  /!\\  MOT DE PASSE GENERE ALEATOIREMENT — copiez-le MAINTENANT.")
        print("       Il ne sera PAS reaffiche. Conservez-le dans un gestionnaire")
        print("       de mots de passe.")
    print("\n  → Vous pouvez maintenant vous connecter sur le dashboard.\n")


if __name__ == "__main__":
    print("=" * 55)
    print("  ActivEducation — Creation du Super Admin")
    print("=" * 55 + "\n")
    create_super_admin()
