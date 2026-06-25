"""Alembic environment configuration."""

import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool
from alembic import context

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = None


def _normalize_driver(url: str) -> str:
    """Choisit le driver PostgreSQL disponible.

    En prod, psycopg2-binary est installe -> on garde `postgresql://`.
    En local (ex: Python 3.14 sans wheel psycopg2), on bascule sur psycopg v3
    via `postgresql+psycopg://` si psycopg2 est absent mais psycopg present.
    N'altere pas une URL qui specifie deja un driver (`postgresql+xxx://`).
    """
    if "+psycopg" in url or "+asyncpg" in url:
        return url
    try:
        import psycopg2  # noqa: F401
        return url  # psycopg2 dispo : comportement historique inchange
    except ModuleNotFoundError:
        pass
    try:
        import psycopg  # noqa: F401
        if url.startswith("postgresql://"):
            return "postgresql+psycopg://" + url[len("postgresql://"):]
        if url.startswith("postgres://"):
            return "postgresql+psycopg://" + url[len("postgres://"):]
    except ModuleNotFoundError:
        pass
    return url


# Résoudre DATABASE_URL depuis les variables d'environnement
def get_database_url() -> str:
    url = os.environ.get("DATABASE_URL")
    if url:
        return _normalize_driver(url)

    # Reconstruction depuis les variables Supabase
    host = os.environ.get("SUPABASE_DB_HOST")
    password = os.environ.get("SUPABASE_DB_PASSWORD")
    db_name = os.environ.get("SUPABASE_DB_NAME", "postgres")
    db_user = os.environ.get("SUPABASE_DB_USER", "postgres")
    db_port = os.environ.get("SUPABASE_DB_PORT", "5432")

    if host and password:
        return _normalize_driver(
            f"postgresql://{db_user}:{password}@{host}:{db_port}/{db_name}"
        )

    raise ValueError(
        "DATABASE_URL ou SUPABASE_DB_HOST + SUPABASE_DB_PASSWORD requis pour les migrations"
    )


def run_migrations_offline() -> None:
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = get_database_url()

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
