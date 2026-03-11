# Pratiques de sécurité

## Principes

1. **Défense en profondeur** : plusieurs couches de sécurité
2. **Moindre privilège** : chaque composant n'a que les droits nécessaires
3. **Sécurité par défaut** : les configs sécurisées sont les configs par défaut
4. **Secrets jamais dans le code** : uniquement via variables d'environnement

## Authentification et autorisation

### Tokens JWT

- Algorithme : HS256
- Durée access token : 30 minutes
- Durée refresh token : 7 jours
- SECRET_KEY : minimum 32 caractères, générée aléatoirement

> ⚠️ Migration en cours vers Supabase Auth natif (élimine la gestion JWT maison)

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

- Hachage bcrypt (12 rounds)
- Validation force : 8+ chars, majuscule, minuscule, chiffre, caractère spécial
- Troncature à 72 bytes (limite bcrypt)

## Infrastructure

### Docker

- Backend tourne en utilisateur non-root (`appuser`)
- Pas d'accès au socket Docker depuis le backend
- ⚠️ Traefik accède au socket Docker directement (à migrer vers `tecnativa/docker-socket-proxy`)

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
- [ ] `SECRET_KEY` générée aléatoirement (≥32 chars)
- [ ] `BACKEND_CORS_ORIGINS` limité aux domaines officiels
- [ ] `ENVIRONMENT=production`
- [ ] Certificats SSL valides
- [ ] RLS activé sur Supabase
- [ ] Logs ne contiennent pas de données sensibles
