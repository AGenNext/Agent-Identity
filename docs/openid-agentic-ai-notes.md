# Notes from OpenID Foundation: Identity Management for Agentic AI

Source: `Identity-Management-for-Agentic-AI (4).pdf`, uploaded by the project owner.

## Product implications for Agent Identity

The OpenID Foundation paper frames AI agents as a new class of identity and authorization subject. Agent Identity should therefore be designed as a system of record for autonomous, delegated, and auditable non-human actors.

## Key principles to implement

### 1. Agents must be identifiable

Agents should not rely only on anonymous client IDs, API keys, or shared service accounts. Each agent needs a persistent identity with metadata such as:

- agent instance identifier
- owner user or organization
- agent provider
- model and version
- runtime environment
- capabilities
- lifecycle state

### 2. Delegation must replace impersonation

Agents should not act indistinguishably from humans. Agent Identity should support explicit on-behalf-of relationships where both the human principal and the agent actor are visible in credentials and logs.

Useful claim concepts:

- `sub`: user or owning principal
- `act`: acting agent
- `azp`: authorized party / client
- scopes and permissions: delegated authority limits

### 3. Auditability is a core feature

Every authorization decision and agent action should record:

- human principal
- agent actor
- delegated authority
- target resource
- action performed
- policy decision
- timestamp
- request context

This closes the auditability gap where agent actions are otherwise logged as ordinary user actions.

### 4. Lifecycle management is mandatory

Agents require formal lifecycle controls similar to enterprise identities:

- creation
- approval
- provisioning
- credential rotation
- suspension
- revocation
- de-provisioning
- ownership transfer

SCIM-style provisioning and de-provisioning should be considered for future interoperability.

### 5. Policies need to be externalized

Authorization should be separated from application code using a policy enforcement point and policy decision point pattern.

Agent Identity should eventually expose a policy decision API that can answer:

```txt
Can agent X perform action Y on resource Z on behalf of principal P under context C?
```

### 6. Least privilege must be rigorous

Agents should receive narrowly scoped permissions. Permissions can be constrained by:

- action
- resource
- tool
- data class
- tenant
- time window
- execution count
- risk level
- budget or spend limit

### 7. Support asynchronous approval

Agents often execute long-running tasks. Some actions may require delayed human approval rather than blocking the whole workflow.

Future support can include:

- pending authorization requests
- out-of-band approvals
- approval expiration
- risk-based escalation

### 8. Prepare for recursive delegation

Agents may delegate work to sub-agents. The platform should model delegation chains and support scope attenuation so downstream agents never receive broader authority than the upstream agent.

### 9. Trust and attestation matter

Agent Identity should be able to store or reference attestations such as:

- security review completed
- model provenance
- compliance status
- organization verification
- runtime integrity
- trusted publisher metadata

### 10. Guardrails complement IAM

IAM controls who can access what. AI guardrails control how an agent uses that access.

Agent Identity should integrate guardrails such as:

- sensitive data masking
- rate limits
- action allowlists
- policy-based denial
- compliance checks
- human escalation thresholds

## MVP scope

The first version should focus on:

1. Agent registry
2. Delegation graph
3. Credential metadata
4. Capability and policy model
5. Audit ledger
6. Local SurrealDB schema
7. Simple API specification

## Later standards alignment

Future work should evaluate alignment with:

- OAuth 2.1
- OpenID Connect
- OAuth Token Exchange
- SCIM
- Shared Signals Framework
- OpenID Federation
- SPIFFE/SPIRE
- Verifiable Credentials
- Decentralized Identifiers
- MCP authorization patterns
- A2A authorization patterns

## Working product definition

Agent Identity is an IAM layer for AI agents. It gives each agent a verifiable identity, delegated authority, lifecycle controls, scoped credentials, policy-governed access, and complete auditability.
