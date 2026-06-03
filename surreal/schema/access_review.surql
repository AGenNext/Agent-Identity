-- AGenNext Agent Identity
-- SurrealQL schema for access reviews (certification of an agent's access).
-- Source of truth: SurrealDB. Execute after surreal/schema/agent_identity.surql.
--
-- SOURCE GROUNDING
--   * SailPoint Identity Security Cloud "Certifications / Campaigns" -- periodic
--     reviews where owners re-approve access (https://developer.sailpoint.com/docs/api/v3/).
--   * OpenID "Identity Management for Agentic AI" §2.12 (IGA) and §2.9 (lifecycle
--     governance): agents are first-class identities whose access is governed and reviewed.
--
-- DESIGN NOTE: uses only SurrealDB out-of-the-box features. The review links to
-- the agent via a record field (not a graph edge), so the edge validators are unaffected.

DEFINE TABLE access_review SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE access_review TYPE record<agent_identity>;
-- Who performs the review (owner / certifier).
DEFINE FIELD reviewer ON TABLE access_review TYPE string;
-- Snapshot of the entitlements under review at the time the review was opened.
DEFINE FIELD reviewed_entitlements ON TABLE access_review TYPE array<string> DEFAULT [];
DEFINE FIELD decision ON TABLE access_review TYPE string DEFAULT "pending"
  ASSERT $value IN ["pending", "certified", "revoked"];
DEFINE FIELD reason ON TABLE access_review TYPE option<string>;
DEFINE FIELD due_at ON TABLE access_review TYPE option<datetime>;
DEFINE FIELD decided_at ON TABLE access_review TYPE option<datetime>;
DEFINE FIELD created_at ON TABLE access_review TYPE datetime DEFAULT time::now();

DEFINE INDEX access_review_identity_idx ON TABLE access_review COLUMNS identity;
DEFINE INDEX access_review_decision_idx ON TABLE access_review COLUMNS decision;
