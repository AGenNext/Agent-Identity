-- AGenNext Agent Identity Lifecycle Seed Data
-- Execute after surreal/schema/agent_identity.surql,
-- surreal/seeds/agent_identity.seed.surql, and surreal/schema/agent_lifecycle.surql.
-- Vocabulary grounded in "Identity Management for Agentic AI" (OpenID, Oct 2025).

-- Provision the seeded research agent into the lifecycle as "provisioned".
CREATE agent_lifecycle:research_agent SET
  identity = agent_identity:research_agent,
  state = "provisioned",
  owners = ["AGenNext"],
  entitlements = ["agent.identity", "agent.registry.read"],
  reason = "Initial provisioning via registry";

-- Activate the agent (provisioned -> active).
UPDATE agent_lifecycle:research_agent SET
  state = "active",
  previous_state = "provisioned",
  reason = "Activated for production operation";
