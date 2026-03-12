# Architecture ActivEducation

## Vue d'ensemble

ActivEducation est une plateforme d'orientation scolaire gamifiée pour l'Afrique de l'Ouest. Elle est composée de :

```
Internet
   │
   ▼
┌─────────────────────────────────┐
│  Traefik (Reverse Proxy)        │
│  - SSL automatique (Let's Encrypt)│
│  - Routing par domaine          │
│  - Security headers             │
└──────┬──────────┬──────────┬───┘
       │          │          │
       ▼          ▼          ▼
   ┌──────┐  ┌──────┐  ┌──────────┐
   │ App  │  │Admin │  │ Backend  │
   │ Web  │  │ Web  │  │  API     │
   │(Nginx│  │(Nginx│  │(FastAPI) │
   │ +    │  │ +    │  │          │
   │Flutter│  │Flutter│  │          │
   │  Web)│  │  Web)│  │          │
   └──────┘  └──────┘  └────┬─────┘
                             │
                             ▼
                     ┌──────────────┐
                     │  Supabase    │
                     │  - PostgreSQL│
                     │  - Auth      │
                     │  - Storage   │
                     └──────────────┘
```

## Composants

### Backend (FastAPI)

**Technologie :** Python 3.11, FastAPI, Supabase Python Client

**Structure :**
```
backend/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/      # Handlers HTTP
│   │       │   ├── auth.py
│   │       │   ├── orientation.py
│   │       │   ├── schools.py
│   │       │   ├── chat.py
│   │       │   └── admin/      # Endpoints admin
│   │       └── router.py
│   ├── core/
│   │   ├── config.py           # Settings Pydantic
│   │   ├── security.py         # JWT + auth dependencies
│   │   ├── logging.py          # Logging structuré
│   │   └── exceptions.py       # Exceptions typées
│   ├── db/
│   │   └── supabase_client.py  # Client DB singleton
│   ├── repositories/           # Accès données
│   ├── services/               # Logique métier
│   ├── schemas/                # Modèles Pydantic
│   ├── middleware/             # Rate limiting, sécurité
│   └── main.py                 # Point d'entrée
├── tests/
├── database/                   # Schéma SQL
└── requirements.txt
```

**Endpoints principaux :**

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/auth/login` | Authentification |
| `POST /api/v1/auth/register` | Inscription |
| `GET /api/v1/orientation/tests` | Liste des tests d'orientation |
| `POST /api/v1/orientation/tests/{id}/start` | Démarrer un test |
| `POST /api/v1/orientation/sessions/{id}/complete` | Soumettre un test |
| `GET /api/v1/schools` | Liste des écoles |
| `POST /api/v1/chat/message` | Chat avec AÏDA (LLM) |
| `GET /api/v1/admin/dashboard` | Métriques admin |

### App Flutter (Étudiants)

**Technologie :** Flutter 3.32, Dart, BLoC pattern

**Architecture :** Clean Architecture avec BLoC

```
activ_education_app/lib/
├── core/
│   ├── di/             # Injection de dépendances (get_it)
│   ├── network/        # Client Dio, intercepteurs
│   ├── router/         # Navigation (go_router)
│   └── theme/          # Thème global
├── features/
│   ├── auth/           # Login, Register
│   ├── orientation/    # Tests RIASEC, résultats
│   ├── schools/        # Exploration écoles
│   ├── chat/           # Chat AÏDA
│   └── profile/        # Profil utilisateur
└── shared/
    ├── widgets/        # Composants réutilisables
    └── utils/
```

### Dashboard Admin (Flutter)

**Technologie :** Flutter 3.32, Dart, BLoC

Gestion complète de la plateforme :
- Gestion utilisateurs et rôles
- CRUD écoles, carrières, tests
- Métriques et analytics
- Paramètres système

### Base de données (Supabase / PostgreSQL)

**Tables principales :**

| Table | Description |
|-------|-------------|
| `user_profiles` | Profils utilisateurs |
| `schools` | Établissements scolaires |
| `careers` | Carrières et débouchés |
| `orientation_tests` | Tests d'orientation |
| `orientation_sessions` | Sessions de test |
| `gamification_points` | Points et badges |
| `mentors` | Profils mentors |

**Authentification :** JWT maison (en cours de migration vers Supabase Auth natif)

## Flux d'authentification (état actuel)

```
Client → POST /auth/login (email + password)
Backend → Vérifie password en base
Backend → Génère JWT (python-jose)
Client → Stocke JWT localement
Client → Envoie JWT dans Authorization: Bearer <token>
Backend → Valide JWT via security.py
```

> ⚠️ En cours de migration vers Supabase Auth (Phase 1.2)

## Déploiement

**Infrastructure :** VPS Linux (Hostinger)

**Stack déploiement :**
- Docker + Docker Compose
- Traefik v3 (reverse proxy + SSL)
- Nginx (fichiers statiques Flutter)

**Domaines :**
- `activeduhub.com` → App Flutter étudiants
- `admin.activeduhub.com` → Dashboard admin
- `api.activeduhub.com` → API FastAPI

## Sécurité

Voir [SECURITY.md](SECURITY.md).

## Environnements

| Environnement | Branche | URL |
|---------------|---------|-----|
| Production | `main` | activeduhub.com |
| Staging | `develop` | staging.activeduhub.com |
| Local | — | localhost |

## LLM / IA

**AÏDA** : Assistant conversationnel alimenté par Groq (modèle Llama 3) pour guider les étudiants dans leur orientation.

Endpoint : `POST /api/v1/chat/message`
