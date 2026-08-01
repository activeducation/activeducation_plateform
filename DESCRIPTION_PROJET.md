# ActivEducation — Plateforme d'Orientation Scolaire et Professionnelle Gamifiée

## Vue d'ensemble

ActivEducation est une plateforme numérique destinée aux étudiants d'Afrique de l'Ouest (principalement Togo) qui combine **orientation scolaire**, **e-learning**, **mentorat**, **découverte des métiers/écoles**, et **gamification** dans une expérience unifiée. La plateforme couvre 4 interfaces :

| Interface | Technologie | URL (prod) | Public |
|-----------|------------|------------|--------|
| **App étudiant** (web) | Next.js 16 + React 19 + Tailwind CSS 4 | `activeducationhub.com` | Étudiants |
| **App étudiant** (mobile) | Flutter 3.32+ (Dart ^3.8.0) | servie sous `/app/` | Étudiants |
| **Dashboard admin** | Flutter 3.32+ (Dart ^3.10.8) | `admin.activeducationhub.com` | Administrateurs |
| **Landing page** | HTML statique | racine (via Nginx) | Public |

**API** : FastAPI (Python 3.11) — `api.activeducationhub.com`

---

## Architecture technique

```
┌─────────────────────────────────────────────────────────────┐
│ Traefik (reverse proxy + SSL Let's Encrypt)                 │
├──────────────────────┬──────────────────┬───────────────────┤
│  Nginx app-frontend  │  Nginx admin     │  FastAPI backend  │
│  (/ = landing stat.) │  (/ = admin web) │  (:8000)          │
│  (/app/ = Flutter)   │                  │                   │
├──────────────────────┴──────────────────┴───────────────────┤
│  Redis (cache, 7.2-alpine)                                  │
│  Supabase (PostgreSQL + Auth, via PostgREST)                │
└─────────────────────────────────────────────────────────────┘
```

- **Pas de SQLAlchemy** : communication directe avec Supabase via le client PostgREST raw
- **Redis** : cache distribué (tokens, listes statiques)
- **Alembic** : migrations manuelles (18+ versions)
- **Sentry** : monitoring d'erreurs
- **Docker** : 6 services (socket-proxy, traefik, redis, backend, app-frontend, admin-frontend)

---

## Modules fonctionnels

### 1. Orientation scolaire & professionnelle

- **Tests d'orientation** basés sur les centres d'intérêt (RIASEC/Holland)
- **Moteur de matching** carrières/formations
- **Catalogue des métiers** avec fiches détaillées (formations requises, débouchés, salaires)
- **Base écoles** : 97 établissements d'enseignement supérieur du Togo importés (universités, grandes écoles, instituts, centres de formation)

### 2. E-learning & Examens

- **Cours** structurés en modules et leçons
- **Suivi de progression** avec leçons complétées
- **Examens** : soumission, correction automatique, suivi des scores
- **Certificats** : générés après validation des examens

### 3. Mentorat

- **Catalogue de mentors** avec profils publics
- **Portfolio mentor** structuré (formations, expériences, certifications, projets, langues, liens)
- **Candidature mentor** via formulaire avec portfolio
- **Système de rendez-vous** avec créneaux disponibles
- **Avis et notation** des mentors par les étudiants
- **Messagerie** (endpoint backend non implémenté — affiche "Messagerie indisponible")
- **Dashboard admin** pour approbation des candidatures

### 4. Gamification

- **Points et badges** attribués pour actions (connexion, cours complété, examen réussi, etc.)
- **Classement** hebdomadaire des étudiants (leaderboard)
- **Suivi des séquences** (streaks) de connexion quotidienne
- **Niveaux** (level up) basés sur l'XP accumulée
- Cache Redis pour les leaderboards

### 5. Intelligence Artificielle — AÏDA

- **Chatbot IA** d'orientation basé sur Groq (LLM)
- Sessions de conversation persistantes
- Réponses contextualisées sur les métiers, formations, parcours
- Filtres de sécurité et modération

### 6. Partenariats & Opportunités

- **Offres de stage/emploi** avec pagination
- **Espace partenaires** (organisations)
- **Portail écoles** : gestion des cours, modules, leçons, profils scolaires

### 7. Fonctionnalités sociales & compte

- **Authentification** : email/mot de passe, JWT
- **Profils utilisateurs** avec avatar, bio, préférences
- **Système de rôles** : super_admin, admin, school_admin, partner, student, mentor
- **Notifications** en temps réel
- **Paramètres** utilisateur

---

## Backend (FastAPI)

### Stack
- **Python 3.11** — FastAPI
- **Supabase** (PostgreSQL + Auth) — client raw (PostgREST), pas de SQLAlchemy
- **Redis** — cache (via `redis.asyncio`)
- **Alembic** — migrations DDL (exécutées manuellement via Supabase SQL Editor)
- **Sentry** — monitoring
- **SlowAPI** — rate limiting
- **Pydantic v2** — validation des schémas

### Endpoints API (v1)

| Groupe | Endpoints principaux |
|--------|---------------------|
| **Auth** | POST `/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout` |
| **Mentors** | GET `/mentors`, GET `/mentors/{id}`, GET/PATCH `/mentors/{id}/portfolio`, POST `/mentors/apply`, POST `/mentors/{id}/reviews`, GET `/mentors/{id}/slots` |
| **Écoles** | GET `/schools`, GET `/schools/{id}`, recherche |
| **Orientation** | GET `/orientation/careers`, GET `/orientation/careers/{id}`, POST `/orientation/test` |
| **E-learning** | GET `/courses`, GET `/courses/{id}`, POST `/courses/{id}/enroll`, GET `/lessons/{id}`, POST `/lessons/{id}/complete` |
| **Examens** | GET `/courses/{id}/exam`, POST `/exam/submit`, GET `/exam/results/{id}` |
| **Gamification** | GET `/gamification/profile`, GET `/gamification/leaderboard`, GET `/gamification/badges` |
| **Opportunités** | GET `/opportunities` (limit/offset) |
| **Chat AÏDA** | POST `/chat/session`, POST `/chat/message` |
| **Recherche** | GET `/search?q=...` |
| **Annonces** | GET `/announcements` |
| **Paramètres** | GET/PATCH `/settings` |
| **Admin** | CRUD utilisateurs, mentors, écoles, carrières, cours, opportunités, paramètres, upload fichiers, dashboard stats |
| **School admin** | Auth école, dashboard, cours, modules, leçons, profil |
| **Partner** | CRUD organisations |

### Schemas Pydantic
`auth.py`, `mentor.py`, `schools.py`, `elearning.py`, `exam.py`, `gamification.py`, `orientation.py`, `partner.py`, `school_admin.py`, et dossiers `admin/`

### Services
- `auth_service.py` — authentification et gestion des tokens
- `llm_service.py` + `llm/` (groq_provider, prompt_builder, safety_filter, session_manager) — chat IA
- `orientation_engine.py` — matching métiers/formations
- `career_matcher.py` — algorithme de recommandation
- `partner_service.py` — gestion partenaires

### Middleware
- Rate limiter (SlowAPI)
- Security headers (CSP, HSTS, X-Frame-Options, etc.)
- Request logging avec correlation IDs
- Compression GZip
- CORS configurable

---

## Frontend web (Next.js 16)

### Stack
- **Next.js 16** (App Router)
- **React 19**
- **Tailwind CSS 4**
- **lucide-react** (icônes — pas d'émojis)
- Cache API in-memory (TTL 30s, déduplication)

### Pages

| Route | Description |
|-------|-------------|
| `/` | Accueil |
| `/login` | Connexion |
| `/register` | Inscription |
| `/onboarding/*` | Questionnaire d'intérêts |
| `/profil` | Profil utilisateur |
| `/classement` | Leaderboard gamification |
| `/cours/*` | Catalogue et détail cours |
| `/lecon/[id]` | Leçon individuelle |
| `/ecoles/*` | Catalogue et détail écoles |
| `/mentors/*` | Liste mentors, candidature, profil mentor |
| `/orientation/*` | Tests, métiers, fiches carrière |
| `/search` | Recherche globale |
| `/aida` | Chat IA d'orientation |
| `/notifications` | Centre de notifications |
| `/opportunities` | Offres de stage/emploi |
| `/parametres` | Paramètres compte |
| `/confidentialite` | Politique de confidentialité |
| `/metiers` | Fiches métiers |
| `/elearning` | E-learning |

### Composants
- `auth/` — formulaires connexion/inscription, AuthGuard, NavGuard
- `layout/` — SideNav (desktop), bottom-nav (mobile), AppShell
- `onboarding/` — questionnaire pas-à-pas
- `shared/` — cartes, listes, spinners
- `ui/` — boutons, inputs, modales

---

## App Flutter étudiant

### Stack
- **Dart ^3.8.0** — Flutter 3.32+
- **Bloc/Cubit** — gestion d'état
- **GoRouter** — navigation
- **Freezed + json_serializable** — codegen
- Build web avec `--base-href=/app/`

### Features (13 modules)
`ai_chat`, `auth`, `elearning`, `gamification`, `home`, `mentors`, `onboarding`, `opportunities`, `orientation`, `partner`, `profile`, `schools`, `search`

---

## Dashboard admin (Flutter)

### Stack
- **Dart ^3.10.8** — Flutter 3.32+
- **Bloc/Cubit** — gestion d'état
- **GoRouter** — navigation
- API_BASE_URL inclut `/api/v1`

### Features (13 modules)
`auth`, `careers`, `dashboard`, `elearning`, `gamification`, `mentors`, `opportunities`, `orientation_tests`, `partner`, `school_portal`, `schools`, `settings`, `users`

---

## Infrastructure & Déploiement

### Services Docker
| Service | Image | Rôle |
|---------|-------|------|
| `socket-proxy` | tecnativa/docker-socket-proxy | Accès Docker sécurisé (lecture seule) |
| `traefik` | traefik:v3.2 | Reverse proxy + SSL Let's Encrypt |
| `redis` | redis:7.2-alpine | Cache (128 MB max, pas de persistence) |
| `backend` | custom (Dockerfile) | API FastAPI (2 workers) |
| `app-frontend` | nginx:1.25-alpine | Landing statique + Flutter student /app/ |
| `admin-frontend` | nginx:1.25-alpine | Dashboard admin Flutter |

### CI/CD (GitHub Actions)
- **backend-ci.yml** : lint (ruff, black, isort, bandit) → tests (pytest, couverture 48%) → check migrations → docker build
- **frontend-ci.yml** : analyze (2 apps Flutter) → build student web
- **deploy-staging.yml** : auto push sur `develop`
- **deploy-prod.yml** : manuel (workflow_dispatch) sur `main`

### Branches
- `main` — protégée, déploiement prod manuel
- `develop` — auto-déploiement staging
- `feature/*`, `fix/*`, `hotfix/*`

### URLs production
- App : `https://activeducationhub.com`
- API : `https://api.activeducationhub.com`
- Admin : `https://admin.activeducationhub.com`

---

## Données

### Base écoles
97 établissements d'enseignement supérieur du Togo importés depuis Google Sheets (24 feuilles, 574 formations). Types : `university` (5), `grande_ecole` (38), `institut` (53), `centre_formation` (1). Colonnes : région, latitude, longitude, diplômes offerts, admission, infrastructure (JSONB).

### Portfolio mentor
Données structurées JSONB : formations, expériences, certifications, projets, langues, liens. Copié automatiquement vers `mentors` lors de l'approbation admin.

### Gamification
Points, badges, streaks, niveaux, leaderboard hebdomadaire. Cache Redis. Endpoint leaderboard hebdomadaire défini dans l'API mais non implémenté côté backend.

---

## Sécurité

- **Headers HTTP** : HSTS, X-Frame-Options, Content-Security-Policy, X-Content-Type-Options, Permissions-Policy, Referrer-Policy
- **Rate limiting** : 100 req/s par IP (Traefik) + SlowAPI
- **CORS** : origines configurées par environnement
- **JWT** : tokens signés avec SECRET_KEY (>32 caractères)
- **Sentry** : monitoring, pas de PII
- **Pas de SQL direct** : tout passe par l'API Supabase (RLS)
- **Validation** : Pydantic v2, messages d'erreur en français
- **Docker** : no-new-privileges, healthchecks, resource limits

---

## Équipe & Contribution

- **Licence** : Propriétaire — ActivEducation © 2024
- **Conventions** : Conventional Commits (`type(scope): message`), pre-commit (commitizen, commitlint)
- **Tests** : pytest backend (seuil 48%), Flutter tests (advisory)

---

## Sessions de développement

| Session | Travail effectué |
|---------|-----------------|
| 2026-07-21 | 14 bugs frontend (401, page blanche onboarding, endpoint AIDA, routes search, etc.) |
| 2026-07-22 | Fix RLS mentors backend + affichage Flutter admin + import 97 écoles Togo |
| 2026-07-23 | Portfolio mentor (JSONB, formulaire, API, approbation admin) |
