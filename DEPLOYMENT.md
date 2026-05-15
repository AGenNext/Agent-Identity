# Deployment Guide

## Docker

```bash
pnpm install
pnpm --filter @agent-identity/api build
pnpm --filter @agent-identity/api start
```

## Environment Variables

See `apps/api/.env.example`.

## Production Recommendations

- Use a managed SurrealDB cluster
- Store secrets in Vault or cloud secret manager
- Rotate JWT secrets regularly
- Enable HTTPS
- Add centralized logging
- Configure backups
- Enable monitoring and alerts

## Infrastructure Options

- Docker Compose
- Kubernetes
- Fly.io
- Railway
- AWS ECS/Fargate
- Google Cloud Run
- Azure Container Apps
