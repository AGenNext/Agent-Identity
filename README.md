# Agent Identity

Agent Identity is the **identity control plane for AI agents and digital workers**.

It is not just an auth service. Authentication, authorization, IGA, and PAM belong to the access control plane. Agent Identity is the system of record for the agent itself: who it is, who owns it, what lifecycle state it is in, what it consumes, what it costs, what evidence exists, and whether it should remain active.

## Platform Positioning

```txt
Okta = identity platform for humans and apps
Agent Identity = identity control plane for AI agents
```

## What Agent Identity Owns

- Agent Universal Directory
- Agent Registry
- Agent lifecycle state
- Agent identity card/profile
- Agent owner, sponsor, company, team, and project context
- Agent usage signals
- Agent Pay metadata
- Agent FinOps recommendations
- Agent Optimize recommendations
- Agent audit evidence
- Agent evaluation signals
- Integrations with IAM, IGA, PAM, HRMS, runtime, finance, and evaluation systems

## What It Does Not Own Directly

These belong to the access control plane, but Agent Identity integrates with them:

- Authentication
- Authorization
- IGA approvals and certifications
- PAM sessions and secrets
- Access enforcement
- Token issuance

## Product Services

```txt
Directory
Lifecycle
Usage
Pay
FinOps
Optimize
Audit
Evaluation
Integrations
```

## API-First Design

Most users will not manage agents manually. Other systems and agents will use the platform through APIs, SDKs, and MCP tools.

Primary interface order:

```txt
1. APIs
2. SDKs
3. MCP tools for agents
4. Reports and dashboards
5. Manual UI controls only where needed
```

## Core APIs

Initial API surface:

- `GET /agents`
- `POST /agents`
- `GET /capabilities`
- `POST /capabilities`
- `GET /credentials`
- `POST /credentials`
- `POST /credentials/:id/revoke`
- `GET /delegations`
- `POST /delegations`
- `GET /policies`
- `POST /policies`
- `POST /authorize`
- `GET /audits`
- `POST /audits`
- `POST /tokens/issue`
- `POST /tokens/verify`

Planned API surface:

- `GET /agents/:id/identity-card`
- `GET /agents/:id/lifecycle`
- `POST /agents/:id/lifecycle-transition`
- `GET /agents/:id/usage-summary`
- `GET /agents/:id/pay-summary`
- `GET /agents/:id/evaluation`
- `GET /reports/usage`
- `GET /reports/finops`
- `GET /reports/audit`

## SDKs

SDKs should make Agent Identity easy to embed into SaaS platforms, runtime providers, agent frameworks, and enterprise systems.

Planned SDKs:

```txt
packages/sdk-js      JavaScript/TypeScript SDK
packages/sdk-python  Python SDK
packages/mcp-server  MCP server for agent access
```

## MCP Support

Agents should be able to query Agent Identity through MCP.

Planned MCP tools:

- `agent_identity.get_identity_card`
- `agent_identity.get_lifecycle_status`
- `agent_identity.record_usage`
- `agent_identity.record_audit_event`
- `agent_identity.request_lifecycle_transition`
- `agent_identity.get_policy_context`
- `agent_identity.get_evaluation_summary`

## UI Strategy

The UI is not the primary control surface. It should focus first on reports and dashboards.

Dashboard priorities:

- Agent inventory
- Lifecycle distribution
- Usage reports
- Agent Pay reports
- FinOps recommendations
- Optimize recommendations
- Audit explorer
- Evaluation summary

Manual controls should be limited to exceptional workflows such as approvals, investigations, suspensions, and termination reviews.

## Local Development

```bash
pnpm install
cp apps/api/.env.example apps/api/.env
docker compose up -d
pnpm dev
```

API:

```txt
http://localhost:3000
```

SurrealDB:

```txt
http://localhost:8000
```

Default local credentials:

```txt
user: root
pass: root
namespace: agent_identity
database: dev
```

## Repository Layout

```txt
apps/api/          API service
apps/web/          Future reports and dashboard UI
packages/          Future SDKs and shared packages
surreal/           SurrealDB schema and seed data
docs/              Product, architecture, and standards notes
```

## Status

MVP scaffold in progress. The project currently includes the API scaffold, SurrealDB schema, lifecycle model, JWT utilities, audit model, service architecture, and product documentation.
