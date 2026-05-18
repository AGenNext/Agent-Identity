# ADR 0002: Use walt.id for DID and Verifiable Credential Infrastructure

## Status

Accepted

## Context

Agent Identity needs support for decentralized identifiers, verifiable credential issuance, credential verification, proof handling, and standards-oriented interoperability.

Building all DID and VC infrastructure from scratch would create unnecessary security, interoperability, and maintenance risk.

The product should focus on the agent-specific identity layer:

- Agent registry
- Agent metadata
- Capability grants
- Trust and reputation
- Revocation metadata
- Auditability
- Integration workflows

## Decision

Use **walt.id** as the DID and Verifiable Credential infrastructure layer.

Use **SurrealDB Cloud** as the backend data store for Agent Identity-specific records and trust graph metadata.

## Responsibilities

### walt.id owns

- DID creation and management
- DID method support
- Verifiable Credential issuance
- Verifiable Credential verification
- Credential templates
- Proof handling
- Standards-aligned identity workflows

### SurrealDB Cloud owns

- Agent records
- Organization and developer records
- walt.id DID references
- walt.id credential references
- Capability grants
- Trust scores
- Reputation events
- Revocation metadata
- Audit events

### Agent Identity owns

- Product-level orchestration
- Agent-specific schema
- SDK workflows
- Trust and reputation logic
- Capability evaluation
- Integration between SurrealDB Cloud and walt.id

## Architecture

```text
Agent Identity SDK / UI
        ↓
Agent Identity Orchestration Layer
        ↓
┌────────────────────┬──────────────────────┐
│ SurrealDB Cloud     │ walt.id              │
│ agent registry      │ DID management       │
│ trust graph         │ VC issuance          │
│ capabilities        │ VC verification      │
│ audit metadata      │ identity standards   │
└────────────────────┴──────────────────────┘
```

## Consequences

- The project should not implement a custom DID/VC engine as the primary path.
- Credential records in SurrealDB should store walt.id references and selected metadata, not duplicate all identity infrastructure.
- The SDK should expose simple agent workflows while delegating DID/VC operations to walt.id.
- Documentation should describe Agent Identity as a walt.id-integrated trust layer, not as a standalone VC implementation.

## Non-Goals

- Replacing walt.id wallet, issuer, or verifier infrastructure.
- Locking the product forever to a single DID method.
- Preventing future support for other identity providers.

## Future Flexibility

The schema should keep provider fields such as:

- `identity_provider`
- `external_did_id`
- `external_credential_id`
- `issuer_did`
- `subject_did`

This allows Agent Identity to support additional providers later while using walt.id as the default implementation.
