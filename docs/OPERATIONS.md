# Operations runbook — ActivEducation

Guide opérationnel pour les tâches récurrentes de production : déploiement, rollback, backups, rotation de secrets, incidents courants.

Interlocuteurs : équipe DevOps / mainteneurs. Tous les endpoints production sont sur le VPS Hostinger (`prod`), staging sur VPS séparé.

---

## 1. Architecture de déploiement

```
Internet → Traefik (80/443) → [backend, app-frontend, admin-frontend]
                              → Redis (interne)
                              → Supabase (externe, managed)
```

- **Traefik v3.2** : reverse proxy, SSL Let's Encrypt automatique, rate limit global 100 req/min/IP.
- **docker-socket-proxy** (tecnativa/docker-socket-proxy:0.3.0) : isole le socket Docker. Traefik ne monte plus `/var/run/docker.sock`.
- **Redis 7.2** : cache tokens Supabase + listes statiques (carrières, filières). TTL 60s tokens, 10min listes.
- **Backend** : FastAPI + uvicorn derrière Traefik. Healthcheck `/health`.
- **Frontends** : Flutter Web buildés puis servis par nginx (images distinctes app-frontend et admin-frontend).

---

## 2. Déploiement

### Production (manuel, workflow GitHub Actions)

1. Merger sur `main`.
2. Déclencher le workflow `Deploy Production` via `gh workflow run deploy-prod.yml` (ou UI GitHub).
3. Le workflow :
   - Lance `backend-ci.yml` (lint + tests + Docker build).
   - SSH sur `PROD_HOST`, `git pull`, `docker compose pull && docker compose up -d --no-deps --build`.
   - Vérifie `/health` sur https://api.activeduhub.com.
4. Post-déploiement : surveiller Sentry pendant 15 min.

### Staging (automatique sur `develop`)

Pas d'action manuelle. CI pousse sur `STAGING_HOST` automatiquement.

### Rollback rapide

```bash
ssh prod
cd /opt/activeducation
git log --oneline -n 10         # identifier le commit sain
git checkout <sha>
docker compose up -d --build
```

Le cache Redis est vidé par `docker compose restart redis` si le rollback touche le schéma cache.

---

## 3. Migrations de base de données (Alembic)

Les migrations vivent dans `backend/alembic/versions/`. Chaîne actuelle : `001` → `006_supabase_auth_cleanup`.

```bash
cd backend
# Variables requises
export DATABASE_URL='postgresql://postgres:<pwd>@<host>:5432/postgres'
# (ou SUPABASE_DB_HOST + SUPABASE_DB_PASSWORD)

alembic current              # vérifier l'état actuel
alembic upgrade head         # appliquer les migrations en attente
alembic downgrade -1         # annuler la dernière
alembic revision -m "description courte"   # créer une nouvelle migration
```

Toujours créer la migration en local, la tester sur staging, puis déployer en prod. Ne jamais modifier une migration déjà appliquée.

---

## 4. Backups Supabase

Supabase Cloud fait des backups journaliers automatiques (rétention 7 jours sur plan Pro). Pour des snapshots explicites (ex : avant migration risquée), utiliser le script fourni :

```bash
./scripts/backup_supabase.sh         # snapshot complet → storage/backups/<date>.sql.gz
```

Le script utilise `pg_dump` via `DATABASE_URL`. Les backups sont gzip + chiffrés avec `AGE_PUBLIC_KEY` si configuré.

Restauration :

```bash
./scripts/backup_supabase.sh --restore storage/backups/2026-04-17.sql.gz
```

> IMPORTANT : la restauration est destructive. Toujours la tester sur staging d'abord, et garder un backup "avant restauration".

---

## 5. Rotation de secrets

### SECRET_KEY (JWT interne)

1. Générer : `python -c "import secrets; print(secrets.token_urlsafe(48))"`
2. Mettre à jour `backend/.env.production` sur le VPS.
3. `docker compose restart backend`.
4. Impact : toutes les sessions backend-émises (reset password, internes) invalidées. Les tokens Supabase (auth principal) ne sont PAS affectés.

### SUPABASE_SERVICE_ROLE_KEY

1. Régénérer depuis Supabase Dashboard > Settings > API.
2. Mettre à jour `.env.production` + secrets GitHub Actions (`PROD_SUPABASE_SERVICE_ROLE_KEY`).
3. Redémarrer backend.
4. Tester `/admin/users` avec un compte super_admin.

### REDIS_PASSWORD

1. Choisir un nouveau password (≥32 chars aléatoires).
2. `docker compose.yml` utilise `${REDIS_PASSWORD}` — mettre à jour `.env` à la racine.
3. `docker compose up -d redis backend` (backend redémarre pour reconnexion).
4. Aucun impact visible utilisateur ; cache repart vide.

---

## 6. Observabilité

### Sentry

- Backend : DSN dans `SENTRY_DSN` (env var Python). Activation : DSN non vide.
- Flutter apps : DSN injecté via `--dart-define=SENTRY_DSN=...` au build. Activation conditionnelle — DSN vide = Sentry désactivé, zéro overhead.

Projet Sentry recommandé : un projet par cible (`activeducation-backend`, `activeducation-app`, `activeducation-admin`) pour alerting distinct.

### Logs applicatifs

```bash
ssh prod
docker compose logs -f backend              # API
docker compose logs -f --tail=100 traefik   # reverse proxy
docker compose logs redis                   # cache
```

Rotation : `json-file` driver, max-size 10 MB × 5 fichiers par service (voir `docker-compose.yml`).

### Healthchecks

- https://api.activeduhub.com/health → `{"status":"ok"}` en <500 ms
- https://activeduhub.com → 200
- https://admin.activeduhub.com → 200

Un cron externe (UptimeRobot ou BetterStack) doit pinger ces 3 endpoints toutes les 5 min.

---

## 7. Incidents courants

### Backend renvoie 503

1. `docker compose ps` → backend unhealthy ?
2. `docker compose logs --tail=200 backend` → chercher exception au démarrage.
3. Cause fréquente : Supabase ou Redis injoignable. Vérifier variables d'env.
4. Si Redis down : l'app tombe sur le cache mémoire fallback, devrait continuer à répondre.

### Taux de 401 anormal

1. Vérifier Sentry (erreurs `InvalidTokenError` / `TokenExpiredError`).
2. Si pic soudain : probable rotation de `SUPABASE_JWT_SECRET` côté Supabase — synchroniser l'env backend.
3. Si progressif sur plusieurs jours : tokens expirés normalement, pas d'action.

### Certificat Let's Encrypt expiré

Traefik renouvelle automatiquement à 30 jours restants. Si échec :

```bash
docker compose logs traefik | grep -i acme
# Rate limit Let's Encrypt ? Problème DNS ? Port 80 bloqué ?
```

Le fichier `traefik/letsencrypt/acme.json` doit avoir les permissions `600`.

### Cache Redis saturé

```bash
docker exec -it activeducation-redis redis-cli -a $REDIS_PASSWORD INFO memory
```

Policy `allkeys-lru` en place : les clés les moins récentes sont évincées automatiquement. Si saturation chronique, augmenter `maxmemory` dans `docker-compose.yml` (actuellement 128 MB).

---

## 8. Secrets GitHub Actions requis

| Secret | Usage |
|---|---|
| `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | Push des images Docker |
| `PROD_HOST` / `PROD_USER` / `PROD_SSH_KEY` | SSH déploiement prod |
| `STAGING_HOST` / `STAGING_USER` / `STAGING_SSH_KEY` | SSH déploiement staging |
| `PROD_SUPABASE_URL` / `PROD_SUPABASE_KEY` / `PROD_SUPABASE_SERVICE_ROLE_KEY` | Injection env au déploiement |
| `PROD_SECRET_KEY` / `PROD_REDIS_PASSWORD` | Secrets backend |
| `PROD_SENTRY_DSN` (optionnel) | Active Sentry en prod |
| `CI_*` (préfixe) | Valeurs placeholder pour les tests CI uniquement — ne doivent jamais être valides en prod |

Les placeholders `CI_*` sont rejetés par `config.py` en environnement `production` (marqueurs `placeholder`, `ci-test`, `pytest-dummy`).

---

## 9. Contacts

- **Incident critique** : israelawaga2@gmail.com
- **Supabase support** : support@supabase.io (plan Pro)
- **Hostinger support** : panel VPS > Support

---

## 10. Références internes

- Architecture : [ARCHITECTURE.md](ARCHITECTURE.md)
- Sécurité : [SECURITY.md](SECURITY.md)
- Déploiement VPS : [../DEPLOIEMENT_VPS_HOSTINGER.md](../DEPLOIEMENT_VPS_HOSTINGER.md)
- Contribution : [../CONTRIBUTING.md](../CONTRIBUTING.md)
