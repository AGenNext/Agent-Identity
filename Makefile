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
