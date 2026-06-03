# Okta Integration Catalog

A catalog of Okta Management API integration points and how each maps onto the Agent Identity
model. This is the human-readable twin of
[`vocabulary/okta-integration.catalog.json`](../vocabulary/okta-integration.catalog.json).
Both are **reference material**, not enforced vocabulary.

**Grounding:** the [Okta Management API](https://developer.okta.com/docs/api/). The SCIM
lifecycle mapping is also grounded in the OpenID *Identity Management for Agentic AI*
whitepaper §2.9. The executable lifecycle/attribute mapping lives in
[`surreal/flows/okta_integration.flows.surql`](../surreal/flows/okta_integration.flows.surql);
this catalog is the wider menu of what an Okta tenant offers and where each part lands.

| Okta resource | What it does | Maps to (Agent Identity) |
| --- | --- | --- |
| [Users](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/user/) | Identity lifecycle: create, activate, suspend, deactivate, delete. | `agent_identity` + `agent_lifecycle` (`provisioned`/`active`/`revoked`/`deprovisioned`) |
| [Schema](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/schema/) | Attribute definitions for users/groups/apps (base + custom). | `schema_attribute` via `has_attribute` |
| [SCIM provisioning](https://developer.okta.com/docs/concepts/scim/) | Automated create/update/deactivate/delete across systems. | `scim_provision` / `scim_activate` / `scim_deactivate` / `scim_delete` flows |
| [Groups](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/group/) | Collections of identities; group-based access. | `role` / `access_profile` (`assigned_role` / `assigned_access`) |
| [Applications](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/application/) | Connected apps and per-app user profiles. | `source`; account on a source (`holds_account` / `account_on_source`) |
| [Roles](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/role-assignment/) | Role-based administrative permissions. | `role` (`assigned_role`) |
| [System Log](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/system-log/) | Audit trail of all org events. | `lifecycle_audit_log` (`audited_by`) |
| [Event / Inline Hooks](https://developer.okta.com/docs/concepts/event-hooks/) | Outbound notifications and synchronous decision hooks. | triggers for lifecycle transitions (e.g. deactivate on a `security_alert`) |
| [Policies](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/policy/) | Sign-on, password, MFA policies. | guardrails / access constraints on `entitlements` |
| [Authenticators / Factors](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/authenticator/) | Credentials and auth factors. | DID `verification_method` (`has_verification_method`) |
| [Authorization Servers (OAuth2/OIDC)](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/authorization-server/) | Issue tokens; define scopes/claims. | `agent_identity.oidc_issuer` / `oidc_scopes`; `entitlements` |
| [Identity Providers](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/identity-provider/) | Federation with external IdPs. | `trust_domain` (`operates_in`); cross-domain federation |

## How to use this catalog

Start from the row you need, follow the "maps to" column into the schema/flows, and the data
lands in the grounded model. The two rows already implemented end-to-end are **Schema** and
**SCIM provisioning** (see the Okta integration flows). The rest are the planned surface for a
full connector and are documented here so the mapping is decided before any code is written.
