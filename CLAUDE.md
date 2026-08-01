# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Source de vérité pour ce projet : `AGENTS.md`** (mis à jour en continu par l'équipe).
> Ce `CLAUDE.md` ne contient que les ajouts / rappels spécifiques à Claude Code et renvoie à `AGENTS.md` pour le reste.

## À lire en priorité

1. `AGENTS.md` — commandes, architecture, conventions de commit, secrets, CI/CD, conventions `API_BASE_URL` (piège critique), quirks Flutter, credentials de test.
2. `docs/ARCHITECTURE.md` — vue d'ensemble des composants (Traefik, Supabase, Flutter apps).
3. `docs/OPERATIONS.md` — runbook production (déploiement, rollback, migrations Alembic, incidents).
4. `docs/INVENTAIRE_PAGES.md` — inventaire des pages (mobile + Next.js + admin) + palette de couleurs partagée.
5. `README.md` — installation rapide et URLs de production.

## Vue d'ensemble du repo

Plateforme d'orientation scolaire et professionnelle gamifiée (Afrique de l'Ouest). 4 fronts + 1 API + Postgres managé.

```
activ_education_app/   # Flutter app étudiants (Dart ^3.8) — servie sous /app/
admin_dashboard/       # Flutter admin (Dart ^3.10) — servie à la racine admin
backend/               # FastAPI + Supabase (PostgREST, pas d'ORM) — Python 3.11
frontend/              # Next.js 16 / React 19 / Tailwind 4 (parité page par page avec le mobile)
packages/shared_core/  # Package Dart partagé (path dep)
landing/               # Page statique racine (HTML premium)
docs/                  # ARCHITECTURE, OPERATIONS, INVENTAIRE_PAGES, SECURITY, RLS_AUDIT…
nginx/  traefik/       # Reverse proxy + SSL (Traefik v3 file-based, labels compose = doc only)
docker-compose*.yml    # 6 services : traefik, redis, backend, app-frontend, admin-frontend, socket-proxy
```

URLs prod : app `activeduhub.com` · API `api.activeduhub.com` · admin `admin.activeduhub.com`.

## Commandes les plus utilisées

Tout passe par le `Makefile` côté backend, et par `npm` / `flutter` côté front.

| Action | Commande |
|---|---|
| Backend dev | `make backend-run` |
| Backend tests (floor 48%) | `make backend-test` |
| Lint Python | `ruff check backend/app/` |
| Format Python | `black backend/app/ --line-length=100` |
| Type check (advisory) | `mypy backend/app/ --ignore-missing-imports` |
| Security scan (CI bloquant) | `bandit -r backend/app/ -ll -x backend/app/tests` |
| Migrations | `make migrate-upgrade` / `migrate-current` / `migrate-history` |
| Docker stack | `make docker-up` / `docker-down` |
| Flutter analyze (CI bloquant) | `flutter analyze --fatal-infos` |
| Flutter codegen | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Build app web (prod) | `flutter build web --release --base-href=/app/ --no-tree-shake-icons --dart-define=API_BASE_URL=…` |
| Build admin web (prod) | `flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=…/api/v1` |
| Frontend Next dev | `cd frontend && npm run dev` |
| Frontend Next build (typecheck) | `cd frontend && npm run build` |
| Frontend Next lint | `cd frontend && npm run lint` |
| Créer super admin | `ADMIN_EMAIL=… ADMIN_PASSWORD=… python -m scripts.create_super_admin` |

## Rappels critiques (pièges à ne pas se prendre)

- **`API_BASE_URL` est compile-time** : un changement demande un hot restart (`r`), pas un hot reload (`R`).
- **Piège `API_BASE_URL`** : app étudiant = `http://localhost:8000` (le code ajoute `/api/v1`) ; admin = `http://localhost:8000/api/v1` (l'admin attend déjà le préfixe). Détail complet dans `AGENTS.md`.
- **Pas de SQLAlchemy côté backend** : accès direct au client Supabase (PostgREST). `Alembic` ne gère que le schéma (`target_metadata = None`).
- **Sentry doit s'initialiser avant les imports applicatifs** dans `backend/app/main.py` (lignes 23-46).
- **Flutter build** : `--no-tree-shake-icons` est obligatoire (sinon crash sur codepoint 0, ~150KB gzip économisés en plus).
- **`SagaBloc` n'est pas dans le DI** — instancié manuellement. `LeaderboardPage` utilise un `_LeaderboardCubit` inline. L'endpoint weekly leaderboard du `ApiEndpoints` n'est **pas implémenté** côté backend.
- **Coverage floor backend** : 48% (cf. `Makefile`). Bandit est bloquant, mypy est advisory.
- **Frontend Next.js** : aligné page par page sur l'app Flutter mobile (cf. section dédiée en bas d'`AGENTS.md`).
- **Images** : `thumbnail_url` est le nom de champ cohérent partout (backend, frontend, admin). Toutes les images portent `onError={(e) => e.currentTarget.style.display='none'}` côté Next.js.
- **Pas d'emoji dans le frontend Next.js** : utiliser `lucide-react` (cf. `src/lib/career-icons.ts`).
- **Ne jamais lancer `npm run build` pendant que `npm run dev` tourne** sur la même machine (peut tuer le dev server, locker `.next/`, déclencher des recompiles infinies).
- **Machine limitée en RAM** (~7 Go). Vérifier `free -h` (>1.5 Go libres) avant de lancer `npm run dev`. Détail procédure de kill propre dans `AGENTS.md` section "Frontend Next.js — 19–20/07/2026" §9.

## Conventions de commit et branches

- Conventional Commits : `<type>(<scope>): <subject>` (header ≤120, subject 5-100 chars, lowercase). Scopes valides : `backend|app|admin|infra|ci|docs|deps`. Vérifié par commitizen en pre-commit.
- Pas d'édition directe sur `main` (protégée). `develop` → staging auto, `main` → prod manuelle.
- Branches : `main` (protégée), `develop` (auto-deploy), `feature/*`, `fix/*`, `hotfix/*`, `grace`.

## Skills et outils à privilégier

- `/init` a produit ce fichier. Pour les futures modifications structurelles, relire `AGENTS.md` d'abord.
- Commandes de build/test : cf. `AGENTS.md` section "Commands" (backend, Flutter student, Flutter admin, Next.js).
- Pour le déploiement : `docs/OPERATIONS.md` (runbook) + workflows `.github/workflows/deploy-{staging,prod}.yml`.

## Règles d'édition quand on touche du code

- Commits Conventional Commits : `<type>(<scope>): <subject>` (header ≤120, subject 5-100 chars, lowercase). Scopes valides : `backend|app|admin|infra|ci|docs|deps`. Vérifié par commitizen en pre-commit.
- Pas d'édition directe sur `main` (protégée). `develop` → staging auto, `main` → prod manuelle.
- Secrets : root `.env` ne contient que `REDIS_PASSWORD`. Secrets backend dans `backend/.env`. Ne jamais commiter de `.env`.
