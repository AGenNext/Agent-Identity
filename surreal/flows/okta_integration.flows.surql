-- AGenNext Agent Identity
-- Okta integration flows: map Okta Schema attributes and Okta/SCIM lifecycle
-- operations onto the agent identity model. Execute against the existing schema
-- (agent_identity, agent_lifecycle, agent_knowledge_graph).
--
-- SOURCE GROUNDING
--   * Okta Management Schema API -- https://developer.okta.com/docs/api/openapi/okta-management/management/tags/schema
--     (schema property fields: title, type, required, mutability, permissions, master).
--   * SCIM lifecycle for agentic identities -- OpenID "Identity Management for Agentic AI"
--     §2.9 (provision via SCIM, deactivate, SCIM DELETE de-provisioning).
-- No new vocabulary is introduced; these flows reuse existing tables/edges only.

-- Okta Integration Flow: upsert_schema_attribute
-- Map one Okta user-schema property onto a governed schema_attribute node and
-- attach it to the agent (has_attribute edge).
LET $attr = (CREATE ONLY schema_attribute CONTENT {
  title: $title,
  type: $type,
  required: $required,
  mutability: $mutability,
  permissions: $permissions,
  master: $master
});
RELATE agent_identity:$identity->has_attribute->$attr.id;

-- Okta Integration Flow: scim_provision
-- An Okta SCIM create of the AgenticIdentity provisions the lifecycle (§2.9).
CREATE agent_lifecycle CONTENT {
  identity: agent_identity:$identity,
  state: "provisioned",
  owners: $owners,
  entitlements: $entitlements,
  reason: "Provisioned via Okta SCIM"
};

-- Okta Integration Flow: scim_activate
-- SCIM active = true moves a provisioned agent into active operation.
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "active",
  reason = "Activated via Okta SCIM"
WHERE identity = agent_identity:$identity;

-- Okta Integration Flow: scim_deactivate
-- SCIM active = false revokes the agent's active credentials (§3.2 Revocation).
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "revoked",
  actor = $actor,
  trigger = $trigger,
  reason = "Deactivated via Okta SCIM"
WHERE identity = agent_identity:$identity;

-- Okta Integration Flow: scim_delete
-- A SCIM DELETE on the AgenticIdentity is the authoritative de-provisioning
-- signal: permanent removal of the identity and all entitlements (§2.9, §3.2).
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "deprovisioned",
  entitlements = [],
  actor = $actor,
  trigger = $trigger,
  reason = "De-provisioned via Okta SCIM DELETE"
WHERE identity = agent_identity:$identity;
