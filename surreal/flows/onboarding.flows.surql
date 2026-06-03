-- AGenNext Agent Identity
-- Agent onboarding orchestration. Ties the per-layer flows into the end-to-end
-- path the whitepaper describes: provisioning -> identity -> verification ->
-- activation -> access (§2.9 SSO & Provisioning; §3.7 lifecycle management).
--
-- Run the steps in order. Each step is also available standalone in its own flow
-- file (agent_identity / agent_did / identity_verification / agent_lifecycle /
-- knowledge_graph). Parameters: $identity (record id suffix), $subject, $did, etc.

-- Step 1 — Register the agent identity  (agent_identity.flows.surql: register)
CREATE agent_identity:$identity CONTENT {
  subject: $subject,
  oidc_issuer: $oidc_issuer,
  oidc_subject: $oidc_subject,
  oidc_scopes: $oidc_scopes,
  claims: $claims,
  status: "active"
};

-- Step 2 — Create its DID document  (agent_did.flows.surql: create_did_document)
CREATE did_document CONTENT {
  identity: agent_identity:$identity,
  id: $did,
  controller: $did_controller
};

-- Step 3 — Open and complete a verification  (identity_verification.flows.surql)
LET $v = (CREATE ONLY identity_verification CONTENT {
  identity: agent_identity:$identity,
  verifier: $verifier,
  method: $verification_method,
  status: "verified",
  verified_at: time::now()
});
RELATE agent_identity:$identity->verified_by->$v.id;

-- Step 4 — Provision the lifecycle  (agent_lifecycle.flows.surql: provision)
CREATE agent_lifecycle CONTENT {
  identity: agent_identity:$identity,
  state: "provisioned",
  owners: $owners,
  entitlements: $entitlements,
  reason: "Onboarding"
};

-- Step 5 — Activate  (agent_lifecycle.flows.surql: activate)
UPDATE agent_lifecycle SET
  previous_state = state,
  state = "active",
  reason = "Onboarding complete"
WHERE identity = agent_identity:$identity;

-- Step 6 — Place in a trust domain  (trust_domain.flows.surql: operate_in)
RELATE agent_identity:$identity->operates_in->trust_domain:$trust_domain;

-- Step 7 — Grant an initial role  (knowledge_graph.flows.surql: assign_role)
RELATE agent_identity:$identity->assigned_role->role:$role;
