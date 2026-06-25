# ActivEducation — Agent Guide

## Repository overview

```
activ_education_app/   # Flutter app for students (Dart ^3.8.0)
admin_dashboard/       # Flutter admin dashboard (Dart ^3.10.8)
backend/               # Python FastAPI REST API
packages/shared_core/  # Shared Dart package (path dep from both Flutter apps)
landing/               # Static HTML landing page served at root
nginx/                 # Nginx configs for app/admin static serving
traefik/               # Traefik v3 reverse proxy config (file-based, not labels)
```

## Backend (FastAPI + Supabase)

### Commands
```sh
# Run dev server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Test with coverage floor at 48%
pytest tests/ -v --cov=app --cov-fail-under=48

# Lint / format / typecheck
ruff check app/
black app/ --line-length=100
isort app/ --profile=black --line-length=100
mypy app/ --ignore-missing-imports   # advisory only (1142+ existing errors)
bandit -r app/ -ll                   # blocking in CI

# Alembic migrations (must run manually, no auto-migrate on startup)
alembic upgrade head

# Update dependencies from requirements.in
pip-compile requirements.in --output-file requirements.txt
```

### Gotchas
- **Sentry must be initialized first** in `main.py` before any application imports.
- **CORS validation in production**: `Settings` refuses to start if CORS is empty, contains `*`, or has placeholder CI values.
- **`SECRET_KEY`** must be >32 chars, not a default placeholder, and must NOT start with `eyJ` (JWT-like).
- **Redis password** is injected into `docker-compose.yml` via `${REDIS_PASSWORD}` from root `.env`; `REDIS_URL` is constructed in compose, not in `backend/.env.production`.
- **Traefik routing in production is file-based** (`traefik/dynamic.yml`), not label-based. Labels in `docker-compose.yml` are documentation only.
- Docker socket is accessed through `tecnativa/docker-socket-proxy` (read-only), not directly.

## Flutter apps

### Commands (student app / admin dashboard)
```sh
# Analyze (fatal in CI)
flutter analyze --fatal-infos

# Test (advisory in CI, not enforced)
flutter test --coverage

# Generate code (freezed, json_serializable, injectable)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build for production
```sh
# Student app — served under /app/ sub-path
flutter build web --release --base-href=/app/ --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com

# Admin dashboard — served at root of its subdomain
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1
```

### Critical API_BASE_URL convention
- Student app endpoints **already include** `/api/v1` → `API_BASE_URL` must NOT include it.
- Admin dashboard endpoints **do NOT** include the prefix → `API_BASE_URL` **MUST** include `/api/v1`.

### Flutter web build quirks
- `--no-tree-shake-icons` is required (IconData with codepoint 0 crashes tree shaker). ~150KB gzip extra.
- `--base-href=/app/` is required for the student app. Admin has no base-href.

## CI/CD (4 GitHub Actions workflows)

| Workflow | Trigger | Key details |
|----------|---------|-------------|
| `backend-ci.yml` | push/PR to main/develop (backend/**) | lint → test (48% coverage) → check-migrations → docker-build |
| `frontend-ci.yml` | push/PR to main/develop (app or admin/**) | analyze both apps → build-student-web |
| `deploy-staging.yml` | push to develop | Build + deploy to staging VPS |
| `deploy-prod.yml` | manual dispatch on main | Requires "deploy-prod" confirmation, creates GitHub release |

Branch strategy: `main` (prod, protected), `develop` (staging, auto-deploy), `feature/*`, `fix/*`, `hotfix/*`.

## Commit conventions

Enforced by pre-commit hooks + commitizen + commitlint. Format:
```
<type>(<scope>): <lowercase subject>  # header ≤120 chars, subject 5-100 chars
```
Types: `feat|fix|docs|style|refactor|test|chore|perf|security|ci|revert`
Scopes: `backend|app|admin|infra|ci|docs|deps`

Pre-commit for Python: black (line-length=100), flake8 (with bugbear+simplify), isort (black profile). Runs only on `backend/` files.

## Docker composition (6 services)

| Service | Notes |
|---------|-------|
| `socket-proxy` | Read-only Docker socket proxy |
| `traefik` | Reverse proxy, Let's Encrypt SSL |
| `redis` | Cache + rate limiting, 7.2-alpine |
| `backend` | FastAPI via uvicorn (2 workers) |
| `app-frontend` | Nginx serving landing (root) + student app (`/app/`) |
| `admin-frontend` | Nginx serving admin dashboard |

No auto-migration on startup. Run: `docker compose exec backend alembic upgrade head`
