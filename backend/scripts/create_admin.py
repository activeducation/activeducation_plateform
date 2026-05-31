"""
Script LEGACY pour creer le premier super_admin (auth JWT maison).

ATTENTION : ce script utilise l'ancienne auth (hash_password). Depuis la
migration vers Supabase Auth natif, utilisez plutot scripts/create_super_admin.py.

IMPORTANT: Avant de lancer ce script, executez la migration 003_admin_tables.sql
dans le Supabase Dashboard > SQL Editor pour ajouter les colonnes role, is_active, etc.

Usage:
    cd backend
    ADMIN_PASSWORD='VotreMotDePasse!' python -m scripts.create_admin
    # Sans ADMIN_PASSWORD : un mot de passe fort est genere et affiche.

Credentials (configurables via variables d'environnement) :
    ADMIN_EMAIL    (defaut: admin@activeducation.com)
    ADMIN_PASSWORD (si absent : genere aleatoirement, affiche une fois)
"""

import sys
import os
import secrets
import string

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.security import hash_password
from app.db.supabase_client import get_supabase_client


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


# Aucun secret en dur : lus depuis l'environnement, mot de passe genere si absent.
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@activeducation.com")
ADMIN_FIRST_NAME = os.environ.get("ADMIN_FIRST_NAME", "Super")
ADMIN_LAST_NAME = os.environ.get("ADMIN_LAST_NAME", "Admin")

_env_password = os.environ.get("ADMIN_PASSWORD")
PASSWORD_WAS_GENERATED = _env_password is None
ADMIN_PASSWORD = _env_password or _generate_password()


def create_super_admin():
    db = get_supabase_client()

    # Verifier si l'admin existe deja
    existing = db.fetch_all(
        table="user_profiles",
        filters={"email": ADMIN_EMAIL},
        limit=1,
    )

    if existing:
        user = existing[0]
        print(f"L'admin {ADMIN_EMAIL} existe deja (id: {user['id']}).")
        # Mettre a jour le role en super_admin
        try:
            db.update(
                table="user_profiles",
                id_column="id",
                id_value=user["id"],
                data={"role": "super_admin", "is_active": True},
            )
            print("Role mis a jour en super_admin.")
        except Exception as e:
            print(f"Impossible de mettre a jour le role: {e}")
            print("Assurez-vous d'avoir execute la migration 003_admin_tables.sql")
        return

    import uuid
    from datetime import datetime, timezone

    password_hash = hash_password(ADMIN_PASSWORD)
    user_id = str(uuid.uuid4())

    # D'abord inserer sans les colonnes admin (au cas ou la migration n'est pas faite)
    base_data = {
        "id": user_id,
        "email": ADMIN_EMAIL,
        "password_hash": password_hash,
        "first_name": ADMIN_FIRST_NAME,
        "last_name": ADMIN_LAST_NAME,
        "display_name": f"{ADMIN_FIRST_NAME} {ADMIN_LAST_NAME}",
        "preferred_language": "fr",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    # Tenter avec les colonnes admin
    full_data = {
        **base_data,
        "role": "super_admin",
        "is_active": True,
    }

    try:
        db.insert(table="user_profiles", data=full_data)
        print(f"Super admin cree avec succes!")
    except Exception:
        # Si les colonnes admin n'existent pas, inserer sans
        print("Colonnes admin non trouvees, insertion de base...")
        try:
            db.insert(table="user_profiles", data=base_data)
            print(f"Utilisateur cree. Executez la migration 003 puis relancez ce script pour definir le role.")
        except Exception as e2:
            print(f"Erreur lors de la creation: {e2}")
            return

    print(f"\n  Email:    {ADMIN_EMAIL}")
    print(f"  Password: {ADMIN_PASSWORD}")
    print(f"  ID:       {user_id}")


def run_migration_check():
    """Verifie si les colonnes admin existent."""
    db = get_supabase_client()
    try:
        # Tente de lire avec la colonne role
        result = db.client.table("user_profiles").select("role").limit(1).execute()
        return True
    except Exception:
        return False


if __name__ == "__main__":
    print("=== Creation du Super Admin ActivEducation ===\n")

    has_admin_cols = run_migration_check()
    if not has_admin_cols:
        print("ATTENTION: Les colonnes admin (role, is_active) n'existent pas.")
        print("Executez d'abord la migration dans Supabase Dashboard > SQL Editor:")
        print("  fichier: backend/app/db/migrations/003_admin_tables.sql\n")
        print("Tentative de creation sans colonnes admin...\n")

    create_super_admin()
