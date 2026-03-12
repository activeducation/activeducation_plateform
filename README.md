# ActivEducation

[![Backend CI](https://github.com/your-org/ActivEducation/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/your-org/ActivEducation/actions/workflows/backend-ci.yml)
[![Frontend CI](https://github.com/your-org/ActivEducation/actions/workflows/frontend-ci.yml/badge.svg)](https://github.com/your-org/ActivEducation/actions/workflows/frontend-ci.yml)

Plateforme d'orientation scolaire et professionnelle gamifiée pour l'Afrique de l'Ouest.

## Architecture

```
ActivEducation/
├── backend/               # API FastAPI (Python 3.11)
├── activ_education_app/   # App Flutter (étudiants)
├── admin_dashboard/       # Dashboard Flutter (admins)
├── nginx/                 # Configs Nginx
├── traefik/               # Reverse proxy + SSL
├── landing/               # Landing page statique
└── docker-compose.yml     # Orchestration production
```

**URLs de production :**
- App : https://activeduhub.com
- API : https://api.activeduhub.com
- Admin : https://admin.activeduhub.com

## Prérequis

- Python 3.11+
- Flutter 3.32+
- Docker & Docker Compose
- Compte Supabase

## Installation rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/your-org/ActivEducation.git
cd ActivEducation
```

### 2. Backend

```bash
cd backend
cp .env.example .env
# Remplir .env avec vos valeurs Supabase et SECRET_KEY
pip install -r requirements.txt
uvicorn app.main:app --reload
```

L'API sera disponible sur http://localhost:8000
Documentation Swagger : http://localhost:8000/docs

### 3. App Flutter (étudiants)

```bash
cd activ_education_app
flutter pub get
flutter run -d chrome
```

### 4. Dashboard admin

```bash
cd admin_dashboard
flutter pub get
flutter run -d chrome
```

## Configuration

### Variables d'environnement backend (.env)

| Variable | Description | Requis |
|----------|-------------|--------|
| `SUPABASE_URL` | URL de votre projet Supabase | ✅ |
| `SUPABASE_KEY` | Clé anon (publique) Supabase | ✅ |
| `SUPABASE_SERVICE_ROLE_KEY` | Clé service role Supabase | ✅ |
| `SECRET_KEY` | Clé JWT (min. 32 chars, aléatoire) | ✅ |
| `ENVIRONMENT` | `development` / `staging` / `production` | ✅ |
| `BACKEND_CORS_ORIGINS` | Origines CORS autorisées (virgule) | ✅ |
| `DEBUG` | `True` en dev, `False` en prod | ✅ |
| `GROQ_API_KEY` | Clé API Groq pour le chat AÏDA | ⚠️ |

Générer une SECRET_KEY sécurisée :
```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## Commandes de développement

### Backend

```bash
# Lancer les tests
cd backend && pytest tests/ -v --cov=app

# Vérifier le formatage
black app/ --check --line-length=100
flake8 app/ --max-line-length=100

# Formater automatiquement
black app/ --line-length=100
```

### Flutter

```bash
# Analyser le code
flutter analyze

# Lancer les tests
flutter test --coverage

# Build web production
flutter build web --release

# Générer le code (freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Docker

```bash
# Démarrer tous les services
docker compose up -d

# Voir les logs
docker compose logs -f backend

# Rebuild après changements
docker compose up -d --build backend
```

## Déploiement

Voir [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) pour les instructions complètes.

**Résumé :**
- `develop` → déploiement automatique sur staging
- `main` → déploiement manuel via GitHub Actions (workflow_dispatch)

## Architecture détaillée

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Sécurité

Voir [docs/SECURITY.md](docs/SECURITY.md).

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

Propriétaire - ActivEducation © 2024
