# ✅ Analyse Communication — Admin Dashboard ↔ App Étudiante ↔ Backend

> Rapport d'analyse de la communication entre les composants de la plateforme ActivEducation

---

## Résumé exécutif

| Composant | URL de production | Statut API | Build Status |
|-----------|-------------------|------------|--------------|
| **Backend API** | `https://api.activeducationhub.com` | ✅ Configuré | ✅ Prêt |
| **App Étudiante** | `https://activeducationhub.com` | ✅ Configuré | ⚠️ **Build incomplet** |
| **Admin Dashboard** | `https://admin.activeducationhub.com` | ✅ Configuré | ✅ Prêt (3.0 MB) |
| **Traefik (Proxy)** | — | ✅ Routes définies | ✅ Prêt |
| **CORS Backend** | — | ✅ Domaines autorisés | ✅ Prêt |

---

## 1. Configuration API — Admin Dashboard

**Fichier :** `admin_dashboard/lib/core/constants/api_endpoints.dart`

### Base URL
```dart
static final String baseUrl = _resolveBaseUrl();

static String _resolveBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  return 'http://localhost:8000/api/v1';  // Dev fallback
}
```

### Build de production
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1
```

### Endpoints définis (44 routes)

| Catégorie | Exemples |
|-----------|----------|
| **Auth Admin** | `/admin/auth/login`, `/admin/auth/logout` |
| **Dashboard** | `/admin/dashboard/stats`, `/admin/dashboard/recent-users` |
| **Gestion Users** | `/admin/users`, `/admin/users/{id}`, `/admin/users/{id}/deactivate` |
| **Gestion Schools** | `/admin/schools`, `/admin/schools/{id}/programs` |
| **Gestion Careers** | `/admin/careers`, `/admin/careers/sectors` |
| **Tests Orientation** | `/admin/tests`, `/admin/tests/{id}/questions` |
| **Gamification** | `/admin/gamification/achievements`, `/admin/gamification/challenges` |
| **Mentors** | `/admin/mentors`, `/admin/mentors/{id}/verify` |
| **Settings** | `/admin/settings/announcements`, `/admin/audit-log` |
| **Uploads** | `/admin/upload/school-logos`, `/admin/upload/career-images` |
| **Knowledge Base** | `/admin/knowledge-base/schools`, `/admin/knowledge-base/careers` |

**Status :** ✅ **Tous les endpoints backend sont mappés dans l'admin dashboard**

---

## 2. Configuration API — App Étudiante

**Fichier :** `activ_education_app/lib/core/constants/api_endpoints.dart`

### Base URL
```dart
static final String baseUrl = _resolveBaseUrl();

static String _resolveBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Dev fallback selon plateforme
  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';  // Android emulator
  }
  return 'http://localhost:8000';
}
```

### Build de production
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com
```

### Endpoints définis (28 routes)

| Catégorie | Exemples |
|-----------|----------|
| **Auth** | `/api/v1/auth/login`, `/api/v1/auth/register`, `/api/v1/auth/refresh` |
| **Users** | `/api/v1/users/me`, `/api/v1/users/me/avatar` |
| **Orientation** | `/api/v1/orientation/tests`, `/api/v1/orientation/sessions` |
| **Careers** | `/api/v1/orientation/mobile/careers` |
| **Mentors** | `/api/v1/mentors`, `/api/v1/mentors/{id}/reviews` |
| **Messages** | `/api/v1/messages/conversations` |
| **Schools** | `/api/v1/schools`, `/api/v1/schools/{id}` |
| **Chat AÏDA** | `/api/v1/chat/message`, `/api/v1/chat/message/stream` |
| **Gamification** | `/api/v1/gamification/profile`, `/api/v1/gamification/leaderboard` |

**Status :** ✅ **Tous les endpoints étudiants sont mappés**

---

## 3. Configuration CORS Backend

**Fichier :** `backend/.env.production`

```env
BACKEND_CORS_ORIGINS=https://activeducationhub.com,https://www.activeducationhub.com,https://admin.activeducationhub.com
```

**Implémentation :** `backend/app/main.py` (lignes 94-109)

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://activeducationhub.com",        # App étudiante
        "https://www.activeducationhub.com",    # App (www redirect)
        "https://admin.activeducationhub.com"   # Admin dashboard
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-Correlation-ID", "X-Process-Time"],
)
```

**Status :** ✅ **CORS correctement configuré pour tous les domaines**

---

## 4. Routage Traefik

**Fichier :** `traefik/dynamic.yml`

### Routes HTTP → HTTPS

| Router | Domaine | Destination | Port | TLS |
|--------|---------|-------------|------|-----|
| `backend` | `api.activeducationhub.com` | `activeducation-api` | 8000 | ✅ Let's Encrypt |
| `app` | `activeducationhub.com` | `activeducation-app` | 80 | ✅ Let's Encrypt |
| `app-www` | `www.activeducationhub.com` | → Redirect vers `activeducationhub.com` | — | ✅ Let's Encrypt |
| `admin` | `admin.activeducationhub.com` | `activeducation-admin` | 80 | ✅ Let's Encrypt |

### Security Headers (Middleware Traefik)

**API (le plus strict) :**
```yaml
customResponseHeaders:
  X-Frame-Options: "DENY"
  X-Content-Type-Options: "nosniff"
  Content-Security-Policy: "default-src 'none'; frame-ancestors 'none'"
  Permissions-Policy: "geolocation=(), microphone=(), camera=()"
```

**App étudiante (permissif pour SPA) :**
```yaml
customResponseHeaders:
  X-Frame-Options: "SAMEORIGIN"
  X-Content-Type-Options: "nosniff"
  Permissions-Policy: "geolocation=(), microphone=(), camera=()"
```

**Admin Dashboard (le plus strict) :**
```yaml
customResponseHeaders:
  X-Frame-Options: "DENY"
  X-Content-Type-Options: "nosniff"
  Permissions-Policy: "geolocation=(), microphone=(), camera=()"
```

**Status :** ✅ **Toutes les routes sont définies avec SSL automatique**

---

## 5. Configuration Nginx (Frontends)

**Fichiers :**
- `nginx/app.conf` (app étudiante)
- `nginx/admin.conf` (admin dashboard)

### Configuration SPA (identique pour les 2)

```nginx
location / {
    try_files $uri $uri/ /index.html;  # Client-side routing
}

# Cache des assets statiques
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|wasm|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Pas de cache pour index.html (déploiements)
location = /index.html {
    add_header Cache-Control "no-cache, must-revalidate";
}

# Pas de cache pour service worker (PWA)
location = /flutter_service_worker.js {
    add_header Cache-Control "no-cache, must-revalidate";
}
```

**Status :** ✅ **Configuration optimisée pour Flutter Web**

---

## 6. Statut des Builds Flutter

### Admin Dashboard ✅

```bash
$ ls -lh admin_dashboard/build/web/
-rw-r--r-- main.dart.js              3.0M   # ✅ Build complet
-rw-r--r-- flutter_service_worker.js  18K
-rw-r--r-- index.html                 5.2K
-rw-r--r-- manifest.json              1.1K
drwxr-xr-x assets/
drwxr-xr-x canvaskit/
```

**Dernière compilation :** 19 février 2026 à 06:32 UTC

**Status :** ✅ **PRÊT POUR DÉPLOIEMENT**

---

### App Étudiante ⚠️

```bash
$ ls -lh activ_education_app/build/web/
drwxr-xr-x assets/
drwxr-xr-x canvaskit/
-rw-r--r-- flutter.js                  8K
-rw-r--r-- index.html                 5K
# ❌ MANQUE : main.dart.js (fichier principal)
```

**Dernière tentative :** 10 mars 2026 à 12:37 UTC

**Status :** ❌ **BUILD INCOMPLET — BLOQUER LE DÉPLOIEMENT**

---

## 7. Action Requise : Rebuilder l'App Étudiante

### Commande de build

```bash
cd activ_education_app

# Nettoyer
flutter clean

# Build production
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com

# Vérifier
ls -lh build/web/main.dart.js
# Doit afficher plusieurs MB (ex: 2-4 MB)
```

### Vérification post-build

```bash
# Fichiers attendus
build/web/
├── main.dart.js              # ✅ Fichier principal (2-4 MB)
├── main.dart.js.map          # ✅ Source map
├── flutter_service_worker.js # ✅ Service Worker PWA
├── index.html                # ✅ Point d'entrée
├── manifest.json             # ✅ PWA manifest
├── assets/                   # ✅ Assets Flutter
├── canvaskit/                # ✅ CanvasKit (rendu web)
└── icons/                    # ✅ App icons
```

---

## 8. Test de Communication (Post-Déploiement)

### Test 1 : Health Check Backend

```bash
curl https://api.activeducationhub.com/health
```

**Résultat attendu :**
```json
{"status": "healthy"}
```

---

### Test 2 : CORS depuis Admin Dashboard

**Ouvrir DevTools (F12) sur `https://admin.activeducationhub.com`**

```javascript
fetch('https://api.activeducationhub.com/api/v1/admin/dashboard/stats', {
  credentials: 'include',
  headers: {
    'Authorization': 'Bearer <TOKEN>'
  }
})
.then(r => r.json())
.then(console.log)
```

**Résultat attendu :** Pas d'erreur CORS

---

### Test 3 : CORS depuis App Étudiante

**Ouvrir DevTools (F12) sur `https://activeducationhub.com`**

```javascript
fetch('https://api.activeducationhub.com/api/v1/schools')
.then(r => r.json())
.then(console.log)
```

**Résultat attendu :** Liste d'écoles en JSON

---

### Test 4 : Auth Flow (Login → API Call)

**Admin Dashboard :**
1. Login sur `https://admin.activeducationhub.com`
2. Vérifier que le token est stocké (DevTools → Application → LocalStorage)
3. Naviguer vers Dashboard → Vérifier que les stats s'affichent

**App Étudiante :**
1. Register/Login sur `https://activeducationhub.com`
2. Naviguer vers Orientation → Vérifier que les tests s'affichent
3. Naviguer vers Chat AÏDA → Envoyer un message

---

## 9. Erreurs Potentielles

### Erreur CORS (navigateur)

```
Access to fetch at 'https://api.activeducationhub.com/...'
from origin 'https://activeducationhub.com'
has been blocked by CORS policy
```

**Cause :** `BACKEND_CORS_ORIGINS` mal configuré dans `.env.production`

**Solution :**
```bash
# Vérifier
grep BACKEND_CORS_ORIGINS backend/.env.production

# Corriger si nécessaire
BACKEND_CORS_ORIGINS=https://activeducationhub.com,https://admin.activeducationhub.com

# Redémarrer backend
docker compose restart backend
```

---

### Erreur 401 Unauthorized

**Cause :** Token Supabase invalide ou expiré

**Solution :**
1. Vérifier que `SUPABASE_KEY` est correcte dans `.env.production`
2. Vérifier que le token JWT est présent dans les headers de la requête
3. Re-login dans l'app pour obtenir un nouveau token

---

### Erreur Network Request Failed

**Cause :** URL API incorrecte ou backend down

**Solution :**
1. Vérifier que le backend tourne : `docker compose ps backend`
2. Vérifier les logs : `docker compose logs backend`
3. Vérifier l'URL de build Flutter : `--dart-define=API_BASE_URL=...`

---

## 10. Conclusion

### Statut Global

| Composant | Communication | Prêt pour Prod |
|-----------|---------------|----------------|
| Admin Dashboard → Backend | ✅ Configuré | ✅ OUI |
| App Étudiante → Backend | ✅ Configuré | ⚠️ **NON** (build incomplet) |
| Backend CORS | ✅ Configuré | ✅ OUI |
| Traefik Routes | ✅ Configuré | ✅ OUI |
| SSL Let's Encrypt | ✅ Auto-renouvelé | ✅ OUI |

### Action Immédiate Requise

```bash
# Rebuilder l'app étudiante
cd activ_education_app
flutter clean
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com

# Vérifier
ls -lh build/web/main.dart.js
```

### Déploiement

Une fois l'app étudiante rebuildée :

```bash
# Depuis la racine du projet
bash deploy-all.sh
```

---

**Analyse réalisée le :** 16 mars 2026
**Status final :** ⚠️ **Prêt après rebuild de l'app étudiante**
