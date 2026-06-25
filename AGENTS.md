# ActivEducation — Agent Guide

## Repository overview

```
activ_education_app/   # Flutter app for students (Dart ^3.12.2)
admin_dashboard/       # Flutter admin dashboard (Dart ^3.12.2)
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

# Supabase local dev (if needed)
supabase start

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

# Create env file for dev
cp .env.example .env   # then fill secrets

# Create admin via script
ADMIN_EMAIL=admin@activeducation.com ADMIN_PASSWORD='Admin@2024!' \
  python -m scripts.create_super_admin

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
- **`env.py`**: removed `config.set_main_option("sqlalchemy.url", ...)` which broke with `%` in URL-encoded passwords.
- **Supabase network isolation**: local backend can't reach Supabase Auth (`auth.refresh_session()`, `sign_in()`). Use Supabase Management API (`/v1/projects/.../database/query`) to run SQL directly.
- **Refresh token 401 in dev**: expected when Supabase isn't reachable locally. Tokens get cleared, user must re-login.

## Flutter apps

### Environment
- Flutter SDK: **3.44.4** (Dart 3.12.2) — both apps updated.
- CI enforces `flutter analyze --fatal-infos` with 0 issues.

### Commands (student app / admin dashboard)
```sh
# Analyze (fatal in CI)
flutter analyze --fatal-infos

# Test (advisory in CI, not enforced)
flutter test --coverage

# Generate code (freezed, json_serializable, injectable)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run locally
```sh
# Student app (uses http://localhost:8000, endpoint paths already include /api/v1)
flutter run -d chrome

# Admin dashboard (uses http://localhost:8000/api/v1)
flutter run -d chrome
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
- Default for both in local dev is `http://localhost:8000` (student) / `http://localhost:8000/api/v1` (admin).

### Flutter web build quirks
- `--no-tree-shake-icons` is required (IconData with codepoint 0 crashes tree shaker). ~150KB gzip extra.
- `--base-href=/app/` is required for the student app. Admin has no base-href.
- `String.fromEnvironment` for `API_BASE_URL` is compile-time — hot reload won't pick up changes, use hot restart (`r`).

### Flutter app fixes (June 25)
- **Auth interceptor** (`lib/core/auth/auth_interceptor.dart`):
  - `_isOptionalAuthRoute` changed from `contains` to `startsWith` + GET-only.
  - Enrollment POST no longer treated as "optional auth" — prevents session-expired requests from being sent without token.
- **Course BLoC** (`lib/features/elearning/presentation/bloc/course_bloc.dart`):
  - `result.fold()` success callback was fire-and-forget (async ignored).
  - Both callbacks now `async` + `await` on fold — reload after enrollment completes synchronously.
- **Catalog shimmer overflow** (`lib/features/elearning/presentation/pages/elearning_catalog_page.widgets.dart:159`):
  - `Row` with 4 pills overflowed by 26px → wrapped in `SingleChildScrollView(horizontal)`.
- **Main shell** (`lib/router/widgets/main_shell.dart`):
  - Removed sidebar layout, bottom navigation bar used on all screen sizes.

### Admin dashboard fixes (June 25)
- **API_BASE_URL default** (`lib/core/constants/api_endpoints.dart`):
  - Changed from `https://` to `http://localhost:8000/api/v1` for local dev.
- **Login page overflow** (`lib/features/auth/presentation/login_page.dart:398`):
  - `_FeaturePill` Row overflowed in narrow Wrap → wrapped in `FittedBox(fit: BoxFit.scaleDown)`.

## Test credentials

| Role | Email | Password |
|------|-------|----------|
| super_admin (seed) | `admin@activeducation.com` | `Admin@2024!` |
| test user (script) | `test@activeducation.com` | `Test1234!` |
| demo (login page) | `demo@activeducation.com` | `Demo1234!` |

## CI/CD (4 GitHub Actions workflows)

| Workflow | Trigger | Key details |
|----------|---------|-------------|
| `backend-ci.yml` | push/PR to main/develop (backend/**) | lint → test (48% coverage) → check-migrations → docker-build |
| `frontend-ci.yml` | push/PR to main/develop (app or admin/**) | analyze both apps → build-student-web |
| `deploy-staging.yml` | push to develop | Build + deploy to staging VPS |
| `deploy-prod.yml` | manual dispatch on main | Requires "deploy-prod" confirmation, creates GitHub release |

Branch strategy: `main` (prod, protected), `develop` (staging, auto-deploy), `feature/*`, `fix/*`, `hotfix/*`, `grace` (agent's working branch).

## Commit conventions

Enforced by pre-commit hooks + commitizen + commitlint. Format:
```
<type>(<scope>): <lowercase subject>  # header ≤120 chars, subject 5-100 chars
```
Types: `feat|fix|docs|style|refactor|test|chore|perf|security|ci|revert`
Scopes: `backend|app|admin|infra|ci|docs|deps`

Pre-commit for Python: black (line-length=100), flake8 (with bugbear+simplify), isort (black profile). Runs only on `backend/` files.

## Secrets & .env
- `.env`, `.env.production`, `backend/.env`, `backend/.env.production` in `.gitignore`.
- Raw secrets bundle `env` also in `.gitignore`.
- `backend/supabase/.temp/` in `.gitignore` (auto-generated by `supabase start`).
- `.env.example` files exist at root and `backend/` with placeholder values — use as template.

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
