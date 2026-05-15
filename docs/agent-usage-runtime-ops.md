# Agent Usage, Runtime Cost, and Ops Cost

This document defines the finance and metering vocabulary for Agent Identity.

## Product Terms

```txt
Agent Usage = metering layer
Agent Spend = company-side total cost view
Agent Runtime Cost = direct execution and infrastructure cost
Agent Ops Cost = operational, governance, audit, and policy cost
Agent Pay = settlement layer for external providers
```

## Agent Usage

Agent Usage is the raw metering layer. It records what the agent consumed before cost is calculated.

For LLMs, this is primarily token usage.

Examples:

- Input tokens
- Output tokens
- Reasoning tokens
- Embedding tokens
- Model calls
- Tool calls
- Runtime seconds
- Storage GB-hours
- Vector DB reads/writes
- API calls
- Human approval events

Agent Usage is not the same as spend. Usage is the quantity. Spend is the financial value calculated from that quantity.

## Agent Runtime Cost

Agent Runtime Cost is the direct cost of running the agent.

Includes:

- LLM/model usage cost
- Cloud compute cost
- Container/serverless runtime cost
- GPU/CPU/memory cost
- Network egress cost
- Storage cost
- Vector database cost
- Runtime orchestration cost
- Tool/API usage cost directly needed to execute the task

Formula:

```txt
agent_runtime_cost = llm_cost + compute_cost + storage_cost + network_cost + tool_execution_cost
```

## Agent Ops Cost

Agent Ops Cost is the operational and governance cost required to safely run the agent.

Includes:

- IAM checks
- IGA access review checks
- PAM brokering
- Policy decision point calls
- Guardrail checks
- Audit logging
- SIEM/SOAR events
- Human approval workflow cost
- Incident review cost
- Compliance verification cost
- Evaluation framework cost

Formula:

```txt
agent_ops_cost = policy_cost + audit_cost + security_cost + approval_cost + evaluation_cost
```

## Agent Spend

Agent Spend is the company-facing total cost attributed to an agent.

Formula:

```txt
agent_spend = agent_runtime_cost + agent_ops_cost
```

If internal chargeback is enabled:

```txt
chargeback_amount = agent_spend
```

If only visibility is needed:

```txt
showback_amount = agent_spend
```

## Agent Pay

Agent Pay is the settlement layer.

It calculates what must be paid to an external SaaS platform, runtime provider, model provider, infrastructure provider, or policy/audit provider.

Formula:

```txt
agent_pay = external_runtime_cost + external_ops_cost + provider_margin_or_fee
```

If the agent is fully self-hosted and the organization does not settle with an external provider:

```txt
agent_pay = 0
agent_spend = internal_runtime_cost + internal_ops_cost
```

## Daily Flow

```txt
1. Agent Usage is collected
2. Usage is split into runtime and ops categories
3. Agent Runtime Cost is calculated
4. Agent Ops Cost is calculated
5. Agent Spend is assigned to cost center/project/team
6. Agent Pay is calculated for external settlement when applicable
7. Audit evidence is stored
```

## Cost Category Mapping

| Usage Event | Cost Category | Product Layer |
|---|---|---|
| LLM tokens | Runtime | Agent Runtime Cost |
| Embeddings | Runtime | Agent Runtime Cost |
| Cloud compute | Runtime | Agent Runtime Cost |
| Storage | Runtime | Agent Runtime Cost |
| Tool API call | Runtime | Agent Runtime Cost |
| IAM decision | Ops | Agent Ops Cost |
| Policy decision | Ops | Agent Ops Cost |
| PAM session | Ops | Agent Ops Cost |
| Audit event | Ops | Agent Ops Cost |
| Human approval | Ops | Agent Ops Cost |
| Evaluation run | Ops | Agent Ops Cost |

## Recommended Product Navigation

```txt
Identity
Lifecycle
Access
Usage
Spend
Pay
Audit
```

## LiteLLM Mapping

LiteLLM-style token and spend tracking maps into Agent Identity as:

```txt
LiteLLM token usage -> Agent Usage
LiteLLM spend/cost -> Agent Runtime Cost
Agent Identity governance overhead -> Agent Ops Cost
Agent Runtime Cost + Agent Ops Cost -> Agent Spend
External payable amount -> Agent Pay
```
