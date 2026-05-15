# Agent Identity Platform Architecture

Agent Identity should be built like Okta for AI agents: a modular identity and governance platform, not a single monolithic tool.

## Platform Positioning

```txt
Okta = identity platform for humans and apps
Agent Identity = identity platform for AI agents and digital workers
```

The platform provides a shared control plane for agent identity, lifecycle, access, usage, pay, audit, evaluation, FinOps, and optimization.

## Platform Services

### Agent Universal Directory

Equivalent to Okta Universal Directory, but for AI agents.

Owns:

- Agent profiles
- Owners and sponsors
- Organizations and projects
- Models and providers
- Lifecycle status
- Cost centers
- Identity cards
- Trust metadata

### Agent Lifecycle Management

Equivalent to lifecycle management for employees, contractors, and non-human identities.

Owns:

- Onboarding
- Active state
- Probation
- Leave
- Suspension
- Termination
- Alumni
- Archive
- Lifecycle automation

### Agent Access Management

Equivalent to access management, but for agents.

Owns:

- IAM integration
- IGA integration
- PAM integration
- Policies
- Delegations
- Tool access
- Credential metadata

### Agent Authentication

Can be a platform module or separate service.

Owns:

- OIDC/OAuth authentication
- Agent authentication
- Token issuance
- Delegation flows
- Token exchange
- Session and token revocation

### Agent Authorization

AuthZEN-style policy decision service.

Owns:

- Policy decision API
- Policy enforcement integration
- Context-aware authorization
- Allow/deny decisions
- Decision audit evidence

### Agent Usage

Metering layer.

Owns:

- Token usage
- Model calls
- Tool calls
- Runtime seconds
- Storage usage
- API calls
- Approval events

### Agent Pay

Settlement layer.

Owns:

- External runtime provider settlement
- SaaS provider settlement
- Model provider settlement
- Payment approval evidence
- Daily pay runs

### Agent FinOps

Cost optimization service.

Owns:

- Token waste detection
- Runtime optimization
- Model cost optimization
- Storage optimization
- Budget anomaly detection
- Cost-aware lifecycle recommendations

### Agent Optimize

Performance optimization service.

Owns:

- Reliability scoring
- Hallucination tracking
- Tool-use accuracy
- Latency analysis
- Prompt and retrieval optimization
- Model/runtime tuning recommendations

### Agent Audit

Evidence and compliance layer.

Owns:

- Identity events
- Lifecycle events
- Access decisions
- Usage evidence
- Payment evidence
- Optimization evidence
- Compliance export

### Agent Evaluation

Agent reliability and value assessment service.

Owns:

- Probation evaluation
- Task success rate
- Policy violation rate
- Human feedback
- ROI signals
- Promotion/suspension recommendations

## Platform Navigation

```txt
Directory
Lifecycle
Access
Authentication
Authorization
Usage
Pay
FinOps
Optimize
Audit
Evaluation
```

## Okta Analogy

| Okta Capability | Agent Identity Platform Equivalent |
|---|---|
| Universal Directory | Agent Universal Directory |
| Single Sign-On | Agent Authentication |
| Lifecycle Management | Agent Lifecycle Management |
| API Access Management | Agent Access and Authorization |
| Workflows | Agent Lifecycle Automation |
| Governance | Agent Access Governance |
| Logs | Agent Audit |
| Integrations | IAM, IGA, PAM, HRMS, Finance, Runtime connectors |

## Core Platform Flow

```txt
1. Agent is registered in Agent Universal Directory
2. Lifecycle service moves it through onboarding, probation, active, leave, suspended, or terminated
3. Authentication service issues delegated credentials
4. Access and Authorization services decide what the agent can do
5. Usage service meters activity
6. Pay service settles external providers when needed
7. FinOps optimizes cost signals across all services
8. Optimize improves performance and reliability
9. Audit stores evidence for every action
10. Evaluation recommends lifecycle changes
```

## Product Principle

Agent Identity should become the enterprise control plane for AI agents.

It should answer:

- Who is this agent?
- Who owns it?
- What state is it in?
- What can it access?
- Who delegated authority to it?
- What did it consume?
- What must be paid externally?
- Is it reliable?
- Is it cost-efficient?
- Should it stay active?
- What evidence exists?

## Category Narrative

```txt
Agent Identity is Okta for AI agents.
```

But broader than authentication alone:

```txt
Identity + Lifecycle + Access + Governance + Usage + Pay + Optimization for AI agents.
```
