# Documentation — Backend API (`backend/`)

> Documentation exhaustive de l'API **FastAPI** d'ActivEducation : architecture,
> démarrage, chaque couche (endpoint → service → repository → Supabase), la
> sécurité/auth, le cache, les middlewares, la gestion d'erreurs, AÏDA (LLM), et
> le rôle de chaque module.
>
> Public : développeurs backend (onboarding & maintenance), audit/reprise.
> Dernière mise à jour : 2026-06.
>
> Voir aussi : `docs/DOCUMENTATION.md` (vue projet globale),
> `activ_education_app/DOCUMENTATION_FLUTTER.md`,
> `admin_dashboard/DOCUMENTATION_ADMIN.md`.

---

## Table des matières

1. [Rôle & principes](#1-rôle--principes)
2. [Stack & dépendances](#2-stack--dépendances)
3. [Arborescence complète](#3-arborescence-complète)
4. [Point d'entrée `main.py`](#4-point-dentrée-mainpy)
5. [Configuration (`core/config.py`)](#5-configuration)
6. [L'architecture en couches](#6-larchitecture-en-couches)
7. [Couche Endpoints (`api/v1/`)](#7-couche-endpoints)
8. [Couche Services](#8-couche-services)
9. [Couche Repositories](#9-couche-repositories)
10. [Accès données : le client Supabase](#10-accès-données--le-client-supabase)
11. [Schémas Pydantic](#11-schémas-pydantic)
12. [Sécurité & authentification (`core/security.py`)](#12-sécurité--authentification)
13. [Cache (`core/cache.py`)](#13-cache)
14. [Middlewares](#14-middlewares)
15. [Gestion d'erreurs (`core/exceptions.py`)](#15-gestion-derreurs)
16. [AÏDA — le service LLM](#16-aïda--le-service-llm)
17. [Migrations Alembic](#17-migrations-alembic)
18. [Logging & observabilité](#18-logging--observabilité)
19. [Référence des endpoints](#19-référence-des-endpoints)
20. [Build, configuration & exécution](#20-build-configuration--exécution)
21. [Conventions & pièges connus](#21-conventions--pièges-connus)
22. [Index des fichiers de fondation](#22-index-des-fichiers-de-fondation)

---

## 1. Rôle & principes

Le backend est l'**API REST unique** consommée par les deux fronts Flutter
(étudiant + admin). Il :

- valide les requêtes (Pydantic), applique l'authentification (Supabase Auth) et
  le contrôle de rôle ;
- orchestre la logique métier (services) ;
- accède aux données via le **SDK Supabase** (pas de connexion PostgreSQL
  directe en runtime — uniquement pour les migrations Alembic) ;
- met en cache (Redis + fallback mémoire) ;
- expose des erreurs **lisibles en français** avec `correlation_id`.

87 modules Python dans `app/`.

**Principe de séparation** :
```
Endpoint (HTTP, auth, validation)
   → Service (logique métier)
       → Repository (accès Supabase, cache)
           → SDK Supabase → PostgreSQL (+ RLS)
```

---

## 2. Stack & dépendances

| Composant | Version | Rôle |
|---|---|---|
| FastAPI | 0.115.6 | Framework API |
| Uvicorn[standard] | 0.34.0 | Serveur ASGI |
| Pydantic | 2.10.4 | Validation / schémas |
| pydantic-settings | 2.7.0 | Configuration via env |
| supabase | 2.11.0 | SDK (DB REST + Auth) |
| Alembic | 1.14.0 | Migrations SQL versionnées |
| redis | 5.2.1 | Cache |
| slowapi | 0.1.9 | Rate limiting |
| python-jose | — | Validation JWT locale (HS256) |
| sentry-sdk[fastapi] | 2.20.0 | Monitoring (optionnel) |
| groq | — | LLM (AÏDA) |

Python **3.11** (conteneur). En local : Alembic gère psycopg2 **ou** psycopg v3
(voir `alembic/env.py`).

---

## 3. Arborescence complète

```
backend/
├── app/
│   ├── main.py                 # App FastAPI, middlewares, exception handlers, /health
│   ├── api/v1/
│   │   ├── router.py           # Agrège tous les routers (préfixes + tags)
│   │   └── endpoints/
│   │       ├── *.py            # Public/étudiant : auth, orientation, elearning,
│   │       │                   #   gamification, chat, schools, mentors,
│   │       │                   #   opportunities, announcements, settings
│   │       ├── admin/          # Back-office (15 fichiers : users, schools, careers,
│   │       │                   #   tests, gamification, elearning, opportunities,
│   │       │                   #   mentors, dashboard, settings, knowledge_base,
│   │       │                   #   upload, partner, auth)
│   │       ├── school/         # Portail école (auth, courses, modules, lessons,
│   │       │                   #   dashboard, profile)
│   │       └── partner/        # organizations
│   ├── services/               # Logique métier
│   │   ├── auth_service.py
│   │   ├── orientation_engine.py
│   │   ├── career_matcher.py
│   │   ├── partner_service.py
│   │   ├── llm_service.py
│   │   └── llm/                # groq_provider, prompt_builder, safety_filter, session_manager
│   ├── repositories/           # Accès Supabase (+ admin/)
│   ├── schemas/                # Modèles Pydantic (+ admin/)
│   ├── core/                   # config, security, cache, gamification_cache, logging, exceptions
│   ├── middleware/             # rate_limiter, request_logging, security_headers
│   └── db/                     # supabase_client, local_fallback, migrations/ (SQL bruts)
├── alembic/                    # env.py + versions/001..014
├── tests/                      # pytest (153+ tests)
├── scripts/                    # create_super_admin, create_admin (lecture env)
├── requirements.txt
└── Dockerfile
```

---

## 4. Point d'entrée `main.py`

Séquence et responsabilités, dans l'ordre du fichier :

### a) Init Sentry (avant tout import applicatif)
Si `SENTRY_DSN` est défini, `sentry_sdk.init(...)` est appelé **en premier**
(integrations Starlette/FastAPI, `traces_sample_rate=0.1`, `send_default_pii=False`).
L'ordre est intentionnel : les modules importés ensuite sont instrumentés.

### b) Logging
`setup_logging()` configure le format (JSON en prod, coloré en dev).

### c) Lifespan
`@asynccontextmanager lifespan` : log de démarrage (version, env, debug) et
d'arrêt.

### d) Création de l'app
`FastAPI(...)` — `docs_url`/`redoc_url`/`openapi_url` **activés uniquement si
`DEBUG`** (pas de doc exposée en prod).

### e) Middlewares (ordre = important)
> Rappel Starlette : **le dernier ajouté s'exécute en premier**.

1. **Rate Limiter** (slowapi) + handler `RateLimitExceeded`.
2. **CORS** : origines depuis `BACKEND_CORS_ORIGINS`. `allow_credentials`
   désactivé si wildcard `*`. Expose `X-Correlation-ID`, `X-Process-Time`.
3. **GZip** (réponses > 1 Ko).
4. **SecurityHeaders** (CSP, X-Frame-Options…).
5. **RequestLogging** (corrélation — premier à s'exécuter).

### f) Routes
`app.include_router(api_router, prefix="/api/v1")` + endpoints racine :
- `GET /` — message de bienvenue.
- `GET /health` — **health check** : teste Supabase + Redis ; renvoie
  `healthy` / `degraded` (au moins un service up) / `unhealthy` (503).

### g) Exception handlers globaux (5)
1. `AppException` → JSON structuré `{error, message, correlation_id}` au
   `status_code` de l'exception.
2. `RequestValidationError` (422) → **messages français lisibles**
   (`_friendly_field_error` + `_FIELD_LABELS`), ex. « L'adresse email n'est pas
   valide (ex: nom@domaine.com). », avec un dict `fields` par champ.
3. `StarletteHTTPException` (404/405/403/401) → JSON `{error, message}` avec
   messages FR par défaut (« Ressource introuvable. », « Accès refusé. »…).
4. `Exception` (catch-all) → 500 ; **détails masqués en prod**, exposés en dev.
5. Tous passent par `_apply_cors_headers` (garantit les en-têtes CORS même sur
   les erreurs — contournement d'un cas Starlette).

> Chaque réponse d'erreur porte un `correlation_id` (traçabilité bout-en-bout).

---

## 5. Configuration

`core/config.py` — `Settings(BaseSettings)` (pydantic-settings, lit l'env / `.env`).

| Variable | Type | Rôle |
|---|---|---|
| `ENVIRONMENT` | str | development / staging / production |
| `DEBUG` | bool | active docs + détails d'erreur |
| `PROJECT_NAME`, `VERSION`, `API_V1_STR` | str | métadonnées |
| `SUPABASE_URL`, `SUPABASE_KEY` | str | SDK (anon) — **requis** |
| `SUPABASE_SERVICE_ROLE_KEY` | str? | écritures privilégiées + RPC |
| `SUPABASE_JWT_SECRET` | str? | validation JWT **locale** (0 réseau) |
| `SECRET_KEY` | str | signe les tokens internes (reset password) — **≥32 car., validé** |
| `REDIS_URL` | str? | cache (sinon fallback mémoire) |
| `GROQ_API_KEY` | str? | AÏDA |
| `BACKEND_CORS_ORIGINS` | list | origines autorisées |
| `SENTRY_DSN` | str? | monitoring |

**Validations strictes** (`field_validator` + `model_validator`) :
- `SECRET_KEY` ≥ 32 caractères, refuse la valeur par défaut, alerte si ça
  ressemble à un JWT.
- En **production** : `DEBUG` doit être `False` **et** `BACKEND_CORS_ORIGINS` ne
  peut être vide ni contenir `*`.

Propriété `is_production` utilisée à plusieurs endroits (ex. masquage des erreurs).

---

## 6. L'architecture en couches

```
                    Requête HTTP (Dio depuis Flutter)
                              │
        ┌─────────────────────▼─────────────────────┐
        │  MIDDLEWARES (logging, security, gzip, CORS, rate-limit)
        └─────────────────────┬─────────────────────┘
                              ▼
   ENDPOINT (api/v1/endpoints/*.py)
     • Depends(get_current_user_id / _role / _optional)   → AUTH
     • paramètres validés par un SCHÉMA Pydantic           → VALIDATION
     • rate limit (standard/strict/relaxed)
                              │ délègue
                              ▼
   SERVICE (services/*.py)         ← logique métier, orchestration
                              │ appelle
                              ▼
   REPOSITORY (repositories/*.py)  ← requêtes Supabase + cache
                              │
                              ▼
   SupabaseClient (db/supabase_client.py)
     • client anon  (get_supabase_client)     — lecture publique (RLS)
     • client admin (get_admin_supabase_client) — service_role (écritures, RPC)
                              │
                              ▼
                     Supabase → PostgreSQL (+ RLS)
```

- Les domaines **simples** (lecture seule : schools, mentors, opportunities)
  peuvent appeler le repository directement depuis l'endpoint (sans service).
- Les domaines **riches** (auth, orientation, partner, chat) passent par un
  service.

---

## 7. Couche Endpoints

`api/v1/router.py` agrège tous les sous-routers avec préfixe + tag. Trois familles :

- **Public / étudiant** : `auth`, `orientation`, `elearning`, `gamification`,
  `chat`, `schools`, `mentors`, `opportunities`, `announcements`, `settings`.
- **`admin/`** (15 fichiers) : back-office, **tous protégés par rôle**
  admin/super_admin.
- **`school/`** : portail école (rôle `school_admin`).
- **`partner/`** : organisations.

### Anatomie d'un endpoint

```python
@router.post("/sessions/{test_id}/submit", response_model=OrientationResult)
async def submit_orientation(
    test_id: UUID,
    submission: OrientationSubmission,                 # validé par Pydantic
    user_id: Optional[UUID] = Depends(get_current_user_id_optional),  # auth optionnelle
    repo: OrientationRepository = Depends(get_orientation_repository),
):
    result = await orientation_engine.calculate_result(...)
    await career_matcher.enrich_result(result, repo)
    ...
```

Les **dépendances FastAPI** (`Depends`) injectent l'auth, les repositories, et
appliquent les contrôles. Les `response_model` garantissent la forme de sortie.

---

## 8. Couche Services

| Service | Responsabilité |
|---|---|
| `auth_service.py` | login/register/logout/refresh/reset/change password, get/update profile. Pont vers **Supabase Auth**. Mappe les réponses en schémas. |
| `orientation_engine.py` | Calcul des scores des tests (RIASEC, personnalité, génériques), traits dominants. |
| `career_matcher.py` | Matching carrières ↔ traits + récupération des programmes scolaires (enrichit le résultat d'un test). |
| `partner_service.py` | Organisations & bénéficiaires : contrôle d'accès (assert_org_access), approbation via RPC. |
| `llm_service.py` | AÏDA : orchestre Groq + sessions + safety filter (voir §16). |

`auth_service` (méthodes principales) : `login`, `register`, `logout`,
`refresh_tokens`, `request_password_reset`, `reset_password`, `change_password`,
`get_profile`, `update_profile`. Factory : `get_auth_service()`.

---

## 9. Couche Repositories

Encapsulent **toute** la communication avec Supabase. Pattern type :

```python
class OrientationRepository:
    def __init__(self):
        self._db: SupabaseClient = get_admin_supabase_client()   # ou get_supabase_client()
    async def get_tests(self):
        return self._db.fetch_all(table="orientation_tests", ...)
```

Repositories existants :
- **Public/étudiant** : `orientation_repository`, `elearning_repository`,
  `schools_repository`, `users_repository`, `partner_repository`,
  `knowledge_base_repository`.
- **`admin/`** : `users_admin_repository`, `schools_repository`,
  `careers_repository`, `tests_repository`, `opportunities_repository`,
  `stats_repository`.
- **École** : `school_admin_repository`.

**Choix du client (crucial pour la sécurité)** :
- `get_supabase_client()` → **anon** : lectures publiques soumises à RLS.
- `get_admin_supabase_client()` → **service_role** : écritures privilégiées,
  appels RPC (`award_xp`, `approve_partner_organization`…). Exige
  `SUPABASE_SERVICE_ROLE_KEY` (pas de fallback silencieux sur la clé anon).

---

## 10. Accès données : le client Supabase

`db/supabase_client.py` — classe `SupabaseClient` (**singleton thread-safe**,
verrou `Lock`). Deux instances : standard (anon) et admin (service_role).

### Méthodes helper (utilisées par les repositories)
- `fetch_all(table, columns, filters, order_by, limit)` — liste, avec `order_by`
  au format `"col.desc"`.
- `fetch_one(table, id_column, id_value)` — un enregistrement.
- `client` — accès au client brut Supabase pour les requêtes avancées
  (`.table().select().eq()...`, `.rpc(...)`, `.auth...`).
- `health_check()` — testée par `/health` (avec `@with_retry`).

### Résilience
Décorateur `@with_retry(max_retries, base_delay)` sur les opérations sensibles.
`db/local_fallback.py` fournit des **tests d'orientation en dur** (fallback si la
DB est indisponible) — l'orientation reste utilisable hors-ligne/dégradé.

---

## 11. Schémas Pydantic

`schemas/` — séparation requête/réponse, validators. Familles :
- **Public** : `auth.py`, `orientation.py`, `elearning.py`, `gamification.py`,
  `schools.py`, `partner.py`, `school_admin.py`.
- **`admin/`** : `users`, `schools`, `careers`, `orientation`, `elearning`,
  `opportunities`, `dashboard`.

Caractéristiques :
- `fieldRename` / alias snake_case (cohérence avec le front).
- Validators (ex. `auth.py` : robustesse mot de passe, normalisation
  téléphone/nom, validation email).
- `response_model` sur les endpoints → garantit la forme de sortie et masque les
  champs internes.

---

## 12. Sécurité & authentification

`core/security.py` — cœur de l'auth.

### Validation d'un token (`_validate_token_via_supabase`)
Deux stratégies, dans l'ordre :
1. **Locale** (si `SUPABASE_JWT_SECRET`) : `jose.jwt.decode(HS256,
   audience="authenticated")` → `{user_id, email, role}`. **0 appel réseau**.
   Lève `TokenExpiredError` (expiré) ou retombe sur l'API en cas d'autre erreur.
2. **API Supabase** : `client.auth.get_user(token)` (fallback).

`get_user_from_token` ajoute un **cache** (évite de revalider à chaque requête).

### Dépendances FastAPI fournies
| Dépendance | Effet |
|---|---|
| `get_current_user_id` | exige un token valide → `UUID` (401 sinon) |
| `get_current_user_id_optional` | token optionnel (routes publiques enrichies) |
| `get_current_user_role` | renvoie le rôle (**cache 60 s** → évite un roundtrip DB) |
| `get_current_admin` (+ variantes) | exige un rôle admin/super_admin |

> `get_current_user_role` lit `user_profiles.role` (via `asyncio.to_thread` pour
> ne pas bloquer l'event loop) et met le rôle en cache 60 s.

### Durcissement
- RLS PostgreSQL.
- Rate limiting (slowapi).
- Headers de sécurité (CSP…).
- Secrets jamais committés ; `service_role` connue du serveur uniquement.

---

## 13. Cache

`core/cache.py` — `CacheClient` : **Redis avec fallback mémoire automatique**.

- Si `REDIS_URL` absent ou Redis injoignable → bascule **silencieuse** sur un
  cache mémoire local. Un `_redis_failed_at` + `_REDIS_RETRY_INTERVAL` évite de
  marteler Redis quand il est down.
- Méthodes : `get`, `set(key, value, ttl)`, `delete`, `delete_pattern`.

### TTL par catégorie
| Constante | Valeur | Usage |
|---|---|---|
| `TTL_LISTS` | 600 s | listes écoles/carrières |
| `TTL_DETAIL` | 300 s | détail école/carrière |
| `TTL_TESTS` | 1800 s | tests d'orientation (statiques) |
| `TTL_USER_PROFILE` | 120 s | profils |
| `TTL_MENTORS` / `TTL_OPPORTUNITIES` | 300 s | listes semi-statiques |
| `TTL_LEADERBOARD` | 120 s | classement |
| `TTL_GAMIFICATION` | 60 s | profil gamification |

### Invalidation gamification
`core/gamification_cache.py` : `invalidate_gamification_profile(user_id)` et
`invalidate_leaderboard()` — appelées après **chaque** écriture XP/streak
(complétion leçon/test, login). Clés : `gamification:profile:{user_id}`,
`gamification:leaderboard:*`.

---

## 14. Middlewares

| Middleware | Fichier | Rôle |
|---|---|---|
| **RequestLogging** | `request_logging.py` | génère/propage un `X-Correlation-ID`, mesure `X-Process-Time`, log requête + réponse |
| **SecurityHeaders** | `security_headers.py` | `X-Frame-Options`, `Content-Security-Policy`, etc. |
| **RateLimiter** | `rate_limiter.py` | slowapi. Storage **Redis si dispo, sinon mémoire**. Décorateurs `strict_limit` (10/min), `standard_limit`, `relaxed_limit` (200/min). Extraction d'IP personnalisée. |
| GZip | (FastAPI natif) | compression > 1 Ko |
| CORS | (FastAPI natif) | origines configurées |

---

## 15. Gestion d'erreurs

`core/exceptions.py` — hiérarchie `AppException` (base) avec `code`,
`status_code`, `message`, `to_dict()` :

```
AppException (400)
├── AuthenticationError (401)
│   ├── TokenExpiredError
│   └── InvalidTokenError
├── AuthorizationError (403)
├── NotFoundError (404)
│   └── TestNotFoundError
├── AlreadyExistsError (409)
├── ValidationError (422)
│   └── InvalidInputError
├── DatabaseError (500)
│   ├── ConnectionError
│   └── QueryError
└── TestSessionError (400)
```

Levées dans les services/repositories, elles sont converties en JSON propre par
les handlers de `main.py` (§4g). Avantage : un endpoint peut faire
`raise NotFoundError("Cours", id)` et la réponse HTTP + le statut + le message FR
sont gérés automatiquement.

---

## 16. AÏDA — le service LLM

`services/llm_service.py` + `services/llm/` — assistant conversationnel.

| Module | Rôle |
|---|---|
| `LLMService` | Orchestrateur : `chat()`, `chat_stream()` (streaming), `clear_session()`, `get_history()`, `new_session_id()`. |
| `groq_provider.py` | `GroqProvider` : appels **Groq** (`complete`, `stream`, `_call_groq`). Fallback **Ollama** prévu. |
| `prompt_builder.py` | `PromptBuilder(kb_repository)` : construit le system prompt (+ contexte d'orientation, base de connaissances). |
| `safety_filter.py` | `SafetyFilter` : détection d'injection (`_INJECTION_RE` compilée à partir de motifs connus : « ignore previous instructions », « DAN mode »…), `sanitize` (tronque à 2000 car.), `get_rejection_message` (réponse brandée AÏDA). |
| `session_manager.py` | `SessionManager` : historique par `session_id` (mémoire), `seed_from_client`, `append`, `clear`. |

**Endpoints** (`endpoints/chat.py`) : `POST /chat/message`,
`POST /chat/message/stream` (SSE), `DELETE /chat/session/{id}`.

Flux : message utilisateur → `safety_filter` (rejet si injection) → `prompt_builder`
(system + contexte) → `groq_provider` → réponse → `session_manager.append`. Le
front persiste aussi l'historique localement (SharedPreferences).

---

## 17. Migrations Alembic

`alembic/` — migrations SQL **versionnées** (`versions/001..014`). Voir
`docs/DOCUMENTATION.md §5.3` pour la liste. Points spécifiques backend :

- `alembic/env.py` : `get_database_url()` lit `DATABASE_URL` (ou reconstruit
  depuis `SUPABASE_DB_*`) et **sélectionne le driver** : psycopg2 si présent
  (prod), sinon psycopg v3 (local Python 3.14). `target_metadata = None` (pas
  d'ORM → `alembic check`/autogenerate inapplicable).
- **Coexistence** avec des SQL bruts (`app/db/migrations/*.sql`) — `announcements`
  et `app_settings` y sont créées (voir dette §21).
- RPC notables (migrations) : `award_xp`, `get_leaderboard_rank` (014),
  `approve_partner_organization` (013).

---

## 18. Logging & observabilité

- `core/logging.py` : `setup_logging()` — **JSON structuré en prod**, coloré en
  dev. `get_logger(name)`.
- Chaque requête a un `correlation_id` (header `X-Correlation-ID`) propagé dans
  tous les logs et les réponses d'erreur.
- **Sentry** (`observability` côté front, `main.py` côté back) si `SENTRY_DSN` :
  capture les exceptions non gérées, `send_default_pii=False`.

---

## 19. Référence des endpoints

> Préfixe : `/api/v1`. Détail dans `docs/DOCUMENTATION.md §4.4–4.5`.

**Health** : `GET /` · `GET /health`.

**Public / étudiant** :
- `auth` : `POST /auth/{login,register,logout,refresh,forgot-password,reset-password,change-password}` · `GET /auth/me` · `PATCH /auth/me`
- `orientation` : `GET /orientation/tests[/{id}]` · `GET /orientation/mobile/...` · `POST /orientation/sessions/{test_id}/submit` · `GET /orientation/careers[/{id}]` · `GET /orientation/recommendations`
- `elearning` : `GET /elearning/courses…` · `GET /elearning/lessons…` · `POST /elearning/lessons/{id}/complete` · `POST .../enroll`
- `gamification` : `GET /gamification/profile` · `GET /gamification/leaderboard`
- `chat` : `POST /chat/message` · `POST /chat/message/stream` · `DELETE /chat/session/{id}`
- `schools` : `GET /schools[/{id}]`
- `mentors` : `GET /mentors[/{id}][/{id}/reviews]`
- `opportunities` : `GET /opportunities[/{id}]`
- `announcements` : `GET /announcements`
- `settings` : `GET /settings/public`

**Back-office** : `/admin/*` (users, schools, careers, tests, gamification,
elearning, opportunities, mentors, dashboard, settings, knowledge-base, upload,
partner, auth) — protégés par rôle.

**Portail école** : `/school/*` (auth, courses, modules, lessons, dashboard,
profile).

> Doc interactive **Swagger** : `GET /docs` et **ReDoc** `GET /redoc` —
> **uniquement si `DEBUG=True`** (désactivées en prod).

---

## 20. Build, configuration & exécution

### Local
```bash
cd backend
python -m venv venv && venv\Scripts\activate      # Windows
pip install -r requirements.txt
# .env : SUPABASE_URL, SUPABASE_KEY, SECRET_KEY (>=32), [SUPABASE_SERVICE_ROLE_KEY], ...
uvicorn app.main:app --reload                      # http://localhost:8000
# Docs : http://localhost:8000/docs (DEBUG=True)
```

### Migrations
```bash
$env:DATABASE_URL = "postgresql://postgres.<ref>:<pwd>@aws-<n>-<region>.pooler.supabase.com:5432/postgres"
alembic upgrade head
```

### Docker (prod)
Le service `backend` (`activeducation-api`) est **buildé** depuis `./backend`.
Mise à jour : `docker compose up -d --build backend`. Vérifier :
`docker compose logs backend` → « Application startup complete ».

### Tests
```bash
pytest tests/           # 153+ tests, couverture seuil 48%
ruff check app/         # lint
```

---

## 21. Conventions & pièges connus

| Sujet | Détail | À retenir |
|---|---|---|
| **anon vs service_role** | Lectures → anon (RLS) ; écritures/RPC → admin. | Une RPC `GRANT service_role` appelée via le client anon échoue silencieusement (`permission denied`). |
| **Incréments atomiques** | XP via RPC `award_xp` (UPDATE ... = ... + n). | Ne jamais « lire puis écrire » en Python (race condition en prod). |
| **Idempotence** | XP leçon/test crédité une seule fois. | Vérifier l'état (`status=completed`, `has_completed_test`) avant d'attribuer. |
| **Best-effort gamification** | L'attribution XP ne doit jamais casser l'action principale. | Encapsuler dans un `try` isolé (la sauvegarde du test/leçon prime). |
| **Invalidation cache** | Après chaque écriture XP/streak. | Sinon l'UI montre l'ancienne valeur jusqu'à expiration du TTL. |
| **DEBUG en prod** | Désactive docs + détails d'erreur ; validé par config. | `DEBUG=False` obligatoire en prod (sinon l'app refuse de démarrer). |
| **CORS prod** | Ne peut être vide ni `*`. | Lister explicitement les origines. |
| **Deux mécanismes de schéma** | Alembic + SQL bruts. | `announcements`/`app_settings` viennent du SQL brut — vérifier leur présence par env. |
| **Table `profiles` legacy** | Code utilise `user_profiles`. | Ignorer `profiles`/`xp_points` (mort). |
| **`alembic check` inapplicable** | Pas d'ORM (`target_metadata=None`). | CI vérifie « 1 head + historique cohérent ». |

---

## 22. Index des fichiers de fondation

| Fichier | Rôle |
|---|---|
| `app/main.py` | App, middlewares, 5 handlers d'erreur, `/health` |
| `app/core/config.py` | Settings + validations strictes |
| `app/core/security.py` | Validation token (local/Supabase), dépendances auth, cache rôle |
| `app/core/cache.py` | Cache Redis + fallback mémoire + TTL |
| `app/core/gamification_cache.py` | Invalidation cache gamification |
| `app/core/exceptions.py` | Hiérarchie `AppException` |
| `app/core/logging.py` | Logging JSON/coloré + correlation_id |
| `app/db/supabase_client.py` | Clients anon/admin + helpers + health |
| `app/db/local_fallback.py` | Tests d'orientation en dur (mode dégradé) |
| `app/api/v1/router.py` | Agrégation des routers |
| `app/services/auth_service.py` | Auth (Supabase) |
| `app/services/orientation_engine.py` | Scoring tests |
| `app/services/career_matcher.py` | Matching carrières |
| `app/services/llm_service.py` + `llm/` | AÏDA |
| `app/repositories/*` | Accès Supabase par domaine |
| `app/schemas/*` | Modèles Pydantic |
| `app/middleware/*` | logging, security headers, rate limit |
| `alembic/env.py` + `versions/` | Migrations |

---

*Document maintenu à la main. À mettre à jour à chaque évolution structurelle du
backend (nouveau endpoint/service/repository, nouvelle migration, changement
d'auth/cache/middleware).*
