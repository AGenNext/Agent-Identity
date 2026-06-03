-- AGenNext Agent Identity
-- SurrealQL schema intended for execution through SurrealKit.
-- Source of truth: SurrealDB.
-- Identity support: W3C DID-compatible fields + OIDC-compatible agent identity fields.

DEFINE TABLE agent_identity SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD subject ON TABLE agent_identity TYPE string
  ASSERT string::len($value) > 0;

-- W3C DID-compatible identity metadata.
DEFINE FIELD did ON TABLE agent_identity TYPE option<string>;
DEFINE FIELD did_method ON TABLE agent_identity TYPE option<string>;
DEFINE FIELD did_controller ON TABLE agent_identity TYPE option<string>;
DEFINE FIELD did_document_url ON TABLE agent_identity TYPE option<string>;

-- OIDC-compatible agent identity metadata.
DEFINE FIELD oidc_issuer ON TABLE agent_identity TYPE option<string>;
DEFINE FIELD oidc_subject ON TABLE agent_identity TYPE option<string>;
DEFINE FIELD oidc_audiences ON TABLE agent_identity TYPE array<string> DEFAULT [];
DEFINE FIELD oidc_scopes ON TABLE agent_identity TYPE array<string> DEFAULT [];

-- Claims and future provider metadata. Provider is optional; no Walt.id dependency.
DEFINE FIELD claims ON TABLE agent_identity TYPE object DEFAULT {};
DEFINE FIELD external_identity_provider ON TABLE agent_identity TYPE option<string>;
DEFINE FIELD external_identity_provider_ref ON TABLE agent_identity TYPE option<string>;

DEFINE FIELD issuer ON TABLE agent_identity TYPE option<record<identity_issuer>>;
DEFINE FIELD status ON TABLE agent_identity TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "suspended", "revoked"];

DEFINE FIELD created_at ON TABLE agent_identity TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE agent_identity TYPE datetime DEFAULT time::now();

DEFINE INDEX agent_identity_subject_idx ON TABLE agent_identity COLUMNS subject UNIQUE;
DEFINE INDEX agent_identity_did_idx ON TABLE agent_identity COLUMNS did UNIQUE;
DEFINE INDEX agent_identity_oidc_subject_idx ON TABLE agent_identity COLUMNS oidc_issuer, oidc_subject UNIQUE;

DEFINE TABLE identity_issuer SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD name ON TABLE identity_issuer TYPE string
  ASSERT string::len($value) > 0;
DEFINE FIELD issuer_uri ON TABLE identity_issuer TYPE string
  ASSERT string::len($value) > 0;
DEFINE FIELD did ON TABLE identity_issuer TYPE option<string>;
DEFINE FIELD jwks_uri ON TABLE identity_issuer TYPE option<string>;
DEFINE FIELD oidc_discovery_url ON TABLE identity_issuer TYPE option<string>;
DEFINE FIELD status ON TABLE identity_issuer TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "suspended", "revoked"];
DEFINE FIELD created_at ON TABLE identity_issuer TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE identity_issuer TYPE datetime DEFAULT time::now();

DEFINE INDEX identity_issuer_uri_idx ON TABLE identity_issuer COLUMNS issuer_uri UNIQUE;
DEFINE INDEX identity_issuer_did_idx ON TABLE identity_issuer COLUMNS did UNIQUE;

DEFINE TABLE identity_verification SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE identity_verification TYPE record<agent_identity>;
DEFINE FIELD verifier ON TABLE identity_verification TYPE string;
DEFINE FIELD method ON TABLE identity_verification TYPE string
  ASSERT $value IN ["did", "oidc", "vc", "spiffe", "manual", "registry"];
DEFINE FIELD evidence_ref ON TABLE identity_verification TYPE option<string>;
DEFINE FIELD status ON TABLE identity_verification TYPE string DEFAULT "pending"
  ASSERT $value IN ["pending", "verified", "failed", "revoked"];
DEFINE FIELD verified_at ON TABLE identity_verification TYPE option<datetime>;
DEFINE FIELD created_at ON TABLE identity_verification TYPE datetime DEFAULT time::now();

DEFINE TABLE credential_subject SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE credential_subject TYPE record<agent_identity>;
DEFINE FIELD subject_id ON TABLE credential_subject TYPE string;
DEFINE FIELD subject_type ON TABLE credential_subject TYPE string DEFAULT "agent";
DEFINE FIELD claims ON TABLE credential_subject TYPE object DEFAULT {};
DEFINE FIELD created_at ON TABLE credential_subject TYPE datetime DEFAULT time::now();

DEFINE INDEX credential_subject_id_idx ON TABLE credential_subject COLUMNS subject_id UNIQUE;

DEFINE TABLE trust_domain SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD name ON TABLE trust_domain TYPE string;
DEFINE FIELD description ON TABLE trust_domain TYPE option<string>;
DEFINE FIELD created_at ON TABLE trust_domain TYPE datetime DEFAULT time::now();

DEFINE INDEX trust_domain_name_idx ON TABLE trust_domain COLUMNS name UNIQUE;

DEFINE TABLE issued_by TYPE RELATION IN agent_identity OUT identity_issuer SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD issued_at ON TABLE issued_by TYPE datetime DEFAULT time::now();

DEFINE TABLE verified_by TYPE RELATION IN agent_identity OUT identity_verification SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD linked_at ON TABLE verified_by TYPE datetime DEFAULT time::now();

DEFINE TABLE trusted_by TYPE RELATION IN agent_identity OUT trust_domain SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD trust_level ON TABLE trusted_by TYPE option<string>;
DEFINE FIELD linked_at ON TABLE trusted_by TYPE datetime DEFAULT time::now();
