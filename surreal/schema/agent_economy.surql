-- AGenNext Agent Identity
-- SurrealQL schema for the agent economic layer: payment mandates and transactions.
-- Source of truth: SurrealDB. Execute after surreal/schema/agent_identity.surql.
--
-- SOURCE GROUNDING
-- "Identity Management for Agentic AI" (OpenID, Oct 2025) §3.6 "The Economic Layer:
-- Identity, Payments, and Financial Transactions":
--   * Agent Payments Protocol (AP2) Mandates -- a cryptographically-signed artefact
--     that is auditable proof of a user's instructions. Two stages:
--       - Intent Mandate  ("a high-level instruction captured as a signed Intent Mandate")
--       - Cart Mandate    ("the user's approval of that specific purchase signs a Cart Mandate")
--   * Mandates are "often signed using Verifiable Credentials (VCs) that bind the
--     Mandates to a user's identity".
--   * KYAPay "Know Your Agent" (KYA) extends KYC/KYB verification to the agent.
--   * FAPI hardens the high-consequence APIs these transactions run over.
--
-- DESIGN NOTE: SurrealDB out-of-the-box features only. Mandates/transactions link to
-- the agent via record fields (not graph edges), so the edge validators are unaffected.

-- ---------------------------------------------------------------------------
-- payment_mandate (AP2 Mandate). A signed, auditable instruction from a principal.
-- ---------------------------------------------------------------------------
DEFINE TABLE payment_mandate SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE payment_mandate TYPE record<agent_identity>;
-- The human principal who authorized the mandate.
DEFINE FIELD principal ON TABLE payment_mandate TYPE string;
-- AP2 two-stage mandate type.
DEFINE FIELD type ON TABLE payment_mandate TYPE string
  ASSERT $value IN ["intent", "cart"];
DEFINE FIELD status ON TABLE payment_mandate TYPE string DEFAULT "signed"
  ASSERT $value IN ["signed", "fulfilled", "revoked"];
-- Intent: the criteria/limits the agent must stay within. Cart: the specific purchase.
DEFINE FIELD constraints ON TABLE payment_mandate TYPE object DEFAULT {};
DEFINE FIELD amount_limit ON TABLE payment_mandate TYPE option<number>;
DEFINE FIELD currency ON TABLE payment_mandate TYPE option<string>;
-- Reference to the Verifiable Credential that binds the mandate to the principal's identity.
DEFINE FIELD vc_ref ON TABLE payment_mandate TYPE option<string>;
DEFINE FIELD signed_at ON TABLE payment_mandate TYPE datetime DEFAULT time::now();
DEFINE FIELD created_at ON TABLE payment_mandate TYPE datetime DEFAULT time::now();

DEFINE INDEX payment_mandate_identity_idx ON TABLE payment_mandate COLUMNS identity;

-- ---------------------------------------------------------------------------
-- agent_transaction. A financial transaction executed under a mandate.
-- ---------------------------------------------------------------------------
DEFINE TABLE agent_transaction SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE agent_transaction TYPE record<agent_identity>;
-- The mandate that authorized this transaction (auditable chain of evidence, §3.6).
DEFINE FIELD mandate ON TABLE agent_transaction TYPE record<payment_mandate>;
DEFINE FIELD amount ON TABLE agent_transaction TYPE number;
DEFINE FIELD currency ON TABLE agent_transaction TYPE string;
DEFINE FIELD counterparty ON TABLE agent_transaction TYPE option<string>;
DEFINE FIELD status ON TABLE agent_transaction TYPE string DEFAULT "pending"
  ASSERT $value IN ["pending", "settled", "failed"];
-- Whether the settling API enforced a FAPI security profile (§3.6 FAPI).
DEFINE FIELD fapi_secured ON TABLE agent_transaction TYPE bool DEFAULT false;
DEFINE FIELD settled_at ON TABLE agent_transaction TYPE option<datetime>;
DEFINE FIELD created_at ON TABLE agent_transaction TYPE datetime DEFAULT time::now();

DEFINE INDEX agent_transaction_identity_idx ON TABLE agent_transaction COLUMNS identity;
DEFINE INDEX agent_transaction_mandate_idx ON TABLE agent_transaction COLUMNS mandate;

-- A transaction must reference a real mandate and may not exceed its amount_limit.
-- Enforced on CREATE and UPDATE so the limit can't be bypassed by mutating a row
-- (changing amount or swapping mandate) after creation.
DEFINE EVENT agent_transaction_limit ON TABLE agent_transaction WHEN
  $event = "CREATE" OR $event = "UPDATE" THEN {
  LET $mandate = (SELECT amount_limit FROM payment_mandate WHERE id = $after.mandate);
  IF array::len($mandate) = 0 {
    THROW "Transaction references a non-existent payment_mandate";
  };
  LET $limit = $mandate[0].amount_limit;
  IF $limit != NONE AND $after.amount > $limit {
    THROW "Transaction amount exceeds the mandate's amount_limit";
  };
};
