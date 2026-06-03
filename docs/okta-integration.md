# Okta Integration

How an Okta tenant maps onto the Agent Identity model. This is the executable mapping in
[`surreal/flows/okta_integration.flows.surql`](../surreal/flows/okta_integration.flows.surql),
described here in plain English.

**Grounding:** Okta's [Schema API](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/schema)
(attribute definitions) and SCIM-based lifecycle management for agentic identities
(OpenID *Identity Management for Agentic AI*, §2.9 — extend SCIM with an `AgenticIdentity`
resource so agents are provisioned and de-provisioned like users). No new vocabulary is
introduced; the integration reuses existing tables and edges.

## Attribute mapping (Okta Schema → `schema_attribute`)

Each Okta user-schema property becomes a governed `schema_attribute` node attached to the
agent via the `has_attribute` edge. The property fields map one-to-one:

| Okta Schema property | `schema_attribute` field |
| --- | --- |
| `title` | `title` |
| `type` | `type` |
| `required` | `required` |
| `mutability` | `mutability` |
| `permissions` | `permissions` |
| `master` (profile master) | `master` |

Flow: **`upsert_schema_attribute`**.

## Lifecycle mapping (Okta/SCIM → agent lifecycle)

Okta drives the agent through the same grounded lifecycle states the rest of the system uses:

| Okta / SCIM operation | Lifecycle flow | Resulting state |
| --- | --- | --- |
| SCIM create of the `AgenticIdentity` | `scim_provision` | `provisioned` |
| SCIM `active = true` | `scim_activate` | `active` |
| SCIM `active = false` | `scim_deactivate` | `revoked` |
| SCIM `DELETE` | `scim_delete` | `deprovisioned` |

The `scim_deactivate` and `scim_delete` flows accept `actor` and `trigger`
(`security_alert` / `compromise` / `end_of_life`), which the lifecycle audit event records
into `lifecycle_audit_log` — giving an enriched, accountable audit trail (§2.11).

In plain English: Okta **provisions** an agent, **activates** it, can **revoke** it
(deactivate), and a SCIM **DELETE** is the authoritative **de-provisioning** signal that
permanently removes the agent and its entitlements.

## Notes

- The mapping leans on Okta/SCIM as the system of record for provisioning, consistent with
  the whitepaper's recommendation to automate the agent lifecycle via SCIM rather than ad-hoc
  processes (Best Practices, §2.14).
- This is a mapping layer only; it does not call Okta APIs. A connector that polls Okta and
  invokes these flows is a separate, future piece of work.
- For the full menu of Okta resources and where each maps, see the
  [Okta Integration Catalog](./okta-integration-catalog.md).
