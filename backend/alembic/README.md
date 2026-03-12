# Migrations Alembic - ActivEducation

## Configuration

Variables d'environnement requises:

```bash
# Option 1: URL directe (recommandee)
DATABASE_URL=postgresql://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres

# Option 2: Variables individuelles
SUPABASE_DB_HOST=db.PROJECT.supabase.co
SUPABASE_DB_PASSWORD=your-db-password
SUPABASE_DB_PORT=5432       # defaut
SUPABASE_DB_USER=postgres   # defaut
```

Trouver les valeurs dans: Supabase Dashboard → Settings → Database → Connection string

## Commandes courantes

```bash
cd backend

# Voir l'etat actuel
alembic current

# Voir l'historique des migrations
alembic history --verbose

# Creer une nouvelle migration manuelle
alembic revision -m "ajouter_colonne_school_website"

# Creer une migration depuis les modeles SQLAlchemy (autogenerate)
alembic revision --autogenerate -m "description"

# Appliquer toutes les migrations en attente
alembic upgrade head

# Appliquer jusqu'a une migration specifique
alembic upgrade abc123

# Revenir en arriere d'une migration
alembic downgrade -1

# Revenir au debut
alembic downgrade base

# Generer le SQL sans l'appliquer (dry-run)
alembic upgrade head --sql > migration.sql
```

## Workflow recommande

### 1. Creer une migration

```bash
# Migration manuelle (pour changements SQL complexes)
alembic revision -m "add_mentor_availability_table"
# Puis editer le fichier cree dans alembic/versions/
```

### 2. Ecrire la migration

```python
def upgrade() -> None:
    op.execute("""
        CREATE TABLE mentor_availability (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            mentor_id UUID NOT NULL REFERENCES mentors(id),
            day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
            start_time TIME NOT NULL,
            end_time TIME NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX idx_mentor_availability_mentor ON mentor_availability(mentor_id);
    """)

def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS mentor_availability;")
```

### 3. Tester en staging

```bash
# Sur le serveur staging
alembic upgrade head
```

### 4. Appliquer en production

```bash
# Toujours faire un backup avant
# Puis appliquer
alembic upgrade head
```

## Migration initiale

Le schema initial (toutes les tables existantes) est dans:
- `database/schema.sql` - Schema complet de reference
- `app/db/migrations/` - Migrations SQL historiques appliquees manuellement
- `alembic/versions/001_initial_schema.py` - Migration initiale Alembic (etat de base)
