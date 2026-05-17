# Agent Identity

A deployment-ready FastAPI service scaffold for Agent Identity.

## Local Development

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
make run
```

## Docker Deployment

```bash
cp .env.example .env
docker compose up --build
```

## Health Check

- http://localhost:8000/health
- http://localhost:8000/ready
- http://localhost:8000/docs
