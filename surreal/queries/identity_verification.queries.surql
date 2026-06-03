-- AGenNext Agent Identity
-- Identity verification queries. Vocabulary grounded in
-- "Identity Management for Agentic AI" (OpenID, Oct 2025) §2.4 / §3.

-- Query: All verifications for an identity, newest first
SELECT * FROM identity_verification
WHERE identity = agent_identity:$identity
ORDER BY created_at DESC;

-- Query: Current verified methods for an identity
SELECT method FROM identity_verification
WHERE identity = agent_identity:$identity
  AND status = "verified";

-- Query: Is the identity currently verified by any method?
SELECT count() FROM identity_verification
WHERE identity = agent_identity:$identity
  AND status = "verified"
GROUP ALL;

-- Query: Verifications via the graph relation
SELECT ->verified_by->identity_verification.* AS verifications
FROM agent_identity:$identity;

-- Query: Failed or revoked verifications (review / anomaly surface)
SELECT * FROM identity_verification
WHERE status IN ["failed", "revoked"]
ORDER BY created_at DESC;

-- Query: Verifications grouped by method
SELECT method, count() AS total FROM identity_verification
GROUP BY method;
