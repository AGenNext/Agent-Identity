# Customer Account Manager Agent Blueprint

The Customer Account Manager Agent is a customer-facing account management agent for Agent Identity.

It supports customers after onboarding by monitoring adoption, integrations, usage, lifecycle health, open issues, renewals, expansion opportunities, and customer value realization.

## Purpose

The Customer Account Manager Agent acts like a digital customer success manager for each customer account.

It helps ensure that every customer:

- Completes onboarding
- Connects critical integrations
- Registers and governs agents
- Sees value through reports and dashboards
- Receives proactive recommendations
- Expands usage over time
- Has risks escalated before churn

## Lifecycle

The Customer Account Manager Agent itself should be registered in Agent Identity.

Recommended lifecycle:

```txt
onboarding -> probation -> active
```

It should remain in probation until it reliably identifies customer risks, integration blockers, and expansion opportunities.

## Responsibilities

### Account Health

- Track account onboarding status
- Track integration completeness
- Track active agents
- Track lifecycle distribution
- Track usage adoption
- Track audit and report usage
- Detect stalled accounts
- Detect churn risk

### Customer Success

- Prepare weekly account summaries
- Recommend next best actions
- Identify missing integrations
- Identify underused modules
- Recommend reports and dashboards
- Escalate blockers to human customer success team

### Expansion

- Identify additional teams or projects using agents
- Recommend new integrations
- Recommend Agent FinOps opportunities
- Recommend Agent Optimize opportunities
- Identify upgrade or paid conversion signals

### Governance

- Monitor suspended, probation, and terminated agent trends
- Flag risky lifecycle patterns
- Monitor audit gaps
- Track policy and access governance adoption
- Recommend reviews for high-risk agents

## Inputs

The Customer Account Manager Agent uses:

- Customer profile
- Workspace and project metadata
- Agent inventory
- Lifecycle states
- Integration status
- Usage events
- Pay and settlement metadata
- Audit events
- Evaluation scores
- FinOps recommendations
- Optimize recommendations
- Support tickets
- Customer notes

## Outputs

The Customer Account Manager Agent produces:

```txt
account-health-summary.md
weekly-customer-update.md
integration-gap-report.md
adoption-score.json
churn-risk-report.md
expansion-opportunities.md
renewal-readiness-report.md
open-action-items.md
```

## Account Health Score

Suggested score components:

```txt
account_health_score =
  onboarding_completion_score
  + integration_completion_score
  + active_agent_score
  + usage_adoption_score
  + audit_completeness_score
  + evaluation_health_score
  - risk_penalty
```

## Risk Signals

The agent should flag:

- No usage after signup
- No IdP or runtime integration connected
- No agents registered
- Many suspended agents
- High usage but low value
- Missing audit events
- Failed onboarding tasks
- Open integration blockers
- No dashboard/report views
- Upcoming renewal without clear value proof

## Expansion Signals

The agent should detect:

- Multiple teams asking for agents
- Repeated manual integration requests
- Growing usage
- High report engagement
- Strong evaluation scores
- FinOps savings opportunities
- Optimize performance wins
- Need for additional runtime, SaaS, or finance connectors

## Workflow

```txt
1. Customer completes onboarding
2. Customer Account Manager Agent is assigned to the account
3. Agent reads customer profile, integrations, agent inventory, usage, and audit data
4. Agent computes account health
5. Agent generates weekly summary and next actions
6. Agent escalates risks to human customer success
7. Agent recommends integrations, optimization, and expansion opportunities
8. Agent prepares renewal and value evidence
```

## Relationship With Other Agents

```txt
Customer Onboarding Agent -> gets customer live
Integration Agent         -> builds/connects customer tools
Customer Account Manager  -> keeps customer healthy and expanding
```

## Guardrails

The Customer Account Manager Agent must not:

- Promise contractual terms
- Approve discounts without human approval
- Access customer secrets
- Send external customer communication without configured approval policy
- Publish customer data to reusable templates
- Modify production access without explicit policy approval

## Success Metrics

- Trial activation rate
- Time to first value
- Integration completion rate
- Account health score improvement
- Churn risk reduction
- Expansion opportunity creation
- Renewal readiness
- Customer-reported value

## Strategic Role

The Customer Account Manager Agent turns customer success into a scalable, agent-assisted function.

```txt
Onboarding Agent gets the customer started
Integration Agent connects their stack
Customer Account Manager Agent proves value and grows the account
```
