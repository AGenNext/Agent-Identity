-- AGenNext Agent Identity
-- Economic-layer flows. Execute against surreal/schema/agent_economy.surql.
-- Grounded in "Identity Management for Agentic AI" (OpenID, Oct 2025) §3.6.

-- Economy Flow: sign_intent_mandate  (AP2 Intent Mandate)
-- A principal authorizes a high-level intent with limits the agent must stay within.
CREATE payment_mandate CONTENT {
  identity: agent_identity:$identity,
  principal: $principal,
  type: "intent",
  status: "signed",
  constraints: $constraints,
  amount_limit: $amount_limit,
  currency: $currency,
  vc_ref: $vc_ref
};

-- Economy Flow: sign_cart_mandate  (AP2 Cart Mandate)
-- The principal approves a specific purchase that meets the intent's criteria.
CREATE payment_mandate CONTENT {
  identity: agent_identity:$identity,
  principal: $principal,
  type: "cart",
  status: "signed",
  constraints: $constraints,
  amount_limit: $amount,
  currency: $currency,
  vc_ref: $vc_ref
};

-- Economy Flow: record_transaction
-- Execute a transaction under a mandate (the agent_transaction_limit event rejects
-- amounts above the mandate's limit).
CREATE agent_transaction CONTENT {
  identity: agent_identity:$identity,
  mandate: payment_mandate:$mandate,
  amount: $amount,
  currency: $currency,
  counterparty: $counterparty,
  status: "pending",
  fapi_secured: $fapi_secured
};

-- Economy Flow: settle_transaction
UPDATE agent_transaction:$transaction SET
  status = "settled",
  settled_at = time::now();

-- Economy Flow: fail_transaction
UPDATE agent_transaction:$transaction SET
  status = "failed";

-- Economy Flow: fulfil_mandate
UPDATE payment_mandate:$mandate SET status = "fulfilled";

-- Economy Flow: revoke_mandate
UPDATE payment_mandate:$mandate SET status = "revoked";

-- Economy Flow: kya_verify  (KYAPay "Know Your Agent")
-- Record a Know-Your-Agent verification of the agent's identity.
LET $v = (CREATE ONLY identity_verification CONTENT {
  identity: agent_identity:$identity,
  verifier: $verifier,
  method: "kya",
  evidence_ref: $evidence_ref,
  status: "verified",
  verified_at: time::now()
});
RELATE agent_identity:$identity->verified_by->$v.id;
