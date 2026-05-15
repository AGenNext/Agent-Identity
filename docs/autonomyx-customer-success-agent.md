# Autonomyx Customer Success Agent

Autonomyx Customer Success Agent is the current product framing for the best-in-class customer-facing platform agent.

It is built on the Autonomyx agent framework and uses Agent Identity as its identity control plane.

## Product Framing

```txt
Autonomyx = agent framework/platform
Agent Identity = identity control plane
Autonomyx Customer Success Agent = best-in-class customer success agent built on Autonomyx
```

## Purpose

Autonomyx Customer Success Agent helps onboard, activate, support, retain, and expand customers.

It can manage multiple customer accounts, coordinate sub-agent teams, track customer value, surface risks, and drive integrations.

## When It Is Created

A customer-specific Autonomyx Customer Success Agent is created only after:

- Customer signs up
- Payment is confirmed, or approved paid trial begins
- Tenant/workspace is provisioned
- Owner/sponsor is assigned

## Core Responsibilities

### Onboarding

- Collect customer context
- Create workspace/project setup
- Register first agents
- Trigger integration discovery
- Validate usage and audit ingestion
- Prepare first reports

### Integration Orchestration

- Discover customer tool stack
- Assign Integration Agent
- Track connector setup
- Validate customer workflows
- Convert customer-specific integrations into reusable catalog patterns

### Account Management

- Monitor account health
- Track adoption
- Generate weekly summaries
- Identify blockers
- Escalate customer risks
- Prepare renewal and value evidence

### Sub-Agent Team Orchestration

The Customer Success Agent can coordinate specialized sub-agents:

```txt
Autonomyx Customer Success Agent
  ├── Customer Onboarding Agent
  ├── Integration Agent
  ├── Customer Account Manager Agent
  ├── Agent FinOps Agent
  ├── Agent Optimize Agent
  ├── Audit Reporting Agent
  ├── Evaluation Agent
  └── Support Triage Agent
```

## Multi-Account Support

The agent can manage:

- Multiple customer accounts
- Multiple workspaces
- Multiple projects
- Multiple teams
- Multiple sub-agent teams
- Cross-account reports
- Cross-account risk signals

## Outputs

The agent produces:

```txt
customer-success-plan.md
onboarding-summary.md
integration-roadmap.md
account-health-summary.md
weekly-customer-update.md
risk-escalation-report.md
expansion-opportunities.md
renewal-readiness-report.md
executive-value-report.md
```

## Success Metrics

- Time to first value
- Time to first integration
- Time to first usage event
- Time to first audit report
- Trial activation rate
- Integration completion rate
- Account health score
- Churn risk reduction
- Expansion opportunity creation
- Renewal readiness

## Guardrails

The agent must not:

- Create customer-specific agents before payment or approved paid trial
- Access customer secrets directly
- Approve privileged access without policy approval
- Publish customer-specific data into reusable templates
- Promise commercial terms without human approval
- Terminate agents without configured approval policy
- Bypass audit logging

## Lifecycle

Recommended lifecycle:

```txt
onboarding -> probation -> active
active -> suspended -> active
active -> terminated -> alumni -> archived
```

The agent should remain in probation until it reliably completes onboarding, integration coordination, reporting, and escalation workflows.

## Strategic Role

Autonomyx Customer Success Agent is the flagship proof of the Autonomyx platform.

It demonstrates how best-in-class agents can be created, governed, evaluated, optimized, and scaled using Agent Identity.
