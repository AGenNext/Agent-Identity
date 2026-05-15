# Agent Salary

Agent Salary is the finance layer of Agent Identity.

It treats an AI agent as a digital worker with an approved compensation model, runtime cost, tool cost, performance incentives, and daily settlement to the SaaS/runtime provider that operates the agent.

## Concept

Human workers receive salary through HRMS and payroll systems.

AI agents should receive an equivalent financial model through Agent Identity:

- Approved budget
- Daily salary or runtime allowance
- Tool and SaaS reimbursement
- Performance-based incentives
- Penalties or suspension for unsafe behavior
- Cost center assignment
- Payment settlement to the runtime provider

The agent does not personally receive money. Instead, Agent Identity tracks the agent salary and pays the runtime/SaaS platform, infrastructure provider, or owning vendor according to verified usage and policy.

## Core Model

```txt
Agent Identity
  -> validates lifecycle state
  -> checks IAM/IGA/PAM policies
  -> checks budget and salary rules
  -> records daily work and runtime usage
  -> calculates payable amount
  -> sends payment to runtime provider
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

The agent salary is based on runtime, tool usage, model calls, or task volume.

Example:

```txt
agent_salary_type = usage_based
amount = runtime_cost + approved_margin
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
2. Runtime provider records usage
3. Agent Identity verifies agent lifecycle state
4. IAM/IGA/PAM policies are checked
5. Finance rules calculate daily salary
6. Payment is approved or escalated
7. Runtime provider receives settlement
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
- status

### settlement

Fields:

- agent
- runtime_provider
- period_start
- period_end
- usage_total
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

## Product Positioning

Agent Salary turns Agent Identity into the payroll and finance control plane for AI agents.

Positioning:

> HRMS + IAM + IGA + PAM + Payroll for AI Agents

This allows enterprises to govern not only what agents can access, but also what agents cost, who pays for them, and whether they are worth keeping active.
