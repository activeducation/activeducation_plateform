# Plan d'amélioration de la scalabilité - ActivEducation

## Contexte
Le projet peut gérer ~50k utilisateurs actuellement. Pour atteindre le million+, des investissements sont nécessaires.

---

## Statut des optimizations

| Action | Status | Date |
|--------|--------|------|
| Correction N+1 schools_repository.py | ✅ Terminé | 2026-05-11 |
| Correction N+1 admin/schools_repository.py | ✅ Terminé | 2026-05-11 |
| Index DB (migration 009) | ✅ Script créé, en attente exécution | 2026-05-11 |
| Cache mentors | ✅ Terminé | 2026-05-11 |
| Cache opportunities | ✅ Terminé | 2026-05-11 |
| Cache gamification (profile + leaderboard) | ✅ Terminé | 2026-05-11 |
| Optimisation Nginx (app.conf) | ✅ Terminé | 2026-05-11 |
| Optimisation Nginx (admin.conf) | ✅ Terminé | 2026-05-11 |

**Prochaine étape:** Exécuter `backend/docs/migration_009_indexes.sql` dans Supabase SQL Editor

---

## Phase 1: Optimisations critiques (Impact immédiat)

### 1.1 Corriger le N+1 dans les repositories

**Problème**: `schools_repository.py:53` fait une requête SQL par école affichée.

**Solution**: Requête groupée avec JOIN ou subquery.

```
Fichiers à modifier:
- backend/app/repositories/schools_repository.py
- backend/app/repositories/users_repository.py
- backend/app/repositories/elearning_repository.py

Action: Lister tous les repositories et identifier les boucles avec appels DB inside
```

### 1.2 Ajouter du caching plus intelligent

**Problème**: Cache basique, pas de cache par utilisateur.

**Solution**:
- Cache par utilisateur pour données personnelles (profile, progress)
- Cache invalidé lors des mutations
- Warmup cache sur les endpoints populaires au démarrage

```
Fichiers à modifier:
- backend/app/core/cache.py (enrichir le décorateur @cached)
- Ajouter cache pour user:{user_id}:dashboard
- Ajouter cache pour elearning:{course_id}:progress:{user_id}
```

### 1.3 Ajouter des index manquants

**Problème**: Certaines colonnes filtrées n'ont pas d'index.

**Solution**: Créer migration Alembic pour ajouter les index identifiés.

```sql
-- Migration à créer: 009_add_scalability_indexes.sql
CREATE INDEX IF NOT EXISTS idx_schools_city_type ON schools(city, type);
CREATE INDEX IF NOT EXISTS idx_schools_is_active ON schools(is_active);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created ON user_profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_course ON elearning_enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_gamification_points_user ON gamification_points(user_id);
```

**Effort**: 2-3 jours | **Impact**: Moyen

---

## Phase 2: Infrastructure (Préparer le scaling)

### 2.1 Préparer le scaling horizontal

**Changement**: Passer d'un docker-compose statique à une config qui supporte plusieurs instances.

```
docker-compose.yml → ajouter:
- backend:
    deploy:
      replicas: 2  # Commencer à 2,上限取决于负载
  
Traefik doit load balancer entre les replicas
```

**Prérequis**:
- Session store partagé (Redis au lieu de mémoire locale pour tokens)
- Les variables d'environnement doivent être les mêmes pour toutes les instances

**Fichiers à modifier**:
- docker-compose.yml
- backend/app/core/security.py (stocker sessions dans Redis)

### 2.2 Configurer Redis pour les sessions

**Problème**: Les tokens JWT sont validés localement (pas scalable).

**Solution**: Stocker les tokens actifs dans Redis avec TTL.

```
Fichiers à modifier:
- backend/app/core/security.py → modifier token validation
- Ajouter validation Redis au lieu de cache local uniquement

Workflow:
1. Vérifier Redis pour token actif (clé: token:{jwt_id})
2. Si absent, vérifier blacklist (token révoqué)
3. Si absent, valider JWT (fallback)
```

**Effort**: 3-4 jours | **Impact**: Élevé

### 2.3 Ajouter un CDN pour les assets statiques

**Problème**: Images/logo servis par Nginx sans cache longue durée.

**Solution**: Intégrer Cloudflare ( gratuit pour petit usage) ou configuration Nginx plus agressive.

```
Option A - Cloudflare (recommandé):
1. Mettre api.activeduhub.com, activeducationhub.com, admin.activeduhub.com derrière Cloudflare
2. Configurer page rules pour cache everything sur /static/*
3. Ajouter cache-control headers dans responses API

Option B - Nginx only:
- Modifier nginx/app.conf pour ajouter expires 30d sur /static/*
- Ajouter gzip sur tous les fichiers
```

**Effort**: 2 jours | **Impact**: Moyen

---

## Phase 3: Async processing ( Découpler les tâches lourdes)

### 3.1 Implémenter une file d'attente

**Problème**: Envoi emails, notifications, calculs lourds =同步 bloquant.

**Solution**: Queue asynchrone avec BullMQ (Redis-based).

```
Stack recommandée: BullMQ + Redis (déjà présent)

Tâches à découpler:
1. Envoi emails (bienvenue, mot de passe oublié, notifications)
2. Calcul gamification (points, badges)
3. Génération PDF (rapports, certificats)
4. Notifications push
5. Webhooks vers partenaires

Architecture:
┌─────────────┐     ┌──────────┐     ┌──────────────┐
│  API (FastAPI) ──→ │  Redis   │ ──→ │  Worker (Node)│
│                   │  (Queue) │     │  ou Python    │
└─────────────┘     └──────────┘     └──────────────┘
       ↑                                      │
       └────────── (webhook/socket) ←─────────┘
```

**Fichiers à créer**:
- `backend/app/workers/` (dossier workers)
- `backend/app/tasks/email_tasks.py`
- `backend/app/tasks/gamification_tasks.py`
- `backend/worker.py` (entry point)

**Migration step-by-step**:
1. Créer classe `TaskQueue` wrapper autour de Redis
2. Migrer un endpointpilote (ex: envoi email de welcome)
3. Vérifier fonctionnement
4. Migrer les autres endpoints

**Effort**: 5-7 jours | **Impact**: Élevé

### 3.2 Monitoring et alerting

**Améliorations**:
- Ajouter /metrics endpoint (Prometheus format)
- Dashboard Grafana pour visualiser:
  - Requêtes/sec par endpoint
  - Temps de réponse P95, P99
  - Erreurs par type
  - Queue depth (BullMQ)

```
Fichiers à modifier:
- backend/app/main.py (ajouter /metrics avec prometheus_client)
- docker-compose.yml (ajouter Grafana)
```

**Effort**: 2-3 jours | **Impact**: Moyen

---

## Phase 4: Architecture avancée ( millions d'utilisateurs)

### 4.1 Read replicas pour PostgreSQL/Supabase

**Problème**: Toutes les requêtes sur une instance DB.

**Solution**:
```
Si Supabase Pro:
- Activer read replicas dans dashboard Supabase
- Modifier le code pour utiliser read replica pour requêtes SELECT
- Garder master pour writes

Architecture:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Backend   │ ──→ │    Master   │     │  Replica 1  │
│             │     │   (writes)  │ ←── │  (reads)    │
└─────────────┘     └─────────────┘     └─────────────┘
                                              ↑
                                              └── Reads

Code change:
- Créer SupabaseClientRead replica
- Routage automatique read/write
```

**Alternative si pas Supabase Pro**:
- PgBouncer pour connection pooling (réduit les connections DB)

### 4.2 Kubernetes / Docker Swarm

**Problème**: docker-compose ne scale pas automatiquement.

**Solution**: Migration vers Kubernetes ou Swarm avec:
- HPA (Horizontal Pod Autoscaler) basé sur CPU/memory
- Auto-scaling des workers
- Health checks plus sophistiqués

```
Steps:
1. Créer docker-compose-prod.yml (production ready)
2. Ajouter helm charts ou k8s manifests
3. Configurer CI/CD pour déploiement auto
4. Tester HPA avec load testing (k6 ou Locust)
```

### 4.3 API Gateway

**Problème**: Pas de gestion centralisée des APIs.

**Solution**: Ajouter Kong ou Traefik en tant que API Gateway avec:
- Rate limiting par client/API key
- Quotas
- Analytics
- Versioning d'API

---

## Résumé du plan

| Phase | Effort total | Impact | Priorité |
|-------|---------------|--------|----------|
| **Phase 1**: Corrections N+1 + cache + index | 5-7 jours | Élevé | IMMÉDIATE |
| **Phase 2**: Horizontal scaling + CDN | 5-7 jours | Élevé | Court terme (1-2 mois) |
| **Phase 3**: Queue async + monitoring | 7-10 jours | Élevé | Moyen terme (2-3 mois) |
| **Phase 4**: Read replicas + K8s | 10-15 jours | Moyen | Long terme (6+ mois) |

---

## Options gratuites (sans frais mensuels)

Tout ce qui est listé ci-dessus peut être fait **sans payer** initially:

### Gratuit et immédiat (0€)

| Action | Ce que ça remplace | Gain potentiel |
|--------|-------------------|-----------------|
| **Corriger N+1** | Requêtes supplémentaires | -50% temps réponse |
| **Ajouter index** | Scans séquentiels | -70% temps requêtes |
| **Améliorer cache** | Répéter les mêmes requêtes | -80% charge DB |
| **Cache Redis existant** | Appels API répétés | Gratuit (déjà installé) |
| **Nginx gzip + cache static** | Transfert lourd | -60% bande passante |
| **Queue async via Redis** | Traitement synchrone | Gratuit (utilise Redis existant) |

### Gratuit mais demande du travail (temps only)

1. **Corriger les N+1** - 2-3h de dev
2. **Ajouter les index manquants** - 1h (créer migration Alembic)
3. **Optimiser le cache** - 3-4h (meilleur usage du Redis existant)
4. **Config Nginx plus agressive** - 1h (gzip, cache static, compression)
5. **Implémenter BullMQ avec Redis existant** - 3-4 jours (la queue existe déjà!)
6. **Monitoring avec métriques custom** - 2h (pas besoin de Grafana cloud)

### Ce qui nécessite de payer (optionnel)

Ces éléments peuvent être REPORTÉS jusqu'à ce que le traffic le justifie:

| Service | Pourquoi payer | Quand nécessaire |
|---------|-----------------|------------------|
| **Cloudflare Pro** | Cache CDN + protection DDoS | >50k utilisateurs/mois |
| **Supabase Pro** | Read replicas, plus de connections | >100k utilisateurs |
| **Instance worker** | Puissance de calcul additionnelle | >200k utilisateurs |
| **Grafana Cloud** | Dashboard pro | Phase de debugging |

---

## Plan gratuit - Par où commencer

### Step 1: Gratuit - Corriger les problèmes de code (cette semaine)

```
Coût: 0€ | Temps: 2-3 jours | Impact: Élevé
```

1. **N+1 schools** → 2h
2. **Index manquants** → 1h (migration Alembic)
3. **Cache profiles utilisateurs** → 3h

### Step 2: Gratuit - Optimiser Nginx (semaine prochaine)

```
Coût: 0€ | Temps: 1 jour | Impact: Moyen
```

1. Activer gzip (déjà présent mais vérifier)
2. Ajouter cache static (30 jours pour images)
3. Compression Brotli en plus de gzip

### Step 3: Gratuit - Queue async (2-3 semaines)

```
Coût: 0€ (utilise Redis existant) | Temps: 3-4 jours | Impact: Élevé
```

BullMQ fonctionne avec le Redis déjà installé! Pas de nouveau service.

### Step 4: Later - Quand le traffic augmente

```
Quand >100k utilisateurs actifs/mois
```

1. Passer à Supabase Pro pour les read replicas
2. Ajouter Cloudflare (gratuit pour petit traffic)
3. Kubernetes avec auto-scaling

---

## Résumé - Ce qu'on peut faire gratuitement

**Tout** sauf les read replicas et le vraiCDN peuvent être faits maintenant:

- ✅ Correction N+1 (fait)
- ✅ Index DB (script prêt, en attente exécution)
- ✅ Cache améliorée (fait)
- ✅ Nginx optimisé (fait)
- ⏳ Queue async (BullMQ + Redis existant) - à faire
- ⏳ Monitoring custom - à faire

La seule chose qui nécessite un budget est l'infrastructure additionnelle (read replicas, CDN géographique, scaling automatique) → à prévoir seulement quand le traffic le justifie.

---

## Fichiers modifiés (2026-05-11)

### Backend
- `backend/app/repositories/schools_repository.py` - Fix N+1
- `backend/app/repositories/admin/schools_repository.py` - Fix N+1
- `backend/app/core/cache.py` - Nouveaux TTL
- `backend/app/api/v1/endpoints/mentors.py` - Cache ajouté
- `backend/app/api/v1/endpoints/opportunities.py` - Cache ajouté
- `backend/app/api/v1/endpoints/gamification.py` - Cache ajouté
- `backend/alembic/versions/009_add_scalability_indexes.py` - Migration indexes

### Nginx
- `nginx/app.conf` - Optimisations (open_file_cache, gzip, buffers)
- `nginx/admin.conf` - Optimisations (open_file_cache, gzip, buffers)

### Documentation
- `backend/docs/migration_009_indexes.sql` - Script SQL à exécuter

---

## Budgetestimé

| Service | Coûtestimé/mois |
|---------|------------------|
| Cloudflare Pro (optionnel) | 20-50€ |
| Supabase Pro (read replicas) | 25-50€ |
| Instance worker additionnelle | 10-20€ |
| Grafana Cloud (optionnel) | 0-20€ |
| **Total additionnel** | **55-140€/mois** |

---

*Document généré le 2026-05-11, dernière mise à jour 2026-05-11*