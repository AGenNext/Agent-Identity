# Integration Agent

The Integration Agent is an internal/service agent that helps Agent Identity build and maintain integrations at scale.

It is part of the onboarding and integration flywheel.

## Purpose

When a customer starts a free trial or becomes a customer, the Integration Agent discovers their stack, maps their tools to connector templates, generates missing integration scaffolds, and validates workflows.

## Responsibilities

- Discover customer tools and systems
- Classify each tool by integration pattern
- Generate connector manifests
- Generate adapter scaffolds
- Generate sample configuration
- Generate sample webhook payloads
- Generate smoke tests
- Generate documentation
- Validate customer onboarding workflows
- Recommend reusable catalog connectors

## Inputs

The Integration Agent uses:

- Customer onboarding questionnaire
- IdP / SSO metadata
- SCIM schema details
- SaaS app API documentation
- Runtime usage event formats
- Finance export requirements
- MCP tool requirements
- Existing connector templates

## Outputs

For each integration, the Integration Agent should produce:

```txt
connector.json
adapter.ts or adapter.py
example.env
sample-webhook.json
smoke-test.http
README.md
```

## Integration Patterns

```txt
idp-oidc-template
idp-saml-template
scim-template
saas-oauth-template
runtime-usage-template
finance-export-template
mcp-server-template
webhook-ingestion-template
```

## Workflow

```txt
1. Customer starts onboarding
2. Integration Agent collects stack details
3. Integration Agent maps each tool to a connector template
4. Existing connectors are configured
5. Missing connectors are generated
6. Smoke tests are run
7. Customer workflows are validated
8. Reusable connector is added to the catalog
```

## Agent Lifecycle

The Integration Agent itself should be registered in Agent Identity.

Recommended lifecycle:

```txt
onboarding -> probation -> active
```

It should stay in probation until generated connectors pass validation quality thresholds.

## Guardrails

The Integration Agent must not:

- Store customer secrets in generated files
- Hardcode credentials
- Bypass customer approval
- Publish customer-specific configurations into public templates
- Generate destructive integration actions by default

## Success Metrics

- Time to first integration
- Number of connectors generated per customer
- Connector reuse rate
- Smoke test pass rate
- Customer onboarding completion rate
- Integration catalog growth rate

## Strategic Role

The Integration Agent turns onboarding into an integration factory.

```txt
Every customer -> more connectors -> faster onboarding -> stronger platform moat
```
