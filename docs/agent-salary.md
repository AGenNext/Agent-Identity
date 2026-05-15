# Agent Salary

Agent Salary is the finance layer of Agent Identity.

It treats an AI agent as a digital worker with an approved compensation model, runtime cost, tool cost, performance incentives, and daily settlement to the SaaS/runtime provider that operates the agent.

## Concept

Human workers receive salary through HRMS and payroll systems.

AI agents should receive an equivalent financial model through Agent Identity:

- Approved budget
- Daily salary or runtime allowance
- LLM/model cost tracking
- Cloud runtime cost tracking
- Storage cost tracking
- Tool and SaaS reimbursement
- External audit, policy, and enforcement costs
- Performance-based incentives
- Penalties or suspension for unsafe behavior
- Cost center assignment
- Payment settlement to the runtime provider

The agent does not personally receive money. Instead, Agent Identity tracks the agent salary and pays the runtime/SaaS platform, infrastructure provider, model provider, policy provider, audit provider, or owning vendor according to verified usage and policy.

If the agent is fully self-hosted by the organization and the organization chooses not to charge back internal infrastructure, the external payable cost can be zero. Agent Identity should still track the internal cost and audit evidence for governance.

## Cost Components

Agent Salary should calculate total daily cost from the following components:

### LLM Cost

Cost from model inference and embedding usage.

Examples:

- Input tokens
- Output tokens
- Embedding tokens
- Fine-tuned model calls
- Reasoning/model premium fees

### Cloud Runtime Cost

Cost of running the agent runtime.

Examples:

- Containers
- Serverless execution
- GPUs
- CPUs
- Memory
- Network egress
- Background workers

### Storage Cost

Cost of storing agent state and artifacts.

Examples:

- Agent memory
- Vector database storage
- Logs
- Files
- Conversation history
- Audit evidence
- Backups

### Tool and SaaS Cost

Cost from tools the agent invokes.

Examples:

- CRM API calls
- Search APIs
- Email APIs
- Browser automation
- Data providers
- Internal SaaS metering

### External Audit and Policy Cost

Cost from third-party enforcement or governance layers.

Examples:

- External policy decision point calls
- IGA access review checks
- PAM session brokering
- SIEM/SOAR event processing
- Compliance logging
- Human approval workflows
- External audit verification

### Self-Hosted Cost Rule

If the agent is self-hosted by the organization:

```txt
external_payable_amount = 0
internal_cost = llm_cost + runtime_cost + storage_cost + tool_cost + audit_policy_cost
```

If the agent is operated by a SaaS/runtime provider:

```txt
external_payable_amount = approved_llm_cost + approved_runtime_cost + approved_storage_cost + approved_tool_cost + approved_audit_policy_cost + margin_or_salary_fee
```

## Core Model

```txt
Agent Identity
  -> validates lifecycle state
  -> checks IAM/IGA/PAM policies
  -> checks budget and salary rules
  -> records daily work and runtime usage
  -> calculates payable amount
  -> sends payment to runtime provider when applicable
  -> stores audit evidence
```

## Salary Types

### Fixed Daily Salary

The agent receives a fixed daily allocation while active.

Example:

```txt
agent_salary_type = fixed_daily
amount = 10 USD / day
```

### Usage-Based Salary

The agent salary is based on LLM, runtime, storage, tool, audit, and policy-enforcement usage.

Example:

```txt
agent_salary_type = usage_based
amount = llm_cost + runtime_cost + storage_cost + tool_cost + audit_policy_cost + approved_margin
```

### Performance-Based Salary

The agent receives higher allocation if it performs well.

Metrics may include:

- Task success rate
- Human approval rate
- Low hallucination rate
- Policy compliance
- Revenue contribution
- Time saved

### Hybrid Salary

A base daily salary plus variable usage and performance incentives.

Example:

```txt
agent_salary = base_daily + approved_usage + performance_bonus
```

## HRMS State to Salary Rules

| Agent State | Salary Behavior |
|---|---|
| onboarding | Setup budget only; no production salary |
| active | Full salary and approved runtime settlement |
| probation | Reduced salary and stricter spend caps |
| leave | Salary paused unless explicitly authorized |
| suspended | Salary and runtime payments frozen |
| terminated | Salary stopped; final settlement only |
| alumni | Historical salary records retained |
| archived | Salary disabled |

## Daily Settlement Flow

```txt
1. Agent performs approved work
2. Runtime provider records LLM, runtime, storage, tool, and policy/audit usage
3. Agent Identity verifies agent lifecycle state
4. IAM/IGA/PAM policies are checked
5. Finance rules calculate daily cost and payable salary
6. Payment is approved, denied, or escalated
7. Runtime/SaaS provider receives settlement when applicable
8. Audit ledger stores evidence
```

## Core Data Objects

### agent_salary

Fields:

- agent
- salary_type
- base_daily_amount
- currency
- cost_center
- project
- owner
- daily_limit
- monthly_limit
- status
- effective_from
- effective_to

### cost_component

Fields:

- agent
- component_type
- provider
- amount
- currency
- usage_quantity
- usage_unit
- billing_reference
- evidence_reference
- occurred_at

Supported component types:

```txt
llm
cloud_runtime
storage
tool_saas
audit_policy
human_approval
internal_allocated
```

### salary_event

Fields:

- agent
- event_type
- amount
- currency
- reason
- policy
- occurred_at

### runtime_provider

Fields:

- name
- provider_type
- billing_account
- settlement_frequency
- payment_method_reference
- self_hosted
- status

### settlement

Fields:

- agent
- runtime_provider
- period_start
- period_end
- llm_cost_total
- runtime_cost_total
- storage_cost_total
- tool_cost_total
- audit_policy_cost_total
- internal_cost_total
- external_payable_amount
- salary_total
- bonus_total
- penalty_total
- payable_amount
- currency
- status
- approved_by
- paid_at

## Governance Rules

- No salary without active identity
- No payment without audit trail
- No runtime settlement if the agent is suspended or terminated
- Probation agents receive limited budgets
- High-cost tool use requires approval
- Every salary event must be tied to policy and usage evidence
- Self-hosted agents can have zero external payable amount
- Internal costs should still be tracked for showback, chargeback, and ROI analysis

## Product Positioning

Agent Salary turns Agent Identity into the payroll and finance control plane for AI agents.

Positioning:

> HRMS + IAM + IGA + PAM + Finance + Payroll for AI Agents

This allows enterprises to govern not only what agents can access, but also what agents cost, who pays for them, and whether they are worth keeping active.
