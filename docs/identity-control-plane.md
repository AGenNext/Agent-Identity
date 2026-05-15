# Agent Identity Control Plane

Agent Identity should be the identity control plane for AI agents and digital workers.

Authentication, authorization, IGA, and PAM remain part of the access control plane. Agent Identity integrates with them, but does not need to own them directly.

## Product Decision

```txt
Agent Identity = Identity Control Plane
IGA + PAM + Auth + Authorization = Access Control Plane
```

Agent Identity owns the system of record for agents.

Access control systems decide and enforce what those agents can access.

## Identity Control Plane Responsibilities

Agent Identity owns:

- Agent registry
- Agent universal directory
- Agent profile
- Agent owner and sponsor
- Agent lifecycle state
- Agent provenance
- Agent identity card
- Agent metadata
- Agent usage signals
- Agent pay metadata
- Agent audit evidence
- Agent evaluation signals
- Agent FinOps and Optimize recommendations

## Access Control Plane Responsibilities

IGA, PAM, IAM, authentication, and authorization systems own:

- Authentication
- Session management
- Token issuance
- Access requests
- Approvals
- Access reviews
- Certifications
- Privileged access
- Secrets and vaulting
- Policy enforcement
- Authorization decisions
- Deprovisioning enforcement

## Relationship Between the Planes

```txt
Identity Control Plane tells access systems who the agent is and what lifecycle state it is in.

Access Control Plane decides and enforces what the agent can access.
```

Example:

```txt
Agent Identity: agent:sales_assistant is suspended
IGA/PAM/Auth: revoke active sessions, block new access, remove tool privileges
Agent Audit: record evidence
```

## Platform Boundary

Agent Identity should expose identity and lifecycle APIs that IAM/IGA/PAM systems can consume.

Examples:

- `GET /agents/{id}`
- `GET /agents/{id}/lifecycle`
- `GET /agents/{id}/identity-card`
- `GET /agents/{id}/usage-summary`
- `POST /agents/{id}/lifecycle-transition`
- `POST /events/access-control`

## Product Navigation

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

Access-specific navigation can live in partner systems or a separate access-control module:

```txt
Authentication
Authorization
IGA
PAM
Access Reviews
Approvals
Secrets
```

## Integration Model

Agent Identity integrates with:

- IAM systems for identity and session context
- IGA systems for access lifecycle and certifications
- PAM systems for privileged tools and secrets
- HRMS systems for owner/user context
- Finance systems for pay and chargeback context
- Runtime platforms for usage signals
- Evaluation systems for reliability signals

## Core Principle

Agent Identity is the source of truth for the agent as a digital worker.

Access control systems are the source of truth for access decisions and enforcement.

Together they form the enterprise operating system for AI agents.
