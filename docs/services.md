# Agent Identity Services

Agent Identity is a platform made of several services. Each service owns a specific part of the agent governance lifecycle.

Cost is not a standalone product category. Cost appears across every service as a financial attribute attached to identity, lifecycle, access, usage, audit, evaluation, optimization, and payment events.

## Core Services

### Agent Registry Service

System of record for agent identities.

Owns:

- Agent profiles
- Owners
- Providers
- Models
- Versions
- Lifecycle status
- Identity cards
- Registry-level cost attribution metadata

### Agent Lifecycle Service

Controls HRMS-style agent lifecycle states.

Owns:

- Onboarding
- Active
- Probation
- Leave
- Suspended
- Terminated
- Alumni
- Archived
- Lifecycle-triggered cost controls

### Agent Access Service

Controls what the agent can access and do.

Owns:

- IAM integration
- IGA integration
- PAM integration
- Policies
- Delegations
- Credentials
- Tool access
- Access-related cost and approval overhead

### Agent Usage Service

Metering service for raw usage.

Owns:

- Token usage
- Model calls
- Tool calls
- Runtime seconds
- Storage usage
- Approval events
- API calls
- Usage-level cost attribution

### Agent Pay Service

Settlement service for external providers.

Owns:

- Runtime provider settlement
- SaaS provider settlement
- Model provider settlement
- Payment approval
- Payment evidence
- Daily pay runs

## Optimization Services

### Agent FinOps Service

Cost optimization service for AI agents.

Agent FinOps is not the only place where cost exists. Instead, it analyzes cost signals from every service and recommends ways to reduce waste and improve financial governance.

Uses signals from:

- Registry ownership and cost center metadata
- Lifecycle state
- Access policies and approvals
- Usage events
- Runtime activity
- Audit and policy enforcement events
- Evaluation outcomes
- Pay/settlement records

Owns:

- Cost optimization recommendations
- Token waste detection
- Model cost optimization
- Runtime cost optimization
- Storage cost optimization
- Tool/API cost optimization
- Budget anomaly detection
- Cost-aware lifecycle recommendations

Example actions:

- Switch to a cheaper model for low-risk tasks
- Reduce context window size
- Cache repeated responses
- Deduplicate tool calls
- Pause inactive agents
- Recommend probation or termination for high-cost, low-value agents

### Agent Optimize Service

Performance optimization service for AI agents.

Agent Optimize improves reliability, quality, latency, task success, and tool-use accuracy.

Owns:

- Performance optimization recommendations
- Reliability scoring
- Hallucination tracking
- Tool-use accuracy tracking
- Latency analysis
- Prompt improvement recommendations
- Context strategy recommendations
- Model and runtime tuning recommendations
- Evaluation-based lifecycle recommendations

Example actions:

- Improve prompts
- Adjust retrieval settings
- Add guardrails
- Change model selection
- Add human-in-the-loop for risky actions
- Recommend promotion from probation to active
- Recommend suspension when reliability drops

## Supporting Services

### Agent Audit Service

Records all identity, access, usage, pay, optimization, and lifecycle events.

Owns:

- Audit events
- Evidence links
- Authorization decisions
- Lifecycle transition logs
- Payment evidence
- Optimization decision evidence
- Cost evidence attached to events

### Agent Evaluation Service

Evaluates agent reliability and business value.

Owns:

- Task success rate
- Hallucination rate
- Policy violation rate
- Human approval rate
- Tool accuracy
- ROI signals
- Probation pass/fail decisions
- Cost-to-value signals

## Cross-Cutting Cost Model

Cost flows through all services rather than living in a single category.

```txt
Registry   -> owner, cost center, project attribution
Lifecycle  -> state-based cost controls
Access     -> cost of permissions, approvals, and privileged access
Usage      -> raw metering and usage-derived cost
Pay        -> external settlement
Audit      -> compliance and evidence cost
Evaluation -> cost-to-quality and cost-to-value metrics
FinOps     -> optimization recommendations using all cost signals
Optimize   -> performance recommendations using cost and quality signals
```

## Service Map

```txt
Agent Registry     -> Who is the agent?
Agent Lifecycle    -> What state is it in?
Agent Access       -> What can it access?
Agent Usage        -> What did it consume?
Agent Pay          -> What must be settled externally?
Agent FinOps       -> How can cost be optimized across services?
Agent Optimize     -> How can performance be optimized?
Agent Audit        -> What evidence exists?
Agent Evaluation   -> Is the agent reliable and valuable?
```

## Product Navigation

```txt
Registry
Lifecycle
Access
Usage
Pay
FinOps
Optimize
Audit
Evaluation
```
