-- AGenNext Agent Identity
-- Trust-domain flows. trust_domain is defined in surreal/schema/agent_identity.surql;
-- the operates_in edge is defined in surreal/schema/agent_graph.surql.
-- Grounded in the OpenID whitepaper Key Term "Trust Domain".

-- Trust Domain Flow: create_trust_domain
CREATE trust_domain CONTENT { name: $name, description: $description };

-- Trust Domain Flow: operate_in
-- Record that an agent operates within a trust domain (it may operate in several).
RELATE agent_identity:$identity->operates_in->trust_domain:$trust_domain;

-- Trust Domain Flow: leave_trust_domain
DELETE operates_in
WHERE in = agent_identity:$identity AND out = trust_domain:$trust_domain;

-- Trust Domain Flow: list_agents_in_domain
SELECT <-operates_in<-agent_identity.subject AS agents
FROM trust_domain:$trust_domain;
