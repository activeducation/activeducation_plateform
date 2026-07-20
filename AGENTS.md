# ActivEducation — Agent Guide

## Repo overview
```
backend/               # FastAPI (Python 3.11, Supabase raw client, no SQLAlchemy)
activ_education_app/   # Flutter student app (Dart ^3.8.0)
admin_dashboard/       # Flutter admin dashboard (Dart ^3.10.8)
frontend/              # Next.js 16 web app (student-facing, FR)
landing/               # Static HTML landing page
packages/shared_core/  # Shared Dart package (path dep)
traefik/, nginx/       # Infra configs (file-based routing, Let's Encrypt)
```

## Backend (FastAPI + Supabase)

### Critical gotchas
- **No SQLAlchemy** — raw Supabase client (PostgREST). Alembic has `target_metadata = None`.
- **Sentry init before app imports** (`main.py:23-46`).
- **Settings validation** — rejects placeholder CI values and `*` CORS in production.
- **`SECRET_KEY`** >32 chars, not `eyJ`-prefixed, not a default placeholder.
- **Redis password** via `${REDIS_PASSWORD}` in compose; `REDIS_URL` built there, not in `.env.production`.
- **Local backend can't reach Supabase Auth** (no `auth.refresh_session()`). Use Management API for SQL. 401 on token refresh is expected.

### Commands
```sh
make backend-run              # uvicorn --reload :8000
make backend-test             # pytest --cov=app --cov-fail-under=48
make migrate-upgrade          # alembic upgrade head
make update-deps              # pip-compile requirements.in
```

### CI env requirements
`ENVIRONMENT=testing`, `REDIS_URL=redis://localhost:6379/0`, `SUPABASE_KEY`/`SUPABASE_SERVICE_ROLE_KEY` must be 3-segment JWTs (base64.base64.base64) or import crashes.

### Lint pipeline
`ruff check app/` → `black app/ --line-length=100` → `isort app/ --profile=black --line-length=100` → `bandit -r app/ -ll -x app/tests` (blocking). `mypy app/ --ignore-missing-imports` is advisory (~1142 errors).

### Migrations
18 versions in `alembic/versions/`. Manual only (no auto-migration). Check head count with `alembic heads`.

## Flutter apps

### API_BASE_URL trap (critical)
- **Student app** appends `/api/v1` to endpoint paths → `API_BASE_URL` must NOT include `/api/v1`. Local default: `http://localhost:8000`.
- **Admin dashboard** endpoints are bare → `API_BASE_URL` MUST include `/api/v1`. Default: `http://localhost:8000/api/v1`.
- Compile-time via `--dart-define=API_BASE_URL=...` — hot restart (`r`), not hot reload.

### Build
```sh
flutter analyze --fatal-infos                                  # CI blocking
flutter pub run build_runner build --delete-conflicting-outputs # codegen

# Student (served under /app/)
flutter build web --release --base-href=/app/ --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com

# Admin (served at root)
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1
```

### Quirks
- `--no-tree-shake-icons` required (codepoint 0 crashes tree shaker, ~150KB gzip extra).
- `SagaBloc` not in DI — created manually in `saga_page.dart:24`.
- `LeaderboardPage` uses inline `_LeaderboardCubit` (not in DI). See `leaderboard_page.dart:35`.
- Weekly leaderboard endpoint defined in `ApiEndpoints` but **not implemented** in backend.
- Tests are advisory in CI (`continue-on-error: true`).

## Frontend Next.js
- Next.js 16, React 19, Tailwind CSS 4, lucide-react. Dev: `npm run dev` (port 3000). Build: `npm run build`.
- **No emojis** — always `lucide-react` icons. Helper: `getSectorIcon()` in `src/lib/career-icons.ts`.
- In-memory API cache at `src/lib/api.ts` (default TTL 30s, dedup in-flight). Call `api.invalidate()` after mutations.
- Images: `onError={(e) => e.currentTarget.style.display='none'}` for silent fallback. Canonical field: `thumbnail_url`.
- Responsive: `<SideNav>` (md+), bottom-nav (<md). `<NavGuard>` hides shell on auth/onboarding pages.
- Pages: `/` `/login` `/register` `/onboarding/*` `/profil` `/classement` `/cours/*` `/lecon/[id]` `/ecoles/*` `/mentors/*` `/orientation/*` `/search` `/aida` `/notifications`

## Test credentials
| Role | Email | Password |
|------|-------|----------|
| super_admin | `admin@activeducation.com` | `Admin@2024!` |
| test user | `test@activeducation.com` | `Test1234!` |
| demo | `demo@activeducation.com` | `Demo1234!` |

## CI/CD
- `backend-ci.yml`: lint → test (48%) → check-migrations → docker-build. `frontend-ci.yml`: analyze (both apps) → build student web.
- `deploy-staging.yml`: auto on push `develop`. `deploy-prod.yml`: manual dispatch on `main` (requires "deploy-prod" confirmation).
- Branch strategy: `main` (protected), `develop` (auto-deploy), `feature/*`, `fix/*`, `hotfix/*`.

## Commit conventions
`<type>(<scope>): <lowercase subject>` — header ≤120 chars, subject 5-100 chars.
Types: `feat|fix|docs|style|refactor|test|chore|perf|security|ci|revert`
Scopes: `backend|app|admin|infra|ci|docs|deps`
Enforced by pre-commit (commitizen) and commitlint.

## Secrets
- Root `.env`: only `REDIS_PASSWORD` (for docker-compose). Backend secrets: `backend/.env`.
- `.env.example` templates at root and `backend/`. Never commit `.env`.

## Docker (6 services)
`socket-proxy` (unused), `traefik` (file-based `traefik/`, labels in compose are docs only), `redis` (7.2-alpine, no persistence), `backend` (FastAPI, 2 workers), `app-frontend` (Nginx: landing + student app at `/app/`), `admin-frontend` (Nginx: admin dashboard).
No auto-migration — run: `docker compose exec backend alembic upgrade head`
