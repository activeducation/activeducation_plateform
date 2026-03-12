# Guide de contribution

## Workflow Git

Nous utilisons **GitFlow** :

```
main        ← Production (protégée, déploiement manuel)
develop     ← Staging (déploiement automatique)
feature/*   ← Nouvelles fonctionnalités
fix/*       ← Corrections de bugs
hotfix/*    ← Corrections urgentes en production
```

### Créer une feature

```bash
git checkout develop
git pull origin develop
git checkout -b feature/ma-fonctionnalite
# ... travailler ...
git push origin feature/ma-fonctionnalite
# Ouvrir une PR vers develop
```

### Règles des PR

- Toute PR nécessite au minimum **1 review**
- Le CI doit passer (backend lint + tests, flutter analyze)
- Pas de merge si coverage < 60%
- Titre de PR clair et descriptif

## Conventions de commit

Nous suivons **Conventional Commits** :

```
<type>(<scope>): <description courte>

[corps optionnel]

[footer optionnel]
```

### Types

| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `style` | Formatage (pas de changement logique) |
| `refactor` | Refactoring sans nouvelles fonctionnalités |
| `test` | Ajout ou correction de tests |
| `chore` | Maintenance, dépendances, CI |
| `perf` | Amélioration de performance |
| `security` | Correction de faille de sécurité |

### Scopes

`backend`, `app`, `admin`, `infra`, `ci`, `docs`

### Exemples

```bash
feat(backend): ajouter endpoint de liste des écoles par région
fix(app): corriger crash au démarrage sur Android 12
docs: mettre à jour README avec nouvelles instructions Docker
chore(ci): mettre à jour Flutter vers 3.32.0
security(backend): corriger validation CORS en production
test(backend): ajouter tests unitaires pour auth_service
```

## Standards de code

### Python (Backend)

- Formatage : **Black** (line-length=100)
- Linting : **flake8** (max-line-length=100)
- Type hints obligatoires sur les fonctions publiques
- Docstrings pour toutes les classes et méthodes publiques
- Tests unitaires pour chaque service / repository

```bash
# Avant de commiter
black app/ --line-length=100
flake8 app/ --max-line-length=100
pytest tests/ -v
```

### Dart/Flutter

- Respecter `flutter analyze` (zéro warning)
- Utiliser des `const` constructors quand possible
- Pattern BLoC pour la gestion d'état
- Pas de `setState` dans les pages principales
- Tests BLoC obligatoires pour chaque nouveau BLoC

```bash
# Avant de commiter
flutter analyze
flutter test
```

## Structure des branches de protection

| Branche | Règles |
|---------|--------|
| `main` | Review obligatoire, CI vert, pas de push direct |
| `develop` | CI vert obligatoire |

## Signalement de bugs

Ouvrir une issue avec :
- Description claire du problème
- Étapes pour reproduire
- Comportement attendu vs observé
- Logs d'erreur (sans données sensibles)
- Environnement (OS, navigateur, version Flutter/Python)

## Questions

Ouvrir une issue avec le label `question`.
