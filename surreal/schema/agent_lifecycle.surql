-- AGenNext Agent Identity
-- SurrealQL schema for agent identity lifecycle management.
-- Source of truth: SurrealDB. Intended for execution through SurrealKit.
-- Execute after surreal/schema/agent_identity.surql
--
-- SOURCE GROUNDING
-- All domain vocabulary below is taken from:
--   "Identity Management for Agentic AI" (OpenID Foundation, Tobin South, Oct 2025).
-- Every state, trigger, and attribute name is annotated with its source location
-- in that whitepaper. No vocabulary is introduced from outside that document.
--
-- DESIGN NOTE
-- Only SurrealDB out-of-the-box features are used (ASSERT / VALUE / DEFAULT /
-- DEFINE EVENT / DEFINE INDEX / RELATE / built-in functions). Custom
-- DEFINE FUNCTIONs are used only for the lifecycle state machine, for which
-- SurrealDB offers no native construct.

-- ---------------------------------------------------------------------------
-- Lifecycle state machine.
-- States (whitepaper, Key Terms table and §2.9 / §3.2 / §3.7):
--   provisioned    -- "agent provisioning"; §3.7 "from provisioning to ... de-provisioning"
--   active         -- Key Terms, Revocation: "an agent's active credentials ... current session"
--   revoked        -- Key Terms, Revocation; §3.2 "The Revocation Challenge"
--   deprovisioned  -- Key Terms, De-provisioning; §3.2 "De-provisioning & Off-boarding"
-- Transitions reflect the whitepaper's lifecycle:
--   provisioning -> operation, revocation of the active session, and the
--   permanent de-provisioning that is "the ultimate response to a compromise".
-- ---------------------------------------------------------------------------

-- Allowed next states for a given state. Returns [] for unknown/terminal states.
DEFINE FUNCTION fn::lifecycle_next_states($from: string) {
  RETURN {
    provisioned: ["active", "deprovisioned"],
    active: ["revoked", "deprovisioned"],
    revoked: ["deprovisioned"],
    deprovisioned: []
  }[$from] ?? [];
};

-- Whether a transition is permitted, derived from the map above.
DEFINE FUNCTION fn::lifecycle_allows($from: string, $to: string) {
  RETURN $to IN fn::lifecycle_next_states($from);
};

-- ---------------------------------------------------------------------------
-- Current lifecycle position for an agent identity. One record per identity.
-- ---------------------------------------------------------------------------
DEFINE TABLE agent_lifecycle SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE agent_lifecycle TYPE record<agent_identity>;
DEFINE FIELD state ON TABLE agent_lifecycle TYPE string DEFAULT "provisioned"
  ASSERT $value IN ["provisioned", "active", "revoked", "deprovisioned"];
DEFINE FIELD previous_state ON TABLE agent_lifecycle TYPE option<string>
  ASSERT $value = NONE OR $value IN ["provisioned", "active", "revoked", "deprovisioned"];
-- "owners": §2.9 "its own attributes, owners, and group memberships".
DEFINE FIELD owners ON TABLE agent_lifecycle TYPE array<string> DEFAULT [];
-- "entitlements": §2.9 "all its associated entitlements are irrevocably purged".
DEFINE FIELD entitlements ON TABLE agent_lifecycle TYPE array<string> DEFAULT [];
DEFINE FIELD reason ON TABLE agent_lifecycle TYPE option<string>;
DEFINE FIELD entered_state_at ON TABLE agent_lifecycle TYPE datetime DEFAULT time::now();
DEFINE FIELD created_at ON TABLE agent_lifecycle TYPE datetime
  VALUE $before.created_at OR time::now() DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE agent_lifecycle TYPE datetime VALUE time::now();

DEFINE INDEX agent_lifecycle_identity_idx ON TABLE agent_lifecycle COLUMNS identity UNIQUE;
DEFINE INDEX agent_lifecycle_state_idx ON TABLE agent_lifecycle COLUMNS state;

-- Reject illegal transitions inside the write transaction, per the state machine.
DEFINE EVENT agent_lifecycle_guard ON TABLE agent_lifecycle WHEN
  $event = "UPDATE" AND $before.state != $after.state THEN {
  IF !fn::lifecycle_allows($before.state, $after.state) {
    THROW "Illegal lifecycle transition from '" + $before.state + "' to '" + $after.state + "'";
  };
};

-- Stamp entered_state_at whenever the state actually changes.
DEFINE EVENT agent_lifecycle_stamp ON TABLE agent_lifecycle WHEN
  $event = "UPDATE" AND $before.state != $after.state THEN {
  UPDATE $after.id SET entered_state_at = time::now();
};

-- Append an immutable audit-log entry and graph edge on every state change.
-- "audit logs of all authentication events" (§2.4); "enriched audit logs" (§2.11).
DEFINE EVENT agent_lifecycle_audit ON TABLE agent_lifecycle WHEN
  ($event = "CREATE" AND $after.state != "provisioned")
  OR ($event = "UPDATE" AND $before.state != $after.state) THEN {
  LET $entry = (CREATE ONLY lifecycle_audit_log CONTENT {
    identity: $after.identity,
    from_state: IF $event = "CREATE" { NONE } ELSE { $before.state },
    to_state: $after.state,
    reason: $after.reason
  });
  RELATE $after.identity->audited_by->$entry.id;
};

-- ---------------------------------------------------------------------------
-- Append-only audit log of every lifecycle change for an identity.
-- ---------------------------------------------------------------------------
DEFINE TABLE lifecycle_audit_log SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE lifecycle_audit_log TYPE record<agent_identity>;
DEFINE FIELD from_state ON TABLE lifecycle_audit_log TYPE option<string>
  ASSERT $value = NONE OR $value IN ["provisioned", "active", "revoked", "deprovisioned"];
DEFINE FIELD to_state ON TABLE lifecycle_audit_log TYPE string
  ASSERT $value IN ["provisioned", "active", "revoked", "deprovisioned"];
-- "actor": §2.11 "the act (actor) claim ... identify the acting party".
DEFINE FIELD actor ON TABLE lifecycle_audit_log TYPE option<string>;
-- "principal": §2.11 "distinct identifiers for both the human principal and the agent actor".
DEFINE FIELD principal ON TABLE lifecycle_audit_log TYPE option<string>;
-- "trigger" values from §3.2: "security alert", "compromise", "end-of-life".
DEFINE FIELD trigger ON TABLE lifecycle_audit_log TYPE option<string>
  ASSERT $value = NONE OR $value IN ["security_alert", "compromise", "end_of_life"];
DEFINE FIELD reason ON TABLE lifecycle_audit_log TYPE option<string>;
DEFINE FIELD metadata ON TABLE lifecycle_audit_log TYPE object DEFAULT {};
DEFINE FIELD created_at ON TABLE lifecycle_audit_log TYPE datetime DEFAULT time::now();

DEFINE INDEX lifecycle_audit_log_identity_idx ON TABLE lifecycle_audit_log COLUMNS identity;

-- Graph relation linking an identity to its audit-log entries.
DEFINE TABLE audited_by TYPE RELATION IN agent_identity OUT lifecycle_audit_log SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD recorded_at ON TABLE audited_by TYPE datetime DEFAULT time::now();
