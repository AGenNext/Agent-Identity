-- AGenNext Agent Identity
-- SurrealQL graph-layer traversals. Vocabulary grounded in
-- "Identity Management for Agentic AI" (OpenID Foundation, Oct 2025).
-- Execute against surreal/schema/agent_graph.surql.

-- Query: Agents this agent delegates to (one hop) — Recursive Delegation
SELECT ->delegates_to->agent_identity.* AS delegatees
FROM agent_identity:$identity;

-- Query: Full delegation chain reachable from an agent (multi-hop)
SELECT ->delegates_to->agent_identity->delegates_to->agent_identity.* AS chain
FROM agent_identity:$identity;

-- Query: Who delegated to this agent (incoming edge)
SELECT <-delegates_to<-agent_identity.* AS delegators
FROM agent_identity:$identity;

-- Query: Human principals an agent acts on behalf of — On-Behalf-Of
SELECT ->acts_on_behalf_of.principal AS principals
FROM agent_identity:$identity;

-- Query: Trust domains an agent operates in — Trust Domain
SELECT ->operates_in->trust_domain.* AS trust_domains
FROM agent_identity:$identity;

-- Query: Delegations where scope was attenuated (least privilege / Scope Attenuation)
SELECT * FROM delegates_to
WHERE attenuated = true;

-- Query: Resolve the full identity graph for an agent
SELECT
  *,
  ->delegates_to->agent_identity.subject AS delegatees,
  ->acts_on_behalf_of.principal AS principals,
  ->operates_in->trust_domain.name AS trust_domains,
  ->audited_by->lifecycle_audit_log.* AS audit_log
FROM agent_identity:$identity;
