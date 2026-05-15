# Customer Onboarding Agent

The Customer Onboarding Agent is a customer-facing service agent that automates onboarding into the Agent Identity platform.

It works with the Integration Agent, but owns the full customer journey from free trial or signup to a working deployment.

## Purpose

The Customer Onboarding Agent helps a customer move from signup to a functioning Agent Identity setup.

It collects the customer stack, creates the initial tenant setup, registers first agents, triggers integration discovery, validates workflows, and prepares initial reports and dashboards.

## Responsibilities

- Collect customer onboarding information
- Identify IdP, SSO, IGA, PAM, HRMS, runtime, finance, SaaS, observability, and evaluation tools
- Create initial organization, workspace, and project records
- Create owner and sponsor mappings
- Register first agents in the Agent Directory
- Assign initial lifecycle states
- Trigger the Integration Agent for connector setup
- Validate API, SDK, and MCP connectivity
- Confirm usage and audit event ingestion
- Prepare first reports and dashboards
- Generate onboarding completion summary

## Inputs

The Customer Onboarding Agent uses:

- Customer signup details
- Organization metadata
- Admin contact
- Security contact
- Billing contact
- Customer onboarding questionnaire
- Tool stack inventory
- First agent use cases
- Compliance and audit requirements
- Runtime and model provider details

## Outputs

The Customer Onboarding Agent should produce:

```txt
customer-profile.json
workspace-config.json
agent-inventory.json
integration-plan.md
onboarding-checklist.md
first-report-summary.md
open-action-items.md
```

## Workflow

```txt
1. Customer starts free trial or paid onboarding
2. Customer Onboarding Agent collects company and admin context
3. Agent discovers the customer's tool stack
4. Agent creates workspace and initial project structure
5. Agent registers initial agents
6. Agent assigns lifecycle states and owner/sponsor mappings
7. Agent triggers Integration Agent for connector setup
8. Agent validates identity, usage, audit, and reporting flows
9. Agent generates onboarding summary and open tasks
10. Customer is marked as onboarded
```

## Relationship with Integration Agent

The Customer Onboarding Agent owns the onboarding journey.

The Integration Agent owns connector generation and validation.

```txt
Customer Onboarding Agent -> discovers needs and manages journey
Integration Agent         -> builds/configures integrations
```

## Guardrails

The Customer Onboarding Agent must not:

- Store customer secrets in plain text
- Automatically approve privileged access without customer approval
- Create production integrations without explicit confirmation
- Skip audit logging
- Publish customer-specific data into reusable templates

## Success Metrics

- Time to first agent registered
- Time to first integration connected
- Time to first usage event
- Time to first audit event
- Time to first report
- Trial activation rate
- Onboarding completion rate
- Number of reusable integrations created per onboarding

## Lifecycle

The Customer Onboarding Agent itself should be registered in Agent Identity.

Recommended lifecycle:

```txt
onboarding -> probation -> active
```

It should remain in probation until it completes onboarding workflows reliably without missing critical steps.

## Strategic Role

The Customer Onboarding Agent turns onboarding into a guided, automated, integration-driven experience.

```txt
Customer signs up
-> Customer Onboarding Agent guides setup
-> Integration Agent builds connectors
-> Reports prove value
-> Customer activates
```
