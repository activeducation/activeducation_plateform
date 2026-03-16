"""Alembic environment configuration."""

import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool
from alembic import context

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = None

# Résoudre DATABASE_URL depuis les variables d'environnement
def get_database_url() -> str:
    url = os.environ.get("DATABASE_URL")
    if url:
        return url

    # Reconstruction depuis les variables Supabase
    host = os.environ.get("SUPABASE_DB_HOST")
    password = os.environ.get("SUPABASE_DB_PASSWORD")
    db_name = os.environ.get("SUPABASE_DB_NAME", "postgres")
    db_user = os.environ.get("SUPABASE_DB_USER", "postgres")
    db_port = os.environ.get("SUPABASE_DB_PORT", "5432")

    if host and password:
        return f"postgresql://{db_user}:{password}@{host}:{db_port}/{db_name}"

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
    # Override sqlalchemy.url BEFORE get_section() to avoid ConfigParser interpolation errors
    config.set_main_option("sqlalchemy.url", get_database_url())
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
