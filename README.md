# Agent Identity

Agent Identity is an identity, credential, delegation, authorization, and audit platform for AI agents.

The goal is to treat every AI agent as a first-class digital identity with:

- Persistent agent identifiers
- Owner and delegation chains
- Scoped capabilities and policies
- Credential metadata and revocation status
- Trust attestations
- Complete audit history

## Why this exists

Agentic AI systems need stronger identity controls than traditional API keys or shared service accounts. Agent Identity provides the system of record for who an agent is, who authorized it, what it can do, and what it has done.

## Core modules

- **Agent Registry**: register and manage agent identities.
- **Delegation Graph**: connect users, organizations, and agents.
- **Credential Registry**: track signing keys, tokens, rotations, and revocations.
- **Capability Catalog**: define what actions agents may perform.
- **Policy Layer**: bind agents to scoped permissions.
- **Audit Ledger**: record agent actions for accountability.

## Initial stack

- SurrealDB for graph-native identity data
- SurrealQL schema definitions
- Docker Compose for local development
- Future API layer for issuing, validating, and revoking credentials

## Local development

```bash
docker compose up -d
```

SurrealDB will be available at:

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

## Repository layout

```txt
docs/       Product and architecture notes
surreal/    SurrealDB schema and seed data
```

## Status

MVP scaffold in progress.
