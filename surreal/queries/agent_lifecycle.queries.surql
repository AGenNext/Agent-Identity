-- AGenNext Agent Identity
-- SurrealQL lifecycle queries. Vocabulary grounded in
-- "Identity Management for Agentic AI" (OpenID Foundation, Oct 2025).

-- Query: Current lifecycle state for an identity
SELECT * FROM agent_lifecycle
WHERE identity = agent_identity:$identity;

-- Query: All identities currently in a given lifecycle state
SELECT * FROM agent_lifecycle
WHERE state = $state;

-- Query: Identities eligible for production-level access (active state)
SELECT * FROM agent_lifecycle
WHERE state = "active";

-- Query: Full audit log for an identity, newest first (§2.11 "enriched audit logs")
SELECT * FROM lifecycle_audit_log
WHERE identity = agent_identity:$identity
ORDER BY created_at DESC;

-- Query: Audit-log entries via the graph relation
SELECT
  ->audited_by->lifecycle_audit_log.* AS audit_log
FROM agent_identity:$identity;

-- Query: Revocation and de-provisioning events triggered by compromise or security alert
SELECT * FROM lifecycle_audit_log
WHERE to_state IN ["revoked", "deprovisioned"]
  AND trigger IN ["security_alert", "compromise"]
ORDER BY created_at DESC;

-- Query: Resolve the lifecycle graph for an identity
SELECT
  *,
  ->audited_by->lifecycle_audit_log.* AS audit_log
FROM agent_lifecycle
WHERE identity = agent_identity:$identity;
