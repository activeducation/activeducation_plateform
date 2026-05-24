"""
Cree un utilisateur de test confirme (sans verification email) pour
faciliter les tests manuels de l'app.

Utilise le client Supabase Admin (service role) pour:
  1) Creer le compte dans auth.users avec email_confirm=True
  2) Inserer le profil correspondant dans user_profiles

Usage:
    cd backend
    python -m scripts.create_test_user

    # ou avec des credentials custom:
    python -m scripts.create_test_user --email demo@activedu.com --password Demo1234!

Credentials par defaut:
    Email:    test@activeducation.com
    Password: Test1234!

Re-execution: si l'utilisateur existe deja (cote auth ou profile), le script
le detecte et affiche les credentials sans planter.
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.supabase_client import get_admin_supabase_client  # noqa: E402


DEFAULT_EMAIL = "test@activeducation.com"
DEFAULT_PASSWORD = "Test1234!"
DEFAULT_FIRST_NAME = "Test"
DEFAULT_LAST_NAME = "User"


def _find_auth_user_by_email(admin_client, email: str):
    """Cherche un user existant dans auth.users via l'API admin."""
    try:
        page = admin_client.auth.admin.list_users()
        users = page if isinstance(page, list) else getattr(page, "users", []) or []
        for u in users:
            u_email = getattr(u, "email", None) or (u.get("email") if isinstance(u, dict) else None)
            if u_email and u_email.lower() == email.lower():
                return u
    except Exception as e:
        print(f"  ! list_users a echoue: {e}")
    return None


def create_test_user(
    email: str,
    password: str,
    first_name: str,
    last_name: str,
) -> None:
    db = get_admin_supabase_client()
    admin_client = db.client

    print(f"=== Creation utilisateur de test ===")
    print(f"  Email:    {email}")
    print(f"  Password: {password}")
    print()

    # 1) Auth user
    existing_auth = _find_auth_user_by_email(admin_client, email)
    if existing_auth is not None:
        user_id = getattr(existing_auth, "id", None) or existing_auth.get("id")
        print(f"-> Compte auth existant detecte (id={user_id}).")
    else:
        print("-> Creation du compte auth via admin API...")
        response = admin_client.auth.admin.create_user({
            "email": email.lower(),
            "password": password,
            "email_confirm": True,
            "user_metadata": {
                "first_name": first_name,
                "last_name": last_name,
            },
        })
        user = getattr(response, "user", None) or response
        user_id = getattr(user, "id", None) or user.get("id")
        print(f"   Compte auth cree (id={user_id}).")

    # 2) user_profiles row
    existing_profile = admin_client.table("user_profiles").select("id").eq(
        "id", str(user_id)
    ).limit(1).execute()

    if existing_profile.data:
        print("-> Profil existant detecte, OK.")
    else:
        print("-> Insertion du profil...")
        profile = {
            "id": str(user_id),
            "email": email.lower(),
            "first_name": first_name,
            "last_name": last_name,
            "display_name": f"{first_name} {last_name}".strip(),
            "preferred_language": "fr",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        admin_client.table("user_profiles").insert(profile).execute()
        print("   Profil insere.")

    print()
    print("=== Pret a tester ===")
    print(f"  Email:    {email}")
    print(f"  Password: {password}")
    print(f"  User ID:  {user_id}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Cree un user de test confirme.")
    parser.add_argument("--email", default=DEFAULT_EMAIL)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    parser.add_argument("--first-name", default=DEFAULT_FIRST_NAME)
    parser.add_argument("--last-name", default=DEFAULT_LAST_NAME)
    args = parser.parse_args()

    create_test_user(
        email=args.email,
        password=args.password,
        first_name=args.first_name,
        last_name=args.last_name,
    )
