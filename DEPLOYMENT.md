# Guide de déploiement VPS — ActivEducation

Ce document décrit, **pas à pas et de zéro**, comment mettre ActivEducation en
production sur un VPS Linux : provisionnement du serveur, DNS, Docker, TLS,
base de données, build des fronts Flutter et mise en ligne. Quelqu'un qui
découvre le projet doit pouvoir suivre ce guide du début à la fin sans rien
deviner.

> **Exemple concret utilisé partout :** domaine `activeducationhub.com`, VPS chez
> LWS à l'IP `185.98.128.154`, répertoire `/opt/activeducation`. Remplace ces
> valeurs par les tiennes (notées `VOTRE_DOMAINE`, `VOTRE_IP`).

---

## Table des matières

1. [Ce qui sera déployé (architecture)](#1-architecture)
2. [Prérequis (comptes & outils)](#2-prérequis)
3. [Étape 1 — Provisionner le VPS](#3-étape-1--provisionner-le-vps)
4. [Étape 2 — Installer Docker & Docker Compose](#4-étape-2--installer-docker--docker-compose)
5. [Étape 3 — Configurer le nom de domaine et le DNS](#5-étape-3--dns)
6. [Étape 4 — Préparer Supabase (base de données + Auth)](#6-étape-4--supabase)
7. [Étape 5 — Récupérer le code sur le serveur](#7-étape-5--code)
8. [Étape 6 — Configurer les variables d'environnement](#8-étape-6--variables-denvironnement)
9. [Étape 7 — Builder les fronts Flutter](#9-étape-7--builder-les-fronts-flutter)
10. [Étape 8 — TLS / Let's Encrypt (Traefik)](#10-étape-8--tls)
11. [Étape 9 — Lancer la stack](#11-étape-9--lancer-la-stack)
12. [Étape 10 — Appliquer les migrations de base de données](#12-étape-10--migrations)
13. [Étape 11 — Vérifications post-déploiement](#13-étape-11--vérifications)
14. [Mises à jour (redéploiement)](#14-mises-à-jour)
15. [Exploitation (logs, sauvegardes, renouvellement TLS)](#15-exploitation)
16. [Dépannage (pièges connus)](#16-dépannage)
17. [Annexes (variables, ports, arborescence)](#17-annexes)

---

## 1. Architecture

ActivEducation = **3 frontaux Flutter Web** + **1 API FastAPI** + **Redis**,
le tout derrière **Traefik** (reverse proxy + HTTPS automatique). La base de
données, l'authentification et le stockage de fichiers sont **externalisés chez
Supabase** (managé) — il n'y a donc **pas** de conteneur PostgreSQL à héberger.

```
                          Internet (ports 80/443)
                                   │
                          ┌────────▼────────┐
                          │     Traefik     │  TLS Let's Encrypt auto
                          │   (v3.2)        │  routing par sous-domaine
                          └───┬────┬────┬───┘
            ┌─────────────────┘    │    └─────────────────┐
            ▼                      ▼                       ▼
  activeducationhub.com    api.activeducationhub.com   admin.activeducationhub.com
   (+ www → non-www)
            │                      │                       │
   ┌────────▼────────┐    ┌────────▼────────┐    ┌─────────▼────────┐
   │  app-frontend   │    │     backend     │    │  admin-frontend  │
   │  nginx          │    │  FastAPI :8000  │    │  nginx           │
   │  /  → landing   │    │  (Python 3.11)  │    │  Flutter admin   │
   │  /app/ → Flutter│    └────────┬────────┘    └──────────────────┘
   └─────────────────┘             │
                          ┌────────▼────────┐        ┌──────────────────┐
                          │     Redis       │        │   Supabase (SaaS) │
                          │  cache :6379    │        │  PostgreSQL + Auth│
                          └─────────────────┘        │  + Storage        │
                                                      └──────────────────┘

   socket-proxy : expose le socket Docker à Traefik en lecture seule (sécurité).
```

**Conteneurs (`docker compose ps`) :**

| Conteneur | Image | Rôle | Exposé |
|---|---|---|---|
| `activeducation-traefik` | traefik:v3.2 | Reverse proxy + TLS | 80, 443 |
| `activeducation-socket-proxy` | tecnativa/docker-socket-proxy | Accès Docker read-only | interne |
| `activeducation-redis` | redis:7.2-alpine | Cache | interne |
| `activeducation-api` | build `./backend` | API FastAPI | interne (:8000) |
| `activeducation-app` | nginx:1.25-alpine | Landing + app étudiante | interne (:80) |
| `activeducation-admin` | nginx:1.25-alpine | Dashboard admin | interne (:80) |

**Domaines servis :**

| URL | Sert |
|---|---|
| `https://VOTRE_DOMAINE/` | Landing page (vitrine) |
| `https://VOTRE_DOMAINE/app/` | Application étudiante (Flutter) |
| `https://www.VOTRE_DOMAINE/` | Redirection 301 → non-www |
| `https://api.VOTRE_DOMAINE/` | API REST (`/api/v1/...`) |
| `https://admin.VOTRE_DOMAINE/` | Dashboard administrateur |

> ⚠️ **Routing Traefik = fichier, pas labels.** Le routing réel est défini dans
> `traefik/dynamic.yml` (provider *file*), qui joint les conteneurs par leur
> `container_name`. Les labels `traefik.*` présents dans `docker-compose.yml`
> sont **ignorés** (le provider Docker est désactivé). Si tu ajoutes/renommes un
> service, édite `traefik/dynamic.yml`.

---

## 2. Prérequis

### Comptes à créer (gratuits ou peu coûteux)
- **Un VPS** Ubuntu 22.04/24.04 LTS — minimum **2 vCPU / 2–4 Go RAM / 20 Go SSD**
  (le backend est plafonné à 1 Go, Traefik 256 Mo, Redis 160 Mo).
- **Un nom de domaine** (chez n'importe quel registrar : LWS, OVH, Namecheap…).
- **Un projet Supabase** — https://supabase.com (PostgreSQL + Auth + Storage managés).
- *(Optionnel)* **Clé Groq** — https://console.groq.com (gratuite) pour l'assistant IA « AÏDA ».
- *(Optionnel)* **DSN Sentry** — monitoring d'erreurs.

### Outils sur ta machine locale
- `git`, `ssh`, `scp`.
- **Flutter 3.32.0** (`flutter --version`) — pour builder les fronts web.
  > Tu peux builder les fronts **localement** (recommandé, plus rapide) puis les
  > `scp` vers le serveur, **ou** builder directement sur le VPS (cf. Étape 7).

---

## 3. Étape 1 — Provisionner le VPS

Connexion initiale en root (l'IP et le mot de passe viennent de ton hébergeur) :

```bash
ssh root@VOTRE_IP
```

### 3.1 Mettre à jour le système
```bash
apt update && apt upgrade -y
timedatectl set-timezone UTC          # cohérence des logs
```

### 3.2 Créer un utilisateur non-root (recommandé)
```bash
adduser deploy
usermod -aG sudo deploy
# Copier ta clé SSH pour te connecter en tant que 'deploy'
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```
> Pour la suite tu peux travailler en `deploy` (avec `sudo`) ou rester en `root`.
> Les commandes ci-dessous supposent que tu as les droits (`sudo` si non-root).

### 3.3 Pare-feu (UFW) — n'ouvrir que SSH + HTTP + HTTPS
```bash
apt install -y ufw
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
ufw status
```

### 3.4 Durcissement de base
```bash
# fail2ban : bloque le brute-force SSH
apt install -y fail2ban
systemctl enable --now fail2ban

# (Recommandé) Désactiver le login SSH par mot de passe une fois ta clé en place
#   nano /etc/ssh/sshd_config  →  PasswordAuthentication no  ; PermitRootLogin prohibit-password
#   systemctl restart ssh
```

### 3.5 Swap (utile si 2 Go RAM, pour absorber le build backend)
```bash
fallocate -l 2G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## 4. Étape 2 — Installer Docker & Docker Compose

Méthode officielle (Docker Engine + plugin Compose v2) :

```bash
# Dépendances
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Dépôt Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Vérifier
docker --version
docker compose version          # Compose v2 → 'docker compose' (sans tiret)
systemctl enable --now docker
```
> Si tu utilises l'utilisateur `deploy` : `usermod -aG docker deploy` puis
> reconnecte-toi pour utiliser `docker` sans `sudo`.

---

## 5. Étape 3 — DNS

Chez ton registrar (zone DNS du domaine), crée **4 enregistrements A** pointant
tous vers l'IP du VPS :

| Type | Nom (host) | Valeur | TTL |
|---|---|---|---|
| A | `@`     | `VOTRE_IP` | 3600 |
| A | `www`   | `VOTRE_IP` | 3600 |
| A | `api`   | `VOTRE_IP` | 3600 |
| A | `admin` | `VOTRE_IP` | 3600 |

Vérifie la propagation (peut prendre quelques minutes à quelques heures) :

```bash
dig +short VOTRE_DOMAINE
dig +short api.VOTRE_DOMAINE
dig +short admin.VOTRE_DOMAINE
dig +short www.VOTRE_DOMAINE
```
Les 4 doivent renvoyer `VOTRE_IP`.

> **Important :** Let's Encrypt valide les certificats via un challenge HTTP sur
> le port 80. Le DNS **doit** être propagé **avant** de lancer la stack, sinon
> l'émission des certificats échoue.

---

## 6. Étape 4 — Supabase

ActivEducation n'héberge pas sa base : tout est sur Supabase.

1. Crée un projet sur https://supabase.com (choisis une région proche, ex. EU).
2. Récupère les clés dans **Project Settings → API** :
   - `Project URL` → `SUPABASE_URL`
   - `anon` `public` → `SUPABASE_KEY`
   - `service_role` `secret` → `SUPABASE_SERVICE_ROLE_KEY` *(garde-la secrète !)*
   - **Project Settings → API → JWT Settings → JWT Secret** → `SUPABASE_JWT_SECRET`
3. Récupère la chaîne de connexion PostgreSQL (pour les migrations Alembic) dans
   **Project Settings → Database → Connection string → URI** :
   ```
   postgresql://postgres:[MOT_DE_PASSE]@db.[REF].supabase.co:5432/postgres
   ```
   → ce sera `DATABASE_URL` (utilisé uniquement pour appliquer les migrations).
4. *(Stockage)* Dans **Storage**, crée les buckets utilisés par l'app si besoin
   (images d'écoles, avatars…). Les politiques RLS du projet sont versionnées
   dans `backend/alembic/` et `docs/RLS_AUDIT.md`.

---

## 7. Étape 5 — Code

Place le projet dans `/opt/activeducation` :

```bash
mkdir -p /opt/activeducation
cd /opt
git clone https://github.com/activeducation/activeducation_plateform.git activeducation
cd /opt/activeducation
git checkout main          # la prod suit la branche main
```

> Le VPS sert les fronts depuis des **volumes montés** (`./landing`,
> `./activ_education_app/build/web`, `./admin_dashboard/build/web`). Les dossiers
> `build/web` sont **gitignorés** : ils n'existent pas après le clone, il faut
> les **builder** (Étape 7).

---

## 8. Étape 6 — Variables d'environnement

Il y a **deux** fichiers d'environnement à créer (jamais commités) :

### 8.1 `.env` à la racine — secret de Redis
`docker-compose.yml` substitue `${REDIS_PASSWORD}`. Crée `/opt/activeducation/.env` :

```bash
cd /opt/activeducation
cp .env.example .env
# Génère un mot de passe Redis fort :
echo "REDIS_PASSWORD=$(openssl rand -hex 24)" > .env
cat .env
```

### 8.2 `backend/.env.production` — Supabase, secrets, migrations
Le service `backend` charge `./backend/.env.production` (`env_file`). Crée-le à
partir de l'exemple :

```bash
cp backend/.env.example backend/.env.production
nano backend/.env.production
```

Remplis au minimum :

```dotenv
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# --- Supabase (OBLIGATOIRE) ---
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_KEY=<anon-public-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-secret>
SUPABASE_JWT_SECRET=<jwt-secret>

# --- Secret interne (reset password, etc.) ---
# Génère : python3 -c "import secrets; print(secrets.token_urlsafe(48))"
SECRET_KEY=<chaine-aleatoire-64-caracteres>

# --- Migrations Alembic (connexion Postgres directe Supabase) ---
# Permet de lancer `alembic upgrade head` DEPUIS le conteneur backend.
DATABASE_URL=postgresql://postgres:<db-password>@db.<ref>.supabase.co:5432/postgres

# --- CORS : domaines autorisés à appeler l'API ---
BACKEND_CORS_ORIGINS=https://activeducationhub.com,https://admin.activeducationhub.com

# --- Optionnels ---
GROQ_API_KEY=<cle-groq>     # assistant IA AÏDA ; laisser vide si non utilisé
SENTRY_DSN=                 # monitoring ; laisser vide si non utilisé
```

> `REDIS_URL` n'est **pas** à mettre ici : `docker-compose.yml` l'injecte déjà
> avec le mot de passe (`redis://:${REDIS_PASSWORD}@redis:6379/0`).

> 🔐 **Sécurité :** `SUPABASE_SERVICE_ROLE_KEY` et `DATABASE_URL` donnent un accès
> total à la base. Ne les commite jamais, ne les colle jamais dans un chat. En
> cas de fuite, régénère-les côté Supabase.

---

## 9. Étape 7 — Builder les fronts Flutter

Trois artefacts web sont nécessaires. **Attention aux conventions d'URL d'API,
différentes entre l'app et l'admin** (voir Dépannage §16) :

| Front | `base-href` | `API_BASE_URL` à passer |
|---|---|---|
| App étudiante | `/app/` | `https://api.VOTRE_DOMAINE` *(sans `/api/v1`)* |
| Admin | `/` (défaut) | `https://api.VOTRE_DOMAINE/api/v1` *(avec `/api/v1`)* |
| Landing | — | *(statique, aucun build)* |

### Option A — Builder en local puis `scp` (recommandé)

Sur ta machine (avec Flutter installé) :

```bash
# App étudiante (servie sous /app/)
cd activ_education_app
flutter pub get
flutter build web --release --no-tree-shake-icons \
  --base-href=/app/ \
  --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE

# Dashboard admin (servi à la racine du sous-domaine admin)
cd ../admin_dashboard
flutter pub get
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE/api/v1
```

> ⚠️ **Windows + Git Bash : `--base-href=/app/` est corrompu silencieusement.**
> Git Bash (MSYS2) prend `/app/` pour un chemin Unix et le réécrit en chemin
> Windows. Le build échoue avec :
> ```
> Received a --base-href value of "C:/Program Files/Git/app/"
> --base-href should start and end with /
> ```
> Deux façons de s'en sortir :
> ```bash
> # 1) Désactiver la conversion de chemins pour cette commande (Git Bash)
> MSYS_NO_PATHCONV=1 flutter build web --release --no-tree-shake-icons \
>   --base-href=/app/ --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE
> ```
> ```powershell
> # 2) Ou simplement builder depuis PowerShell / cmd, qui ne convertissent rien
> flutter build web --release --no-tree-shake-icons `
>   --base-href=/app/ --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE
> ```
> Ne concerne que l'app étudiante (l'admin n'utilise pas `--base-href`).
> Sous Linux/macOS, rien à faire.

**Vérifie toujours le build avant de l'envoyer** (30 s qui évitent un déploiement cassé) :

```bash
# L'app doit déclarer <base href="/app/"> — sinon 404 sur tous les assets
grep -o '<base href="[^"]*"' activ_education_app/build/web/index.html

# Chaque front doit embarquer SON URL d'API (et pas localhost)
grep -o "api.VOTRE_DOMAINE"        activ_education_app/build/web/main.dart.js | head -1
grep -o "api.VOTRE_DOMAINE/api/v1" admin_dashboard/build/web/main.dart.js | head -1
```

Puis envoie les builds sur le VPS :

```bash
# Depuis la racine du repo local
scp -r activ_education_app/build/web/*  root@VOTRE_IP:/opt/activeducation/activ_education_app/build/web/
scp -r admin_dashboard/build/web/*      root@VOTRE_IP:/opt/activeducation/admin_dashboard/build/web/
```
> Les répertoires cibles doivent exister :
> `ssh root@VOTRE_IP "mkdir -p /opt/activeducation/{activ_education_app,admin_dashboard}/build/web"`

### Option B — Builder directement sur le VPS

```bash
# Installer Flutter sur le serveur (une fois)
cd /opt && git clone https://github.com/flutter/flutter.git -b 3.32.0 --depth 1
export PATH="$PATH:/opt/flutter/bin"

cd /opt/activeducation/activ_education_app
flutter build web --release --no-tree-shake-icons --base-href=/app/ \
  --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE

cd /opt/activeducation/admin_dashboard
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE/api/v1
```

> La **landing** (`./landing/`) est du HTML statique déjà présent dans le repo :
> rien à builder, elle est servie telle quelle.

---

## 10. Étape 8 — TLS

Rien à générer manuellement : **Traefik émet et renouvelle les certificats
Let's Encrypt automatiquement** (challenge HTTP sur le port 80, défini dans
`traefik/traefik.yml`). Une seule préparation : le fichier de stockage des
certificats doit exister avec les bons droits.

```bash
cd /opt/activeducation
mkdir -p traefik/letsencrypt
touch traefik/letsencrypt/acme.json
chmod 600 traefik/letsencrypt/acme.json
```

> **À personnaliser :** l'email de contact ACME dans `traefik/traefik.yml`
> (`certificatesResolvers.letsencrypt.acme.email`). Remplace
> `ops@activeducationhub.com` par le tien.
>
> Si tu changes de domaine, mets à jour **tous** les `Host(...)` dans
> `traefik/dynamic.yml` et `docker-compose.yml`, ainsi que `nginx/*.conf`.

---

## 11. Étape 9 — Lancer la stack

```bash
cd /opt/activeducation
docker compose up -d --build
```

Cela construit l'image backend et démarre les 6 conteneurs. Suis l'obtention des
certificats :

```bash
docker compose ps                         # tout doit être "Up" / "healthy"
docker compose logs -f traefik            # cherche "Certificates obtained ..." (Ctrl+C pour sortir)
docker compose logs -f backend            # l'API doit démarrer sans erreur
```

> La première émission TLS prend 10–60 s par domaine. Si un certificat échoue,
> voir Dépannage §16 (souvent : DNS pas encore propagé, ou port 80 fermé).

---

## 12. Étape 10 — Migrations

Le conteneur backend embarque Alembic. Une fois `DATABASE_URL` présent dans
`backend/.env.production` (Étape 6), applique les migrations **depuis le
conteneur** :

```bash
cd /opt/activeducation
docker compose exec backend alembic current     # état actuel
docker compose exec backend alembic upgrade head # applique toutes les migrations
docker compose exec backend alembic current     # doit afficher la dernière révision (ex. 017)
```

> Le backend **ne migre pas tout seul au démarrage** : c'est volontaire (on ne
> modifie pas le schéma de prod sans action explicite). Les migrations sont
> idempotentes côté seed (ex. la 017 ne réinsère pas les métiers s'ils existent).
>
> Alternative sans `DATABASE_URL` : `env.py` accepte aussi
> `SUPABASE_DB_HOST` + `SUPABASE_DB_PASSWORD` (+ `SUPABASE_DB_NAME/USER/PORT`).

---

## 13. Étape 11 — Vérifications

```bash
# API en bonne santé
curl -fsS https://api.VOTRE_DOMAINE/health && echo "  ✅ API OK"

# Une route protégée répond 401 (= route présente, auth requise)
curl -s -o /dev/null -w "%{http_code}\n" https://api.VOTRE_DOMAINE/api/v1/admin/dashboard/stats   # → 401

# Recherche unifiée (publique)
curl -s "https://api.VOTRE_DOMAINE/api/v1/search?q=info" | head -c 200; echo
```

Puis dans un navigateur :

| À tester | Attendu |
|---|---|
| `https://VOTRE_DOMAINE/` | La landing s'affiche, cadenas TLS valide |
| Bouton **Créer un compte** | redirige vers `https://VOTRE_DOMAINE/app/#/register` |
| `https://VOTRE_DOMAINE/app/` | l'app étudiante charge (login) |
| `https://admin.VOTRE_DOMAINE/` | la page de login admin charge |
| `https://www.VOTRE_DOMAINE/` | redirige (301) vers la version non-www |

> 💡 Après chaque (re)déploiement d'un front, fais un **hard refresh**
> (`Ctrl+Shift+R`) : Flutter web met `main.dart.js` en cache via un service
> worker.

---

## 14. Mises à jour

La prod suit la branche **`main`**. Cycle de redéploiement :

### Backend (code Python)
```bash
cd /opt/activeducation
git pull origin main
docker compose up -d --build backend
# Si la mise à jour contient de nouvelles migrations :
docker compose exec backend alembic upgrade head
```

### Fronts (app / admin)
```bash
# 1) Rebuild (local) avec les MÊMES flags qu'à l'Étape 7
#    app   → --base-href=/app/  --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE
#    admin → --dart-define=API_BASE_URL=https://api.VOTRE_DOMAINE/api/v1
#    Git Bash/Windows : préfixer par MSYS_NO_PATHCONV=1 (sinon /app/ est corrompu).
#    Oublier un --dart-define = front qui retombe sur localhost -> prod cassée.

# 2) Pousser les builds
scp -r activ_education_app/build/web/* root@VOTRE_IP:/opt/activeducation/activ_education_app/build/web/
scp -r admin_dashboard/build/web/*     root@VOTRE_IP:/opt/activeducation/admin_dashboard/build/web/

# 3) Recharger nginx
ssh root@VOTRE_IP "cd /opt/activeducation && docker compose restart app-frontend admin-frontend"
```

### Landing (HTML statique versionné)
```bash
# Sur le VPS — servie depuis le volume ./landing, aucun rebuild ni restart requis
cd /opt/activeducation && git pull origin main
```
Puis hard refresh côté navigateur.

---

## 15. Exploitation

### Logs
```bash
docker compose logs -f                 # tout
docker compose logs -f backend         # un service
docker compose logs --tail=200 traefik
```

### Cycle de vie
```bash
docker compose ps                      # état + santé
docker compose restart backend         # redémarrer un service
docker compose down                    # tout arrêter
docker compose up -d                   # tout relancer
docker stats --no-stream               # CPU/RAM par conteneur
```

### TLS — renouvellement
Automatique (Traefik renouvelle ~30 j avant expiration). Rien à faire.
Sauvegarde simplement `traefik/letsencrypt/acme.json`.

### Sauvegardes
- **Base de données :** gérée par Supabase (backups automatiques selon ton plan).
  Le script `scripts/backup_supabase.sh` du repo permet un dump manuel.
- **Secrets :** sauvegarde hors-serveur `/opt/activeducation/.env` et
  `backend/.env.production` (coffre-fort, jamais dans git).
- **Certificats :** `traefik/letsencrypt/acme.json` (sinon ré-émission au prochain boot).

### Nettoyage disque
```bash
docker system prune -f                 # images/conteneurs orphelins (sans -a si tu veux garder le cache)
```

---

## 16. Dépannage

### 🔴 « Connection error » / « Impossible de joindre le serveur » dans un front
**Cause n°1 : mauvaise `API_BASE_URL` au build.** Les deux fronts ont des
conventions **opposées** :
- **App étudiante** : les endpoints ajoutent déjà `/api/v1` → `baseUrl` **sans**
  `/api/v1` (`https://api.VOTRE_DOMAINE`).
- **Admin** : les endpoints n'ont pas de préfixe → `baseUrl` **avec** `/api/v1`
  (`https://api.VOTRE_DOMAINE/api/v1`).

Si tu oublies `--dart-define`, le build retombe sur `localhost` (défaut dev) →
le navigateur ne joint rien. Vérifie ce qui est embarqué dans le build :
```bash
grep -o "api.VOTRE_DOMAINE/api/v1" admin_dashboard/build/web/main.dart.js | head -1   # admin: doit matcher
grep -o "api.VOTRE_DOMAINE"        activ_education_app/build/web/main.dart.js | head -1 # app: doit matcher
```
Corrige les flags, rebuild, re-scp, restart, hard refresh.

### 🔴 `/app/` renvoie 404 ou page blanche
Le build app doit être fait avec **`--base-href=/app/`**. Sinon les chemins
d'assets pointent vers `/` et nginx renvoie 404. Vérifie ce que contient
réellement le build :
```bash
grep -o '<base href="[^"]*"' activ_education_app/build/web/index.html   # attendu : /app/
```
Rebuild avec le bon `base-href` si la valeur diffère.

### 🔴 Le build échoue : `Received a --base-href value of "C:/Program Files/Git/app/"`
Tu builds depuis **Git Bash sous Windows** : MSYS2 a pris `/app/` pour un chemin
Unix et l'a réécrit en chemin Windows. Préfixe la commande par
`MSYS_NO_PATHCONV=1`, ou build depuis PowerShell (cf. Étape 7). Le piège est
sournois car le message ne parle pas de Git Bash.

### 🔴 Certificat TLS non émis (`docker compose logs traefik` montre une erreur ACME)
- DNS pas encore propagé → `dig +short VOTRE_DOMAINE` doit renvoyer `VOTRE_IP`.
- Port 80 bloqué → `ufw status` (doit autoriser 80/tcp), et le port ne doit pas
  être pris par un autre service (`ss -tlnp | grep :80`).
- `acme.json` mauvais droits → `chmod 600 traefik/letsencrypt/acme.json`.
- Limite Let's Encrypt atteinte (trop d'essais) → attendre, ou tester d'abord
  avec le serveur ACME *staging* (modifier temporairement `traefik.yml`).

### 🔴 Redis ne démarre pas / backend ne se connecte pas au cache
`REDIS_PASSWORD` manquant dans le `.env` racine → `docker compose config | grep -i redis`
pour vérifier la substitution. Recrée le `.env` (Étape 6.1).

### 🔴 Migrations : « DATABASE_URL ou SUPABASE_DB_HOST requis »
`DATABASE_URL` absent de `backend/.env.production`. Ajoute la connexion Postgres
Supabase (Étape 6.2), puis `docker compose up -d backend` et relance la migration.

### 🔴 Un changement de front ne s'affiche pas
Service worker Flutter → **hard refresh** (`Ctrl+Shift+R`) ou navigation privée.

### 🔴 J'ai ajouté/renommé un service mais Traefik ne le route pas
Le routing est dans `traefik/dynamic.yml` (provider *file*), **pas** les labels
Docker. Édite `dynamic.yml` (router + service + middleware) puis
`docker compose restart traefik`.

---

## 17. Annexes

### A. Référence des variables d'environnement

**`/opt/activeducation/.env` (racine)**

| Variable | Obligatoire | Description |
|---|---|---|
| `REDIS_PASSWORD` | ✅ | Mot de passe Redis (substitué dans compose). `openssl rand -hex 24` |

**`backend/.env.production`**

| Variable | Obligatoire | Description |
|---|---|---|
| `ENVIRONMENT` | ✅ | `production` |
| `DEBUG` | ✅ | `false` en prod |
| `SUPABASE_URL` | ✅ | URL du projet Supabase |
| `SUPABASE_KEY` | ✅ | Clé `anon public` |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Clé `service_role` (secrète) |
| `SUPABASE_JWT_SECRET` | ✅ | Secret JWT Supabase (validation locale des tokens) |
| `SECRET_KEY` | ✅ | Secret interne (≥48 octets aléatoires) |
| `DATABASE_URL` | ✅* | Connexion Postgres directe — requise pour les migrations |
| `BACKEND_CORS_ORIGINS` | ✅ | Domaines front autorisés (séparés par virgules) |
| `GROQ_API_KEY` | ⬜ | Assistant IA AÏDA (optionnel) |
| `SENTRY_DSN` | ⬜ | Monitoring d'erreurs (optionnel) |
| `LOG_LEVEL` | ⬜ | `INFO` par défaut |

\* ou le couple `SUPABASE_DB_HOST` + `SUPABASE_DB_PASSWORD`.

> `REDIS_URL` est injecté par `docker-compose.yml` — ne pas le définir à la main.

### B. Ports

| Port | Ouvert au public | Usage |
|---|---|---|
| 22 | oui (restreint conseillé) | SSH |
| 80 | oui | HTTP → redirigé en HTTPS + challenge ACME |
| 443 | oui | HTTPS (Traefik) |
| 8000, 6379 | non | internes au réseau Docker `app-network` |

### C. Arborescence des fichiers d'infra

```
/opt/activeducation/
├── docker-compose.yml          # orchestration des 6 services
├── .env                        # REDIS_PASSWORD (à créer, non commité)
├── traefik/
│   ├── traefik.yml             # config statique (entrypoints, ACME/Let's Encrypt)
│   ├── dynamic.yml             # ROUTING RÉEL (routers/services/middlewares)
│   └── letsencrypt/acme.json   # certificats (chmod 600, à sauvegarder)
├── nginx/
│   ├── app.conf                # landing à / + app Flutter sous /app/
│   └── admin.conf              # dashboard admin
├── landing/                    # vitrine HTML statique (servie telle quelle)
├── backend/
│   ├── Dockerfile              # image FastAPI (python:3.11-slim)
│   ├── .env.production         # secrets backend (à créer, non commité)
│   └── alembic/                # migrations base de données
├── activ_education_app/
│   └── build/web/              # build Flutter app (gitignoré → à builder/scp)
└── admin_dashboard/
    └── build/web/              # build Flutter admin (gitignoré → à builder/scp)
```

### D. Checklist express (de zéro à en ligne)

1. ☐ VPS provisionné (MAJ, UFW 80/443/SSH, fail2ban, swap)
2. ☐ Docker + Compose v2 installés
3. ☐ DNS : `@`, `www`, `api`, `admin` → `VOTRE_IP` (propagé : `dig`)
4. ☐ Projet Supabase créé, clés + `DATABASE_URL` récupérées
5. ☐ `git clone` dans `/opt/activeducation`, `git checkout main`
6. ☐ `.env` racine (`REDIS_PASSWORD`) + `backend/.env.production` remplis
7. ☐ Fronts buildés (app `--base-href=/app/` ; admin `/api/v1`) et **vérifiés**
   (`<base href="/app/">` présent, URL d'API bakée — Git Bash : `MSYS_NO_PATHCONV=1`)
8. ☐ `traefik/letsencrypt/acme.json` créé (`chmod 600`), email ACME personnalisé
9. ☐ `docker compose up -d --build` → 6 conteneurs Up, certs TLS obtenus
10. ☐ `docker compose exec backend alembic upgrade head`
11. ☐ Vérifs : `/health` 200, landing OK, `/app/` OK, admin login OK

---

*Stack : FastAPI (Python 3.11) · Supabase (PostgreSQL/Auth/Storage) · Redis ·
Flutter Web · Traefik v3 · Docker Compose. Dernière mise à jour de ce guide :
voir l'historique git de ce fichier.*
