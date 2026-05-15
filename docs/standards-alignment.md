# Standards Alignment

Agent Identity is designed to align with emerging identity patterns for autonomous and agentic software.

## OAuth 2.1

Use OAuth-style scoped authorization for delegated access.

## OpenID Connect

Use identity claims to distinguish principals and acting agents.

Recommended claims:

- `sub`: human or owning principal
- `act`: acting agent identity
- `azp`: authorized party
- `scope`: delegated permissions
- `aud`: intended resource server

## OAuth Token Exchange

Future support should allow one agent to exchange a token for a narrower downstream token when delegating to another agent.

## SCIM

Future support should expose lifecycle APIs for provisioning, updating, suspending, and de-provisioning agent identities.

## Shared Signals

Future support should emit revocation, suspension, compromise, and de-provisioning events.

## Verifiable Credentials

Future support should store and verify signed attestations for agent provenance, publisher trust, runtime integrity, and compliance status.
