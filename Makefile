# =============================================================================
# ActivEducation - Commandes de developpement
# =============================================================================
# Usage: make <cible>
# =============================================================================

.DEFAULT_GOAL := help
.PHONY: help install-hooks backend-install backend-test backend-lint backend-format \
        flutter-get flutter-analyze flutter-test flutter-build-web \
        docker-up docker-down docker-logs migrate-status migrate-upgrade migrate-create

# =============================================================================
# AIDE
# =============================================================================

help: ## Afficher cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# INSTALLATION
# =============================================================================

install-hooks: ## Installer les pre-commit hooks
	pip install pre-commit commitizen
	pre-commit install
	pre-commit install --hook-type commit-msg
	@echo "✅ Pre-commit hooks installed"

# =============================================================================
# BACKEND
# =============================================================================

backend-install: ## Installer les dependances backend
	cd backend && pip install -r requirements.txt

backend-test: ## Lancer les tests backend avec coverage
	cd backend && pytest tests/ -v --cov=app --cov-report=term-missing --cov-fail-under=60

backend-test-fast: ## Lancer les tests backend sans coverage (plus rapide)
	cd backend && pytest tests/ -v

backend-lint: ## Verifier le style du code backend
	cd backend && flake8 app/ --max-line-length=100 --exclude=__pycache__
	cd backend && black app/ --check --line-length=100

backend-format: ## Formater le code backend automatiquement
	cd backend && black app/ --line-length=100
	cd backend && isort app/ --profile=black

backend-run: ## Demarrer l'API en mode developpement
	cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# =============================================================================
# FLUTTER
# =============================================================================

flutter-get: ## Installer les dependances Flutter (app + admin)
	cd activ_education_app && flutter pub get
	cd admin_dashboard && flutter pub get

flutter-analyze: ## Analyser le code Flutter (app + admin)
	cd activ_education_app && flutter analyze
	cd admin_dashboard && flutter analyze

flutter-test: ## Lancer les tests Flutter (app + admin)
	cd activ_education_app && flutter test
	cd admin_dashboard && flutter test

flutter-build-web: ## Builder les apps Flutter web (release)
	cd activ_education_app && flutter build web --release
	cd admin_dashboard && flutter build web --release

flutter-gen: ## Regenerer le code Flutter (freezed, json_serializable)
	cd activ_education_app && flutter pub run build_runner build --delete-conflicting-outputs
	cd admin_dashboard && flutter pub run build_runner build --delete-conflicting-outputs

# =============================================================================
# DOCKER
# =============================================================================

docker-up: ## Demarrer tous les services Docker
	docker compose up -d

docker-down: ## Arreter tous les services Docker
	docker compose down

docker-logs: ## Voir les logs en temps reel
	docker compose logs -f

docker-rebuild: ## Reconstruire et redemarrer le backend
	docker compose up -d --build backend

docker-status: ## Voir l'etat des conteneurs
	docker compose ps

# =============================================================================
# MIGRATIONS
# =============================================================================

migrate-status: ## Voir l'etat des migrations Alembic
	cd backend && alembic current

migrate-history: ## Voir l'historique des migrations
	cd backend && alembic history --verbose

migrate-upgrade: ## Appliquer toutes les migrations en attente
	cd backend && alembic upgrade head

migrate-downgrade: ## Revenir d'une migration en arriere
	cd backend && alembic downgrade -1

migrate-create: ## Creer une nouvelle migration (usage: make migrate-create MSG="description")
	cd backend && alembic revision -m "$(MSG)"

# =============================================================================
# CHECKS
# =============================================================================

check-all: backend-lint flutter-analyze ## Lancer tous les checks de qualite

test-all: backend-test flutter-test ## Lancer tous les tests

ci-backend: backend-lint backend-test ## Simuler le CI backend localement

ci-frontend: flutter-analyze flutter-test ## Simuler le CI frontend localement
