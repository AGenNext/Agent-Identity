-- Agent Identity SurrealDB Schema
-- Source of truth for AGenNext agent identities.
-- Supports both W3C DID-compatible metadata and OIDC-compatible agent identity metadata.

DEFINE TABLE agent_identity SCHEMAFULL;

DEFINE FIELD subject ON agent_identity TYPE string;
DEFINE FIELD did ON agent_identity TYPE option<string>;
DEFINE FIELD did_method ON agent_identity TYPE option<string>;
DEFINE FIELD did_controller ON agent_identity TYPE option<string>;
DEFINE FIELD did_document_url ON agent_identity TYPE option<string>;

DEFINE FIELD oidc_issuer ON agent_identity TYPE option<string>;
DEFINE FIELD oidc_subject ON agent_identity TYPE option<string>;
DEFINE FIELD oidc_audiences ON agent_identity TYPE array<string>;
DEFINE FIELD oidc_scopes ON agent_identity TYPE array<string>;

DEFINE FIELD claims ON agent_identity TYPE object;
DEFINE FIELD external_identity_provider ON agent_identity TYPE option<string>;
DEFINE FIELD external_identity_provider_ref ON agent_identity TYPE option<string>;

DEFINE FIELD issuer ON agent_identity TYPE option<record<identity_issuer>>;
DEFINE FIELD status ON agent_identity TYPE string DEFAULT "active";
DEFINE FIELD created_at ON agent_identity TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON agent_identity TYPE datetime DEFAULT time::now();

DEFINE INDEX agent_identity_subject_idx ON agent_identity COLUMNS subject UNIQUE;
DEFINE INDEX agent_identity_did_idx ON agent_identity COLUMNS did UNIQUE;
DEFINE INDEX agent_identity_oidc_subject_idx ON agent_identity COLUMNS oidc_issuer, oidc_subject UNIQUE;

DEFINE TABLE identity_issuer SCHEMAFULL;
DEFINE FIELD name ON identity_issuer TYPE string;
DEFINE FIELD issuer_uri ON identity_issuer TYPE string;
DEFINE FIELD did ON identity_issuer TYPE option<string>;
DEFINE FIELD jwks_uri ON identity_issuer TYPE option<string>;
DEFINE FIELD oidc_discovery_url ON identity_issuer TYPE option<string>;
DEFINE FIELD status ON identity_issuer TYPE string DEFAULT "active";
DEFINE FIELD created_at ON identity_issuer TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON identity_issuer TYPE datetime DEFAULT time::now();

DEFINE INDEX identity_issuer_uri_idx ON identity_issuer COLUMNS issuer_uri UNIQUE;

DEFINE TABLE identity_verification SCHEMAFULL;
DEFINE FIELD identity ON identity_verification TYPE record<agent_identity>;
DEFINE FIELD verifier ON identity_verification TYPE string;
DEFINE FIELD method ON identity_verification TYPE string;
DEFINE FIELD evidence_ref ON identity_verification TYPE option<string>;
DEFINE FIELD status ON identity_verification TYPE string DEFAULT "pending";
DEFINE FIELD verified_at ON identity_verification TYPE option<datetime>;
DEFINE FIELD created_at ON identity_verification TYPE datetime DEFAULT time::now();

DEFINE TABLE credential_subject SCHEMAFULL;
DEFINE FIELD identity ON credential_subject TYPE record<agent_identity>;
DEFINE FIELD subject_id ON credential_subject TYPE string;
DEFINE FIELD subject_type ON credential_subject TYPE string DEFAULT "agent";
DEFINE FIELD claims ON credential_subject TYPE object;
DEFINE FIELD created_at ON credential_subject TYPE datetime DEFAULT time::now();

DEFINE TABLE trust_domain SCHEMAFULL;
DEFINE FIELD name ON trust_domain TYPE string;
DEFINE FIELD description ON trust_domain TYPE option<string>;
DEFINE FIELD created_at ON trust_domain TYPE datetime DEFAULT time::now();

DEFINE TABLE issued_by TYPE RELATION IN agent_identity OUT identity_issuer SCHEMAFULL;
DEFINE FIELD issued_at ON issued_by TYPE datetime DEFAULT time::now();

DEFINE TABLE verified_by TYPE RELATION IN agent_identity OUT identity_verification SCHEMAFULL;
DEFINE FIELD linked_at ON verified_by TYPE datetime DEFAULT time::now();

DEFINE TABLE trusted_by TYPE RELATION IN agent_identity OUT trust_domain SCHEMAFULL;
DEFINE FIELD trust_level ON trusted_by TYPE option<string>;
DEFINE FIELD linked_at ON trusted_by TYPE datetime DEFAULT time::now();
