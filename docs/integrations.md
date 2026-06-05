# Integrations

Integrations are the adoption engine for Agent Identity (issue #4). Every integration is a
**declarative connector manifest** that maps an external system onto the grounded model, plus
an **MCP server** so agents can drive identity directly.

## Connector manifests

A connector is a JSON file under [`connectors/`](../connectors/) conforming to
[`connectors/manifest.schema.json`](../connectors/manifest.schema.json). It declares the
provider, category, auth, capabilities, event→flow mappings, and a `mapping` from provider
concepts to model terms. `scripts/validate_connectors.py` validates every manifest in CI
(including that each `mapping` target is a real model term).

| Connector | Category | Maps |
| --- | --- | --- |
| [`okta`](../connectors/okta.connector.json) | idp | users→`agent_identity`, schema→`schema_attribute`, lifecycle events→flows |
| [`sailpoint`](../connectors/sailpoint.connector.json) | iga | sources/accounts/entitlements/access-profiles/roles, certifications→`access_review` |
| [`cyberark`](../connectors/cyberark.connector.json) | pam | safes→`safe`, accounts→`account` |
| [`scim-agentic`](../connectors/scim.connector.json) | scim | `AgenticIdentity`→`agent_identity`, SCIM lifecycle→flows |

**Categories:** `idp`, `iga`, `pam`, `saas`, `runtime`, `finance`, `mcp`, `scim`.
**Capabilities:** provision, deprovision, verify, revoke, lifecycle_events, entitlements,
access_review, attributes, secrets, sessions, payments.

### Add a connector

1. Copy an existing `*.connector.json` and edit `id`, `provider`, `category`, `auth`,
   `capabilities`, `endpoints`, `events`, and `mapping`.
2. Make sure every `mapping` value is a real model term (the validator enforces this).
3. `python scripts/validate_connectors.py`.

## MCP server

[`mcp/`](../mcp/) is an MCP server scaffold exposing the flows as tools
(`resolve_agent`, `verify_agent`, `provision_agent`, `activate_agent`, `revoke_agent`,
`list_entitlements`) over SurrealDB. See [`mcp/README.md`](../mcp/README.md).

## Deeper integration guides

- [Okta](./okta-integration.md) · [Okta catalog](./okta-integration-catalog.md)
- [Unboxd Platform / SPIFFE](./unboxd-platform-integration.md)
- [Crossplane control plane](./crossplane-control-plane.md)
