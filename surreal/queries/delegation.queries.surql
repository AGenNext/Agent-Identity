-- AGenNext Agent Identity
-- Delegation & authorization queries. Vocabulary grounded in
-- "Identity Management for Agentic AI" (OpenID, Oct 2025) §3.2 / §4.4.
-- (Basic traversals live in agent_graph.queries.surql; these focus on scope.)

-- Query: Outgoing delegations with their granted scope
SELECT out AS delegatee, scope, attenuated FROM delegates_to
WHERE in = agent_identity:$identity;

-- Query: The effective delegated scope reaching each direct delegatee
SELECT
  ->delegates_to AS edges,
  ->delegates_to->agent_identity.subject AS delegatees
FROM agent_identity:$identity;

-- Query: Delegations not marked as attenuated (review surface for least privilege)
SELECT in, out, scope FROM delegates_to
WHERE attenuated = false;

-- Query: Delegations whose scope is NOT a subset of the delegator's entitlements
-- (post-hoc check; the create-time event prevents new ones, this catches drift
-- after an entitlement is reduced).
SELECT in, out, scope FROM delegates_to
WHERE !(scope ALLINSIDE (SELECT VALUE entitlements FROM ONLY agent_lifecycle
                         WHERE identity = $parent.in LIMIT 1));

-- Query: Principals an agent acts on behalf of, with scope
SELECT out AS subagent, principal, scope FROM acts_on_behalf_of
WHERE in = agent_identity:$identity;
