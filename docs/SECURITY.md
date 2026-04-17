# Pratiques de sécurité

## Principes

1. **Défense en profondeur** : plusieurs couches de sécurité
2. **Moindre privilège** : chaque composant n'a que les droits nécessaires
3. **Sécurité par défaut** : les configs sécurisées sont les configs par défaut
4. **Secrets jamais dans le code** : uniquement via variables d'environnement

## Authentification et autorisation

### Authentification (Supabase Auth)

L'authentification principale s'appuie sur Supabase Auth. Le backend valide les tokens :

- **Mode local (recommandé en prod)** : si `SUPABASE_JWT_SECRET` est défini, les tokens sont validés localement avec `python-jose` (zéro appel réseau).
- **Mode API (fallback)** : si le secret JWT n'est pas configuré, le backend appelle `supabase.auth.get_user(token)` à chaque requête.
- Dans les deux cas, les résultats sont mis en cache Redis 60 s (clé = SHA-256 du token, jamais le token brut).

### Tokens internes (reset password, liens signés)

- Algorithme : HS256
- SECRET_KEY : minimum 32 caractères, aléatoire — rejetée si elle ressemble à un JWT (préfixe `eyJ`) ou si elle contient un marqueur placeholder (`placeholder`, `ci-test`, `pytest-dummy`).
- Rotation : voir `docs/OPERATIONS.md` § 5.

### Rôles

| Rôle | Description |
|------|-------------|
| `student` | Étudiant standard |
| `admin` | Administrateur de la plateforme |
| `super_admin` | Accès total |

### Protection des endpoints

Tous les endpoints sensibles utilisent la dependency `get_current_user_id` de FastAPI.
Les endpoints admin utilisent `get_current_admin` ou `get_current_super_admin`.

## Sécurité API

### Rate Limiting (slowapi)

- Endpoints d'auth : 10 requêtes/minute (strict)
- API générale : 60 requêtes/minute
- Réponse 429 avec Retry-After header

### CORS

- En production : seuls les domaines officiels autorisés
- Pas de wildcard `*` en production
- Configuration dans `BACKEND_CORS_ORIGINS`

### Headers de sécurité (Traefik + Nginx)

```
Strict-Transport-Security: max-age=63072000; includeSubdomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY (admin), SAMEORIGIN (app)
Referrer-Policy: strict-origin-when-cross-origin
```

### Validation des entrées

- Pydantic v2 valide toutes les entrées API
- Email validator sur les champs email
- Longueur maximale sur les champs texte libres

## Mots de passe

- Le hachage est délégué à Supabase Auth (bcrypt, géré côté plateforme managée).
- Validation côté backend avant soumission : 8+ chars, majuscule, chiffre, caractère spécial (voir `validate_password_strength`).

## Stockage client

- **Tokens mobiles/web (Flutter)** : `flutter_secure_storage` (Keychain iOS / Keystore Android via `encryptedSharedPreferences` / DPAPI Windows). Migration automatique depuis l'ancien stockage `SharedPreferences` en clair au premier lancement.
- **Metadonnées non sensibles** (user_id, email, role) : SharedPreferences.

## Infrastructure

### Docker

- Backend tourne en utilisateur non-root (`appuser`)
- Pas d'accès au socket Docker depuis le backend
- Traefik passe par **`tecnativa/docker-socket-proxy:0.3.0`** en lecture seule (`POST=0`, `CONTAINERS=1`, `NETWORKS=1`) — aucune mutation possible sur le démon Docker depuis le reverse proxy.
- Le proxy est isolé dans un réseau `socket-proxy-network` marqué `internal: true` (pas de trafic sortant).
- Tous les services appliquent `no-new-privileges:true` et des limites `cpus/memory` via `deploy.resources`.
- Les logs sont bornés (`json-file`, rotation 5-10 MB × 2-5 fichiers) pour éviter la saturation disque.

### Secrets

- Variables d'environnement via fichiers `.env` (jamais commités)
- `.env.example` commité sans valeurs réelles
- Fichiers `.env.*` dans `.gitignore`

### Réseau

- Tous les services dans un réseau bridge isolé (`app-network`)
- Seul Traefik expose les ports 80/443
- Backend non exposé directement (uniquement via Traefik)

## Supabase

- Row Level Security (RLS) activé sur toutes les tables sensibles
- Clé `anon` utilisée pour les opérations publiques
- Clé `service_role` utilisée uniquement côté backend pour les opérations admin

## Ce qu'il ne faut JAMAIS faire

- Commiter des secrets, clés API, ou mots de passe
- Désactiver le SSL en production
- Utiliser `DEBUG=True` en production
- Logger des mots de passe ou tokens
- Exposer le socket Docker sans proxy
- Utiliser `allow_origins=["*"]` avec `allow_credentials=True`

## Signalement de vulnérabilités

Ne pas ouvrir une issue publique. Contacter directement l'équipe à security@activeduhub.com.

## Checklist avant déploiement production

- [ ] `DEBUG=False`
- [ ] `SECRET_KEY` générée aléatoirement (≥32 chars, pas de marqueur placeholder)
- [ ] `SUPABASE_SERVICE_ROLE_KEY` défini (obligatoire en prod — endpoints admin)
- [ ] `SUPABASE_JWT_SECRET` défini (valide les tokens en local, zéro appel réseau)
- [ ] `BACKEND_CORS_ORIGINS` limité aux domaines officiels, pas de `*`
- [ ] `ENVIRONMENT=production`
- [ ] Certificats SSL valides (renouvelés auto par Traefik)
- [ ] RLS activé sur toutes les tables Supabase sensibles
- [ ] Logs ne contiennent pas de données sensibles (tokens, passwords)
- [ ] `SENTRY_DSN` configuré (backend + `--dart-define` pour chaque build Flutter)
- [ ] Headers CSP / HSTS vérifiés via https://securityheaders.com
- [ ] Rate limit Traefik actif (100 req/min/IP par défaut)
