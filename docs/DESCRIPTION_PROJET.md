# ActivEducation — description complète du projet

## Vision

ActivEducation est une plateforme numérique d'orientation scolaire et professionnelle destinée en priorité aux jeunes d'Afrique de l'Ouest. Elle réunit, dans un même environnement, l'exploration des métiers, les tests d'orientation, l'accès à des établissements et des formations, le mentorat, l'e-learning et les opportunités. La plateforme cherche à rendre l'information d'orientation plus accessible, plus concrète et plus engageante grâce à la personnalisation et à la gamification.

Le projet est construit comme un écosystème : une expérience étudiant, un site web étudiant moderne, un back-office pour les équipes de gestion et un portail pour les organisations partenaires et les écoles. Tous ces clients utilisent une API REST commune.

## Publics et rôles

| Public | Usage principal |
| --- | --- |
| Élèves, étudiants et jeunes actifs | Découvrir des métiers, construire un projet, apprendre et trouver des opportunités. |
| Mentors | Partager leur expérience et accompagner des jeunes. |
| Écoles et universités | Rendre leur offre visible et, selon leurs droits, gérer leur espace établissement. |
| Organisations partenaires | Créer une organisation et suivre leurs bénéficiaires. |
| Administrateurs | Publier, modérer, administrer les utilisateurs, les contenus et les données de la plateforme. |

Les rôles applicatifs comprennent notamment l'utilisateur standard, le mentor, l'administrateur d'école, le partenaire, l'administrateur et le super-administrateur. Les droits sont vérifiés côté API et dans les interfaces protégées.

## Fonctionnalités côté étudiant

### Compte et personnalisation

L'utilisateur peut créer un compte, se connecter et suivre un onboarding. Ce parcours recueille les informations de profil, les centres d'intérêt et les objectifs afin de personnaliser les recommandations. Le profil permet ensuite de consulter ou modifier ses informations et de visualiser sa progression.

### Orientation scolaire et professionnelle

Le module Orientation propose des tests, notamment des parcours de type RIASEC, pour identifier les intérêts et les aptitudes. Les résultats produisent des recommandations de domaines et de métiers. Chaque fiche métier peut présenter sa description, les compétences attendues, les formations associées, les secteurs, les perspectives et des informations salariales lorsqu'elles sont disponibles.

### Annuaire des écoles et formations

Les utilisateurs peuvent rechercher et filtrer les écoles, universités, instituts et centres de formation. Les fiches établissement regroupent la présentation, les filières, les conditions d'admission, les coordonnées, les accréditations et les informations pratiques disponibles. Les recherches peuvent aussi porter sur un BTS, une formation ou un métier.

### E-learning et progression ludique

Le catalogue de cours permet de suivre des parcours organisés en modules et leçons. Les leçons prennent en charge plusieurs formats : vidéo, article, document, quiz et challenge. Des examens de fin de cours mesurent l'acquisition des connaissances.

La dimension ludique repose sur l'expérience (XP), les niveaux, les badges, les défis, les séries d'activité (*streaks*), la page « Ma Saga » et un classement. Elle met en valeur les progrès et encourage la régularité sans remplacer le contenu pédagogique.

### Mentorat et opportunités

L'annuaire des mentors donne accès aux profils, spécialités, expériences et localisations des professionnels volontaires. Les professionnels peuvent envoyer une candidature pour devenir mentor.

Le module Opportunités centralise les offres pertinentes : stages, bourses, événements ou autres possibilités d'accompagnement. Les annonces et les raccourcis depuis l'accueil facilitent également l'accès à ces informations.

### AÏDA, l'assistant conversationnel

AÏDA est l'assistant de la plateforme. À travers une interface de conversation, il accompagne la recherche d'une voie, d'un métier, d'une filière, d'une école ou d'un cours. Le service est relié au backend, qui gère les prompts, la sécurité et les sessions de conversation.

## Interfaces du projet

| Composant | Dossier | Technologie | Rôle |
| --- | --- | --- | --- |
| Application étudiant | `activ_education_app/` | Flutter / Dart | Application responsive, destinée au mobile et au web. |
| Frontend étudiant web | `frontend/` | Next.js, React, TypeScript, Tailwind | Version web moderne alignée page par page avec l'expérience mobile. |
| Dashboard d'administration | `admin_dashboard/` | Flutter / Dart | Back-office et portail établissement. |
| Landing page | `landing/` | HTML, CSS, JavaScript | Présentation publique et point d'entrée marketing. |
| API | `backend/` | FastAPI / Python | Logique métier, données, sécurité et API REST. |
| Bibliothèque partagée | `packages/shared_core/` | Dart | Utilitaires Dart communs. |

### Application Flutter étudiant

L'application Flutter organise le code par fonctionnalités avec une séparation entre domaine, données et présentation. Elle utilise BLoC/Cubit pour l'état, `go_router` pour la navigation, Dio pour les appels API, Supabase pour l'authentification et un stockage sécurisé pour les jetons. L'interface est adaptée aux petits écrans avec une barre de navigation basse ; sur écran large, elle peut utiliser une disposition différente. Les principales rubriques sont Accueil, Orientation, Cours, Mentors, Écoles et Profil.

### Frontend Next.js

Le dossier `frontend/` contient une expérience étudiant rendue avec Next.js. Il comprend les routes d'accueil, connexion, inscription, onboarding, profil, classement, cours et examens, leçons, saga, succès, écoles, mentors, orientation, opportunités, recherche et AÏDA. Il utilise React Query pour la gestion des données côté client et reprend les usages du produit mobile dans une interface web.

### Dashboard d'administration et portail école

Le dashboard permet de gérer les utilisateurs, établissements, métiers, tests d'orientation, cours, modules, leçons, examens, badges, défis, mentors, opportunités, partenaires, réglages et contenus de la base de connaissances. Il contient des tableaux de données, des éditeurs, des uploads d'images et des vues de suivi.

Le portail école est une partie contrôlée par rôle du dashboard. Il permet aux responsables d'établissement d'administrer leur profil, leur offre de cours et leur tableau de bord selon les autorisations fournies.

## Architecture technique

```text
Utilisateur web ou mobile
        │
        ├── Application Flutter / Frontend Next.js / Dashboard Flutter / Landing page
        │                         │
        └─────────────────────────┴── API REST FastAPI (/api/v1)
                                             │
                             ┌───────────────┼────────────────┐
                             │               │                │
                       Supabase         Redis            Service AÏDA
                  PostgreSQL/Auth/    cache et          modèle de langage
                     Storage            sessions
```

Le backend est le point central de l'architecture. Il valide les requêtes avec Pydantic, applique l'authentification Supabase et le contrôle d'accès par rôle, exécute la logique métier et retourne des réponses JSON. Son organisation suit les couches suivantes :

```text
Endpoint HTTP → Service métier → Repository → client Supabase → PostgreSQL
```

Les données sont hébergées dans Supabase : PostgreSQL pour les données applicatives, Auth pour les identités et Storage pour les médias. Le backend ne s'appuie pas sur SQLAlchemy en exécution ; il utilise le client Supabase/PostgREST. Alembic est utilisé pour versionner les migrations de schéma. Redis sert de cache et de support aux mécanismes qui en ont besoin.

## Modules de l'API

L'API versionnée sous `/api/v1` couvre notamment :

- l'authentification, le profil et les rôles ;
- les écoles, les programmes et le portail établissement ;
- les métiers, les tests, les résultats et les recommandations d'orientation ;
- les cours, modules, leçons, quiz, examens et la progression e-learning ;
- les XP, badges, défis, succès et classements ;
- les mentors et les candidatures de mentors ;
- les opportunités, annonces et la recherche globale ;
- AÏDA et la base de connaissances ;
- les organisations partenaires et leurs bénéficiaires ;
- les endpoints d'administration, d'upload et de réglages.

## Déploiement et infrastructure

Le dépôt contient une infrastructure Docker Compose. En production, Traefik assure le rôle de reverse proxy HTTPS et la gestion des certificats TLS. Il route les requêtes vers les services applicatifs. Nginx sert les fichiers statiques de la landing page, de l'application Flutter et du dashboard. Le backend FastAPI, Redis et un proxy de socket Docker complètent l'environnement.

```text
Internet → Traefik (HTTPS, routage, limites) → Nginx ou FastAPI
                                              ├→ Flutter web / landing
                                              ├→ dashboard admin
                                              └→ Supabase et Redis via l'API
```

Les builds Flutter utilisent une URL d'API injectée à la compilation. Une différence importante est conservée entre les deux applications Flutter : l'application étudiant attend une base d'URL sans `/api/v1`, alors que le dashboard admin attend une base d'URL qui inclut déjà `/api/v1`.

## Sécurité et qualité

La plateforme prévoit des contrôles de configuration pour éviter les secrets ou CORS non sûrs en production. Les jetons sont conservés dans un stockage sécurisé côté client, les appels sont authentifiés et les permissions sont évaluées par rôle. L'API dispose de limitation de débit, en-têtes de sécurité, compression, journalisation corrélée et gestion d'erreurs structurée. Sentry peut être activé pour l'observabilité.

Le projet est couvert par des workflows CI/CD : contrôle du backend, tests et migrations ; analyse et build des frontends ; déploiement de staging depuis `develop` et déploiement de production contrôlé depuis `main`. Les tests backend utilisent Pytest et les applications Flutter s'appuient sur `flutter analyze` et les tests Flutter.

## Arborescence simplifiée

```text
activeducation_plateform/
├── activ_education_app/   # application Flutter étudiant
├── frontend/              # frontend étudiant Next.js
├── admin_dashboard/       # back-office et portail école Flutter
├── backend/               # API FastAPI, tests et migrations Alembic
├── packages/shared_core/  # package Dart commun
├── landing/               # site vitrine statique
├── nginx/                 # configurations de serveurs web
├── traefik/               # reverse proxy, TLS et routage
├── docs/                  # documentation fonctionnelle et technique
├── docker-compose.yml     # services de production
└── docker-compose.dev.yml # surcharges de développement
```

## Résumé

ActivEducation n'est pas seulement un annuaire ou une application de cours : c'est une plateforme d'accompagnement du parcours d'orientation. Elle part de la connaissance de soi (profil et tests), conduit vers l'exploration (métiers, écoles et mentors), aide à agir (cours et opportunités) et soutient l'engagement dans la durée (XP, badges, défis et accompagnement AÏDA). Son architecture sépare clairement l'expérience étudiant, l'administration, les partenaires et les données pour permettre au produit d'évoluer avec ses utilisateurs.

## Documents complémentaires

- [Documentation globale](DOCUMENTATION.md)
- [Documentation de l'application Flutter étudiant](../activ_education_app/DOCUMENTATION_FLUTTER.md)
- [Documentation du backend](../backend/DOCUMENTATION_BACKEND.md)
- [Documentation du dashboard admin](../admin_dashboard/DOCUMENTATION_ADMIN.md)
- [Description des pages mobiles](MOBILE_LOGIN_ECOLES.md)
- [Inventaire de toutes les pages](INVENTAIRE_PAGES.md)
