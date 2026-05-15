# Paid Customer Agent Creation Policy

Customer-facing service agents should be created only after a customer signs up and pays, or starts an approved paid trial.

## Principle

```txt
No customer-specific agents before commercial activation.
```

Agent Identity can show product demos and templates before payment, but customer-specific operational agents should be created only after the customer account is commercially activated.

## Trigger

A customer-specific agent is created when:

- Customer signs up
- Payment is confirmed, or approved paid trial is started
- Customer account is created
- Workspace/tenant is provisioned
- Customer owner/sponsor is assigned

## Agents Created After Activation

After payment or approved paid trial, Agent Identity creates:

- Customer Onboarding Agent
- Integration Agent
- Customer Account Manager Agent

## Creation Flow

```txt
1. Customer signs up
2. Payment or paid trial is confirmed
3. Customer tenant is created
4. Customer profile is created
5. Customer Onboarding Agent is created
6. Integration Agent is assigned or created for the customer
7. Customer Account Manager Agent is created
8. Initial lifecycle state is set to onboarding
9. Audit event is recorded
```

## Lifecycle Defaults

| Agent | Initial State | Notes |
|---|---|---|
| Customer Onboarding Agent | onboarding | Guides setup and first value |
| Integration Agent | onboarding | Discovers and builds connectors |
| Customer Account Manager Agent | onboarding | Starts after customer activation |

After first successful workflow validation, these agents can move to probation and then active.

## Customer-Specific Agent Boundary

Customer-specific agents should be tenant-scoped.

They must include:

- customer_id
- workspace_id
- owner
- sponsor
- lifecycle_status
- allowed_scope
- audit_profile
- cost_center or billing reference

## Guardrails

Customer-specific agents must not be created for anonymous visitors.

They must not receive production access until:

- Customer payment or paid trial is confirmed
- Workspace is provisioned
- Owner/sponsor is assigned
- Initial policy is attached
- Audit logging is enabled

## Commercial Logic

Free marketing/demo users can see:

- Sample dashboards
- Example blueprints
- Documentation
- Sandbox demo agents

Paid or approved trial customers get:

- Real tenant
- Real customer-specific agents
- Real integrations
- Real reports
- Real usage/audit tracking

## Product Rule

```txt
Demo agents are generic.
Customer agents are created only after commercial activation.
```
