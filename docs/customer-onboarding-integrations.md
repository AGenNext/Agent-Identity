# Customer Onboarding Integration Flow

Integrations should be a core part of customer onboarding.

When a customer starts a free trial or becomes a paid customer, Agent Identity should discover their enterprise stack and build or configure the integrations needed for their agents to become governed digital workers.

## Onboarding Goal

```txt
Customer onboarded
-> discover tools
-> configure existing connectors
-> generate missing connectors
-> validate workflows
-> add reusable integrations to catalog
```

This turns customer onboarding into the integration flywheel.

## Onboarding Steps

### 1. Stack Discovery

Collect the customer's current tools:

- IdP / SSO
- IAM / IGA
- PAM / secrets
- HRMS
- SaaS applications
- Agent runtimes
- LLM gateways
- Observability tools
- Finance / ERP systems
- Evaluation tools

### 2. Integration Plan

Classify each tool into an integration pattern:

```txt
OIDC
SAML
SCIM
OAuth SaaS
Webhook ingestion
Runtime usage
Finance export
MCP tool
Custom API
```

### 3. Connector Manifest

Create a connector manifest for each tool.

The manifest defines:

- Provider name
- Protocol
- Capabilities
- Claims mapping
- Lifecycle event mapping
- Usage event mapping
- Audit evidence mapping
- Pay/settlement mapping where applicable

### 4. Configure Existing Connectors

If a connector template already exists, configure it for the customer.

### 5. Generate Missing Connectors

If the connector does not exist, use an Aider-style loop:

```txt
Define manifest
Generate adapter
Add sample config
Add smoke test
Add docs
Validate with customer workflow
Publish reusable template
```

### 6. Validate Customer Workflows

Validate these core workflows:

- Create agent identity
- Link owner and sponsor
- Assign lifecycle state
- Import usage events
- Send audit evidence
- Trigger suspension/deprovisioning event
- Generate reports

### 7. Publish to Integration Catalog

Once validated, convert the customer-specific connector into a reusable catalog connector.

## Free Trial Promise

A strong onboarding promise:

> Connect your agent stack during trial. If your critical tool is not supported, we will build the connector pattern with you.

## Onboarding Questionnaire

Ask each customer:

1. What IdP/SSO do you use?
2. What IGA or access review system do you use?
3. What PAM or secrets manager do you use?
4. What HRMS owns employee and manager data?
5. What SaaS apps will agents use?
6. What runtime platform runs your agents?
7. What LLM gateway or model providers do you use?
8. What finance system owns cost centers and chargeback?
9. What observability system receives logs and metrics?
10. What evaluation framework measures agent reliability?

## First Customer Success Criteria

A customer is successfully onboarded when:

- At least one IdP or SSO source is connected
- At least one runtime usage source is connected
- At least one audit destination is connected
- Agents can be registered through API
- Usage can be recorded through API or webhook
- Lifecycle state can influence downstream access systems
- Reports show inventory, lifecycle, usage, and audit evidence

## Strategic Outcome

Every customer onboarding should make the integration catalog stronger.

The long-term moat is not only the platform. It is the growing library of real enterprise integrations validated through customer deployments.
