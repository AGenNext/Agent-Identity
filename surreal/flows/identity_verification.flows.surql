-- AGenNext Agent Identity
-- Identity verification flows. Execute against the identity_verification table
-- and verified_by relation defined in surreal/schema/agent_identity.surql.
--
-- SOURCE GROUNDING
-- Verification answers the whitepaper's central question — "is this agent
-- permitted to perform this action on behalf of this entity?" — by providing a
-- verifiable "who" (§2.4 Authentication). Methods are grounded as:
--   did      -- §3.1 Sovereign and Portable Agent Identity; W3C DID 1.1
--   oidc     -- §2.4 (OAuth 2.1/OIDC); §3.1 OIDC-A
--   vc       -- §3.6 "signed using Verifiable Credentials (VCs)"
--   registry -- §3.3 Registries and Dynamic Connections
-- ('manual' remains available in the schema as an operator escape hatch.)

-- Verification Flow: request_verification
-- Open a pending verification of an identity by a verifier using a given method.
LET $v = (CREATE ONLY identity_verification CONTENT {
  identity: agent_identity:$identity,
  verifier: $verifier,
  method: $method,
  evidence_ref: $evidence_ref,
  status: "pending"
});
RELATE agent_identity:$identity->verified_by->$v.id;

-- Verification Flow: mark_verified
-- Record a successful verification and stamp the time.
UPDATE identity_verification:$verification SET
  status = "verified",
  verified_at = time::now();

-- Verification Flow: mark_failed
-- Record a failed verification attempt.
UPDATE identity_verification:$verification SET
  status = "failed";

-- Verification Flow: revoke_verification
-- Revoke a previously successful verification (e.g. on credential compromise).
UPDATE identity_verification:$verification SET
  status = "revoked";

-- Verification Flow: verify_and_attach (convenience)
-- Create an already-verified record and attach it to the identity in one step,
-- e.g. when a registry has independently verified the agent.
LET $rv = (CREATE ONLY identity_verification CONTENT {
  identity: agent_identity:$identity,
  verifier: $verifier,
  method: $method,
  evidence_ref: $evidence_ref,
  status: "verified",
  verified_at: time::now()
});
RELATE agent_identity:$identity->verified_by->$rv.id;
