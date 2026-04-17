# 🚀 Tutoriel Complet — Déploiement ActivEducation sur VPS Hostinger

> Guide étape par étape pour déployer la plateforme ActivEducation (Backend FastAPI + App Flutter + Admin Dashboard) sur un VPS Hostinger avec SSL automatique.

---

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Préparation locale](#préparation-locale)
3. [Configuration DNS](#configuration-dns)
4. [Connexion VPS et accès root](#connexion-vps)
5. [Déploiement automatisé](#déploiement-automatisé)
6. [Vérification du déploiement](#vérification)
7. [Commandes utiles post-déploiement](#commandes-utiles)
8. [Dépannage](#dépannage)

---

## 1. Prérequis {#prérequis}

### Sur votre machine locale

| Outil | Version minimale | Commande de vérification |
|-------|------------------|--------------------------|
| **Flutter** | 3.x | `flutter --version` |
| **Git** | 2.x | `git --version` |
| **SSH** | OpenSSH | `ssh -V` |
| **WSL ou Git Bash** (Windows) | — | `wsl --version` ou `bash --version` |

### VPS Hostinger

| Ressource | Recommandé | Minimum |
|-----------|------------|---------|
| **CPU** | 2 vCPU | 1 vCPU |
| **RAM** | 4 GB | 2 GB |
| **Stockage** | 40 GB SSD | 20 GB |
| **OS** | Ubuntu 22.04 LTS | Ubuntu 20.04+ |
| **Accès** | Root SSH | Root SSH |

### Domaine configuré

- Domaine principal : `activeducationhub.com`
- Sous-domaines requis :
  - `api.activeducationhub.com` → API Backend
  - `admin.activeducationhub.com` → Dashboard Admin
  - (optionnel) `www.activeducationhub.com` → Redirect vers domaine principal

---

## 2. Préparation locale {#préparation-locale}

### Étape 2.1 : Cloner le projet

```bash
git clone https://github.com/activeducation/activeducation_plateform.git
cd activeducation_plateform
```

### Étape 2.2 : Builder les applications Flutter Web

#### 🔹 App étudiante (activ_education_app)

```bash
cd activ_education_app

# Nettoyer les anciens builds
flutter clean

# Build pour la production avec l'URL de l'API
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com

# Vérifier que le build est complet
ls -lh build/web/main.dart.js
# Doit afficher un fichier de plusieurs MB
```

#### 🔹 Dashboard admin (admin_dashboard)

```bash
cd ../admin_dashboard

flutter clean

flutter build web --release \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1

# Vérifier
ls -lh build/web/main.dart.js
```

### Étape 2.3 : Configurer les variables d'environnement

Ouvrir `backend/.env.production` et remplir **toutes** les valeurs :

```bash
# Éditeur (VS Code, nano, vim, etc.)
code backend/.env.production
```

**Variables CRITIQUES à remplir :**

```env
# --- Supabase (depuis console.supabase.com) ---
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# --- Sécurité JWT (générer avec: python3 -c "import secrets; print(secrets.token_urlsafe(48))") ---
SECRET_KEY=votre-clé-secrète-unique-de-48-caractères

# --- CORS (vérifier les domaines) ---
BACKEND_CORS_ORIGINS=https://activeducationhub.com,https://www.activeducationhub.com,https://admin.activeducationhub.com

# --- Groq API pour AÏDA (gratuit sur console.groq.com) ---
GROQ_API_KEY=gsk_votre_clé_groq_ici

# --- Redis Password (générer: openssl rand -base64 32) ---
REDIS_PASSWORD=votre-mot-de-passe-redis-fort
```

⚠️ **IMPORTANT :** Ne jamais commiter ce fichier dans Git ! Il contient vos secrets.

### Étape 2.4 : Configurer Traefik (email Let's Encrypt)

Ouvrir `traefik/traefik.yml` et vérifier l'email pour les certificats SSL :

```bash
code traefik/traefik.yml
```

**Ligne à vérifier :**

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: votre-email@gmail.com  # ← Mettre votre VRAI email
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

### Étape 2.5 : Vérifier les domaines dans dynamic.yml

Ouvrir `traefik/dynamic.yml` et vérifier que tous les domaines correspondent :

```bash
code traefik/dynamic.yml
```

**Sections à vérifier :**

```yaml
http:
  routers:
    backend:
      rule: "Host(`api.activeducationhub.com`)"  # ← API
    app:
      rule: "Host(`activeducationhub.com`)"      # ← App étudiante
    app-www:
      rule: "Host(`www.activeducationhub.com`)"  # ← Redirect www
    admin:
      rule: "Host(`admin.activeducationhub.com`)"  # ← Admin dashboard
```

---

## 3. Configuration DNS {#configuration-dns}

### Étape 3.1 : Récupérer l'IP du VPS

Depuis le panneau Hostinger (hpanel) :

1. Aller dans **VPS** → Votre VPS
2. Noter l'**adresse IP publique** (ex: `185.45.123.45`)

### Étape 3.2 : Configurer les enregistrements DNS

Dans le gestionnaire DNS de votre domaine (Hostinger DNS ou autre registrar) :

| Type | Nom | Valeur | TTL |
|------|-----|--------|-----|
| **A** | `@` | `185.45.123.45` | 3600 |
| **A** | `api` | `185.45.123.45` | 3600 |
| **A** | `admin` | `185.45.123.45` | 3600 |
| **A** | `www` | `185.45.123.45` | 3600 |

**Exemple de configuration dans hPanel :**

```
activeducationhub.com         A      185.45.123.45
api.activeducationhub.com     A      185.45.123.45
admin.activeducationhub.com   A      185.45.123.45
www.activeducationhub.com     A      185.45.123.45
```

### Étape 3.3 : Vérifier la propagation DNS (attendre 5-10 min)

```bash
# Depuis votre machine locale
dig activeducationhub.com +short
dig api.activeducationhub.com +short
dig admin.activeducationhub.com +short

# Tous doivent retourner l'IP de votre VPS : 185.45.123.45
```

---

## 4. Connexion VPS et accès root {#connexion-vps}

### Étape 4.1 : Connexion SSH initiale

Depuis le terminal (WSL, Git Bash ou Linux/Mac) :

```bash
ssh root@185.45.123.45
```

Entrez le mot de passe root fourni par Hostinger.

### Étape 4.2 : Mettre à jour le système

```bash
apt update && apt upgrade -y
```

### Étape 4.3 : (Optionnel) Configurer une clé SSH

Pour éviter de taper le mot de passe à chaque fois :

**Sur votre machine locale :**

```bash
# Générer une clé SSH (si vous n'en avez pas)
ssh-keygen -t ed25519 -C "votre-email@example.com"

# Copier la clé sur le VPS
ssh-copy-id root@185.45.123.45
```

Vous pourrez ensuite vous connecter sans mot de passe : `ssh root@185.45.123.45`

---

## 5. Déploiement automatisé {#déploiement-automatisé}

Le projet inclut un script de déploiement automatique **`deploy-all.sh`** qui :

1. ✅ Détecte votre environnement (WSL/Git Bash)
2. ✅ Vérifie que les builds Flutter sont prêts
3. ✅ Upload tout le projet sur le VPS (via SSH)
4. ✅ Lance le déploiement sur le VPS automatiquement

### Étape 5.1 : Lancer le déploiement

**Depuis la racine du projet sur votre machine locale :**

```bash
bash deploy-all.sh
```

### Étape 5.2 : Suivre les instructions du script

Le script va vous demander :

1. **Adresse IP du VPS :**
   ```
   Entrer l'IP ou le domaine du VPS : 185.45.123.45
   ```

2. **Nom d'utilisateur SSH :**
   ```
   Nom d'utilisateur SSH [root] : root
   ```

3. **Méthode d'authentification SSH :**
   ```
   Choisir méthode d'authentification :
   1) Clé SSH spécifique
   2) Mot de passe (nécessite sshpass)
   3) Clé SSH par défaut (~/.ssh/id_rsa)
   Votre choix [1-3] : 3
   ```

   - **Option 1 (Recommandée)** : Si vous avez configuré une clé SSH
   - **Option 2** : Si vous utilisez un mot de passe (installer `sshpass` d'abord)
   - **Option 3** : Clé SSH système par défaut

### Étape 5.3 : Le script va automatiquement

1. ✅ Vérifier que Flutter et Docker sont installés localement
2. ✅ Vérifier que les builds web sont complets
3. ✅ Compresser le projet en `.tar.gz`
4. ✅ Uploader vers `/root/activeducation` sur le VPS
5. ✅ Lancer `deploy.sh` sur le VPS
6. ✅ Installer Docker + Docker Compose
7. ✅ Configurer le firewall UFW (autoriser SSH, HTTP, HTTPS)
8. ✅ Démarrer Traefik + Backend + Redis + Frontends
9. ✅ Demander les certificats SSL Let's Encrypt
10. ✅ Vérifier la santé de tous les services (health checks)

**Durée estimée : 5-10 minutes** (selon vitesse réseau et première installation)

### Étape 5.4 : Vérifier les logs de déploiement

À la fin du script, vous verrez un résumé :

```
========================================
  ✅ DÉPLOIEMENT TERMINÉ
========================================

Services disponibles :
  🌐 App étudiante : https://activeducationhub.com
  🔧 Admin Dashboard : https://admin.activeducationhub.com
  🚀 API Backend : https://api.activeducationhub.com

Commandes utiles sur le VPS :
  docker compose ps                # État des services
  docker compose logs backend      # Logs backend
  docker compose restart backend   # Redémarrer backend

Certificats SSL :
  Stockés dans : /root/activeducation/traefik/letsencrypt/
  Auto-renouvellement actif (Traefik s'en charge)
```

---

## 6. Vérification du déploiement {#vérification}

### Étape 6.1 : Vérifier que les services tournent

**Depuis le VPS (connecté en SSH) :**

```bash
cd /root/activeducation
docker compose ps
```

**Résultat attendu :**

```
NAME                      STATUS    PORTS
activeducation-traefik    Up        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
activeducation-redis      Up        6379/tcp
activeducation-api        Up        8000/tcp
activeducation-app        Up        80/tcp
activeducation-admin      Up        80/tcp
```

### Étape 6.2 : Tester les endpoints depuis votre navigateur

| URL | Ce que vous devez voir |
|-----|------------------------|
| `https://activeducationhub.com` | App étudiante Flutter (page d'accueil) |
| `https://admin.activeducationhub.com` | Dashboard admin (page de login) |
| `https://api.activeducationhub.com/health` | `{"status":"healthy"}` (JSON) |
| `https://api.activeducationhub.com/docs` | Documentation Swagger de l'API |

### Étape 6.3 : Vérifier les certificats SSL

Dans le navigateur, cliquer sur le **🔒 cadenas** à côté de l'URL :

- **Émetteur** : Let's Encrypt
- **Validité** : Certificat valide
- **HTTPS** : Connexion sécurisée

### Étape 6.4 : Tester l'authentification (Backend → Supabase)

1. Aller sur `https://admin.activeducationhub.com`
2. Essayer de se connecter avec un compte admin
3. Vérifier que l'auth fonctionne via Supabase

Si erreur CORS ou connexion impossible → voir [Dépannage](#dépannage)

### Étape 6.5 : Tester AÏDA (Chat IA)

1. Se connecter dans l'app étudiante
2. Aller dans le chat AÏDA
3. Envoyer un message : `Quelles sont les meilleures écoles au Togo ?`
4. Vérifier que la réponse cite les vraies écoles (UL, UCAO, ESGIS, etc.)

Si AÏDA ne répond pas → vérifier la clé Groq dans `.env.production`

---

## 7. Commandes utiles post-déploiement {#commandes-utiles}

### Gestion des services Docker

```bash
cd /root/activeducation

# Voir l'état de tous les services
docker compose ps

# Voir les logs en temps réel
docker compose logs -f

# Logs d'un service spécifique
docker compose logs -f backend
docker compose logs -f traefik

# Redémarrer un service
docker compose restart backend
docker compose restart traefik

# Arrêter tous les services
docker compose down

# Relancer tous les services
docker compose up -d

# Forcer le rebuild (après changement de code)
docker compose up -d --build
```

### Gestion des certificats SSL

```bash
# Voir les certificats Let's Encrypt
ls -lh /root/activeducation/traefik/letsencrypt/

# Vérifier l'expiration (auto-renouvelé par Traefik)
openssl s_client -connect activeducationhub.com:443 -servername activeducationhub.com < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

### Gestion du firewall UFW

```bash
# État actuel
ufw status verbose

# Règles configurées par deploy.sh :
# - 22/tcp (SSH) : ALLOW
# - 80/tcp (HTTP) : ALLOW
# - 443/tcp (HTTPS) : ALLOW

# Ajouter une règle (exemple : autoriser ping)
ufw allow from any to any proto icmp
ufw reload
```

### Monitoring système

```bash
# Utilisation CPU/RAM/Disque
htop

# Espace disque
df -h

# Logs système
journalctl -xe

# Logs Docker
docker compose logs --tail=100
```

### Mise à jour du backend (nouvelle version)

```bash
# Depuis votre machine locale
cd /chemin/vers/activeducation
git pull origin main

# Rebuilder le backend localement si nécessaire
cd backend
# (modifications...)

# Re-déployer avec deploy-all.sh
cd ..
bash deploy-all.sh
```

Ou directement sur le VPS :

```bash
cd /root/activeducation
git pull origin main
docker compose up -d --build backend
```

### Backup de la base de données Supabase

⚠️ **Note** : La base de données est hébergée sur Supabase (cloud), pas sur le VPS.

- Backups automatiques par Supabase (voir console.supabase.com)
- Pas de backup local nécessaire

---

## 8. Dépannage {#dépannage}

### Problème 1 : Erreur CORS dans le navigateur

**Symptôme :**
```
Access to fetch at 'https://api.activeducationhub.com/api/v1/auth/login'
from origin 'https://activeducationhub.com' has been blocked by CORS policy
```

**Solution :**

1. Vérifier `backend/.env.production` :
   ```env
   BACKEND_CORS_ORIGINS=https://activeducationhub.com,https://admin.activeducationhub.com
   ```

2. Redémarrer le backend :
   ```bash
   docker compose restart backend
   ```

---

### Problème 2 : Certificat SSL non émis (ERR_CERT_AUTHORITY_INVALID)

**Symptôme :** Le navigateur affiche une erreur de certificat.

**Causes possibles :**
- DNS pas encore propagé
- Let's Encrypt n'a pas pu valider le domaine

**Solution :**

1. Vérifier que le DNS pointe bien vers le VPS :
   ```bash
   dig activeducationhub.com +short
   # Doit retourner l'IP du VPS
   ```

2. Vérifier les logs Traefik :
   ```bash
   docker compose logs traefik | grep -i "error\|certificate"
   ```

3. Si erreur de challenge HTTP, vérifier que le port 80 est ouvert :
   ```bash
   ufw status | grep 80
   ```

4. Forcer la demande d'un nouveau certificat (supprimer l'ancien) :
   ```bash
   rm -rf traefik/letsencrypt/acme.json
   touch traefik/letsencrypt/acme.json
   chmod 600 traefik/letsencrypt/acme.json
   docker compose restart traefik
   ```

---

### Problème 3 : Backend ne démarre pas (unhealthy)

**Symptôme :**
```bash
docker compose ps
# activeducation-api  unhealthy
```

**Solution :**

1. Voir les logs du backend :
   ```bash
   docker compose logs backend
   ```

2. Erreurs courantes :
   - **"Connection refused" Supabase** → Vérifier `SUPABASE_URL` et `SUPABASE_KEY` dans `.env.production`
   - **"Redis connection failed"** → Vérifier que Redis tourne : `docker compose ps redis`
   - **"ModuleNotFoundError"** → Rebuild : `docker compose up -d --build backend`

3. Tester manuellement le health check :
   ```bash
   docker exec activeducation-api curl http://localhost:8000/health
   ```

---

### Problème 4 : Page blanche sur l'app Flutter

**Symptôme :** `https://activeducationhub.com` affiche une page blanche.

**Causes possibles :**
- Build Flutter incomplet
- Nginx ne trouve pas les fichiers

**Solution :**

1. Vérifier que les fichiers Flutter sont bien montés :
   ```bash
   docker exec activeducation-app ls -lh /var/www/html/
   # Doit afficher : index.html, main.dart.js, flutter_service_worker.js, etc.
   ```

2. Si fichiers absents, vérifier le volume dans `docker-compose.yml` :
   ```yaml
   volumes:
     - ./activ_education_app/build/web:/var/www/html:ro
   ```

3. Rebuilder l'app Flutter localement et re-déployer :
   ```bash
   cd activ_education_app
   flutter clean
   flutter build web --release --dart-define=API_BASE_URL=https://api.activeducationhub.com
   ```

4. Vérifier les logs Nginx :
   ```bash
   docker compose logs app-frontend
   ```

---

### Problème 5 : AÏDA ne répond pas

**Symptôme :** Le chat AÏDA reste en "chargement" indéfiniment.

**Solution :**

1. Vérifier que `GROQ_API_KEY` est configurée :
   ```bash
   grep GROQ_API_KEY backend/.env.production
   ```

2. Tester l'API Groq manuellement :
   ```bash
   docker compose logs backend | grep -i "groq\|llm"
   ```

3. Si erreur "401 Unauthorized" → Clé Groq invalide ou expirée :
   - Aller sur https://console.groq.com
   - Générer une nouvelle clé
   - Mettre à jour `.env.production`
   - Redémarrer : `docker compose restart backend`

---

### Problème 6 : Accès SSH perdu après configuration du firewall

**Symptôme :** Impossible de se reconnecter en SSH après le déploiement.

**Cause :** UFW a bloqué le port SSH par erreur.

**Solution d'urgence (depuis le panel Hostinger) :**

1. Aller dans hPanel → VPS → Console Web
2. Se connecter via le terminal web (pas besoin de SSH)
3. Vérifier UFW :
   ```bash
   ufw status
   ```
4. Autoriser SSH :
   ```bash
   ufw allow 22/tcp
   ufw reload
   ```

---

### Problème 7 : Manque de RAM / OOM Killer

**Symptôme :**
```bash
docker compose ps
# Un ou plusieurs services redémarrent constamment
```

**Cause :** Le VPS manque de RAM (surtout sur VPS 2GB).

**Solution :**

1. Vérifier l'utilisation mémoire :
   ```bash
   free -h
   docker stats
   ```

2. Réduire les workers du backend dans `Dockerfile` :
   ```dockerfile
   CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
   ```

3. Limiter la mémoire Redis dans `docker-compose.yml` (déjà configuré à 128MB).

4. Ajouter un fichier swap :
   ```bash
   fallocate -l 2G /swapfile
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
   echo '/swapfile none swap sw 0 0' >> /etc/fstab
   ```

---

## 📝 Checklist finale

Avant de considérer le déploiement comme terminé :

- [ ] DNS propagé (tous les domaines pointent vers le VPS)
- [ ] SSL actif (cadenas vert sur tous les domaines)
- [ ] App étudiante accessible (`https://activeducationhub.com`)
- [ ] Admin dashboard accessible (`https://admin.activeducationhub.com`)
- [ ] API documentée (`https://api.activeducationhub.com/docs`)
- [ ] Auth Supabase fonctionnelle (test login/register)
- [ ] Chat AÏDA répond correctement
- [ ] CORS configuré (pas d'erreurs dans la console navigateur)
- [ ] Health checks OK : `docker compose ps` → tous "Up (healthy)"
- [ ] Logs propres : `docker compose logs` → pas d'erreurs critiques
- [ ] Firewall actif : `ufw status` → SSH, HTTP, HTTPS autorisés
- [ ] Secrets sécurisés : `.env.production` **jamais commité dans Git**

---

## 🎉 Félicitations !

Votre plateforme ActivEducation est maintenant **live en production** !

**URLs de production :**
- 🌐 **App étudiante** : https://activeducationhub.com
- 🔧 **Admin dashboard** : https://admin.activeducationhub.com
- 🚀 **API Backend** : https://api.activeducationhub.com

**Support et maintenance :**
- Surveiller les logs : `docker compose logs -f`
- Vérifier l'état : `docker compose ps`
- Certificats SSL : Auto-renouvelés par Traefik (pas d'action requise)
- Backups Supabase : Automatiques (voir console Supabase)

---

## 📚 Ressources supplémentaires

- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [Documentation Docker Compose](https://docs.docker.com/compose/)
- [Documentation Let's Encrypt](https://letsencrypt.org/docs/)
- [Documentation Supabase](https://supabase.com/docs)
- [Documentation Flutter Web](https://docs.flutter.dev/platform-integration/web)

---

**Créé par l'équipe ActivEducation** | Dernière mise à jour : Mars 2026
