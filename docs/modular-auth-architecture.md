# Modular Authentication and Authorization Architecture

Authentication should live in a separate repository so Agent Identity remains modular.

## Product Decision

Agent Identity should not own the full authentication implementation.

Instead:

```txt
Agent Auth repo      -> OIDC/OAuth authentication, token issuance, delegation flows
Agent Identity repo  -> registry, lifecycle, access, usage, pay, audit, evaluation
Agent Authorization  -> AuthZEN-style policy decision API, either inside Agent Identity or separate later
```

## Why Separate Auth

Keeping authentication separate gives us:

- Modular architecture
- Cleaner security boundary
- Easier replacement with customer IdPs
- Easier OIDC/OAuth compliance
- Better enterprise adoption
- Reusable auth service for multiple Agennext products

## Standards Split

| Concern | Recommended Standard | Owner |
|---|---|---|
| Human authentication | OIDC | Agent Auth |
| Agent authentication | OAuth 2.1 / workload identity | Agent Auth |
| Delegated authority | OAuth OBO / Token Exchange | Agent Auth |
| Token claims | JWT / OIDC claims | Agent Auth |
| Policy decision | AuthZEN-style PDP API | Agent Authorization |
| Lifecycle provisioning | SCIM-style APIs | Agent Identity |
| Registry and lifecycle state | Agent Identity model | Agent Identity |

## Agent Auth Responsibilities

The separate Agent Auth repository should own:

- User login
- Agent login
- OIDC provider integration
- OAuth client registration
- Token issuance
- Token verification
- Delegated token exchange
- On-behalf-of flows
- JWT claim profiles
- Session management
- Token revocation

Recommended claims:

```txt
sub = human or owning principal
act = acting agent
azp = authorized party
aud = target service
scope = delegated permissions
agent_lifecycle_status = current lifecycle state
agent_registry_id = registered agent identity
```

## Agent Identity Responsibilities

This repository should own:

- Agent registry
- Agent lifecycle
- Agent access metadata
- IAM/IGA/PAM integrations
- Usage metering
- Agent Pay settlement metadata
- Agent FinOps
- Agent Optimize
- Audit and evidence
- Evaluation signals

## AuthZEN Decision

AuthZEN should be used for authorization decisions, not authentication.

An AuthZEN-style endpoint should answer:

```txt
Can subject S perform action A on resource R in context C?
```

Example input:

```json
{
  "subject": {
    "type": "agent",
    "id": "agent:research_assistant",
    "principal": "user:chinmay"
  },
  "action": "crm.read",
  "resource": {
    "type": "account",
    "id": "account:acme"
  },
  "context": {
    "lifecycle_status": "probation",
    "risk": "medium",
    "cost_center": "growth"
  }
}
```

Example output:

```json
{
  "decision": "deny",
  "reason": "probation agents require approval for crm.read",
  "matched_policy": "policy:probation-crm-approval"
}
```

## Recommended Repo Split

```txt
AGenNext/Agent-Identity
AGenNext/Agent-Auth
AGenNext/Agent-Authorization   optional later
```

Start with two repos:

1. Agent Identity
2. Agent Auth

Keep AuthZEN-style authorization inside Agent Identity initially, then split it into Agent Authorization when it becomes large enough.

## Integration Flow

```txt
1. User authenticates through Agent Auth
2. Agent authenticates through Agent Auth
3. Agent Auth issues delegated JWT
4. Agent calls a tool or API
5. PEP sends authorization question to Agent Identity/AuthZEN endpoint
6. Agent Identity evaluates lifecycle, access, usage, risk, and policy
7. Decision is returned
8. Audit evidence is stored
```

## Product Principle

Authentication proves who the user and agent are.

Authorization decides what the agent can do.

Identity records what the agent is, where it is in its lifecycle, what it has access to, what it consumed, what it cost, and what evidence exists.
