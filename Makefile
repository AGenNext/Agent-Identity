install:
	pip install -r requirements.txt

run:
	uvicorn app.main:app --reload

test:
	pytest -q

build:
	docker build -t agent-identity .

up:
	docker compose up --build

down:
	docker compose down

validate:
	python3 scripts/validate_lifecycle.py

validate-release:
	python3 scripts/validate_release.py

smoke:
	bash scripts/surreal_smoke_test.sh

k8s-image:
	docker build -t ghcr.io/agennext/agent-identity-api:latest apps/api

k8s-schema:
	bash deploy/k8s/create-schema-configmap.sh

k8s-deploy:
	kubectl apply -k deploy/k8s
