"""
Configuration d'environnement Alembic pour ActivEducation.

Supporte:
- Migrations online (connexion directe a la DB)
- Migrations offline (generation de SQL sans connexion)
- Autogenerate depuis les modeles SQLAlchemy (si utilises)
"""

import os
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Charger le fichier .ini de configuration
config = context.config

# Configurer le logging depuis le fichier .ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# =============================================================================
# CONFIGURATION DE L'URL DE BASE DE DONNEES
# =============================================================================

def get_database_url() -> str:
    """
    Construit l'URL de connexion PostgreSQL Supabase.

    Priorite:
    1. Variable d'environnement DATABASE_URL (si definie directement)
    2. Variables SUPABASE_DB_* individuelles
    3. URL dans alembic.ini
    """
    # URL directe (la plus simple)
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return database_url

    # Construction depuis les variables individuelles
    host = os.getenv("SUPABASE_DB_HOST")
    password = os.getenv("SUPABASE_DB_PASSWORD")
    port = os.getenv("SUPABASE_DB_PORT", "5432")
    user = os.getenv("SUPABASE_DB_USER", "postgres")
    db = os.getenv("SUPABASE_DB_NAME", "postgres")

    if host and password:
        return f"postgresql://{user}:{password}@{host}:{port}/{db}"

    # Fallback vers l'URL dans alembic.ini
    return config.get_main_option("sqlalchemy.url")


# Injecter l'URL dans la config Alembic
url = get_database_url()
if url:
    config.set_main_option("sqlalchemy.url", url)

# Metadata (si vous utilisez SQLAlchemy ORM pour l'autogenerate)
# Pour ActivEducation, on utilise des migrations manuelles SQL
# donc target_metadata = None
target_metadata = None


# =============================================================================
# FONCTIONS DE MIGRATION
# =============================================================================


def run_migrations_offline() -> None:
    """
    Mode offline: genere le SQL sans connexion a la DB.

    Utile pour:
    - Revue avant application
    - Environnements sans acces direct a la DB
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """
    Mode online: connexion directe a la DB et application des migrations.
    """
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


# Choisir le mode selon le contexte
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
