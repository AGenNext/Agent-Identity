-- AGenNext Agent Identity
-- Delegation & authorization flows. Execute against the graph edges in
-- surreal/schema/agent_graph.surql.
--
-- SOURCE GROUNDING ("Identity Management for Agentic AI", OpenID, Oct 2025):
--   * Delegated Authority / On-Behalf-Of (OBO)  -- Key Terms; §3.2
--   * Recursive Delegation                       -- Key Terms; §3.2; §4.4
--   * Scope Attenuation                          -- Key Terms; §3.2; §4.4
-- The delegates_to_attenuation event rejects a delegation whose scope exceeds
-- the delegator's entitlements, so these flows only express intent.

-- Delegation Flow: delegate
-- One agent delegates a (narrowed) scope to another agent. `attenuated` marks
-- that permissions were narrowed at this step.
RELATE agent_identity:$from->delegates_to->agent_identity:$to
  SET scope = $scope, attenuated = $attenuated;

-- Delegation Flow: sub_delegate
-- A recursive delegation: an agent that holds a delegation passes a further
-- narrowed scope to a sub-agent (Russian-nesting-doll attenuation, §4.4).
RELATE agent_identity:$from->delegates_to->agent_identity:$to
  SET scope = $scope, attenuated = true;

-- Delegation Flow: revoke_delegation
-- Remove a delegation edge between two agents.
DELETE delegates_to
WHERE in = agent_identity:$from AND out = agent_identity:$to;

-- Delegation Flow: act_on_behalf_of  (On-Behalf-Of, §3.2)
-- Record that an agent acts for a human principal within a scope, while staying
-- distinct from that principal.
RELATE agent_identity:$from->acts_on_behalf_of->agent_identity:$to
  SET principal = $principal, scope = $scope;

-- Delegation Flow: end_on_behalf_of
-- End an on-behalf-of relationship for a principal.
DELETE acts_on_behalf_of
WHERE in = agent_identity:$from AND out = agent_identity:$to AND principal = $principal;
