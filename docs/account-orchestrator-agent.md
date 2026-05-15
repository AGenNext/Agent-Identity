# Customer Account Orchestrator Agent

The Customer Account Orchestrator Agent is the top-level customer-facing orchestration agent for Agent Identity.

It is created only after a customer signs up and payment or an approved paid trial is confirmed.

## Purpose

The Customer Account Orchestrator Agent manages the full customer account across multiple customer workspaces, projects, teams, and sub-agent groups.

It is not just an account manager. It is the orchestrator for the customer's Agent Identity operating model.

## Core Idea

```txt
One paid customer account
-> one Customer Account Orchestrator Agent
-> multiple workspaces/projects/accounts
-> sub-agent teams for onboarding, integrations, reporting, FinOps, optimization, and support
```

## Responsibilities

### Multi-Account Management

The orchestrator can manage multiple customer accounts, business units, workspaces, or projects under one customer relationship.

Owns:

- Account hierarchy
- Workspace hierarchy
- Project hierarchy
- Team mappings
- Agent ownership mapping
- Cross-account reports
- Cross-account risk signals

### Sub-Agent Team Orchestration

The orchestrator can create, assign, supervise, and evaluate sub-agent teams.

Sub-agent teams may include:

- Customer Onboarding Agent
- Integration Agent
- Customer Account Manager Agent
- Agent FinOps Agent
- Agent Optimize Agent
- Audit Reporting Agent
- Evaluation Agent
- Support Triage Agent

### Customer Success Orchestration

Owns:

- Account health
- Onboarding progress
- Integration completeness
- Trial activation
- Expansion signals
- Renewal readiness
- Churn risk
- Customer value evidence

### Integration Orchestration

Coordinates with Integration Agents to:

- Discover the customer's stack
- Configure existing connectors
- Generate missing connectors
- Validate customer workflows
- Publish reusable connector templates

### Governance Orchestration

Coordinates with Agent Identity services and access-control systems to:

- Monitor lifecycle health
- Detect suspended or risky agents
- Escalate security issues
- Track policy gaps
- Confirm audit completeness

## Inputs

The orchestrator uses:

- Customer account profile
- Payment or paid trial status
- Workspace and project inventory
- Agent inventory
- Lifecycle states
- Integration status
- Usage events
- Pay/settlement metadata
- Audit events
- Evaluation results
- FinOps recommendations
- Optimize recommendations
- Support tickets
- Customer success notes

## Outputs

The orchestrator produces:

```txt
account-orchestration-plan.md
workspace-health-summary.md
sub-agent-team-plan.md
integration-roadmap.md
customer-value-report.md
risk-escalation-report.md
renewal-readiness-report.md
executive-summary.md
```

## Sub-Agent Team Model

```txt
Customer Account Orchestrator Agent
  ├── Customer Onboarding Agent
  ├── Integration Agent
  ├── Customer Account Manager Agent
  ├── Agent FinOps Agent
  ├── Agent Optimize Agent
  ├── Audit Reporting Agent
  ├── Evaluation Agent
  └── Support Triage Agent
```

## Lifecycle

The orchestrator itself should be registered in Agent Identity.

Recommended lifecycle:

```txt
onboarding -> probation -> active
```

The orchestrator should remain in probation until it proves that it can manage sub-agent teams, account risks, customer reports, and integration workflows reliably.

## Guardrails

The orchestrator must not:

- Create customer-specific agents before payment or approved paid trial
- Approve privileged access without explicit policy approval
- Access customer secrets directly
- Publish customer-specific data into public templates
- Promise commercial terms without human approval
- Terminate agents without configured approval policy

## Account Creation Flow

```txt
1. Customer signs up
2. Payment or paid trial is confirmed
3. Customer tenant is created
4. Customer Account Orchestrator Agent is created
5. Orchestrator creates or assigns sub-agent teams
6. Customer Onboarding Agent starts setup
7. Integration Agent starts connector discovery
8. Reports and dashboards are generated
9. Customer Account Manager Agent tracks ongoing health
```

## Success Metrics

- Time to first workspace live
- Time to first registered customer agent
- Time to first integration connected
- Time to first usage event
- Time to first audit report
- Integration completion rate
- Account health score
- Churn risk reduction
- Expansion opportunity creation
- Customer value proof generated

## Strategic Role

The Customer Account Orchestrator Agent turns Agent Identity into a managed platform experience.

```txt
Customer pays
-> Orchestrator Agent is created
-> Sub-agent team is assigned
-> Customer stack is connected
-> Reports prove value
-> Account expands
```

This gives Agent Identity a scalable operating model for onboarding, managing, and growing many customer accounts while each customer can also run internal sub-agent teams.
