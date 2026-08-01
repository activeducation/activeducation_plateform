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

## Session 2026-07-21 — Bug fixes frontend (14 bugs)

### Bugs corrigés

| # | Bug | Fichier | Fix |
|---|-----|---------|-----|
| 1 | 401 en console (prewarm sans token) | `auth.tsx:41` | `if (!token) return` |
| 2 | Page blanche onboarding/login | `nav-guard.tsx` | AppShell conditionnel |
| 3 | Endpoint AIDA `/aida/chat {conversation_id}` → `/chat/message {session_id}` | `aida/page.tsx:34-37` | Endpoint + champ corrigés |
| 4 | Lien `/opportunites` → `/opportunities` | `page.tsx:379` | Typo FR/EN |
| 5 | Routes search cassées (3 types) | `search/page.tsx:180` | Navigation vers les bonnes pages FR (/ecoles, /orientation/career, /cours) |
| 6 | False success message mentor (endpoint `/conversations` inexistant) | `mentors/[id]/page.tsx:133` | Affiche "Messagerie indisponible" au lieu de faux "Message envoyé" |
| 7 | NaN slotsLeft | `mentors/[id]/page.tsx:125` | `??` guards |
| 8 | Null crash filtre mentors | `mentors/page.tsx:51` | Optional chaining `?? ''` |
| 9 | Race condition pagination opportunités | `opportunities/page.tsx:131` | `const next = page + 1` |
| 10 | Erreur cache données existantes pagination | `opportunities/page.tsx:86` | Condition `opportunities.length === 0` ajoutée |
| 11 | Pas de spinner pagination | `opportunities/page.tsx:130-134` | `loadingMore` state + disabled |
| 12 | Validation exam contournée (tableau vide) | `exam/page.tsx:87` | `Array.isArray` check |
| 13 | Navigation vers `/lecon/` (ID vide) | `cours/[id]/page.tsx:206` | `firstIncompleteLesson` retourne `null` + bouton désactivé |
| 14 | Silent catch inscription cours | `cours/[id]/page.tsx:48` | `console.warn` + `api.invalidate()` |

### Frontend gotchas découverts
- **`/conversations` POST n'existe pas dans le backend** — le mentor contact est en simulation, affiche une erreur explicite
- **`/opportunities` endpoint backend ne gère pas le paramètre `page`** — utilise `limit` + `offset` (pas de `page`/`per_page`)
- **`firstIncompleteLesson()`** doit retourner `string | null` pour éviter la navigation vers `/lecon/`
- **`api.invalidate()` est requis après `POST /exam/submit`** et `POST /courses/{id}/enroll` pour rafraîchir le cache
- **L'endpoint `/search` backend retourne des routes EN** (`/schools`, `/orientation/career?id=...`) — le frontend doit les convertir en routes FR

## Session 2026-07-22 — Mentors backend RLS + affichage frontend

### Bugs corrigés

| # | Bug | Fichier | Fix |
|---|-----|---------|-----|
| 1 | API publique `/mentors` retourne 0 mentors (RLS) | `backend/endpoints/mentors.py:121` | `get_supabase_client()` → `get_admin_supabase_client()` |
| 2 | Detail mentor `/mentors/{id}` introuvable (RLS) | `backend/endpoints/mentors.py:183` | `get_supabase_client()` → `get_admin_supabase_client()` |
| 3 | Reviews mentor `/mentors/{id}/reviews` vide (RLS) | `backend/endpoints/mentors.py:241` | `get_supabase_client()` → `get_admin_supabase_client()` |
| 4 | Filtre `is_verified=True` exclut mentors créés par admin | `backend/endpoints/mentors.py:133` | Filtre supprimé (conserve `is_active=True`) |
| 5 | Mentors créés depuis admin ont `is_verified=False` | `backend/endpoints/admin/mentors.py` | `data["is_verified"] = True` ajouté |
| 6 | Mentors Flutter nom vide si `user_profiles` null | `admin_dashboard/.../mentors_list_page.dart` | Fallback `full_name` |

### Gotchas découverts
- **Tous les endpoints publics mentors (list, detail, reviews) doivent utiliser `get_admin_supabase_client()`** car RLS bloque la clé anon sur la table `mentors`
- **La clé anon (`get_supabase_client()`) ne voit aucune donnée des tables protégées** — seul le service_role (`get_admin_supabase_client()`) fonctionne pour les lectures publiques
- **Les mentors créés depuis l'admin dashboard ont `is_verified=False`** par défaut dans le schema, mais doivent être visible immédiatement sans passer par le filtre `is_verified=True`

## Session 2026-07-22 — Import écoles (Base de Données Nationale)

### Résumé
Import des 97 établissements d'enseignement supérieur du Togo depuis un fichier Excel Google Sheets (24 feuilles, 97 écoles, 574 formations).

### Fichiers créés/modifiés

| Fichier | Action |
|---------|--------|
| `backend/scripts/import_schools.py` | Créé - Script d'import principal (replacing strategy) |
| `backend/alembic/versions/021_enrich_schools.py` | Créé - Migration ajoutant 6 colonnes à `schools` |
| `backend/database/migration_021_enrich_schools.sql` | Créé - SQL à exécuter dans le dashboard Supabase |

### Nouvelles colonnes schools

| Colonne | Type | Source Excel |
|---------|------|-------------|
| `region` | TEXT | Localisation → Région |
| `latitude` | DOUBLE PRECISION | Localisation → Latitude |
| `longitude` | DOUBLE PRECISION | Localisation → Longitude |
| `degrees_offered` | TEXT | Diplomes → Diplômes délivrés (synthèse) |
| `admission_info` | TEXT | Admissions → Niveau requis, Concours, etc. |
| `infrastructure` | JSONB | Infrastructures (Wi-Fi, bibliothèque, etc.) |

### Mapping type
49 types Excel → 4 valeurs DB : `university` (5), `grande_ecole` (38), `institut` (53), `centre_formation` (1).

### Commandes
```sh
cd backend && python3 -m scripts.import_schools        # Réimport complet
# Pour re-télécharger le fichier depuis Google Sheets:
curl -sL -o /tmp/ecoles.xlsx "https://docs.google.com/spreadsheets/d/1iL39mVkJTQ0rEB-jhlfXzaiOAHzOxdJZay_3LUljq_U/export?format=xlsx"
```

### Gotchas
- **Pas d'accès direct à la base de données** — les migrations DDL doivent être exécutées manuellement dans le SQL Editor de Supabase (pas de `SUPABASE_DB_PASSWORD` en local).
- **`delete().neq('id', '00000000-0000-0000-0000-000000000000')` peut ne pas fonctionner** — préférer exécuter la suppression en deux passes ou via SQL direct.
- **Le mapping des écoles utilise le `name`** pour reconstruire la relation ID_ETABLISSEMENT → UUID après insertion (pas de ID métier conservé).
- **Les données Excel sont bien structurées** : 24 feuilles reliées par `ID_ETABLISSEMENT`, compatible PostgreSQL/Supabase.

## Session 2026-07-23 — Portfolio mentor

### Résumé
Ajout du portfolio mentor : données structurées (formations, expériences, certifications, projets, langues, liens) stockées dans une colonne JSONB `portfolio` sur `mentors` et `mentor_applications`.

### Fichiers créés/modifiés

| Fichier | Action |
|---------|--------|
| `backend/alembic/versions/022_mentor_portfolio.py` | Créé — Migration ajoutant colonne `portfolio JSONB` |
| `backend/app/schemas/mentor.py` | Modifié — 6 sous-modèles portfolio + `MentorPortfolio` + `MentorPortfolioUpdate` |
| `backend/app/api/v1/endpoints/mentors.py` | Modifié — `GET /mentors/{id}` inclut portfolio + endpoints `GET/PATCH /mentors/{id}/portfolio` |
| `backend/app/api/v1/endpoints/admin/mentor_applications.py` | Modifié — Approbation copie le portfolio vers le mentor |
| `frontend/src/app/mentors/apply/page.tsx` | Modifié — Formulaire portfolio complet (6 sections) |
| `frontend/src/app/mentors/[id]/page.tsx` | Modifié — Composant `PortfolioSection` affiché sur la fiche publique |
| `frontend/src/lib/api.ts` | Modifié — Lecture de `err.message` en plus de `err.detail` pour les erreurs API |

### Migration SQL manuelle
```sql
ALTER TABLE mentors ADD COLUMN IF NOT EXISTS portfolio JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE mentor_applications ADD COLUMN IF NOT EXISTS portfolio JSONB DEFAULT '{}'::jsonb;
```

### Structure JSONB `portfolio`
```json
{
  "formations": [{"ecole": "", "diplome": "", "domaine": "", "annee_debut": 2020, "annee_fin": 2023}],
  "experiences": [{"poste": "", "entreprise": "", "debut": "2020-01", "fin": null, "en_cours": true, "description": ""}],
  "certifications": [{"nom": "", "organisme": "", "annee": 2022, "lien": ""}],
  "projets": [{"nom": "", "description": "", "lien": "", "technologies": ["Flutter", "Python"]}],
  "langues": [{"langue": "Français", "niveau": "Natif"}],
  "liens": [{"type": "github", "url": "https://..."}]
}
```

### Limites de texte (max_length)
- `bio`, `motivation` → 5000
- `description` (expériences, projets) → 5000
- `PortfolioFormation.ecole`, `diplome` → 200
- `PortfolioExperience.poste`, `entreprise` → 200
- `PortfolioCertification.nom`, `organisme` → 200
- `PortfolioProjet.nom` → 200

### Flux
1. Candidature → étudiant remplit le portfolio dans le formulaire `POST /mentors/apply`
2. Approbation admin → `portfolio` copié automatiquement vers `mentors`
3. Visite publique → `GET /mentors/{id}` retourne `portfolio` affiché dans `PortfolioSection`
