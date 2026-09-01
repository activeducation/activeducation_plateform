# ActivEducation — Fonctionnalités en production & implémentation

> Document technique de référence pour développeur backend.
> Périmètre : tout ce qui tourne en production (https://activeducationhub.com) au 2026-07-11.
> Stack : FastAPI (Python 3.11) + Supabase (PostgreSQL/Auth/Storage) + Redis + Traefik v3 + Flutter Web.

---

## Table des matières

1. [Architecture de production](#1-architecture-de-production)
2. [Socle transversal (auth, cache, middleware, erreurs)](#2-socle-transversal)
3. [Fonctionnalités étudiant (app publique)](#3-fonctionnalités-étudiant)
4. [Espace partenaire (CDEJ / ONG)](#4-espace-partenaire-cdej--ong)
5. [Back-office admin](#5-back-office-admin)
6. [Espace school admin (écoles)](#6-espace-school-admin)
7. [Infrastructure, observabilité et déploiement](#7-infrastructure-observabilité-et-déploiement)

---

## 1. Architecture de production

Orchestration par `docker-compose.yml` à la racine. 5 services :

| Service | Image | Rôle | URL |
|---|---|---|---|
| `socket-proxy` | tecnativa/docker-socket-proxy | Accès Docker en lecture seule pour Traefik (moindre privilège : `CONTAINERS=1`, `NETWORKS=1`, `POST=0`) | interne |
| `traefik` | traefik:v3.2 | Reverse proxy, TLS Let's Encrypt auto, headers sécurité, rate limit IP | 80/443 |
| `redis` | redis:7.2-alpine | Cache distribué (128 Mo, `allkeys-lru`, pas de persistance `--save ""`, mot de passe requis) | interne |
| `backend` | build `./backend` | API FastAPI (uvicorn, port 8000) | api.activeducationhub.com |
| `app-frontend` | nginx:1.25-alpine | Landing statique (`/`) + app Flutter étudiants (`/app/`, build `--base-href=/app/`) | activeducationhub.com |
| `admin-frontend` | nginx:1.25-alpine | Dashboard admin Flutter Web | admin.activeducationhub.com |

Points notables :
- **Réseau `socket-proxy-network` `internal: true`** : le proxy Docker n'a aucun accès sortant.
- **Tous les conteneurs** : `no-new-privileges:true`, limites CPU/RAM, rotation des logs json-file.
- **Traefik → backend** : middleware `api-headers` (HSTS 2 ans + preload, `X-Frame-Options: DENY`, CSP `default-src 'none'`) + `api-ratelimit` (100 req/s en moyenne, burst 50, par IP).
- **Redirection www → apex** via `redirectregex` permanent.
- Healthcheck backend : `GET /health` toutes les 30 s ; le backend ne démarre qu'après le healthcheck Redis.

---

## 2. Socle transversal

### 2.1 Authentification — Supabase Auth natif

**Fichiers** : `backend/app/core/security.py`, `backend/app/services/auth_service.py`

Il n'y a **pas de JWT maison** : les mots de passe et tokens sont entièrement délégués à Supabase Auth (GoTrue). Le backend :

1. **Login/register** (`auth_service.py`) : appelle `client.auth.sign_in_with_password()` / `sign_up()`. À la connexion, il récupère (ou crée à la volée) le profil métier dans `user_profiles` et met à jour `last_login`. La réponse contient `access_token` + `refresh_token` Supabase.
2. **Validation des tokens** (`security.py::_validate_token_via_supabase`), en deux stratégies :
   - **Locale (prioritaire, 0 réseau)** : si `SUPABASE_JWT_SECRET` est configuré, décodage `python-jose` en HS256 avec `audience="authenticated"`. Renvoie `{user_id: sub, email, role}`.
   - **Fallback API** : `client.auth.get_user(token)` si pas de secret local ou si le décodage local échoue (hors expiration).
3. **Cache des tokens validés** : clé `auth:token:<sha256(token)>` (jamais le token en clair), TTL **60 s**, partagé entre workers via Redis. Évite une validation par requête.

**Dependencies FastAPI** (injection via `Depends`) :

| Dependency | Garantie | Détail |
|---|---|---|
| `get_current_user_id` | utilisateur authentifié | retourne l'`UUID` |
| `get_current_user_id_optional` | anonyme autorisé | `None` sans token ; **lève** si token invalide/expiré (le client a tenté de s'authentifier, il doit le savoir) |
| `get_current_user_role` | rôle | lookup `user_profiles.role` caché 60 s (`auth:user_role:<id>`) |
| `get_current_admin` | rôle `admin`/`super_admin` + compte actif | profil caché 60 s (`auth:admin_profile:<id>`), lookup DB offloadé en threadpool (`asyncio.to_thread`) car le client Supabase est synchrone |
| `get_current_super_admin` | rôle `super_admin` | délègue à `get_current_admin` puis vérifie |
| `get_current_school_admin` | rôle `school_admin` + profil `school_admin_profiles` actif | double lookup en parallèle (`asyncio.gather`) ; retourne `{user_id, school_id, email}` — le `school_id` sert au scoping de toutes les routes `/school/*` |

Les rôles vivent dans `user_profiles.role` : `student` (défaut), `admin`, `super_admin`, `school_admin`, (+ partenaires).

### 2.2 Cache Redis avec fallback mémoire

**Fichier** : `backend/app/core/cache.py`

`CacheClient` singleton :
- Sérialisation JSON, `decode_responses=True`, timeouts socket 2 s.
- **Fallback transparent** : si Redis est indisponible, bascule sur un dict mémoire local ; **circuit breaker** de 30 s (`_REDIS_RETRY_INTERVAL`) avant de retenter la connexion — évite de payer un timeout à chaque requête quand Redis est down.
- API : `get`, `set(key, value, ttl)`, `delete`, `delete_pattern` (invalidations par préfixe).

TTL standards (constantes du module) :

| Constante | TTL | Usage |
|---|---|---|
| `TTL_LISTS` | 10 min | listes écoles/carrières/cours |
| `TTL_DETAIL` | 5 min | détail école/carrière |
| `TTL_TESTS` | 30 min | tests d'orientation (quasi statiques) |
| `TTL_USER_PROFILE` | 2 min | profils utilisateur |
| `TTL_MENTORS` / `TTL_OPPORTUNITIES` | 5 min | listes semi-statiques |
| `TTL_LEADERBOARD` | 2 min | classement |
| `TTL_GAMIFICATION` | 1 min | profil gamification |

`backend/app/core/gamification_cache.py` fournit `invalidate_gamification_profile(user_id)` et `invalidate_leaderboard()` (delete_pattern) — appelés partout où on crédite de l'XP.

### 2.3 Rate limiting (deux niveaux)

1. **Traefik** (infra) : 100 req/s moyenne + burst 50 par IP sur l'API.
2. **Applicatif** (`backend/app/middleware/rate_limiter.py`) : `slowapi.Limiter` avec :
   - Extraction d'IP consciente des proxies : `X-Forwarded-For` (première IP) > `X-Real-IP` > IP directe.
   - **Storage Redis** en production (compteurs partagés entre workers), mémoire en dev. Stratégie `fixed-window`.
   - Décorateurs : `strict_limit("10/minute")` (auth, soumission de tests), `standard_limit()` (`RATE_LIMIT_PER_MINUTE` global), `relaxed_limit("200/minute")`.
   - Handler 429 custom : JSON structuré + headers `Retry-After` et `X-RateLimit-Limit`.

### 2.4 Middlewares (ordre d'exécution : logging → headers → gzip → CORS)

**Fichier d'assemblage** : `backend/app/main.py`

- **RequestLoggingMiddleware** : génère un **correlation ID** par requête, stocké dans `request.state.correlation_id`, exposé au client via header `X-Correlation-ID` (avec `X-Process-Time`). Repris dans tous les logs et toutes les réponses d'erreur — c'est la clé de corrélation logs ↔ client.
- **SecurityHeadersMiddleware** : headers de sécurité applicatifs (complète ceux de Traefik).
- **GZipMiddleware** : compression des réponses > 1 Ko.
- **CORS** : origines depuis `BACKEND_CORS_ORIGINS` (env). Si wildcard `*`, `allow_credentials` est désactivé (incompatibilité spec). Headers exposés : `X-Correlation-ID`, `X-Process-Time`.

### 2.5 Gestion des erreurs

**Fichiers** : `backend/app/main.py`, `backend/app/core/exceptions.py`

Quatre handlers globaux, tous au format `{error, message, correlation_id}` :

- `AppException` (hiérarchie custom : `AuthenticationError`, `AuthorizationError`, `NotFoundError`, `ValidationError`, `TokenExpiredError`…) → statut + code portés par l'exception.
- `RequestValidationError` (422) : les erreurs Pydantic brutes sont **traduites en français lisible** (`_friendly_field_error` + table `_FIELD_LABELS`) avec un dict `fields` par champ pour l'affichage frontend.
- `StarletteHTTPException` : uniformise 401/403/404/405 en messages français.
- `Exception` catch-all (500) : en production le détail n'est **jamais exposé** (message générique) ; en dev le type et le message sont inclus.

Particularité : `_apply_cors_headers()` ré-applique manuellement les headers CORS sur les réponses d'erreur, car les exception handlers court-circuitent le `CORSMiddleware` dans la config Starlette utilisée.

### 2.6 Client Supabase

**Fichier** : `backend/app/db/supabase_client.py`

- Singleton **thread-safe** (`Lock`).
- Décorateur `@with_retry` : 3 tentatives, backoff exponentiel (0,5 s → 10 s max), sleep **non bloquant** pour l'event loop (offload dans un ThreadPoolExecutor si une loop tourne).
- Helpers `fetch_one` / `fetch_all` (table, filtres, order_by, limit) qui wrappent PostgREST avec exceptions typées (`QueryError`, `DBConnectionError`).
- `health_check()` consommé par `/health`.
- Deux clients : anon (`SUPABASE_KEY`) et service-role (`get_admin_supabase_client`, bypass RLS) pour les écritures serveur (soumission de tests, XP…).

### 2.7 Logging & monitoring

- **Logging structuré** (`backend/app/core/logging.py`) : JSON en production, coloré en dev. Champs extra systématiques (`correlation_id`, `user_id`, `path`).
- **Sentry** (optionnel via `SENTRY_DSN`) : initialisé **avant** tout import applicatif dans `main.py` (sinon les modules ne seraient pas instrumentés). `traces_sample_rate=0.1`, `profiles_sample_rate=0.1`, `send_default_pii=False`.
- **`GET /health`** : teste Supabase + Redis. Trois états : `healthy` (200), `degraded` (200 — au moins un service up), `unhealthy` (503). Utilisé par le healthcheck Docker.

### 2.8 Email

**Fichier** : `backend/app/core/email.py`

SMTP natif (`smtplib`), **best-effort** : un échec d'envoi ne casse jamais la requête métier (candidature mentor, etc.). Envoi non bloquant via `asyncio.to_thread`. Le destinataire des notifications internes est lu **à chaud** depuis `app_settings.notification_email` (modifiable dans le back-office sans redéploiement), avec repli sur l'env `NOTIFICATION_EMAIL`.

---

## 3. Fonctionnalités étudiant

Toutes les routes sont préfixées `/api/v1`. Fichiers : `backend/app/api/v1/endpoints/*.py`.

### 3.1 Authentification (`/auth`)

`endpoints/auth.py` + `services/auth_service.py` :

| Route | Implémentation |
|---|---|
| `POST /auth/register` | `sign_up()` Supabase avec `first_name`/`last_name` en metadata ; création du profil `user_profiles` |
| `POST /auth/login` | `sign_in_with_password()` ; get-or-create profil ; `update_last_login` ; les erreurs Supabase sont mappées sur un message unique « Email ou mot de passe incorrect » (pas d'énumération d'emails) |
| `POST /auth/refresh` | rotation du refresh token via Supabase |
| `POST /auth/logout` | invalidation de session Supabase |
| `POST /auth/forgot-password` / `reset-password` | flow de reset Supabase (email magique) |
| `POST /auth/change-password` | re-authentification puis update |
| `GET /auth/me` / `PATCH /auth/me` | lecture/mise à jour du profil `user_profiles` (le repo `users_repository.py` ne manipule **jamais** de `password_hash` — tout est chez Supabase) |

### 3.2 Orientation (tests RIASEC / personnalité) (`/orientation`)

**Fichiers** : `endpoints/orientation.py`, `services/orientation_engine.py`, `services/career_matcher.py`, `repositories/orientation_repository.py`

- **Catalogue** : `GET /tests` (résumés, `active_only`), `GET /tests/{id}` (avec questions/options). Variantes **mobile** `GET /mobile/tests[...]` et `/mobile/careers[...]` qui renvoient du camelCase pour l'app Flutter.
- **Soumission** : `POST /sessions/{test_id}/submit` (rate-limité). Auth **optionnelle** : un anonyme peut passer le test, seuls les connectés persistent leurs résultats (écrits via le client service-role).
- **Moteur de scoring** (`orientation_engine.py`) :
  - RIASEC : agrégation des points par trait (les 6 traits sont **libellés en français** : Réaliste, Investigateur, Artistique, Social, Entrepreneur, Conventionnel), avec pour chacun description, forces et secteurs porteurs localisés (contexte Togo/Afrique de l'Ouest). Tables de normalisation `EN_TO_FR` / `CODE_TO_FR` pour absorber les données historiques.
  - Personnalité type MBTI : calcul par paires de dimensions.
  - Produit un `TestResult` structuré (scores, top traits, interprétation).
- **Matching carrières** (`career_matcher.py`) :
  - Score de correspondance carrière ↔ profil basé sur les `related_traits` de chaque carrière (normalisés FR).
  - **Diversification anti-biais** : les carrières sont regroupées en « tiers » de score (marge de 8 points) puis mélangées aléatoirement à l'intérieur d'un tier — évite que le tri alphabétique favorise toujours les mêmes carrières à score égal. Max 6 recommandations.
  - Enrichit chaque recommandation avec salaire FCFA, demande du marché, compétences requises, niveau d'études minimum (extrait du JSON `education_path`).
- **Carrières** : `GET /careers`, `GET /careers/{id}`, `GET /recommendations` (basé sur le dernier résultat de l'utilisateur). Après soumission, invalidation du cache gamification (la complétion d'un test crédite de l'XP).

### 3.3 Écoles (public) (`/schools`)

`endpoints/schools.py` + `repositories/schools_repository.py` : liste paginée avec filtres (ville, type, recherche) et détail public (programmes, images, contact). Cache `TTL_LISTS`/`TTL_DETAIL`.

### 3.4 Chat IA — AÏDA (`/chat`)

**Fichiers** : `endpoints/chat.py`, `services/llm_service.py`, `services/llm/{groq_provider,session_manager,prompt_builder,safety_filter}.py`, `repositories/knowledge_base_repository.py`

Assistante d'orientation conversationnelle. Architecture en façade :

```
ChatRequest ──▶ LLMService
                 ├── SafetyFilter    (sanitize + détection d'injection)
                 ├── SessionManager  (historique en mémoire)
                 ├── PromptBuilder   (persona + garde-fous + KB + contexte élève)
                 └── GroqProvider    (Groq principal, Ollama fallback)
```

- **Routes** (auth requise) :
  - `POST /chat/message` : réponse JSON complète.
  - `POST /chat/message/stream` : **SSE** (`StreamingResponse`, `text/event-stream`, `X-Accel-Buffering: no` pour désactiver le buffering proxy). Événements `data: {"chunk": "..."}` puis `data: {"done": true, "session_id": "..."}`. Premier token < 500 ms.
  - `DELETE /chat/session/{id}` : purge l'historique.
  - `session_id` généré côté serveur si absent : `{user_id}:{uuid4}`.
- **Provider** (`groq_provider.py`) : API Groq (OpenAI-compatible), modèle `llama-3.1-8b-instant`, `max_tokens=800`, `temperature=0.7`, timeout 30 s. **Fallback Ollama** auto-hébergé (`OLLAMA_BASE_URL`, `llama3.1:8b`) si Groq échoue ou si `GROQ_API_KEY` absent ; en streaming, Ollama est simulé mot par mot. Si tout échoue : message d'indisponibilité gracieux (jamais de 500 côté flux).
- **Sessions** (`session_manager.py`) : **en mémoire** (pas Redis), max 1000 sessions avec éviction LRU, 10 messages conservés par session (5 échanges). Comme le serveur peut redémarrer, l'app envoie son historique local (`client_history`) et la session est **re-seedée côté serveur** si inconnue — le contexte survit aux redéploiements sans stockage serveur.
- **Sécurité** (`safety_filter.py`) : troncature à 2000 caractères + regex de détection d'injection de prompt (« ignore previous instructions », « jailbreak », « [system] »…). Une injection détectée reçoit un message de refus poli sans jamais atteindre le LLM.
- **Prompt système** (`prompt_builder.py`) : persona AÏDA (français, contexte togolais/CEDEAO, salaires FCFA, 3-5 phrases) + **garde-fous stricts** (refus politique/religion/médical/devoirs…) + **base de connaissances** + le profil RIASEC de l'élève si fourni (`orientation_context`) pour personnaliser.
- **Base de connaissances** (`knowledge_base_repository.py`) : table Supabase `knowledge_base`, éditable depuis le back-office. Cache Redis **1 h**, fallback cache mémoire, fallback ultime sur une KB statique embarquée. Injectée dans le prompt système à chaque tour.

### 3.5 E-learning (`/elearning`)

**Fichiers** : `endpoints/elearning.py`, `repositories/elearning_repository.py`, `repositories/exam_repository.py`

- **Catalogue** : `GET /courses` (publiés uniquement, filtres, cache par utilisateur), `GET /courses/{id}` (modules + leçons + progression si connecté), `GET /lessons/{id}` (contenu : vidéo/texte/quiz depuis `elearning_lesson_content`).
- **Inscription** : `POST /courses/{id}/enroll` — vérifie que le cours existe et `is_published`, 409 si déjà inscrit (le repo lève `ValueError("already_enrolled")` traduit en `HTTP 409`). Invalidation ciblée : `delete_pattern("elearning:courses:{user_id}*")`.
- **Mes cours** : `GET /my-courses` — enrollments + `progress_pct` + `last_lesson_id` (reprise de lecture), cache `TTL_LISTS`.
- **Complétion de leçon** : `POST /lessons/{id}/complete` — marque la leçon complétée, recalcule `progress_pct` du cours, **crédite les points** de la leçon, invalide les caches de progression.
- **Examens de cours (QCM)** :
  - `GET /courses/{id}/exam` : renvoie l'examen **sans les flags `is_correct`** (les options sont réduites à leur texte côté API — les bonnes réponses ne quittent jamais le serveur).
  - `POST /courses/{id}/exam/submit` : scoring serveur — pour chaque question, l'index d'option choisi doit pointer une option `is_correct` ; pondération par `points` de question ; score en % arrondi ; seuil `passing_score` (défaut 80).
  - **Idempotence des récompenses** : `has_passed_before(user_id, exam_id)` — badge (achievement) + XP ne sont crédités qu'à la **première réussite** ; chaque tentative est historisée (`record_attempt` avec réponses).

### 3.6 Gamification (`/gamification`)

**Fichier** : `endpoints/gamification.py`

- **Modèle de niveau** : formule fermée O(1) — `level = ⌊(1 + √(1 + 8·XP/100)) / 2⌋`, cap à 100 ; c'est l'inverse d'un coût cumulé triangulaire (`niveau n` requiert `n(n+1)/2 × 100` XP). Retourne aussi `next_level_xp` et `xp_to_next`.
- `GET /profile` : agrège `user_profiles` (total_xp, current_streak, longest_streak), `user_achievements`, `user_challenges` + `challenges` actifs. Le **rang du leaderboard** est calculé par une fonction PostgreSQL (`rpc get_leaderboard_rank`) — pas de scan côté Python. Cache 60 s par utilisateur (`gamification:profile:{user_id}`).
- `GET /leaderboard` : top N (max 50) trié par `total_xp desc`, cache 2 min par valeur de `limit`.
- **Écriture d'XP** : elle se fait dans les modules émetteurs (complétion de leçon, réussite d'examen, soumission de test d'orientation), chacun invalidant ensuite `gamification:profile:*` et `gamification:leaderboard:*` via `core/gamification_cache.py`.
- Achievements et challenges sont **pilotés par la donnée** (CRUD admin, cf. §5.6) : pas de nouvelle logique de code pour ajouter un badge ou un défi.

### 3.7 Mentors (`/mentors`)

`endpoints/mentors.py` + `repositories/mentor_repository.py` :

- `GET /mentors` (liste filtrable, seuls les mentors vérifiés/actifs), `GET /mentors/{id}`, `GET /mentors/{id}/reviews`.
- `POST /mentors/apply` : **candidature mentor** publique — enregistre la candidature (`mentor_applications`) et déclenche un **email de notification interne** (best-effort, cf. §2.8). Le cycle approve/reject est côté admin (§5.7).

### 3.8 Opportunités, annonces, settings, recherche

- **`GET /opportunities`**, `GET /opportunities/{id}` : stages/jobs/bourses **publiés** uniquement, filtres type/lieu, cache 5 min.
- **`GET /announcements`** : annonces actives (bannières in-app), pilotées par le back-office.
- **`GET /settings/public`** : paramètres exposés à l'app (feature flags, contacts) depuis `app_settings`.
- **`GET /search?q=`** (`endpoints/search.py`) : **recherche unifiée** écoles + carrières + cours en un appel. Implémentation : 3 requêtes PostgREST `ilike` (`name/city/description`), avec échappement des caractères sensibles PostgREST (`%`, `,`, parenthèses) pour éviter l'injection de filtres. Chaque résultat porte `{type, id, title, subtitle, image, route}` — la `route` est le chemin de navigation Flutter, le frontend n'a aucune logique de mapping. Cache 2 min par terme.

---

## 4. Espace partenaire (CDEJ / ONG)

**Fichiers** : `endpoints/partner/organizations.py`, `services/partner_service.py`, `repositories/partner_repository.py`

Permet à des organisations partenaires de suivre leurs bénéficiaires sur la plateforme :

- `POST /organizations` (création), `GET /organizations` (liste), `GET /organizations/my-organization` (l'org du user connecté), `GET /organizations/{id}`, `PATCH /organizations/{id}`.
- `GET /organizations/{id}/stats` : statistiques agrégées (bénéficiaires actifs, progression).
- **Bénéficiaires** : `GET /organizations/{id}/beneficiaries` (paginé), `GET/PATCH/DELETE /beneficiaries/{id}` — rattachement d'élèves à une organisation avec contrôle d'accès (un partenaire ne voit que sa propre organisation).

---

## 5. Back-office admin

Toutes les routes `/admin/*` exigent `get_current_admin` (rôle `admin`/`super_admin` + compte actif) ; certaines opérations destructives exigent `super_admin`. Consommé par le dashboard Flutter `admin_dashboard/`.

### 5.1 Auth admin (`/admin/auth/login`)

`endpoints/admin/auth.py` : même flow Supabase que le login étudiant, **plus** vérification du rôle dans `user_profiles` — refuse quiconque n'est pas `admin`/`super_admin` ou désactivé. Retourne user (avec rôle) + tokens Supabase.

### 5.2 Dashboard (`/admin/dashboard/stats`)

`repositories/admin/stats_repository.py` : compteurs agrégés (utilisateurs, écoles, tests passés, inscriptions e-learning…) pour l'écran d'accueil admin.

### 5.3 Utilisateurs (`/admin/users`)

`endpoints/admin/users.py` + `repositories/admin/users_admin_repository.py` : liste paginée/filtrable, détail, `PATCH` profil, **`PATCH /{id}/role`** (changement de rôle — réservé super_admin), `PATCH /{id}/activate|deactivate` (soft-disable : `is_active=false` bloque l'accès dès la prochaine validation de token/dependency, sans supprimer le compte Supabase).

### 5.4 Écoles (`/admin/schools`)

CRUD complet + sous-ressources : **programmes** (`POST/PUT/DELETE /{id}/programs/...`) et **images de galerie** (`POST /{id}/images`, `DELETE .../{image_id}`). Workflow de modération : `PATCH /{id}/verify` (badge vérifié) et `PATCH /{id}/toggle-active`. Chaque mutation invalide les caches publics écoles.

### 5.5 Carrières & tests d'orientation

- **`/admin/careers`** : CRUD carrières + CRUD **secteurs** (`/sectors`). Les champs `related_traits`, `education_path` (JSON), salaires FCFA alimentent directement le career matcher (§3.2).
- **`/admin/tests`** (`endpoints/admin/orientation.py`) : gestion complète des questionnaires — CRUD test, **duplication** (`POST /{id}/duplicate`), CRUD questions et options imbriquées, **réordonnancement** (`PATCH /{id}/questions/reorder`). Les options portent le mapping trait → points utilisé par le moteur de scoring. Invalidation du cache `TTL_TESTS` à chaque mutation.

### 5.6 Gamification (`/admin/gamification`)

CRUD **achievements** (type, icône, condition) et **challenges** (titre, points, période, `is_active`). Aucune logique en dur : le profil étudiant (§3.6) lit ces tables.

### 5.7 Mentors (`/admin/mentors`, `/admin/mentor-applications`)

- CRUD mentors, `PATCH /{id}/verify`, `PATCH /{id}/toggle-active`.
- **Tâches de suivi** par mentor : `GET/POST /{id}/tasks`, `PATCH/DELETE /tasks/{task_id}`.
- **Candidatures** (issues de `POST /mentors/apply`) : `GET /mentor-applications`, `PATCH /{app_id}/approve` (crée le profil mentor) / `reject`.

### 5.8 Contenu & configuration

- **`/admin/settings`** : lecture + `PUT /settings/{key}` sur `app_settings` (clé/valeur JSON) — configuration **à chaud** (email de notification, flags…).
- **`/admin/announcements`** : CRUD des annonces publiques.
- **`GET /admin/audit-log`** : journal d'audit des actions admin (les mutations sensibles — uploads, changements de rôle — écrivent une entrée `{admin_id, action, resource, details}`).
- **`/admin/knowledge-base`** : CRUD des entrées de la KB d'AÏDA (catégorie + contenu). Le cache Redis 1 h de la KB est invalidé à la mutation ; c'est le canal par lequel les équipes métier enrichissent les réponses du chatbot sans redéploiement.
- **`/admin/opportunities`** : CRUD + workflow `PATCH /{id}/publish` et `PATCH /{id}/featured` (seuls les publiés sortent sur l'API publique).

### 5.9 E-learning admin (`/admin/elearning`)

CRUD global cours/modules/leçons (toutes écoles confondues, contrairement à l'espace school qui est scopé), `GET /schools` (écoles avec leurs cours), et gestion des **examens** : `GET/PUT/DELETE /courses/{id}/exam` — le `PUT` est un **upsert** de l'examen complet (questions + options avec `is_correct` + `passing_score` + badge associé).

### 5.10 Upload de fichiers (`/admin/upload/{bucket}`)

`endpoints/admin/upload.py` — upload d'images vers **Supabase Storage**, avec défense en profondeur :

1. Bucket dans une **liste blanche** : `schools`, `careers`, `tests`, `announcements`, `avatars`, `elearning`.
2. `content-type` déclaré ∈ {jpeg, png, webp} **et** vérification des **magic bytes** réels du fichier (`\xff\xd8\xff`, `\x89PNG...`, `RIFF`) — le type déclaré ne suffit pas.
3. Taille max 5 Mo ; extension re-validée par regex `[a-z0-9]{1,10}`.
4. Nom de fichier remplacé par un `uuid4` (aucune injection de chemin possible).
5. Entrée d'audit log, puis retour de l'URL publique Storage.

---

## 6. Espace school admin

Routes `/school/*`, protégées par `get_current_school_admin` — **toutes les requêtes sont scopées au `school_id`** du profil admin (une école ne voit et ne modifie que ses propres contenus). Fichiers : `endpoints/school/*.py`, `repositories/school_admin_repository.py`.

- **`POST /school/auth/login`** : login Supabase + vérification rôle `school_admin` + profil `school_admin_profiles` actif.
- **Cours** : CRUD `/school/courses`, avec `PATCH /courses/{id}/publish` (seuls les cours publiés apparaissent côté étudiants).
- **Modules** : CRUD sous `/school/courses/{id}/modules`, + `PATCH /modules/reorder` (réordonnancement en batch).
- **Leçons** : CRUD sous `/school/modules/{id}/lessons`, + **`POST /lessons/{id}/upload-video`** :
  - Upload vers le bucket Storage `elearning-videos`, chemin par leçon.
  - Gestion du conflit : si le fichier existe (`Duplicate`), bascule sur `storage.update()` (remplacement).
  - Upsert du contenu dans `elearning_lesson_content` (`content_data = {video_url, type: "video"}`).
- **`GET /school/dashboard/stats`** : inscrits, complétions, progression sur les cours de l'école.
- **Profil école** : `GET/PUT /school/profile`, `POST /school/profile/logo`.

---

## 7. Infrastructure, observabilité et déploiement

### 7.1 Base de données & migrations

- **Supabase PostgreSQL**, accès via PostgREST (SDK supabase-py). RLS activé (audit dans `docs/RLS_AUDIT.md`) ; le backend utilise le client **service-role** pour les écritures serveur qui doivent bypasser RLS.
- **Migrations Alembic** (`backend/alembic/`) : SQL versionné. `alembic upgrade head` au déploiement ; nécessite `DATABASE_URL` (ou `SUPABASE_DB_HOST` + `SUPABASE_DB_PASSWORD`).
- Fonctions PostgreSQL utilisées par l'API : `get_leaderboard_rank(p_user_id)` (rang gamification).

### 7.2 Variables d'environnement clés

| Variable | Rôle |
|---|---|
| `SUPABASE_URL`, `SUPABASE_KEY`, `SUPABASE_SERVICE_ROLE_KEY` | obligatoires |
| `SUPABASE_JWT_SECRET` | recommandé en prod — active la validation locale des tokens (0 appel réseau) |
| `REDIS_URL` | injecté par compose : `redis://:<password>@redis:6379/0` |
| `GROQ_API_KEY` | LLM AÏDA (sans elle : fallback Ollama) |
| `OLLAMA_BASE_URL`, `OLLAMA_MODEL` | fallback LLM |
| `SENTRY_DSN` | monitoring erreurs (optionnel) |
| `BACKEND_CORS_ORIGINS`, `RATE_LIMIT_PER_MINUTE`, `ENVIRONMENT` | comportement runtime |
| `SMTP_HOST`, `SMTP_FROM`, `NOTIFICATION_EMAIL` | emails best-effort |

Le fichier de prod est `backend/.env.production` (chargé via `env_file` dans compose).

### 7.3 CI/CD

- `.github/workflows/backend-ci.yml` : lint + tests + build Docker.
- `.github/workflows/frontend-ci.yml` : `flutter analyze` + build.
- `.github/workflows/deploy-staging.yml` : auto sur `develop`.
- `.github/workflows/deploy-prod.yml` : **manuel** (`workflow_dispatch`), SSH vers le VPS (secrets `PROD_HOST/USER/SSH_KEY`).
- Conventional Commits + pre-commit hooks côté repo.

### 7.4 Points d'attention pour un nouveau développeur backend

1. **Le client Supabase est synchrone** : tout appel DB dans un chemin async chaud doit passer par `asyncio.to_thread` (voir les dependencies admin/school dans `security.py`) sous peine de bloquer l'event loop.
2. **Invalidation de cache = responsabilité de l'écrivain** : toute mutation qui affecte une donnée cachée doit appeler `delete`/`delete_pattern` (voir enroll, complete_lesson, gamification_cache). Il n'y a pas d'invalidation automatique.
3. **Ne jamais renvoyer `is_correct`** dans un payload étudiant (examens) — le scoring est exclusivement serveur.
4. **Récompenses idempotentes** : tout crédit XP/badge doit vérifier une condition « première fois » (`has_passed_before` en est le modèle).
5. **Les erreurs doivent passer par `AppException`** (ou HTTPException) pour bénéficier du format uniforme + correlation_id + CORS.
6. **Sessions AÏDA en mémoire** : ne pas supposer leur persistance ; le protocole client_history est le mécanisme de reprise.
7. Le rate limiting applicatif exige le paramètre `request: Request` dans la signature des endpoints décorés (contrainte slowapi).
