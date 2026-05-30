-- AGenNext Agent Identity Graph & Knowledge-Graph Seed Data
-- Execute after the schema files and the agent_identity + agent_lifecycle seeds.
-- Vocabulary grounded in the OpenID whitepaper (graph) and SailPoint/Okta/CyberArk
-- (knowledge graph). See vocabulary/agent-lifecycle.vocabulary.json.

-- A second agent to demonstrate delegation and on-behalf-of edges.
CREATE agent_identity:summary_agent SET
  subject = "agent:summary-agent",
  oidc_issuer = "https://identity.agennext.dev",
  oidc_subject = "agent:summary-agent",
  status = "active";

-- Graph layer (OpenID whitepaper Key Terms).
-- research_agent delegates a narrowed scope to summary_agent (Scope Attenuation).
RELATE agent_identity:research_agent->delegates_to->agent_identity:summary_agent
  SET scope = ["agent.registry.read"], attenuated = true;

-- research_agent acts on behalf of a human principal (On-Behalf-Of).
RELATE agent_identity:research_agent->acts_on_behalf_of->agent_identity:summary_agent
  SET principal = "user:alice", scope = ["research"];

-- research_agent operates in the seeded trust domain.
RELATE agent_identity:research_agent->operates_in->trust_domain:agennext_public_registry;

-- Knowledge graph (SailPoint IGA + Okta + CyberArk).
CREATE source:crm SET name = "CRM", type = "saas";
CREATE account:research_crm SET native_identity = "research-agent@crm";
CREATE entitlement:crm_read SET value = "crm:read", privileged = false;
CREATE access_profile:crm_reader SET name = "CRM Reader";
CREATE role:analyst SET name = "Analyst";
CREATE safe:crm_secrets SET name = "CRM-Secrets";
CREATE schema_attribute:agent_model SET
  title = "agent_model", type = "string", required = true, mutability = "READ_ONLY", master = "OKTA";

RELATE agent_identity:research_agent->holds_account->account:research_crm;
RELATE account:research_crm->account_on_source->source:crm;
RELATE account:research_crm->stored_in->safe:crm_secrets;
RELATE entitlement:crm_read->entitlement_on_source->source:crm;
RELATE access_profile:crm_reader->profile_grants->entitlement:crm_read;
RELATE role:analyst->role_includes->access_profile:crm_reader;
RELATE agent_identity:research_agent->assigned_access->access_profile:crm_reader;
RELATE agent_identity:research_agent->assigned_role->role:analyst;
RELATE agent_identity:research_agent->has_attribute->schema_attribute:agent_model;
