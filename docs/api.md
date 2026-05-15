# API Endpoints

## Health Check

```http
GET /health
```

## List Agents

```http
GET /agents
```

## Create Agent

```http
POST /agents
Content-Type: application/json

{
  "name": "Sales Agent",
  "provider": "OpenAI",
  "model": "gpt-5",
  "version": "1.0.0"
}
```
