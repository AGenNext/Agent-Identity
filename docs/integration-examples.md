# Integration Examples

Agent Identity should be easy to connect with any IdP, SSO system, SaaS app, runtime platform, or enterprise workflow tool.

The adoption goal is to support a large integration ecosystem, similar in spirit to Okta's broad app network. Agent Identity should make integrations fast through open standards, lightweight connector manifests, SDKs, and MCP tools.

## Integration Philosophy

```txt
Do not build one-off integrations first.
Build integration patterns first.
Then let thousands of apps map into those patterns.
```

## Integration Layers

| Integration Type | Purpose | Standards / Interfaces |
|---|---|---|
| IdP / SSO | Human and workforce context | OIDC, SAML, SCIM |
| IAM / IGA | Access governance and lifecycle | SCIM, APIs, events |
| PAM | Privileged tool and secret access | Vault APIs, session brokers |
| SaaS Apps | Tool ownership and usage context | OAuth, webhooks, app APIs |
| Runtime Platforms | Agent runtime and usage signals | REST, webhooks, MCP |
| Finance Systems | Cost center, pay, chargeback | ERP APIs, webhooks, CSV export |
| Evaluation Systems | Reliability and quality signals | REST, events |

## Generic OIDC / SSO Integration

Use this pattern for any OIDC-compatible identity provider.

Examples:

- Okta
- Microsoft Entra ID
- Auth0
- Google Workspace
- Ping Identity
- OneLogin
- Keycloak

### Flow

```txt
1. Human signs in through enterprise IdP
2. IdP returns user identity and organization claims
3. Agent Identity maps the user to agent owner/sponsor
4. Agent lifecycle and audit records are updated
5. Access control plane uses the same context for policy enforcement
```

### Example Mapping

```json
{
  "idp": "okta",
  "subject": "user:00u123",
  "email": "owner@example.com",
  "department": "Sales",
  "manager": "user:00u999",
  "groups": ["sales", "ai-agent-owners"],
  "mapped_agent_role": "agent_owner"
}
```

## Generic SAML Integration

Use this when an enterprise still relies on SAML SSO.

### Flow

```txt
1. Enterprise IdP authenticates the user
2. SAML assertion is received by the access control plane
3. Agent Identity receives normalized owner, team, and project context
4. Agent records are linked to that enterprise identity
```

### Normalized Claims

```json
{
  "subject": "user:enterprise-123",
  "email": "owner@example.com",
  "name": "Agent Owner",
  "groups": ["AI Platform Team"],
  "department": "Engineering"
}
```

## SCIM Integration

SCIM should be used for lifecycle provisioning and deprovisioning.

### Use Cases

- Create agent owner records
- Sync teams and departments
- Deactivate agents when owner leaves
- Move agents when owner changes teams
- Trigger leave state when supervising user is on leave

### Example Event

```json
{
  "event": "user.deactivated",
  "source": "scim",
  "user": "user:123",
  "action": "move_owned_agents_to_suspended"
}
```

## SaaS App Integration Pattern

Every SaaS app connector should answer:

```txt
What tools can agents use?
What usage did agents create?
What access should be linked to each agent?
What audit evidence should be stored?
```

### Example: CRM App

```json
{
  "app": "salesforce",
  "agent": "agent:sales_assistant",
  "tools": ["crm.read", "crm.update", "lead.create"],
  "owner": "user:sales_manager",
  "cost_center": "growth",
  "audit_enabled": true
}
```

## Runtime Provider Integration

Runtime platforms should report usage and operational state.

### Example Usage Event

```json
{
  "agent": "agent:research_assistant",
  "runtime_provider": "provider:agent_runtime_cloud",
  "usage": {
    "input_tokens": 12000,
    "output_tokens": 1800,
    "runtime_seconds": 240,
    "tool_calls": 8,
    "storage_mb": 32
  },
  "occurred_at": "2026-05-15T00:00:00Z"
}
```

## MCP Integration

Agent Identity should expose MCP tools so agents can query their own identity, lifecycle, policy context, usage, and evaluation status.

### Planned MCP Tools

```txt
agent_identity.get_identity_card
agent_identity.get_lifecycle_status
agent_identity.record_usage
agent_identity.record_audit_event
agent_identity.get_policy_context
agent_identity.get_evaluation_summary
agent_identity.request_lifecycle_transition
```

## Connector Manifest

Each integration should be described by a connector manifest.

```json
{
  "name": "Okta",
  "type": "idp",
  "protocols": ["oidc", "saml", "scim"],
  "capabilities": [
    "user_context",
    "group_context",
    "lifecycle_events",
    "owner_mapping"
  ],
  "webhooks": [
    "user.created",
    "user.updated",
    "user.deactivated",
    "group.updated"
  ]
}
```

## Integration Catalog Strategy

To compete with large identity platforms, Agent Identity needs an integration catalog.

Start with standard connector templates:

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

Then each new integration is mostly configuration, not custom engineering.

## First 25 Integrations to Prioritize

### IdP / SSO

- Okta
- Microsoft Entra ID
- Auth0
- Google Workspace
- Ping Identity
- OneLogin
- Keycloak

### IGA / PAM

- SailPoint
- Saviynt
- CyberArk
- HashiCorp Vault
- AWS IAM Identity Center

### SaaS and Developer Platforms

- GitHub Enterprise
- GitLab
- Salesforce
- HubSpot
- Slack
- Microsoft Teams
- Google Drive
- Jira
- ServiceNow

### Runtime / AI / Observability

- OpenAI
- Anthropic
- LiteLLM
- LangSmith
- Datadog
- Cloudflare

## Adoption Principle

A customer should be able to integrate Agent Identity with an existing IdP or SaaS app in minutes by choosing:

```txt
Provider
Protocol
Claims mapping
Lifecycle event mapping
Usage event mapping
Audit destination
```

The long-term objective is thousands of integrations powered by standards-based connector templates.
