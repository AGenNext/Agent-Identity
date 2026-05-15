# Agent Identity Services

Agent Identity is a platform made of several services. Each service owns a specific part of the agent governance lifecycle.

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

### Agent Spend Service

Company-side cost visibility and budget governance.

Owns:

- Runtime cost
- Ops cost
- Budget limits
- Cost center allocation
- Showback
- Chargeback
- Spend analytics

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

Agent FinOps uses Agent Usage, Agent Runtime Cost, Agent Ops Cost, Agent Spend, and Agent Pay data to reduce waste and improve financial governance.

Owns:

- Cost optimization recommendations
- Token waste detection
- Model cost optimization
- Runtime cost optimization
- Storage cost optimization
- Tool/API cost optimization
- Budget anomaly detection
- Cost-based lifecycle recommendations

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

Records all identity, access, usage, spend, pay, optimization, and lifecycle events.

Owns:

- Audit events
- Evidence links
- Authorization decisions
- Lifecycle transition logs
- Payment evidence
- Optimization decision evidence

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

## Service Map

```txt
Agent Registry     -> Who is the agent?
Agent Lifecycle    -> What state is it in?
Agent Access       -> What can it access?
Agent Usage        -> What did it consume?
Agent Spend        -> What did it cost the company?
Agent Pay          -> What must be settled externally?
Agent FinOps       -> How can cost be optimized?
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
Spend
Pay
FinOps
Optimize
Audit
Evaluation
```
