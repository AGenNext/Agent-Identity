-- AGenNext Agent Identity Seed Data
-- Execute after surreal/schema/agent_identity.surql

CREATE identity_issuer:agennext SET
  name = "AGenNext Identity",
  issuer_uri = "https://identity.agennext.dev",
  did = "did:web:identity.agennext.dev",
  jwks_uri = "https://identity.agennext.dev/.well-known/jwks.json",
  oidc_discovery_url = "https://identity.agennext.dev/.well-known/openid-configuration",
  status = "active";

CREATE agent_identity:research_agent SET
  subject = "agent:research-agent",
  did = "did:web:agents.agennext.dev:research-agent",
  did_method = "web",
  did_controller = "did:web:agennext.dev",
  did_document_url = "https://agents.agennext.dev/research-agent/did.json",
  oidc_issuer = "https://identity.agennext.dev",
  oidc_subject = "agent:research-agent",
  oidc_audiences = ["agennext-registry", "agennext-runtime"],
  oidc_scopes = ["agent.identity", "agent.registry.read"],
  claims = {
    agent_id: "research-agent",
    owner: "AGenNext",
    capabilities: ["research", "summarization"]
  },
  external_identity_provider = "none",
  issuer = identity_issuer:agennext,
  status = "active";

CREATE credential_subject:research_agent SET
  identity = agent_identity:research_agent,
  subject_id = "agent:research-agent",
  subject_type = "agent",
  claims = {
    agent_id: "research-agent",
    did: "did:web:agents.agennext.dev:research-agent",
    oidc_subject: "agent:research-agent"
  };

CREATE identity_verification:research_agent_registry SET
  identity = agent_identity:research_agent,
  verifier = "registry:agennext",
  method = "registry",
  evidence_ref = "registry_credential:research_agent",
  status = "verified",
  verified_at = time::now();

CREATE trust_domain:agennext_public_registry SET
  name = "AGenNext Public Registry",
  description = "Default trust domain for public AGenNext registry identities";

RELATE agent_identity:research_agent->issued_by->identity_issuer:agennext;
RELATE agent_identity:research_agent->verified_by->identity_verification:research_agent_registry;
RELATE agent_identity:research_agent->trusted_by->trust_domain:agennext_public_registry SET trust_level = "registry_verified";
