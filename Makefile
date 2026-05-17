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
