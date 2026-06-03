# Documentation technique — ActivEducation

> **Plateforme d'orientation scolaire et professionnelle gamifiée pour l'Afrique de l'Ouest.**
>
> Document maître à jour. Public visé : nouveaux développeurs (onboarding),
> pilotage technique, et repreneur / audit externe.
>
> Dernière refonte : 2026-06. Remplace l'ancien `documentation.md` (mars 2026,
> obsolète depuis l'ajout de la gamification temps réel, des partenaires, des
> annonces/settings et du refactoring des pages).

---

## Table des matières

1. [Vue d'ensemble produit](#1-vue-densemble-produit)
2. [Architecture globale](#2-architecture-globale)
3. [Stack technique](#3-stack-technique)
4. [Backend — FastAPI](#4-backend--fastapi)
5. [Modèle de données](#5-modèle-de-données)
6. [Applications Flutter](#6-applications-flutter)
7. [Authentification & sécurité](#7-authentification--sécurité)
8. [Modules fonctionnels (front ↔ back ↔ DB)](#8-modules-fonctionnels)
9. [Flux de bout en bout](#9-flux-de-bout-en-bout)
10. [Infrastructure & déploiement](#10-infrastructure--déploiement)
11. [CI/CD](#11-cicd)
12. [Conventions & guide de contribution](#12-conventions--guide-de-contribution)
13. [Dette technique & points de vigilance](#13-dette-technique--points-de-vigilance)
14. [Index des fichiers clés](#14-index-des-fichiers-clés)

---

## 1. Vue d'ensemble produit

ActivEducation aide les élèves et étudiants à **choisir leur orientation** (filière,
métier, école) grâce à :

- des **tests d'orientation** (RIASEC, personnalité…) qui produisent des
  recommandations de carrières et d'écoles ;
- un **catalogue e-learning** (cours → modules → leçons, avec quiz) ;
- un **assistant IA conversationnel** (« AÏDA ») qui répond aux questions
  d'orientation ;
- un **annuaire d'écoles**, d'**opportunités** (bourses, stages…) et de **mentors** ;
- une couche de **gamification** (XP, niveaux, streak, badges, classement) qui
  récompense la progression ;
- un volet **partenaires / organisations** (ex. CDEJ) qui suivent des
  bénéficiaires.

Trois surfaces applicatives :

| Surface | Public | Techno | URL prod |
|---|---|---|---|
| **App étudiant** | Élèves / étudiants | Flutter Web | `https://activeducationhub.com` |
| **Dashboard admin** | Admins, écoles, partenaires | Flutter Web | `https://admin.activeducationhub.com` |
| **API** | Les deux fronts | FastAPI | `https://api.activeducationhub.com` |

> Note : le repo référence deux domaines historiques (`activeduhub.com` et
> `activeducationhub.com`). Le déploiement courant utilise **`activeducationhub.com`**.

### Rôles utilisateur

Le type `user_type` (enum PostgreSQL) et la colonne `user_profiles.role` portent
les rôles. Valeurs utilisées dans le code :

- `student` — utilisateur standard de l'app.
- `school_admin` — gère une école et ses cours (portail `/school/*`).
- `partner_admin` — administre une organisation partenaire et ses bénéficiaires.
- `admin` / `super_admin` — back-office complet (`/admin/*`).

> ⚠️ Incohérence historique connue : la migration initiale `001` définit
> `user_type AS ENUM ('student','professional','mentor','admin')` sur une table
> `profiles`, mais **tout le code applicatif** utilise la table **`user_profiles`**
> et des rôles `school_admin`/`partner_admin`/`super_admin`. La table `profiles`
> de la migration 001 est morte (voir §13).

---

## 2. Architecture globale

```
┌──────────────────────────────────────────────────────────────────────┐
│                            UTILISATEURS                                │
│   Élèves (navigateur)            Admins / Écoles / Partenaires         │
└───────────────┬──────────────────────────────┬───────────────────────┘
                │ HTTPS                          │ HTTPS
        ┌───────▼────────┐              ┌────────▼────────┐
        │ App étudiant   │              │ Dashboard admin │   (Flutter Web,
        │ (nginx statique)│             │ (nginx statique)│    servis par nginx)
        └───────┬────────┘              └────────┬────────┘
                │ REST/JSON (Dio)                │ REST/JSON
                └───────────────┬────────────────┘
                                │
                        ┌───────▼────────┐
                        │   Traefik v3   │  reverse proxy + TLS (Let's Encrypt)
                        └───────┬────────┘
                                │
                        ┌───────▼────────┐        ┌───────────────┐
                        │  Backend API   │◄──────►│     Redis     │ cache
                        │  FastAPI       │        └───────────────┘
                        │ (uvicorn)      │
                        └───────┬────────┘
                                │ SDK Supabase (REST/Auth) + RPC SQL
                        ┌───────▼────────┐
                        │   Supabase     │  PostgreSQL + Auth + RLS
                        │  (PostgreSQL)  │
                        └────────────────┘
```

Principes directeurs :

- **Le backend ne se connecte PAS à PostgreSQL en direct** en fonctionnement
  normal : il passe par le **SDK Supabase** (API REST + Auth) avec une clé
  *anon* (lecture publique soumise à RLS) ou *service_role* (écritures
  privilégiées). La connexion PostgreSQL directe (`DATABASE_URL`) n'est utilisée
  que pour **jouer les migrations Alembic**.
- **Front ↔ Back** : exclusivement REST/JSON. Les fronts ne parlent jamais à
  Supabase directement pour les données métier (seul l'auth peut transiter par
  le SDK Supabase Flutter).
- **Séparation des responsabilités côté backend** : Endpoint → Service →
  Repository → Supabase (voir §4).
- **Clean Architecture côté Flutter** : presentation (BLoC/Cubit) → domain
  (usecases/entities) → data (repositories/datasources/models) (voir §6).

---

## 3. Stack technique

### Backend (`backend/requirements.txt`)

| Composant | Version | Rôle |
|---|---|---|
| FastAPI | 0.115.6 | Framework API |
| Uvicorn | 0.34.0 | Serveur ASGI |
| Pydantic | 2.10.4 | Validation / schémas |
| pydantic-settings | 2.7.0 | Configuration via env |
| supabase (py) | 2.11.0 | SDK Supabase (DB + Auth) |
| Alembic | 1.14.0 | Migrations SQL versionnées |
| redis | 5.2.1 | Cache (fallback mémoire) |
| slowapi | 0.1.9 | Rate limiting |
| sentry-sdk | 2.20.0 | Monitoring (optionnel) |
| python-jose | — | Validation JWT locale |
| Groq SDK | — | LLM pour AÏDA |

Python **3.11** (conteneur prod). Note : en local certains contributeurs sont
sur Python 3.14 → voir §10 (driver psycopg pour Alembic).

### Front (`activ_education_app/pubspec.yaml`, `admin_dashboard/pubspec.yaml`)

| Package | Rôle |
|---|---|
| flutter_bloc 9 / bloc 9 | State management (BLoC + Cubit) |
| get_it 9 + injectable 2.5 | Injection de dépendances (génère `injection_container.config.dart`) |
| dio 5.7 | Client HTTP (+ `AuthInterceptor`) |
| supabase_flutter 2.8 | Auth Supabase côté client |
| go_router 17 | Routing déclaratif (`ShellRoute` + `GoRoute`) |
| hive / shared_preferences / flutter_secure_storage | Stockage local (tokens, cache) |
| freezed + json_serializable | Génération de modèles/équality |
| dartz | `Either` (gestion fonctionnelle des erreurs) |
| google_fonts + police bundlée | Typo « Hanken Grotesque » (bundlée localement, voir §13) |
| iconsax, flutter_animate, shimmer, fl_chart, cached_network_image | UI |

Le package partagé **`packages/shared_core`** (chemin `path:`) factorise du code
commun entre les deux apps Flutter.

---

## 4. Backend — FastAPI

### 4.1 Arborescence

```
backend/app/
├── main.py                  # App FastAPI, middlewares, exception handlers
├── api/v1/
│   ├── router.py            # Agrège tous les routers (préfixes + tags)
│   └── endpoints/           # 34 fichiers : 1 par domaine (+ admin/, school/, partner/)
├── services/                # Logique métier (10 fichiers)
├── repositories/            # Accès données via SDK Supabase (14 fichiers)
├── schemas/                 # Modèles Pydantic (req/resp) (15 fichiers)
├── core/                    # config, security, cache, logging, exceptions
├── middleware/              # rate_limiter, request_logging, security_headers
└── db/
    ├── supabase_client.py   # Clients anon + service_role
    └── migrations/          # SQL bruts historiques (003 admin_tables…)
```

### 4.2 Le pattern en couches

```
Requête HTTP
   │
   ▼
Endpoint (api/v1/endpoints/*.py)
   • Dépendances FastAPI : Depends(get_current_user_id), rate limit…
   • Validation entrée/sortie via schémas Pydantic
   │
   ▼
Service (services/*.py)              ← logique métier, orchestration
   │
   ▼
Repository (repositories/*.py)       ← requêtes Supabase, cache
   │
   ▼
SDK Supabase  →  PostgreSQL (+ RLS)
```

- **Endpoints** : minces, déclaratifs. Gèrent l'auth (dépendances), la
  validation, et délèguent. Les domaines « simples » (lecture) appellent parfois
  directement le repository.
- **Services** : `auth_service`, `partner_service`, `orientation_engine`
  (calcul des scores de test), `career_matcher` (matching carrières↔traits),
  `llm_service` (+ `groq_provider`, `prompt_builder`, `safety_filter`,
  `session_manager` pour AÏDA).
- **Repositories** : encapsulent l'accès Supabase. Deux clients :
  - `get_supabase_client()` → **anon** (lecture publique soumise à RLS).
  - `get_admin_supabase_client()` → **service_role** (écritures, RPC
    privilégiées ; exige `SUPABASE_SERVICE_ROLE_KEY`).
- **Schémas** : Pydantic v2, `fieldRename`/validators, séparation req/resp.

### 4.3 `main.py` — point d'entrée

Configure dans l'ordre :

1. **Middlewares** : CORS, `request_logging` (corrélation), `security_headers`
   (CSP…), rate limiting (slowapi).
2. **Exception handlers** : messages d'erreur **français et lisibles** pour
   `RequestValidationError` (ex. « L'adresse email n'est pas valide »),
   `StarletteHTTPException` (404/405/403/401), et `AppException` métier. Chaque
   réponse porte un `correlation_id`.
3. **Lifespan** : log de démarrage, init éventuelle (Sentry si `SENTRY_DSN`).
4. **Router** : `api_router` monté sous `/api/v1`.

### 4.4 Cartographie des endpoints (publics / étudiant)

Préfixe commun : `/api/v1`.

| Domaine | Routes | Auth |
|---|---|---|
| **auth** | `POST /auth/login` `/register` `/logout` `/refresh` `/forgot-password` `/reset-password` `/change-password` · `GET /auth/me` · `PATCH /auth/me` | publique (sauf me/change-password) |
| **orientation** | `GET /orientation/tests` `/tests/{id}` · `GET /orientation/mobile/tests…` · `POST /orientation/sessions/{test_id}/submit` · `GET /orientation/careers…` `/recommendations` | optionnelle (submit enrichi si connecté) |
| **schools** | `GET /schools` · `GET /schools/{id}` | publique |
| **chat** (AÏDA) | `POST /chat/message` · `POST /chat/message/stream` · `DELETE /chat/session/{id}` | requise |
| **elearning** | `GET /elearning/courses…` `/lessons…` · `POST /elearning/lessons/{id}/complete` · `POST /elearning/.../enroll` | optionnelle (catalogue public, complétion authentifiée) |
| **gamification** | `GET /gamification/profile` · `GET /gamification/leaderboard` | requise |
| **mentors** | `GET /mentors` `/{id}` `/{id}/reviews` | publique |
| **opportunities** | `GET /opportunities` `/{id}` | publique |
| **announcements** | `GET /announcements` | publique |
| **settings** | `GET /settings/public` | publique |
| **partner** | `GET /partner/organizations/my-organization` (+ création/bénéficiaires) | requise (rôles partenaire) |

### 4.5 Endpoints back-office

- `/admin/*` : `auth`, `dashboard`, `users`, `schools`, `careers`, `tests`,
  `gamification`, `mentors`, `settings`, `knowledge-base`, `opportunities`,
  `elearning`, `partner`, `upload`. **Tous protégés par vérification de rôle**
  (`admin`/`super_admin`).
- `/school/*` : portail école — `auth`, `courses`, `modules`, `lessons`,
  `dashboard`, `profile` (rôle `school_admin`).

### 4.6 Cache (`core/cache.py`)

`CacheClient` Redis avec **fallback mémoire** automatique si Redis indisponible.
TTL par catégorie (listes ~10 min, détails ~5 min, gamification court). Clés
typées par utilisateur (ex. `gamification:profile:{user_id}`,
`gamification:leaderboard:*`). Invalidation centralisée pour la gamification dans
`core/gamification_cache.py` (`invalidate_gamification_profile`,
`invalidate_leaderboard`) — appelée après chaque écriture XP/streak.

---

## 5. Modèle de données

~34 tables PostgreSQL (Supabase). Créées via **deux mécanismes** : migrations
Alembic versionnées (`backend/alembic/versions/001…014`) **et** SQL bruts
historiques (`backend/app/db/migrations/003_admin_tables.sql`). RLS (Row Level
Security) activée sur la plupart des tables.

### 5.1 Tables par domaine

**Identité / auth**
- `user_profiles` — profil métier (id = `auth.users.id`), `role`, `total_xp`,
  `current_streak`, `longest_streak`, `last_login_at`. **Table pivot du système.**
- `auth_refresh_tokens` — rotation des refresh tokens.
- `profiles` — *(legacy, non utilisée — voir §13).*

**Orientation**
- `orientation_tests`, `test_questions`, `question_options` — tests et items.
- `user_test_sessions` — sessions complétées (sert à l'idempotence du XP test).
- `careers`, `career_sectors` — métiers et secteurs (matching).

**E-learning**
- `elearning_courses` → `elearning_modules` → `elearning_lessons` →
  `elearning_lesson_content` — hiérarchie pédagogique.
- `elearning_enrollments` — inscriptions (avec `progress_pct`).
- `elearning_user_progress` — progression par leçon (`status`, `completed_at`).

**Gamification**
- `challenges`, `user_challenges` — défis et participation.
- `achievements`, `user_achievements` — badges.
- *(le XP/level/streak vit sur `user_profiles`, pas sur une table dédiée).*

**Écoles / opportunités / mentors**
- `schools`, `school_programs`, `school_images`.
- `opportunities` (bourses, stages…).
- `mentors`, `mentor_availability`, `mentor_relationships`, `mentor_reviews`.

**Messagerie**
- `conversations`, `conversation_participants`, `messages`.

**Partenaires**
- `partner_organizations` — organisations (statut d'approbation).
- `beneficiary_dossiers` — bénéficiaires suivis.

**Transverse**
- `announcements`, `app_settings` — annonces et réglages publics.
- `admin_audit_log` — journal des actions admin.

### 5.2 Fonctions RPC PostgreSQL (SECURITY DEFINER)

Certaines opérations sensibles/atomiques sont des **fonctions SQL** appelées via
`db.client.rpc(...)`, `GRANT`ées à `service_role` uniquement :

- `award_xp(user_id, amount)` — incrément **atomique** de `user_profiles.total_xp`
  (migration 014). Évite les races lecture-puis-écriture.
- `get_leaderboard_rank(user_id)` — rang d'un utilisateur (migration 014).
- `approve_partner_organization(...)` — promotion atomique d'un `partner_admin`
  (migration 013).

### 5.3 Migrations Alembic

`001` schéma initial · `002` admin + gamification · `003` mobile · `004` fixes
RLS · `005` e-learning · `006` nettoyage auth Supabase · `007` ré-activation RLS
· `008` organisations/bénéficiaires · `009` index scalabilité · `010` RLS partner
· `011` cascade delete cours · `012` colonnes mentors/opportunités · `013` RPC
approbation org · **`014` colonnes XP/streak + RPC `award_xp`/`get_leaderboard_rank`
+ index leaderboard**.

> `alembic upgrade head` exige `DATABASE_URL` (connexion **pooler** Supabase, pas
> la connexion directe IPv6). Voir §10.

---

## 6. Applications Flutter

### 6.1 Clean Architecture par feature

Chaque feature suit (quand pertinent) trois couches :

```
features/<feature>/
├── domain/
│   ├── entities/        # objets métier purs (immutables)
│   ├── repositories/    # interfaces (contrats)
│   └── usecases/        # cas d'usage (1 action = 1 classe)
├── data/
│   ├── models/          # DTO (json_serializable) + mapping vers entities
│   ├── datasources/     # appels Dio (remote) / Hive (local)
│   └── repositories/    # implémentations des contrats domain
└── presentation/
    ├── bloc/  (ou cubit/) # état (BLoC events/states, ou Cubit)
    ├── pages/             # écrans
    └── widgets/           # composants réutilisables
```

Features de l'**app étudiant** (`activ_education_app/lib/features/`) :
`auth`, `onboarding`, `home`, `orientation`, `elearning`, `gamification`,
`ai_chat`, `schools`, `opportunities`, `mentors`, `mentoring`, `messaging`,
`partner`, `profile`.

Features du **dashboard admin** (`admin_dashboard/lib/features/`) :
`auth`, `dashboard`, `users`, `schools`, `careers`, `orientation_tests`,
`elearning`, `gamification`, `mentors`, `opportunities`, `partner`,
`school_portal`, `settings`.

> La feature `gamification` n'a **pas** de couche `domain` séparée (le modèle
> `GamificationProfile` vit en `data/models`) — choix assumé vu sa simplicité.

### 6.2 Injection de dépendances

`get_it` + `injectable`. Les annotations (`@injectable`, `@lazySingleton`,
`@module`, `@Named`) sont compilées par **build_runner** dans
`lib/core/di/injection_container.config.dart`.

`core/di/register_module.dart` déclare les singletons manuels, notamment **deux
clients Dio** :
- `@Named('apiClient')` — client principal, avec `AuthInterceptor`.
- `@Named('refreshClient')` — client dédié au refresh des tokens (évite la
  récursion d'intercepteur).

> Après toute modif d'une classe annotée, relancer :
> `flutter pub run build_runner build --delete-conflicting-outputs`.

### 6.3 Routing

`go_router` (`lib/router/app_router.dart`, ~67 routes). Un **`ShellRoute`**
enveloppe les routes authentifiées dans `MainShellWrapper`
(`lib/router/widgets/main_shell.dart`) : sidebar verticale sur desktop (≥768px),
bottom-bar + FAB AÏDA sur mobile. La config de routing a été séparée de l'UI du
shell (refacto).

### 6.4 État (BLoC / Cubit)

- **BLoC** (events → states) pour les flux riches : `AuthBloc`, `CourseBloc`,
  `LessonBloc`, `OrientationBloc`, `PartnerBloc`…
- **Cubit** (méthodes directes) pour les cas simples : `GamificationCubit`
  (`load()` / `refresh()` / `reset()`), enregistré en `@lazySingleton` partagé
  toute la session (réinitialisé au logout).

---

## 7. Authentification & sécurité

### 7.1 Modèle d'auth

**Supabase Auth natif** (migré depuis un JWT maison). Le client Flutter
s'authentifie via `supabase_flutter`, récupère un **access token** (JWT) + un
**refresh token**, et les envoie au backend en `Authorization: Bearer <token>`.

### 7.2 Validation du token côté backend (`core/security.py`)

Deux stratégies, dans l'ordre :

1. **Validation locale** (si `SUPABASE_JWT_SECRET` configuré) : décodage JWT
   `HS256`, audience `authenticated`, **0 appel réseau** → rapide. Retourne
   `{user_id, email, role}`. Lève `TokenExpiredError` / `InvalidTokenError`.
2. **Fallback API Supabase** : `supabase.auth.get_user(token)` si pas de secret
   local. Résultat mis en cache court (60 s).

Dépendances FastAPI fournies :
- `get_current_user_id` — exige un token valide (401 sinon).
- `get_current_user_id_optional` — token **optionnel** : routes publiques
  enrichies si connecté (catalogue, recommandations…).
- `get_current_user_role` — pour le contrôle d'accès back-office.

### 7.3 Côté Flutter (`core/auth/`)

- `TokenStorage` — stocke tokens + expiration (`flutter_secure_storage`).
- `AuthInterceptor` (Dio) :
  - attache le Bearer aux routes protégées ;
  - **refresh proactif** si le token est expiré (via `refreshClient`) ;
  - **routes à auth optionnelle** (`/elearning/courses`, `/elearning/lessons`,
    `/mentors`, `/opportunities`, `/schools`) : si le refresh échoue, la requête
    part **sans token** au lieu d'échouer — le contenu public ne casse pas quand
    la session expire ;
  - sur `401`, tente un refresh + rejoue la requête une fois.

### 7.4 Durcissement infra

- **docker-socket-proxy** : le conteneur Traefik n'accède pas directement au
  socket Docker (réduction de surface d'attaque).
- **security_headers** (middleware) : CSP, etc.
- **Rate limiting** (slowapi) sur les endpoints sensibles.
- **RLS** activée côté PostgreSQL.
- **Secrets** : jamais committés. `SUPABASE_SERVICE_ROLE_KEY` n'est connue que du
  serveur. Le mot de passe DB ne sert qu'aux migrations (pas au runtime).
- **Back-office** : pas d'auto-inscription ni de reset public sur la page de
  login admin (choix de sécurité assumé). Création d'admin par script lisant le
  mot de passe depuis l'environnement.

---

## 8. Modules fonctionnels

Pour chaque module : rôle, fichiers clés front, endpoints back, tables.

### 8.1 Authentification
- **Front** : `features/auth/` (`AuthBloc`, login/register pages,
  `auth_remote_data_source`), `core/auth/` (`TokenStorage`, `AuthInterceptor`).
- **Back** : `endpoints/auth.py` → `services/auth_service.py` →
  `repositories/users_repository.py`.
- **Tables** : `user_profiles`, `auth_refresh_tokens`.
- **Particularité** : `update_last_login` calcule le **streak** au login (voir
  §9.3).

### 8.2 Orientation
- **Front** : `features/orientation/` — `test_execution_page` (refactorisée en
  parts : vue+progression, widgets de questions, slider), `results_page`.
- **Back** : `endpoints/orientation.py` → `services/orientation_engine.py`
  (calcul des scores RIASEC/personnalité) + `services/career_matcher.py`
  (matching carrières ↔ traits, programmes écoles).
- **Tables** : `orientation_tests`, `test_questions`, `question_options`,
  `user_test_sessions`, `careers`, `career_sectors`.
- **Gamification** : +50 XP à la **première** complétion (idempotent via
  `user_test_sessions`, best-effort — n'empêche jamais la sauvegarde du résultat).

### 8.3 E-learning
- **Front** : `features/elearning/` — `elearning_catalog_page`,
  `course_detail_page` (refactorisée en parts : hero, infos, modules, bottom),
  `lesson_page` (refactorisée : contenu, types de contenu, complétion),
  `CourseBloc` / `LessonBloc`, `course_model` (mapping snake_case ↔ camelCase).
- **Back** : `endpoints/elearning.py` → `repositories/elearning_repository.py`.
- **Tables** : `elearning_courses/modules/lessons/lesson_content`,
  `elearning_enrollments`, `elearning_user_progress`, `user_points`.
- **Gamification** : `mark_lesson_complete` crédite `user_points` **et**
  `award_xp(user_id, points_reward)` — uniquement à la 1ʳᵉ complétion (idempotent
  via `elearning_user_progress.status`), puis invalide le cache gamification.

### 8.4 Gamification
- **Front** : `features/gamification/` — `GamificationCubit`,
  `GamificationProfile` (model), affiché dans `home/widgets/hero_header.dart`
  (XP/niveau/streak temps réel ; shimmer en chargement, stats neutres en erreur).
  Rafraîchi après complétion de leçon.
- **Back** : `endpoints/gamification.py` (`/profile`, `/leaderboard`) ;
  formule de niveau O(1) `_calculate_level()` (cap 100) ; rang via RPC.
- **Écritures** : `award_xp` (RPC atomique) appelée depuis e-learning et
  orientation ; streak calculé au login (users_repository) ; cache invalidé via
  `core/gamification_cache.py`.
- **Tables** : `user_profiles` (XP/streak), `achievements`, `user_achievements`,
  `challenges`, `user_challenges`.

### 8.5 AÏDA (assistant IA)
- **Front** : `features/ai_chat/` — `chat_page` (refactorisée : écran
  non-connecté, vue chat, widgets de message), `ChatBloc`.
- **Back** : `endpoints/chat.py` → `services/llm_service.py` (+ `groq_provider`,
  `prompt_builder`, `safety_filter` anti-injection, `session_manager`).
- **LLM** : Groq (`GROQ_API_KEY`). `safety_filter` détecte les tentatives de
  prompt-injection et borne la taille des messages.

### 8.6 Écoles / Opportunités / Mentors
- **Front** : `features/schools`, `features/opportunities`, `features/mentors`.
- **Back** : `endpoints/schools.py`, `opportunities.py`, `mentors.py`
  (lectures publiques, cache).
- **Tables** : `schools/school_programs/school_images`, `opportunities`,
  `mentors/mentor_availability/mentor_relationships/mentor_reviews`.

### 8.7 Partenaires / Organisations
- **Front** : `features/partner/` (app) + `features/partner/` (admin :
  `OrganizationsListPage`, approbation). Nav dynamique : item « Partenaire »
  visible pour `partner_admin`/`admin`/`super_admin` ; redirection auto si une
  org existe déjà.
- **Back** : `endpoints/partner/organizations.py` → `services/partner_service.py`
  → `repositories/partner_repository.py`. Approbation atomique via RPC
  `approve_partner_organization`.
- **Tables** : `partner_organizations`, `beneficiary_dossiers`.

### 8.8 Annonces & réglages
- **Front** : `home/widgets/announcements_section.dart`,
  `core/widgets/maintenance_overlay.dart`.
- **Back** : `endpoints/announcements.py` (`GET /announcements`),
  `endpoints/settings.py` (`GET /settings/public` : `maintenance_mode`,
  `welcome_message`, `default_language`).
- **Tables** : `announcements`, `app_settings`.

---

## 9. Flux de bout en bout

### 9.1 Connexion (login)

```
App: form login
  → POST /api/v1/auth/login (email, password)
     → auth_service.login() → Supabase Auth (sign_in)
     → users_repository.update_last_login() [calcul streak + invalide cache gamif]
     → renvoie access_token + refresh_token (+ profil)
  ← TokenStorage stocke les tokens
  ← AuthBloc → AuthAuthenticated → redirection /home
```

### 9.2 Complétion d'une leçon → XP visible

```
App: bouton "Terminer" (lesson_page)
  → POST /api/v1/elearning/lessons/{id}/complete  (Bearer)
     → elearning_repository.mark_lesson_complete()
        • upsert elearning_user_progress (status=completed)
        • si 1re complétion : user_points += reward  ET  rpc award_xp(user, reward)
        • invalidate_gamification_profile(user) + invalidate_leaderboard()
  ← BlocListener (lesson_page) → gamificationCubit.refresh()
  ← GET /api/v1/gamification/profile → hero_header affiche le nouveau XP
```

### 9.3 Calcul du streak (au login)

`users_repository.update_last_login()` (jours calendaires UTC) :
- J+0 (déjà connecté aujourd'hui) → streak inchangé ;
- J+1 (jour consécutif) → `current_streak += 1` ;
- J≥2 (rupture) → `current_streak = 1` ;
- `longest_streak = max(longest_streak, current_streak)`.

Le streak est **calculé à un seul endroit** (login). `/gamification/profile` ne
fait que le **lire** (pas de recalcul → pas de divergence).

### 9.4 Soumission d'un test d'orientation

```
App: réponses → POST /orientation/sessions/{test_id}/submit  (auth optionnelle)
  → orientation_engine.calculate_result()  (scores RIASEC/personnalité)
  → career_matcher.enrich_result()         (carrières + programmes écoles)
  → si connecté :
       • create_test_session + complete_test_session (sauvegarde)
       • si 1re complétion : rpc award_xp(user, 50)  [best-effort]
  ← résultat (scores, traits dominants, recommandations)
```

---

## 10. Infrastructure & déploiement

### 10.1 Topologie (docker-compose.yml)

| Service | Image / build | Conteneur | Rôle |
|---|---|---|---|
| socket-proxy | tecnativa/docker-socket-proxy | activeducation-socket-proxy | accès Docker filtré pour Traefik |
| traefik | traefik:v3.2 | activeducation-traefik | reverse proxy + TLS auto |
| redis | redis:7.2-alpine | activeducation-redis | cache |
| backend | build `./backend` | activeducation-api | API FastAPI |
| app-frontend | nginx:1.25-alpine | activeducation-app | sert `activ_education_app/build/web` |
| admin-frontend | nginx:1.25-alpine | activeducation-admin | sert `admin_dashboard/build/web` |

- Le **backend** est **buildé** depuis le code → un changement de code nécessite
  `docker compose up -d --build backend`.
- Les **fronts** sont des **builds web statiques montés en volume** → un
  changement nécessite de remplacer `build/web` puis `docker restart` du nginx.
  ⚠️ Le `build/web` est **gitignoré** : `git pull` ne le met pas à jour ; il faut
  builder (localement, car **Flutter n'est pas installé sur le VPS**) puis `scp`.

### 10.2 Cible de production

- VPS **LWS** — `185.98.128.154`, projet dans **`/opt/activeducation`**.
- Branche déployée : **`develop`** (le VPS fait `git pull origin develop`).
- Domaine : `activeducationhub.com` (app), `admin.…` (admin), `api.…` (API).
- Auth SSH : **par mot de passe** (root).

### 10.3 Variables d'environnement clés (`backend/.env.production`)

| Variable | Obligatoire | Rôle |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_KEY` | oui | SDK Supabase (anon) |
| `SUPABASE_SERVICE_ROLE_KEY` | oui (prod) | écritures privilégiées + RPC |
| `SUPABASE_JWT_SECRET` | recommandé | validation JWT locale (0 réseau) |
| `REDIS_URL` | défaut docker | cache |
| `GROQ_API_KEY` | pour AÏDA | LLM |
| `SENTRY_DSN` | optionnel | monitoring |
| `DATABASE_URL` | migrations only | Alembic (connexion **pooler**) |

### 10.4 Migrations en prod (Alembic)

```bash
# DATABASE_URL = connexion POOLER Supabase (IPv4), pas la connexion directe (IPv6)
$env:DATABASE_URL = "postgresql://postgres.<ref>:<pwd>@aws-<n>-<region>.pooler.supabase.com:5432/postgres"
cd backend
alembic current        # état
alembic upgrade head   # appliquer
```

- `alembic/env.py` sélectionne **automatiquement le driver** : `psycopg2` si
  présent (prod), sinon `psycopg` v3 (utile en local Python 3.14 sans wheel
  psycopg2).
- Le projet **n'utilise pas l'ORM SQLAlchemy** (`target_metadata = None`), donc
  `alembic check` (--autogenerate) est inapplicable — la CI vérifie plutôt
  « une seule head + historique cohérent ».

### 10.5 Procédure de déploiement type

```bash
# 1. Backend (sur le VPS)
ssh root@185.98.128.154
cd /opt/activeducation
git pull origin develop
docker compose up -d --build backend
docker compose logs --tail=30 backend   # "Application startup complete"

# 2. Fronts (depuis la machine de dev — Flutter requis)
flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=https://api.activeducationhub.com   # (app)
# admin : --dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1
scp -r activ_education_app/build/web root@185.98.128.154:/tmp/app-new
# puis bascule + docker restart activeducation-app  (idem admin)
```

> ⚠️ **Convention d'URL différente** : l'app étudiant attend `API_BASE_URL` **sans**
> `/api/v1` ; le dashboard admin l'attend **avec** `/api/v1`. Se tromper donne un
> « Not Found » au login.

---

## 11. CI/CD

`.github/workflows/` :

- **backend-ci.yml** — `Lint & Security Scan` (ruff + bandit), `Tests` (pytest +
  couverture, seuil 48%), `Check migrations consistency` (1 seule head +
  historique), `Docker Build`.
- **frontend-ci.yml** — `Analyze Student App` + `Analyze Admin Dashboard`
  (`flutter analyze`).
- **deploy-staging.yml** — auto sur `develop`.
- **deploy-prod.yml** — manuel (`workflow_dispatch`).

Secrets requis : `DATABASE_URL` (migrations CI), `DOCKERHUB_*`,
`STAGING_HOST/USER/SSH_KEY`, `PROD_HOST/USER/SSH_KEY`.

---

## 12. Conventions & guide de contribution

- **Commits** : Conventional Commits (`feat:`, `fix:`, `refactor:`, `ci:`,
  `chore:`…) + pre-commit. Voir `CONTRIBUTING.md`.
- **Branches** : `develop` (prod déployée), `main` (intégration), branches de
  feature (`feat/…`, `redesign/…`). Merge via PR avec CI verte.
- **Backend** : Endpoint mince → Service → Repository. Validation Pydantic.
  Écritures privilégiées via `get_admin_supabase_client()`. Incréments DB
  **atomiques** (RPC), jamais lecture-puis-écriture.
- **Flutter** : Clean Architecture. Après modif d'une classe injectable, relancer
  `build_runner`. Pages volumineuses découpées en **`part`/`part of`** (mêmes
  widgets privés, fichiers physiques séparés — zéro changement de comportement).
- **Tests** : `pytest` (backend), `flutter analyze` + (mocktail/bloc_test) front.
- **Setup local** :
  ```bash
  # backend
  cd backend && python -m venv venv && venv\Scripts\activate
  pip install -r requirements.txt && uvicorn app.main:app --reload
  # front
  cd activ_education_app && flutter pub get && flutter run -d chrome
  ```

---

## 13. Dette technique & points de vigilance

| Sujet | Détail | Risque | Reco |
|---|---|---|---|
| **Table `profiles` legacy** | Migration 001 crée `profiles`/`xp_points`, mais le code utilise `user_profiles`/`total_xp`. | Confusion, schéma mort. | Documenter / supprimer la table morte. |
| **Deux mécanismes de migration** | Alembic **et** SQL bruts (`db/migrations/*.sql`). `announcements`/`app_settings` viennent du SQL brut. | Désync entre envs. | Tout migrer sous Alembic à terme. |
| **Deux « monnaies »** | `user_points` (solde) **et** `user_profiles.total_xp` (XP/level). Couplées (+1 pt = +1 XP) mais distinctes. | Incohérence si modifiées séparément. | Garder une seule source de vérité pour l'affichage (total_xp). |
| **Police « Hanken Grotesque »** | `GoogleFonts.getFont('Hanken Grotesque')` échouait (nom réel « Grotesk »). Police **bundlée** localement (`assets/fonts/`). | Crash si on repasse au runtime fetch. | Garder la police bundlée. |
| **Convention API_BASE_URL** | app sans `/api/v1`, admin avec. | « Not Found » au login si inversé. | Vérifier au build. |
| **SSH par mot de passe** | Pas de clé ; rafales d'essais → fail2ban. | Blocage temporaire. | Passer à une clé SSH. |
| **Couverture tests 48%** | Seuil bas ; gros repos peu couverts. | Régressions silencieuses. | Augmenter progressivement. |
| **Pages restantes** | 4 pages monolithiques refactorisées ; d'autres écrans restent gros. | Lisibilité. | Continuer la découpe par parts. |

---

## 14. Index des fichiers clés

**Backend**
- `backend/app/main.py` — app, middlewares, handlers d'erreurs FR.
- `backend/app/api/v1/router.py` — montage de tous les routers.
- `backend/app/core/security.py` — validation token (local + Supabase).
- `backend/app/core/config.py` — settings (env).
- `backend/app/core/cache.py` — cache Redis + fallback mémoire.
- `backend/app/core/gamification_cache.py` — invalidation cache gamif.
- `backend/app/db/supabase_client.py` — clients anon / service_role.
- `backend/app/services/orientation_engine.py` — scoring tests.
- `backend/app/services/career_matcher.py` — matching carrières.
- `backend/app/services/llm_service.py` — AÏDA (Groq).
- `backend/app/repositories/elearning_repository.py` — complétion leçon + XP.
- `backend/app/repositories/users_repository.py` — streak au login.
- `backend/alembic/versions/014_gamification_xp_streak.py` — XP/streak + RPC.
- `backend/alembic/env.py` — sélection driver psycopg.

**App étudiant**
- `lib/router/app_router.dart` + `lib/router/widgets/main_shell.dart` — routing + shell.
- `lib/core/auth/auth_interceptor.dart` + `token_storage.dart` — auth Dio.
- `lib/core/di/register_module.dart` + `injection_container.config.dart` — DI.
- `lib/features/home/presentation/widgets/hero_header.dart` — barre gamification.
- `lib/features/gamification/presentation/cubit/gamification_cubit.dart`.
- `lib/features/elearning/presentation/pages/course_detail_page.dart` (+ `course_detail/`).
- `lib/features/elearning/presentation/pages/lesson_page.dart` (+ `lesson/`).
- `lib/features/orientation/presentation/pages/test_execution_page.dart` (+ `test_execution/`).
- `lib/features/ai_chat/presentation/pages/chat_page.dart` (+ `chat/`).

**Infra**
- `docker-compose.yml` — orchestration.
- `traefik/`, `nginx/` — proxy + service des fronts.
- `.github/workflows/` — CI/CD.

**Documentation associée**
- `docs/ARCHITECTURE.md`, `docs/OPERATIONS.md`, `docs/SECURITY.md`,
  `docs/RLS_AUDIT.md`, `docs/scalability-roadmap.md`.
- `CAHIER_DES_CHARGES_GAMIFICATION.md` — spec détaillée de la gamification.
- `CONTRIBUTING.md`, `DEPLOYMENT.md`, `README.md`.

---

*Document maintenu à la main. À mettre à jour à chaque évolution structurelle
(nouvelle feature, nouvelle table/migration, changement d'infra).*
