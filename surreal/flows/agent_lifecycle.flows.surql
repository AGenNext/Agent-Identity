-- AGenNext Agent Identity
-- SurrealQL lifecycle management flows. Execute against the schema in
-- surreal/schema/agent_lifecycle.surql.
--
-- SOURCE GROUNDING: every operation maps to the lifecycle described in
-- "Identity Management for Agentic AI" (OpenID Foundation, Oct 2025):
-- provisioning -> permission updates -> revocation -> de-provisioning (§3.7).
--
-- The agent_lifecycle_guard event rejects illegal transitions and the
-- agent_lifecycle_audit event writes the audit log, so these flows only set
-- the target state and supporting, source-grounded attributes.

-- Lifecycle Flow: provision  (§2.9 "agent provisioning")
-- Initialise lifecycle tracking for a freshly registered identity.
CREATE agent_lifecycle CONTENT {
  identity: agent_identity:$identity,
  state: "provisioned",
  owners: $owners,
  entitlements: $entitlements,
  reason: $reason
};

-- Lifecycle Flow: activate
-- Move a provisioned agent into active operation.
-- previous_state is assigned before state so it captures the prior value.
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "active",
  reason = $reason
WHERE identity = agent_identity:$identity;

-- Lifecycle Flow: update_entitlements  (§3.7 "through permission updates")
UPDATE agent_lifecycle SET
  entitlements = $entitlements
WHERE identity = agent_identity:$identity;

-- Lifecycle Flow: transfer_ownership  (§2.14 Best Practices "ownership transfer")
UPDATE agent_lifecycle SET
  owners = $owners
WHERE identity = agent_identity:$identity;

-- Lifecycle Flow: revoke  (Key Terms "Revocation"; §3.2 "The Revocation Challenge")
-- Invalidate the agent's active credentials / terminate its current session.
-- actor/principal/trigger are captured into the audit log by the audit event.
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "revoked",
  actor = $actor,
  principal = $principal,
  trigger = $trigger,
  reason = $reason
WHERE identity = agent_identity:$identity;

-- Lifecycle Flow: deprovision  (Key Terms "De-provisioning"; §3.2 "De-provisioning & Off-boarding")
-- Permanent, complete removal of the identity and all associated entitlements.
-- actor/principal/trigger are captured into the audit log by the audit event.
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "deprovisioned",
  entitlements = [],
  actor = $actor,
  principal = $principal,
  trigger = $trigger,
  reason = $reason
WHERE identity = agent_identity:$identity;

-- Lifecycle Flow: record_audit_entry
-- Explicitly append an audit-log entry capturing the human principal, agent actor,
-- and trigger, for cases where the auto-audit's reason is not enough
-- (e.g., a security alert or compromise). §2.11 "enriched audit logs"; §3.2 triggers.
LET $entry = (CREATE ONLY lifecycle_audit_log CONTENT {
  identity: agent_identity:$identity,
  from_state: $from_state,
  to_state: $to_state,
  principal: $principal,
  actor: $actor,
  trigger: $trigger,
  reason: $reason,
  metadata: $metadata
});
RELATE agent_identity:$identity->audited_by->$entry.id;

-- Lifecycle Flow: get_current_state
SELECT identity, state, previous_state, owners, entitlements, reason, entered_state_at
FROM agent_lifecycle
WHERE identity = agent_identity:$identity;

-- Lifecycle Flow: list_allowed_next_states
RETURN fn::lifecycle_next_states(
  (SELECT VALUE state FROM ONLY agent_lifecycle
   WHERE identity = agent_identity:$identity LIMIT 1)
);
