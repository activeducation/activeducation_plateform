# Documentation Technique Complète - ActivEducation

> Plateforme d'orientation scolaire et professionnelle gamifiée pour l'Afrique de l'Ouest

---

## Table des Matières

1. [Introduction et Contexte](#1-introduction-et-contexte)
2. [Architecture Technique Détaillée](#2-architecture-technique-détaillée)
3. [Stack Technologique](#3-stack-technologique)
4. [Backend - FastAPI](#4-backend---fastapi)
5. [Application Flutter - Étudiants](#5-application-flutter---étudiants)
6. [Dashboard Admin](#6-dashboard-admin)
7. [Base de Données et Schemas](#7-base-de-données-et-schemas)
8. [API Endpoints Référence](#8-api-endpoints-référence)
9. [Fonctionnalités Détaillées](#9-fonctionnalités-détaillées)
10. [Déploiement et Infrastructure](#10-déploiement-et-infrastructure)
11. [Guide de Développement](#11-guide-de-développement)
12. [Sécurité et Bonnes Pratiques](#12-sécurité-et-bonnes-pratiques)
13. [Optimisations de Performance](#13-optimisations-de-performance)
14. [Scalabilité et Évolutivité](#14-scalabilité-et-évolutivité)
15. [Dépannage et FAQ](#15-dépannage-et-faq)

---

## 1. Introduction et Contexte

### 1.1 Qu'est-ce qu'ActivEducation ?

ActivEducation est une **plateforme d'orientation scolaire et professionnelle** conçue spécifiquement pour les jeunes d'Afrique de l'Ouest. Le problème que nous solves :

> Comment aider les élèves à choisir leur voie professionnelle alors que l'accès à l'information est limité et que les conseillers d'orientation sont rares ?

Notre solution combine :
- **Tests d'orientation validés scientifiquement** (méthode RIASEC)
- **Mentorat** avec des professionnels locaux
- **E-learning** pour développer des compétences
- **Gamification** pour maintenir la motivation

### 1.2 Pourquoi ce projet ?

**Contexte africain :**
- Plus de 200 millions de jeunes en âge de travailler en Afrique de l'Ouest
- Ratio conseiller/orientation : 1 pour 10 000 élèves (vs 1 pour 300 en France)
- Accès limité aux informations sur les métiers et formations
- Besoin urgent de formation professionnelle pour accélérer le développement économique

**Notre approche :**
1. **Accessibilité** : Application mobile/web accessible sans ordinateur haut de gamme
2. **Personnalisation** : Tests adapts au contexte local (métiers émergents en Afrique)
3. **Motivation** : Système de points et badges pour maintenir l'engagement
4. **Communauté** : Mentorat entre pairs et networking

### 1.3 Les utilisateurs cibles

| Segment | Description | Besoins |
|---------|-------------|---------|
| **Étudiants (15-25 ans)** | Lycée, université, formation pro | Orientation, compétences, opportunités |
| **Mentors (25-45 ans)** | Professionnels souhaitant aider | Volontariat, networking |
| **Écoles/Universités** | Établissements partenaires | Visibilité, recrutement |
| **Partenaires (ONG/CDEJ)** | Organisations jeunesse | Suivi des bénéficiaires |
| **Administrateurs** | Gestion de la plateforme | Analytics, modération |

### 1.4 Statistiques du projet

```
├── 50 000+ utilisateurs potentiels
├── 4 pays cibles (Sénégal, Côte d'Ivoire, Mali, Burkina Faso)
├── 10+ secteurs professionnels couverts
├── 50+ formations carrières référencées
└── Équipe: 3 développeurs + 1 designer
```

---

## 2. Architecture Technique Détaillée

### 2.1 Vue d'Ensemble de l'Architecture

L'architecture est conçue selon le modèle **microservices léger** avec Docker Compose :

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET (HTTPS)                                │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      TRAEFIK (Reverse Proxy v3)                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ • Routage par domaine (Host-based)                                   │  │
│  │ • SSL automatique (Let's Encrypt)                                    │  │
│  │ • Rate limiting (100 req/min/IP)                                     │  │
│  │ • Load balancing                                                     │  │
│  │ • Health checks                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└──────┬──────────────┬──────────────┬──────────────┬───────────────────────┘
       │              │              │              │
       ▼              ▼              ▼              ▼
┌───────────┐   ┌───────────┐  ┌────────────┐  ┌─────────────┐
│   APP     │   │  ADMIN    │  │   BACKEND  │  │  LANDING    │
│ STUDENTS  │   │ DASHBOARD │  │   API      │  │   PAGE      │
│(Flutter)  │   │(Flutter)  │  │ (FastAPI)  │  │   (HTML)    │
│  Nginx    │   │  Nginx    │  │            │  │   Static    │
└─────┬─────┘   └─────┬─────┘  └──────┬─────┘  └─────────────┘
      │              │               │
      │              │               ▼
      │              │       ┌───────────────┐
      │              │       │    REDIS      │
      │              │       │ (Cache/Session)│
      │              │       └───────────────┘
      │              │               │
      │              │               ▼
      │              │       ┌───────────────┐
      └──────────────┴──────►│   SUPABASE    │
                             │  PostgreSQL   │
                             │   + Auth      │
                             │   + Storage   │
                             └───────────────┘
```

**Flux d'une requête typique :**

```
1. Utilisateur tape "https://activeduhub.com"
      │
2. DNS → IP du serveur (Hostinger/VPS)
      │
3. Traefik reçoit la requête HTTPS
      │
4. Traefik vérifie le certificat SSL (Let's Encrypt)
      │
5. Traefik route vers le service approprié (app, admin, backend)
      │
6. Nginx sert les fichiers statiques (Flutter Web)
      │
7. L'app Flutter fait un appel API vers api.activeduhub.com
      │
8. FastAPI traite la requête, accède à Supabase
      │
9. Réponse JSON retournée à l'app Flutter
```

### 2.2 Découpage des Services

| Service | Technologie | Rôle | Ressources |
|---------|-------------|------|------------|
| **Traefik** | Docker | Reverse proxy, SSL, routing | 1 CPU, 256MB |
| **Backend** | FastAPI | API REST, logique métier | 2 CPU, 1GB |
| **Redis** | Redis 7 | Cache, sessions | 0.5 CPU, 160MB |
| **App Nginx** | Nginx | Fichiers statiques Flutter | 0.5 CPU, 128MB |
| **Admin Nginx** | Nginx | Fichiers statiques admin | 0.5 CPU, 128MB |

### 2.3 Structure du Projet

```
ActivEducation/
│
├── 📁 backend/                    # API REST FastAPI (Python 3.11)
│   ├── app/
│   │   ├── main.py               # Point d'entrée FastAPI
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── router.py      # Agrégateur de routes
│   │   │   │   └── endpoints/     # Handlers HTTP
│   │   │   │       ├── auth.py
│   │   │   │       ├── schools.py
│   │   │   │       ├── orientation.py
│   │   │   │       ├── elearning.py
│   │   │   │       ├── gamification.py
│   │   │   │       ├── mentors.py
│   │   │   │       ├── opportunities.py
│   │   │   │       ├── chat.py
│   │   │   │       └── admin/
│   │   ├── core/
│   │   │   ├── config.py         # Settings Pydantic
│   │   │   ├── security.py       # JWT, auth
│   │   │   ├── cache.py          # Redis client
│   │   │   ├── logging.py       # Logging structuré
│   │   │   └── exceptions.py    # Erreurs personnalisées
│   │   ├── db/
│   │   │   └── supabase_client.py # Client Supabase
│   │   ├── repositories/         # Couche données
│   │   ├── services/             # Logique métier
│   │   ├── schemas/             # Modèles Pydantic
│   │   └── workers/             # Tâches async (futur)
│   ├── tests/                    # Tests pytest
│   ├── alembic/                  # Migrations DB
│   ├── requirements.txt          # Dépendances Python
│   └── Dockerfile               # Image Docker
│
├── 📁 activ_education_app/        # App Flutter étudiants
│   ├── lib/
│   │   ├── main.dart            # Point d'entrée
│   │   ├── app.dart             # Configuration app
│   │   ├── core/
│   │   │   ├── di/              # Injection dépendances (get_it)
│   │   │   ├── network/         # Client HTTP (Dio)
│   │   │   ├── router/          # Navigation (go_router)
│   │   │   ├── theme/           # Thème + couleurs
│   │   │   └── constants/      # Configs globales
│   │   ├── features/            # Modules (Clean Architecture)
│   │   │   ├── auth/            # Login, register
│   │   │   ├── onboarding/      # Flow inscription
│   │   │   ├── home/            # Dashboard
│   │   │   ├── orientation/     # Tests RIASEC
│   │   │   ├── elearning/       # Cours en ligne
│   │   │   ├── mentors/        # Liste mentors
│   │   │   ├── schools/         # Établissements
│   │   │   ├── profile/        # Profil + gamification
│   │   │   ├── ai_chat/         # Chat AÏDA (LLM)
│   │   │   └── gamification/   # XP, badges, streaks
│   │   └── shared/              # Widgets partagés
│   └── web/                     # Build web
│
├── 📁 admin_dashboard/            # Dashboard admin (Flutter)
│   └── lib/
│       └── features/            # Modules admin
│
├── 📁 landing/                    # Page statique
├── 📁 nginx/                      # Configs Nginx
├── 📁 traefik/                   # Configs Traefik
├── 📁 docs/                       # Documentation
├── docker-compose.yml            # Orchestration
└── README.md                     # Démarrage rapide
```

---

## 3. Stack Technologique

### 3.1 Backend - Python FastAPI

**Pourquoi FastAPI ?**

| Critère | FastAPI | Django | Flask |
|---------|---------|--------|-------|
| Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Type hints | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Documentation auto | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| ASGI | ⭐⭐⭐⭐⭐ | ❌ | ❌ |
| Validation Pydantic | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐ |

**Dépendances principales :**

```txt
fastapi==0.115.6          # Framework web
uvicorn[standard]==0.34.0  # Server ASGI
pydantic==2.10.4          # Validation données
supabase==2.11.0          # Client DB
redis==5.2.1              # Cache
python-jose[cryptography] # JWT
alembic==1.14.0           # Migrations
sentry-sdk[fastapi]==2.20.0  # Monitoring
```

**Architecture backend - Découpage en couches :**

```
┌─────────────────────────────────────────────────────┐
│                   API Endpoints                      │
│   (fastapi.APIRouter - reçoit les requêtes HTTP)    │
└─────────────────────┬───────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│                  Schemas Pydantic                   │
│   (Validation entrantes / Sortantes)               │
└─────────────────────┬───────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│                    Services                         │
│   (Logique métier - orchestre les opérations)       │
└─────────────────────┬───────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│                   Repositories                      │
│   (Accès données - abstraction de la DB)           │
└─────────────────────┬───────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│               Supabase Client                       │
│   (PostgreSQL + Auth + Storage)                    │
└─────────────────────────────────────────────────────┘
```

### 3.2 Frontend - Flutter

**Pourquoi Flutter ?**

1. **Cross-platform** : iOS, Android, Web, Desktop depuis un seul code
2. **Performance native** : Compile en code machine, pas de VM
3. **Hot reload** : Développement rapide
4. **Widget system** : UI flexible et reusable

**Dépendances Flutter clés :**

```yaml
dependencies:
  flutter_bloc: ^8.1.6        # State management
  go_router: ^14.6.2         # Navigation
  dio: ^5.7.0                 # HTTP client
  get_it: ^8.0.2              # DI
  shared_preferences: ^2.3.3 # Stockage local
  cached_network_image: ^3.4.1 # Image cache
  flutter_secure_storage: ^9.2.2 # Tokens sécurisé

dev_dependencies:
  flutter_lints: ^5.0.0
  bloc_test: ^9.1.7
```

### 3.3 Infrastructure

| Composant | Solution | Justification |
|-----------|----------|---------------|
| **Base de données** | Supabase (PostgreSQL) | PG natif + Auth intégré + Row Level Security |
| **Cache** | Redis | Cache distributed, fallback mémoire |
| **Reverse proxy** | Traefik v3 | SSL auto, routing dynamique, load balancing |
| **Serveur web** | Nginx | Servir fichiers statiques Flutter |
| **Auth** | Supabase Auth | JWT, email magic links, OAuth |
| **Stockage fichiers** | Supabase Storage | Images, documents |
| **Monitoring** | Sentry | Error tracking |
| **CI/CD** | GitHub Actions | Automation |

---

## 4. Backend - FastAPI

### 4.1 Structure des Endpoints

```
/api/v1/
│
├── 📁 auth/                        # Authentification
│   ├── POST /login                # Connexion email/password
│   ├── POST /register             # Inscription
│   ├── POST /logout               # Déconnexion
│   ├── POST /refresh              # Rafraîchir token
│   └── GET  /me                   # Profil courant
│
├── 📁 orientation/                # Tests d'orientation
│   ├── GET    /tests              # Liste tests
│   ├── GET    /tests/{id}         # Détail test
│   ├── POST   /tests/{id}/start   # Démarrer test
│   ├── GET    /sessions/{id}      # État session
│   ├── POST   /sessions/{id}/answer  # Soumettre réponse
│   ├── POST   /sessions/{id}/complete # Terminer test
│   └── GET    /sessions/{id}/results  # Résultats RIASEC
│
├── 📁 schools/                    # Établissements (public)
│   ├── GET /                      # Liste avec filtres
│   └── GET /{id}                  # Détail + programmes
│
├── 📁 elearning/                  # Cours en ligne
│   ├── GET    /courses            # Catalogue
│   ├── GET    /courses/{id}       # Détail cours
│   ├── POST   /courses/{id}/enroll # Inscription
│   ├── GET    /my-courses         # Cours Inscrits
│   ├── GET    /lessons/{id}       # Leçon
│   └── POST   /lessons/{id}/complete # Terminer leçon
│
├── 📁 mentors/                    # Mentors
│   ├── GET /                      # Liste (filtres: specialty)
│   ├── GET /{id}                  # Détail
│   └── GET /{id}/reviews          # Avis
│
├── 📁 opportunities/              # Stages/Jobs/Bourses
│   ├── GET /                      # Liste (filtres: type, location)
│   └── GET /{id}                  # Détail
│
├── 📁 gamification/               # XP, badges, défis
│   ├── GET /profile               # Profil gamification utilisateur
│   └── GET /leaderboard           # Classement top utilisateurs
│
├── 📁 chat/                       # AÏDA - Chat LLM
│   └── POST /                     # Envoyer message
│
├── 📁 admin/                      # Routes administrateur
│   ├── 📁 auth/                   # Admin login
│   ├── 📁 users/                  # CRUD utilisateurs
│   ├── 📁 schools/                # CRUD écoles
│   ├── 📁 careers/                # CRUD carrières
│   ├── 📁 tests/                  # CRUD tests orientation
│   ├── 📁 gamification/           # CRUD badges/défis
│   ├── 📁 mentors/                # CRUD mentors
│   ├── 📁 elearning/              # CRUD cours
│   ├── 📁 opportunities/          # CRUD opportunités
│   ├── 📁 dashboard/               # Métriques
│   └── 📁 settings/               # Configuration
│
└── 📁 school/                     # Routes école (admin local)
    ├── 📁 auth/
    ├── 📁 courses/
    ├── 📁 dashboard/
    └── 📁 profile/
```

### 4.2 Authentification - Comment ça marche ?

**Architecture JWT avec Supabase :**

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUX D'AUTHENTIFICATION                  │
│                                                             │
│  1. INSCRIPTION                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────────┐            │
│  │ Client  │───►│ FastAPI │───►│ Supabase Auth│            │
│  │ Flutter │    │   API   │    │   (create)   │            │
│  └─────────┘    └─────────┘    └─────────────┘            │
│                           │         │                      │
│                           ▼         ▼                      │
│                    ┌─────────────┐  ┌─────────────┐        │
│                    │  .env       │  │ user_profiles│        │
│                    │  JWT secret │  │   (table)    │        │
│                    └─────────────┘  └─────────────┘        │
│                                                             │
│  2. CONNEXION                                               │
│  ┌─────────┐    ┌─────────┐    ┌─────────────┐            │
│  │ Client  │───►│ FastAPI │───►│ Supabase Auth│            │
│  │ Flutter │    │   API   │    │   (verify)  │            │
│  └─────────┘    └─────────┘    └─────────────┘            │
│                     │                                       │
│                     ▼                                       │
│              ┌─────────────┐                                │
│              │ JWT Token    │                                │
│              │ (30 min)     │                                │
│              └─────────────┘                                │
│                                                             │
│  3. REQUÊTE AUTHENTIFIÉE                                   │
│  ┌─────────┐    ┌─────────┐    ┌─────────────┐            │
│  │ Client  │───►│ FastAPI │───►│   Base de    │            │
│  │ Flutter │    │  decode │    │   données   │            │
│  │         │    │  JWT    │    │  (user_id)  │            │
│  └─────────┘    └─────────┘    └─────────────┘            │
│        │              │                                    │
│  Authorization:    verify signature + exp + role           │
│  Bearer <token>                                            │
└─────────────────────────────────────────────────────────────┘
```

**Implementation dans le code :**

```python
# backend/app/core/security.py

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from uuid import UUID

security = HTTPBearer()

async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> UUID:
    """
    Décode le token JWT et retourne l'ID utilisateur.
    Utilisé comme dépendance FastAPI pour protéger les routes.
    """
    token = credentials.credentials

    try:
        # Options de décodage
        options = {
            "verify_signature": True,
            "verify_exp": True,
            "verify_aud": False,
        }

        # Décoder avec la clé secrète
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET or settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
            options=options
        )

        # Extraire le subject (user_id)
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token invalide: missing subject"
            )

        return UUID(user_id)

    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token invalide: {str(e)}"
        )
```

**Utilisation dans un endpoint :**

```python
# backend/app/api/v1/endpoints/gamification.py

from fastapi import APIRouter, Depends
from app.core.security import get_current_user_id
from uuid import UUID

router = APIRouter()

@router.get("/profile")
async def get_my_gamification(
    user_id: UUID = Depends(get_current_user_id)  # 🔐 Route protégée
):
    """
    Retourne le profil gamification de l'utilisateur connecté.
    L'ID vient du token JWT decode.
    """
    # user_id contient l'UUID de l'utilisateur authentifié
    db = get_supabase_client()
    profile = db.fetch_one("user_profiles", "id", str(user_id))
    return profile
```

### 4.3 Services Principaux

#### AuthService - Gestion de l'authentification

```python
# backend/app/services/auth_service.py

class AuthService:
    """Service central pour toute la logique d'authentification."""

    async def login(self, email: str, password: str) -> AuthResponse:
        """
        1. Vérifie les identifiants via Supabase Auth
        2. Récupère le profil utilisateur dans user_profiles
        3. Génère les tokens JWT
        """
        # Appel Supabase Auth
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

        # Récupérer le profil
        user_id = auth_response.user.id
        profile = self._get_profile(user_id)

        return AuthResponse(
            access_token=self._create_access_token(user_id),
            refresh_token=auth_response.session.refresh_token,
            user=profile
        )

    async def register(
        self,
        email: str,
        password: str,
        first_name: str,
        last_name: str
    ) -> AuthResponse:
        """
        1. Crée le compte via Supabase Auth
        2. Crée l'entrée dans user_profiles avec role='student'
        3. Envoie un email de confirmation
        """
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password
        })

        # Créer le profil
        self._create_profile(
            user_id=auth_response.user.id,
            first_name=first_name,
            last_name=last_name
        )

        return AuthResponse(...)
```

#### OrientationEngine - Tests d'orientation

```python
# backend/app/services/orientation_engine.py

class OrientationEngine:
    """
    Calcule les profils RIASEC et génère des recommandations.
    """

    async def calculate_riasec_profile(
        self,
        answers: list[QuestionAnswer]
    ) -> RIASECProfile:
        """
        Algorithme de calcul du profil:
        - 6 dimensions: Realistic, Investigative, Artistic, Social, Enterprising, Conventional
        - Score de 0 à 100 par dimension
        - Basé sur les réponses aux questions
        """
        scores = {dimension: 0 for dimension in RIASEC_DIMENSIONS}

        for answer in answers:
            question = self._get_question(answer.question_id)
            for dimension, weight in question.riasec_weights.items():
                scores[dimension] += weight * answer.selected_option_value

        # Normaliser sur 100
        max_score = max(scores.values()) or 1
        normalized = {
            dim: int((score / max_score) * 100)
            for dim, score in scores.items()
        }

        return RIASECProfile(**normalized)

    async def match_careers(
        self,
        profile: RIASECProfile
    ) -> list[CareerRecommendation]:
        """
        Trouve les carrières correspondantes:
        1. Récupérer toutes les carrières
        2. Calculer la similarité avec le profil
        3. Trier par score décroissant
        """
        careers = await self._get_all_careers()
        recommendations = []

        for career in careers:
            score = self._calculate_match_score(profile, career.riasec_profile)
            if score > 50:  # Seuil minimum
                recommendations.append(CareerRecommendation(
                    career=career,
                    match_score=score
                ))

        return sorted(recommendations, key=lambda x: x.match_score, reverse=True)
```

#### LLM Service - Chat AÏDA

```python
# backend/app/services/llm_service.py

class LLMService:
    """
    Interface avec Groq (Llama 3) pour le chat AÏDA.
    """

    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.system_prompt = """Tu es AÏDA, assistant d'orientation...
        Tu aides les jeunes à trouver leur voie professionnelle.
        Tu donnes des conseils pratiques et réaliste."""

    async def chat(self, message: str, history: list[Message]) -> str:
        """
        Génère une réponse avec le LLM:
        1. Construit le contexte (history + message)
        2. Appelle Groq API
        3. Filtre le contenu inapproprié
        4. Retourne la réponse
        """
        # Construction messages
        messages = [
            {"role": "system", "content": self.system_prompt}
        ]

        for msg in history[-5:]:  # Garder les 5 derniers messages
            messages.append({
                "role": msg.role,
                "content": msg.content
            })

        messages.append({"role": "user", "content": message})

        # Appel API
        response = self.client.chat.completions.create(
            model="llama-3-70b-versatile",
            messages=messages,
            temperature=0.7,
            max_tokens=500
        )

        return response.choices[0].message.content
```

### 4.4 Schémas de Données (Pydantic)

```python
# backend/app/schemas/auth.py

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from uuid import UUID
from datetime import datetime

class UserProfile(BaseModel):
    """Schema pour les informations utilisateur."""
    id: UUID
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    role: str = "student"  # student, admin, school_admin
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    """Réponse après login/register."""
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 1800  # 30 minutes
    user: UserProfile


class LoginRequest(BaseModel):
    """Requête de connexion."""
    email: EmailStr
    password: str = Field(..., min_length=6)


class RegisterRequest(BaseModel):
    """Requête d'inscription."""
    email: EmailStr
    password: str = Field(..., min_length=6)
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
```

---

## 5. Application Flutter - Étudiants

### 5.1 Architecture Clean Architecture

```
lib/
├── main.dart                    # Point d'entrée de l'application
│
├── app.dart                     # Configuration globale (thème, routing)
│
├── core/                        # ⚙️ Configuration technique
│   ├── di/                      # Injection de dépendances (get_it)
│   │   ├── injection_container.dart
│   │   └── register_module.dart
│   │
│   ├── network/                 # Communication HTTP
│   │   ├── api_client.dart      # Client Dio configuré
│   │   ├── api_endpoints.dart   # URLs des endpoints
│   │   └── auth_interceptor.dart # Ajout du token JWT
│   │
│   ├── router/                  # Navigation
│   │   ├── app_router.dart      # Configuration go_router
│   │   └── auth_guard.dart      # Vérification auth
│   │
│   ├── theme/                  # Design system
│   │   ├── app_colors.dart      # Couleurs (Deep Navy + Amber Gold)
│   │   ├── app_typography.dart # Fonts (Sora, Outfit)
│   │   └── app_theme.dart       # ThemeData complet
│   │
│   └── constants/              # Configs globales
│       └── app_constants.dart
│
├── features/                    # 🎯 Fonctionnalités (Domain-driven)
│   └── [feature_name]/
│       ├── data/                # Couche données
│       │   ├── models/          # Modèles (JSON → Dart)
│       │   ├── datasources/    # Sources (API, local)
│       │   └── repositories/   # Implémentations
│       │
│       ├── domain/              # Couche métier
│       │   ├── entities/        # Objets métier (pure Dart)
│       │   ├── repositories/    # Interfaces (abstractions)
│       │   └── usecases/       # Logique métier
│       │
│       └── presentation/       # Couche UI
│           ├── pages/           # Écrans (Widgets)
│           ├── widgets/        # Composants réutilisables
│           └── bloc/           # Gestion d'état (BLoC)
│
└── shared/                      # ♻️ Code partagé
    └── widgets/
        ├── app_button.dart
        ├── app_text_field.dart
        ├── loading_indicator.dart
        └── error_view.dart
```

**Pourquoi Clean Architecture ?**

| Couche | Responsabilité | Beispiel |
|--------|---------------|-----------|
| **Data** | Accès données, conversion JSON | `UserModel.fromJson()` |
| **Domain** | Règles métier pures | `User entity`, `LoginUseCase` |
| **Presentation** | UI, gestion état | `LoginPage`, `AuthBloc` |

**Avantages :**
- ✅ Testabilité (usecases sans UI)
- ✅ Maintenabilité (séparation préoccupations)
- ✅ Réutilisabilité (entities partagés)
- ✅ Évolutivité (ajouter feature sans casser)

### 5.2 State Management - BLoC Pattern

**Pourquoi BLoC ?**

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUX DE DONNÉES BLoC                     │
│                                                             │
│   User Action          Event              State Change      │
│                                                             │
│   ┌─────────┐      ┌─────────┐       ┌─────────┐          │
│   │ Button  │ ───► │  BLoC   │ ───► │  Widget │          │
│   │ "Login" │      │ Event   │      │  Rebuild│          │
│   └─────────┘      └─────────┘       └─────────┘          │
│                         │                 ▲                │
│                         ▼                 │                │
│                  ┌─────────────┐          │                │
│                  │  Repository │          │                │
│                  │   (API)     │──────────┘                │
│                  └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

**Exemple - AuthBloc :**

```dart
// events/auth_event.dart
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}
class LogoutRequested extends AuthEvent {}
class AuthStatusChecked extends AuthEvent {}

// states/auth_state.dart
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
```

**Utilisation dans la page :**

```dart
// presentation/pages/login_page.dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return CircularProgressIndicator();
        }
        if (state is AuthError) {
          return Text(state.message);
        }
        return ElevatedButton(
          onPressed: () {
            context.read<AuthBloc>().add(LoginRequested(
              email: _emailController.text,
              password: _passwordController.text,
            ));
          },
          child: Text('Se connecter'),
        );
      },
    );
  }
}
```

### 5.3 Navigation avec go_router

```dart
// core/router/app_router.dart

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Route publique - splash screen
    GoRoute(
      path: '/',
      builder: (context, state) => SplashPage(),
    ),

    // Routes auth
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterPage(),
    ),

    // Shell route avec bottom navigation (authentifié)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomePage(),
        ),
        GoRoute(
          path: '/orientation',
          builder: (context, state) => OrientationPage(),
        ),
        GoRoute(
          path: '/elearning',
          builder: (context, state) => ElearningPage(),
        ),
        GoRoute(
          path: '/mentors',
          builder: (context, state) => MentorsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfilePage(),
        ),
      ],
    ),

    // Routes nécessitant un paramètre
    GoRoute(
      path: '/schools/:id',
      builder: (context, state) {
        final schoolId = state.pathParameters['id']!;
        return SchoolDetailPage(schoolId: schoolId);
      },
    ),
  ],

  // Guard - redirige si pas connecté
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthBloc>().state is AuthAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' ||
                        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    return null;
  },
);
```

### 5.4 Design System - Deep Navy + Amber Gold

**Philosophie :**
- **Navy (sombre)** : Sidebar, headers, zones de contenu principal
- **Amber (or)** : Accents gamification (badges, XP, succès)
- **Blanc** : Cards, surfaces de contenu
- **Bleu royal** : Actions principales (CTAs)

```dart
// core/theme/app_colors.dart

class AppColors {
  // Primary - Bleu Royal
  static const Color primary = Color(0xFF1060CF);
  static const Color primaryLight = Color(0xFF4A8BE8);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Secondary - Or Ambré (Gamification)
  static const Color secondary = Color(0xFFF2A423);
  static const Color secondaryLight = Color(0xFFF5B84D);
  static const Color secondaryDark = Color(0xFFD08B00);

  // Backgrounds - Deep Navy
  static const Color darkBg = Color(0xFF060E1E);
  static const Color darkBgLight = Color(0xFF0F1E35);
  static const Color surfaceDark = Color(0xFF162236);

  // Surfaces claires
  static const Color background = Color(0xFFF2F5FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8ECF4);

  // Gamification
  static const Color xpBar = Color(0xFF34D399);      // Vert émeraude
  static const Color gold = Color(0xFFF2A423);        // Or
  static const Color bronze = Color(0xFFCD7F32);     // Bronze
  static const Color silver = Color(0xFFC0C0C0);     // Argent
  static const Color streak = Color(0xFFFF6B35);      // Orange feu

  // Status
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
}
```

**Typography :**

```dart
// core/theme/app_typography.dart

class AppTypography {
  // Fonts importées via google_fonts package
  // - Sora: pour les titres (display, headlines)
  // - Outfit: pour le corps de texte
  // - JetBrains Mono: pour les données/code

  static const String fontDisplay = 'Sora';
  static const String fontBody = 'Outfit';
  static const String fontMono = 'JetBrains Mono';

  static TextTheme get textTheme => TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontDisplay,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontDisplay,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontFamily: fontDisplay,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontBody,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontBody,
      fontSize: 14,
    ),
    labelLarge: TextStyle(
      fontFamily: fontBody,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );
}
```

---

## 6. Dashboard Admin

### 6.1 Fonctionnalités par Module

| Module | Fonctionnalités | Tables DB impactées |
|--------|-----------------|-------------------|
| **Dashboard** | Métriques globales, stats utilisateurs, activité récente | user_profiles, orientation_sessions |
| **Users** | Liste, recherche, activation/désactivation, changement rôle | user_profiles |
| **Schools** | CRUD écoles, validation, gestion programmes | schools, school_programs |
| **Careers** | CRUD carrières, secteurs, liens formations | careers, career_schools |
| **Tests** | CRUD tests orientation, questions, options, résultats | orientation_tests, orientation_questions |
| **Gamification** | CRUD badges, défis, achievements utilisateurs | badges, challenges, user_achievements |
| **Mentors** | CRUD mentors, vérification, disponibilité | mentors, mentor_availability |
| **Elearning** | CRUD cours, modules, leçons, progressions | elearning_courses, elearning_modules |
| **Opportunities** | CRUD stages, jobs, bourses, Candidatures | opportunities, applications |
| **Settings** | Configuration, logs d'audit | system_settings, audit_logs |

### 6.2 Interface Admin

```
┌─────────────────────────────────────────────────────────────┐
│  HEADER: Logo + Nom + User Menu                            │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                  │
│ SIDEBAR  │              MAIN CONTENT                        │
│          │                                                  │
│ ┌──────┐ │  ┌─────────────────────────────────────────┐   │
│ │Dashboard│ │  │  Breadcrumb                           │   │
│ ├──────┤ │  ├─────────────────────────────────────────┤   │
│ │Users  │ │  │                                         │   │
│ ├──────┤ │  │  ┌────────┐ ┌────────┐ ┌────────┐      │   │
│ │Schools│ │  │  │ Stats  │ │ Stats  │ │ Stats  │      │   │
│ ├──────┤ │  │  └────────┘ └────────┘ └────────┘      │   │
│ │Careers│ │  │                                         │   │
│ ├──────┤ │  │  ┌─────────────────────────────────┐     │   │
│ │Tests │ │  │  │                                 │     │   │
│ ├──────┤ │  │  │       Data Table / Form         │     │   │
│ │ etc  │ │  │  │                                 │     │   │
│ └──────┘ │  │  └─────────────────────────────────┘     │   │
│          │  └───────────────────────────────────────────┘   │
└──────────┴──────────────────────────────────────────────────┘
```

### 6.3 Gestion des Permissions

```python
# Admin endpoint - avec vérification de rôle

@router.get("/users")
async def list_users(
    current_user: dict = Depends(get_current_admin_user)
):
    """
    Liste tous les utilisateurs.
    Réservé aux admins uniquement.
    """
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=403,
            detail="Accès refusé"
        )

    users = db.fetch_all("user_profiles")
    return users
```

---

## 7. Base de Données et Schemas

### 7.1 Schéma des Tables Principales

```sql
-- ══════════════════════════════════════════════════════════════
-- UTILISATEURS
-- ══════════════════════════════════════════════════════════════

CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    display_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'student',  -- student, admin, school_admin
    total_xp INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_login_at TIMESTAMPTZ,
    organization_id UUID,  -- Pour les partenaires (ONG/CDEJ)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les requêtes fréquentes
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_org ON user_profiles(organization_id);
CREATE INDEX idx_user_profiles_created ON user_profiles(created_at DESC);


-- ══════════════════════════════════════════════════════════════
-- ÉCOLES ET FORMATIONS
-- ══════════════════════════════════════════════════════════════

CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT,  -- university, high_school, vocational
    country TEXT DEFAULT 'SN',  -- Code pays (SN, CI, ML, BF)
    city TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    website TEXT,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    is_public BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    tuition_range TEXT,
    programs_offered TEXT[],  -- Array JSON
    accreditations TEXT[],
    student_count INTEGER,
    founding_year INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE school_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id),
    name TEXT NOT NULL,
    level TEXT,  -- licence, master, bts
    duration_years INTEGER,
    description TEXT,
    tuition_cost INTEGER,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0
);

CREATE TABLE school_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id),
    image_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 0
);


-- ══════════════════════════════════════════════════════════════
-- CARRIÈRES ET MÉTIERS
-- ══════════════════════════════════════════════════════════════

CREATE TABLE careers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    sector TEXT,  -- tech, health, education, business...
    salary_range TEXT,
    riasec_profile JSONB,  -- {R: 30, I: 80, A: 20, S: 60, E: 40, C: 70}
    required_skills TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE career_schools (
    career_id UUID REFERENCES careers(id),
    school_id UUID REFERENCES schools(id),
    PRIMARY KEY (career_id, school_id)
);


-- ══════════════════════════════════════════════════════════════
-- TESTS D'ORIENTATION
-- ══════════════════════════════════════════════════════════════

CREATE TABLE orientation_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    type TEXT,  -- riasec, personality, aptitude
    description TEXT,
    difficulty TEXT,  -- beginner, intermediate, advanced
    time_limit_minutes INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE orientation_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID REFERENCES orientation_tests(id),
    text TEXT NOT NULL,
    question_order INTEGER,
    riasec_weights JSONB NOT NULL  -- {R: 0.8, I: 0.2, ...}
);

CREATE TABLE question_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID REFERENCES orientation_questions(id),
    text TEXT NOT NULL,
    option_value INTEGER,  -- Score pour ce choix
    display_order INTEGER
);

CREATE TABLE orientation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    test_id UUID REFERENCES orientation_tests(id),
    status TEXT DEFAULT 'not_started',  -- not_started, in_progress, completed
    current_question_index INTEGER DEFAULT 0,
    answers JSONB DEFAULT '[]',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    result_riasec JSONB
);

CREATE TABLE test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES orientation_sessions(id),
    user_id UUID REFERENCES user_profiles(id),
    profile_riasec JSONB NOT NULL,
    recommendations JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ══════════════════════════════════════════════════════════════
-- E-LEARNING
-- ══════════════════════════════════════════════════════════════

CREATE TABLE elearning_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    difficulty TEXT,
    thumbnail_url TEXT,
    duration_minutes INTEGER,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE elearning_modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES elearning_courses(id),
    title TEXT NOT NULL,
    description TEXT,
    display_order INTEGER
);

CREATE TABLE elearning_lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID REFERENCES elearning_modules(id),
    title TEXT NOT NULL,
    content_type TEXT,  -- video, text, quiz
    content TEXT,  -- Markdown pour texte, URL pour video
    duration_minutes INTEGER,
    display_order INTEGER
);

CREATE TABLE elearning_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    course_id UUID REFERENCES elearning_courses(id),
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

CREATE TABLE elearning_user_progress (
    user_id UUID REFERENCES user_profiles(id),
    lesson_id UUID REFERENCES elearning_lessons(id),
    status TEXT DEFAULT 'not_started',  -- not_started, in_progress, completed
    completed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, lesson_id)
);


-- ══════════════════════════════════════════════════════════════
-- GAMIFICATION
-- ══════════════════════════════════════════════════════════════

CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    xp_reward INTEGER DEFAULT 0,
    criteria JSONB  -- {type: "courses_completed", count: 5}
);

CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    badge_id UUID REFERENCES badges(id),
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    points INTEGER DEFAULT 0,
    challenge_type TEXT,  -- daily, weekly, one_time
    criteria JSONB,
    is_active BOOLEAN DEFAULT true,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ
);

CREATE TABLE user_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    challenge_id UUID REFERENCES challenges(id),
    status TEXT DEFAULT 'not_started',
    score INTEGER,
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, challenge_id)
);


-- ══════════════════════════════════════════════════════════════
-- MENTORS
-- ══════════════════════════════════════════════════════════════

CREATE TABLE mentors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    full_name TEXT NOT NULL,
    specialty TEXT,
    bio TEXT,
    avatar_url TEXT,
    years_experience INTEGER,
    hourly_rate INTEGER,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    rating DECIMAL(3,2) DEFAULT 0,
    available_slots JSONB
);

CREATE TABLE mentor_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id UUID REFERENCES mentors(id),
    is_available BOOLEAN DEFAULT true,
    available_from TIMESTAMPTZ,
    available_to TIMESTAMPTZ
);

CREATE TABLE mentor_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id UUID REFERENCES mentors(id),
    user_id UUID REFERENCES user_profiles(id),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ══════════════════════════════════════════════════════════════
-- OPPORTUNITÉS (Stages, Jobs, Bourses)
-- ══════════════════════════════════════════════════════════════

CREATE TABLE opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    opportunity_type TEXT NOT NULL,  -- internship, job, volunteer, scholarship
    organization_name TEXT,
    organization_logo TEXT,
    location TEXT,
    remote_type TEXT,  -- onsite, remote, hybrid
    duration TEXT,
    requirements TEXT[],
    benefits TEXT[],
    salary_min INTEGER,
    salary_max INTEGER,
    salary_currency TEXT DEFAULT 'EUR',
    application_url TEXT,
    application_deadline TIMESTAMPTZ,
    is_published BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 7.2 Row Level Security (RLS)

```sql
-- Activation RLS sur user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users peuvent lire leur propre profil
CREATE POLICY "Users can read own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

-- Users peuvent lire tous les profils (pour leaderboard)
CREATE POLICY "Users can read all profiles"
ON user_profiles FOR SELECT
USING (true);

-- Admins peuvent tout modifier
CREATE POLICY "Admins can do everything"
ON user_profiles FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    )
);
```

---

## 8. API Endpoints Référence

### 8.1 Auth

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "id": "uuid",
    "email": "john@example.com",
    "first_name": "John",
    "role": "student"
  }
}
```

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe"
}
```

### 8.2 Schools

```http
GET /api/v1/schools?page=1&per_page=20&city=Dakar&type=university

Response:
{
  "items": [
    {
      "id": "uuid",
      "name": "Université Cheikh Anta Diop",
      "type": "university",
      "city": "Dakar",
      "logo_url": "https://...",
      "programs_count": 45
    }
  ],
  "total": 120,
  "page": 1,
  "per_page": 20
}
```

### 8.3 Gamification

```http
GET /api/v1/gamification/profile
Authorization: Bearer <token>

Response:
{
  "stats": {
    "total_xp": 1250,
    "current_level": 4,
    "current_streak": 7,
    "longest_streak": 14,
    "total_achievements": 8,
    "completed_challenges": 5
  },
  "achievements": [
    {
      "id": "uuid",
      "achievement_type": "first_course",
      "earned_at": "2026-01-15T10:30:00Z"
    }
  ],
  "active_challenges": [
    {
      "id": "uuid",
      "challenge_id": "uuid",
      "title": "Compléter 3 leçons",
      "points": 100,
      "status": "in_progress",
      "score": 2
    }
  ],
  "next_level_xp": 1500,
  "xp_to_next_level": 250
}
```

---

## 9. Fonctionnalités Détaillées

### 9.1 Système de Gamification

**Calcul du niveau :**
```python
def calculate_level(total_xp: int) -> int:
    """
    Formula: level = floor(sqrt(xp / 100)) + 1

    Exemples:
    - 0 XP → Niveau 1
    - 100 XP → Niveau 2
    - 400 XP → Niveau 3
    - 900 XP → Niveau 4
    - 1600 XP → Niveau 5
    """
    return int(math.sqrt(total_xp / 100)) + 1
```

**Sources d'XP :**
| Action | XP |
|--------|-----|
| Compléter un test d'orientation | 50 |
| Terminer un cours e-learning | 100 |
| Compléter une leçon | 20 |
| Terminer un défi quotidien | 30 |
| Maintenir un streak (par jour) | 10 |
| Obtenir un badge | 50-200 |

**Badges disponibles :**
- 🎓 Premier cours terminé
- 📚 5 cours complétés
- 🏆 Premier défi terminé
- 🔥 7 jours de streak
- 💯 1000 XP accumulés
- 🌟 Premier mentor contacté

### 9.2 Tests d'Orientation RIASEC

**Le modèle RIASEC :**

| Code | Type | Métiers exemples |
|------|------|-----------------|
| R | Realistic | Ingénieur, mécanicien, technician |
| I | Investigative | Chercheur, médecin, analyste |
| A | Artistic | Designer, écrivain, musique |
| S | Social | Enseignant, infirmier, counselor |
| E | Enterprising | Manager, entrepreneur, avocat |
| C | Conventional | Comptable, administratif, analyste |

**Flux du test :**

```
1. GET /api/v1/orientation/tests
   → Liste des tests disponibles

2. POST /api/v1/orientation/tests/{id}/start
   → Crée une session, retourne questions

3. POST /api/v1/orientation/sessions/{id}/answer
   → Soumet une réponse à la question courante

4. POST /api/v1/orientation/sessions/{id}/complete
   → Termine le test, calcule le profil

5. GET /api/v1/orientation/sessions/{id}/results
   → Retourne le profil RIASEC + recommandations
```

### 9.3 Chat AÏDA

**Caractéristiques :**
- Model : Llama 3 (via Groq)
- System prompt optimisé pour l'orientation
- Filtre de sécurité (pas de contenu inapproprié)
- History des 5 derniers messages

**Limites :**
- 500 tokens max par réponse
- Rate limiting: 10 requêtes/minute
- Context: 5 messages d'historique

---

## 10. Déploiement et Infrastructure

### 10.1 Prérequis

```bash
# Serveur (Hostinger VPC ou equivalent)
- Ubuntu 22.04 LTS
- 4 vCPU, 8GB RAM, 100GB SSD
- Domain configuré avec DNS

# Logiciels
- Docker 24+
- Docker Compose 2+
- Git
```

### 10.2 Configuration DNS

| Type | Nom | Valeur |
|------|-----|--------|
| A | activeducationhub.com | @ → IP serveur |
| A | admin.activeduhub.com | @ → IP serveur |
| A | api.activeduhub.com | @ → IP serveur |
| CNAME | www | → activeducationhub.com |

### 10.3 Variables d'Environnement

```env
# backend/.env.production

# Environment
ENVIRONMENT=production
DEBUG=false

# Supabase (obligatoire)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_JWT_SECRET=your-jwt-secret-from-supabase-dashboard

# Security (générer avec: python -c "import secrets; print(secrets.token_urlsafe(48))")
SECRET_KEY=your-64-char-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Redis
REDIS_PASSWORD=your-redis-password
REDIS_URL=redis://:password@redis:6379/0

# LLM (optionnel - pour AÏDA)
GROQ_API_KEY=sk-...

# CORS (adresses autorisées en production)
BACKEND_CORS_ORIGINS=https://activeduhub.com,https://admin.activeduhub.com

# Monitoring (optionnel)
SENTRY_DSN=
```

### 10.4 Commandes de Déploiement

```bash
# 1. Cloner le projet
git clone https://github.com/activeducation/activeducation_plateform.git
cd activeducation_plateform

# 2. Configuration
cp backend/.env.example backend/.env.production
# Éditer backend/.env.production avec vos valeurs

# 3. Build et start
docker compose up -d --build

# 4. Vérifier les services
docker compose ps

# 5. Logs
docker compose logs -f backend
docker compose logs -f traefik

# 6. Mettre à jour
git pull
docker compose up -d --build
```

### 10.5 Architecture de Production

```
┌─────────────────────────────────────────────────────────────┐
│                         VPS                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   Traefik (Docker)                   │  │
│  │        SSL Let's Encrypt + Routing                   │  │
│  └─────────────────────┬────────────────────────────────┘  │
│                        │                                    │
│     ┌──────────────────┼──────────────────┐                │
│     │                  │                  │                │
│  ┌──▼──────┐     ┌─────▼─────┐    ┌──────▼─────┐        │
│  │  App    │     │   Admin   │    │   Backend   │        │
│  │ Nginx   │     │  Nginx    │    │  FastAPI    │        │
│  │         │     │           │    │  (uvicorn)   │        │
│  └─────────┘     └───────────┘    └──────┬──────┘        │
│                                           │                │
│                                    ┌──────▼──────┐         │
│                                    │    Redis    │         │
│                                    │   (Cache)   │         │
│                                    └──────┬──────┘         │
│                                           │                │
│                                    ┌──────▼──────┐         │
│                                    │  Supabase   │         │
│                                    │ (PostgreSQL)│         │
│                                    └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

---

## 11. Guide de Développement

### 11.1 Installation Locale

**Backend :**

```bash
# 1. Créer l'environnement virtuel
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows

# 2. Installer les dépendances
pip install -r requirements.txt

# 3. Configuration
cp .env.example .env
# Éditer .env avec vos credentials

# 4. Lancer le serveur
uvicorn app.main:app --reload --port 8000
```

**Frontend (Flutter) :**

```bash
# 1. Installer Flutter
# https://docs.flutter.dev/get-started/install

# 2. Installer les dépendances
cd activ_education_app
flutter pub get

# 3. Lancer en mode développement
flutter run -d chrome

# 4. Build web
flutter build web --release
```

### 11.2 Standards de Code

**Backend (Python) :**

```bash
# Formatage avec black
black app/ --line-length=100

# Linting avec flake8
flake8 app/ --max-line-length=100

# Type checking avec mypy
mypy app/

# Tests
pytest tests/ -v --cov=app --cov-report=html
```

**Frontend (Flutter) :**

```bash
# Analyse
flutter analyze

# Formatage
flutter format .

# Tests
flutter test

# Build
flutter build web --release
```

### 11.3 Git Workflow

```bash
# 1. Créer une branche
git checkout -b feature/mon-feature

# 2. Commit avec conventional commits
git commit -m "feat: ajout de la page mentors"

# Types de commits:
# - feat: nouvelle fonctionnalité
# - fix: correction de bug
# - docs: documentation
# - refactor: refactoring
# - test: ajout tests
# - chore: maintenance

# 3. Pousser
git push origin feature/mon-feature

# 4. Créer une PR sur GitHub
# Review, puis merge sur main
```

---

## 12. Sécurité et Bonnes Pratiques

### 12.1 Sécurité des Données

**Règles importantes :**

1. **Ne jamais commiter les secrets**
   - `.env` dans `.gitignore`
   - Utiliser des secrets GitHub Actions pour la CI

2. **Valider les entrées**
   - Pydantic pour la validation des API
   - Never trust user input

3. **HTTPS everywhere**
   - SSL automatique via Traefik
   - HSTS header activé

4. **CORS strict**
   - Whitelist des domaines autorisés
   - Pas de wildcard en production

### 12.2 Protection des Endpoints

```python
# Exemple: Endpoint protégé avec vérification de rôle

from fastapi import Depends, HTTPException
from app.core.security import get_current_user_id, get_current_admin

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: UUID,
    admin: dict = Depends(get_current_admin)  # Vérifie role=admin
):
    # Logique de suppression
    return {"message": "User deleted"}
```

### 12.3 Rate Limiting

- **Global**: 100 req/min par IP (Traefik)
- **Auth**: 5 req/min (FastAPI)
- **LLM (AÏDA)**: 10 req/min

---

## 13. Optimisations de Performance

### 13.1 Corrections N+1

**Problème identifié :**
```python
# AVANT - Requête N+1
for school in schools:
    count = db.query("SELECT COUNT(*) FROM school_programs WHERE school_id = ?", school.id)
    # 21 requêtes pour 20 écoles!
```

**Solution appliquée :**
```python
# APRÈS - Requête groupée
school_ids = [s.id for s in schools]
counts = db.query("""
    SELECT school_id, COUNT(*) as count
    FROM school_programs
    WHERE school_id IN ($1)
    GROUP BY school_id
""", school_ids)
# 1 seule requête!
```

### 13.2 Cache Redis

**Stratégie de cache :**

| Type de données | TTL | Invalidation |
|----------------|-----|--------------|
| Lists (schools, mentors) | 10 min | Via webhook ou manual |
| Détails (school, mentor) | 5 min | Via webhook ou manual |
| Profils utilisateur | 2 min | Lors mise à jour |
| Gamification | 1 min | Automatique (court TTL) |

### 13.3 Index Database

**Index créés :**

```sql
-- Schools
CREATE INDEX idx_schools_city_type ON schools(city, type);
CREATE INDEX idx_schools_is_active ON schools(is_active);

-- Users
CREATE INDEX idx_user_profiles_org ON user_profiles(organization_id);

-- Elearning
CREATE INDEX idx_elearning_enrollments_user_course ON elearning_enrollments(user_id, course_id);

-- Gamification
CREATE INDEX idx_gamification_points_user ON gamification_points(user_id);
```

### 13.4 Optimisations Nginx

- **gzip** : Compression des réponses (60% réduction bande passante)
- **open_file_cache** : Cache metadata fichiers (-30% temps accès)
- **Cache statique** : 1 an pour assets avec hash (immutable)

---

## 14. Scalabilité et Évolutivité

### 14.1 État Actuel

| Métrique | Valeur |
|----------|--------|
| Utilisateurs supportés | ~50,000 |
| Requêtes DB/page écoles | 2 (après optimisation) |
| Temps de réponse API | ~50-100ms |
| Cache hit rate | ~70% |

### 14.2 Plan d'Évolution

**Phase 2 - Court terme (1-2 mois) :**
- Scaling horizontal (plusieurs instances backend)
- CDN pour assets statiques (Cloudflare)

**Phase 3 - Moyen terme (2-3 mois) :**
- Queue async (BullMQ) pour emails, notifications
- Monitoring avancé (Prometheus + Grafana)

**Phase 4 - Long terme (6+ mois) :**
- Read replicas Supabase Pro
- Migration Kubernetes avec auto-scaling

### 14.3 Monitoring

**Métriques à suivre :**

```yaml
# À implémenter avec Prometheus
- requests_total         # Requêtes par endpoint
- request_duration       # Latence P95/P99
- errors_total           # Erreurs par type
- cache_hits_total       # Cache hit/miss
- database_connections   # Connections DB actives
- redis_memory          # Mémoire Redis utilisée
```

---

## 15. Dépannage et FAQ

### 15.1 Problèmes Courants

**"SECRET_KEY required"**
```bash
# Vérifier que .env est configuré
cat backend/.env | grep SECRET_KEY

# Générer une clé secrète
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

**"Erreur 401 Unauthorized"**
```bash
# Vérifier le token JWT
# Le token expire après 30 minutes
# Utiliser le refresh token pour renouvelle
```

**"Erreur Supabase connection"**
```bash
# Vérifier les clés API dans le dashboard Supabase
# SUPABASE_URL et SUPABASE_KEY doivent être corrects
```

**"Flutter build failed"**
```bash
cd activ_education_app
flutter clean
flutter pub get
flutter build web --release
```

### 15.2 FAQ

**Q: Comment ajouter un nouvel endpoint ?**
1. Créer le endpoint dans `backend/app/api/v1/endpoints/`
2. Ajouter le routeur dans `backend/app/api/v1/router.py`
3. Ajouter les tests dans `backend/tests/`

**Q: Comment ajouter une nouvelle feature Flutter ?**
1. Créer le dossier `lib/features/[nom_feature]/`
2. Implémenter les couches data/domain/presentation
3. Ajouter les routes dans `app_router.dart`
4. Ajouter les tests

**Q: Comment déployer en production ?**
1.Configurer les variables d'environnement
2.Exécuter `docker compose up -d --build`
3.Vérifier les logs avec `docker compose logs -f`

**Q: Comment fonctionne l'authentification ?**
- Supabase Auth génère un JWT
- FastAPI valide le JWT avec la clé secrète
- L'ID utilisateur est extrait du token

---

## Annexe : Glossaire

| Terme | Definition |
|-------|------------|
| **RIASEC** | Modèle d'orientation professionnel (Realistic, Investigative, Artistic, Social, Enterprising, Conventional) |
| **RLS** | Row Level Security - Sécurité au niveau des lignes PostgreSQL |
| **BLoC** | Business Logic Component - Pattern de gestion d'état en Flutter |
| **TTL** | Time To Live - Durée de vie d'une entrée cache |
| **N+1** | Anti-pattern où N requêtes sont faites au lieu d'une |
| **CDN** | Content Delivery Network - Distribution de contenu géographiquement distribuée |
| **HPA** | Horizontal Pod Autoscaler - Auto-scaling Kubernetes |

---

*Document généré automatiquement. Dernière mise à jour : Mai 2026*
*Version: 2.0*