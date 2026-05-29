-- AGenNext Agent Identity
-- SurrealQL graph layer for agent identity relationships.
-- Source of truth: SurrealDB. Intended for execution through SurrealKit.
-- Execute after surreal/schema/agent_identity.surql and agent_lifecycle.surql.
--
-- SOURCE GROUNDING
-- All edge names and attributes come from the Key Terms / §3.2 of
-- "Identity Management for Agentic AI" (OpenID Foundation, Oct 2025).
-- No vocabulary is introduced from outside that document.
--
-- DESIGN NOTE: this layer uses only SurrealDB's native graph feature
-- (DEFINE TABLE ... TYPE RELATION ... RELATE). No custom logic is added.
--
-- JSON-LD REFERENCE: the graph model is defined by reference in
-- vocabulary/agent-lifecycle.context.jsonld. Each RELATION edge below is a
-- JSON-LD/RDF predicate in that context (mapped to schema.org where one exists,
-- e.g. operates_in -> schema:memberOf, or to the agennext: namespace otherwise).
--
-- The graph layer connects identity nodes (agent_identity, trust_domain,
-- identity_issuer, identity_verification — defined in agent_identity.surql)
-- and the lifecycle / DID nodes via directed edges.

-- ---------------------------------------------------------------------------
-- delegates_to  (Key Terms: "Delegated Authority", "Recursive Delegation";
--                §3.2 "Recursive Delegation and Scope Attenuation")
-- One agent delegates a subset of its authority to another agent, forming a
-- delegation chain. "scope" captures the delegated scope; "attenuated" records
-- whether permissions were narrowed at this step (Scope Attenuation).
-- ---------------------------------------------------------------------------
DEFINE TABLE delegates_to TYPE RELATION IN agent_identity OUT agent_identity SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD scope ON TABLE delegates_to TYPE array<string> DEFAULT [];
DEFINE FIELD attenuated ON TABLE delegates_to TYPE bool DEFAULT false;
DEFINE FIELD created_at ON TABLE delegates_to TYPE datetime DEFAULT time::now();

-- ---------------------------------------------------------------------------
-- acts_on_behalf_of  (Key Terms: "On-Behalf-Of (OBO) Flow", "Delegated Authority";
--                     §3.2 "From Impersonation to Delegation (On-Behalf-Of)")
-- Records that an agent acts on behalf of a human principal, keeping the agent
-- distinct from the principal. "principal" is the human who granted authority.
-- ---------------------------------------------------------------------------
DEFINE TABLE acts_on_behalf_of TYPE RELATION IN agent_identity OUT agent_identity SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD principal ON TABLE acts_on_behalf_of TYPE string;
DEFINE FIELD scope ON TABLE acts_on_behalf_of TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON TABLE acts_on_behalf_of TYPE datetime DEFAULT time::now();

-- ---------------------------------------------------------------------------
-- operates_in  (Key Terms: "Trust Domain")
-- Connects an agent identity to a trust domain it operates within. Agents often
-- need to operate across multiple trust domains.
-- ---------------------------------------------------------------------------
DEFINE TABLE operates_in TYPE RELATION IN agent_identity OUT trust_domain SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD created_at ON TABLE operates_in TYPE datetime DEFAULT time::now();
