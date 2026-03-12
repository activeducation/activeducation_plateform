.PHONY: help backend-run backend-test docker-up docker-down migrate-upgrade update-deps

help:
	@echo "ActivEducation — Commandes disponibles:"
	@echo "  make backend-run       Lancer l'API FastAPI en dev"
	@echo "  make backend-test      Lancer les tests backend"
	@echo "  make docker-up         Démarrer tous les services Docker"
	@echo "  make docker-down       Arrêter les services Docker"
	@echo "  make migrate-upgrade   Appliquer les migrations Alembic"
	@echo "  make update-deps       Régénérer requirements.txt via pip-compile"

backend-run:
	cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

backend-test:
	cd backend && pytest tests/ --cov=app --cov-report=term-missing -v

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

migrate-upgrade:
	cd backend && alembic upgrade head

migrate-current:
	cd backend && alembic current

migrate-history:
	cd backend && alembic history

update-deps:
	cd backend && pip install pip-tools && pip-compile requirements.in --output-file requirements.txt
	@echo "requirements.txt mis à jour. Vérifiez les changements avec git diff."
