-- AGenNext Agent Identity
-- SurrealQL knowledge-graph layer for agent identity governance.
-- Source of truth: SurrealDB. Intended for execution through SurrealKit.
-- Execute after surreal/schema/agent_identity.surql and agent_graph.surql.
--
-- SOURCE GROUNDING
-- The governance knowledge graph is modelled on two documented IAM/IGA APIs:
--   * SailPoint Identity Security Cloud API v3 -- https://developer.sailpoint.com/docs/api/v3/
--     (Sources, Accounts, Identities, Entitlements, Access Profiles, Roles).
--   * Okta Management Schema API -- https://developer.okta.com/docs/api/openapi/okta-management/management/tags/schema
--     (attribute/schema property definitions: type, required, mutability, permissions, master).
--   * CyberArk API -- https://api-docs.cyberark.com/
--     (Privileged Access Management: Safes that hold privileged accounts/credentials).
-- The lifecycle vocabulary that ties this together remains grounded in the OpenID
-- "Identity Management for Agentic AI" whitepaper (§2.9 SCIM, §2.12 IGA).
-- Every node/edge name is annotated with its source.
--
-- JSON-LD REFERENCE: every node and edge below is a term in
-- vocabulary/agent-lifecycle.context.jsonld (the reference graph model).
--
-- DESIGN NOTE: only SurrealDB out-of-the-box features (DEFINE TABLE / RELATION /
-- DEFINE FIELD / RELATE) are used.

-- ---------------------------------------------------------------------------
-- Nodes (SailPoint IGA model)
-- ---------------------------------------------------------------------------

-- "source": a connected system where accounts live. SailPoint v3 Sources.
DEFINE TABLE source SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD name ON TABLE source TYPE string;
DEFINE FIELD type ON TABLE source TYPE option<string>;
DEFINE FIELD created_at ON TABLE source TYPE datetime DEFAULT time::now();
DEFINE INDEX source_name_idx ON TABLE source COLUMNS name UNIQUE;

-- "account": a login record on a source. SailPoint v3 Accounts.
DEFINE TABLE account SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD native_identity ON TABLE account TYPE string;
DEFINE FIELD created_at ON TABLE account TYPE datetime DEFAULT time::now();

-- "entitlement": the finest-grained unit of access on a source. SailPoint v3 Entitlements.
DEFINE TABLE entitlement SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD value ON TABLE entitlement TYPE string;
DEFINE FIELD privileged ON TABLE entitlement TYPE bool DEFAULT false;
DEFINE FIELD created_at ON TABLE entitlement TYPE datetime DEFAULT time::now();

-- "access_profile": a bundle of entitlements granted together. SailPoint v3 Access Profiles.
DEFINE TABLE access_profile SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD name ON TABLE access_profile TYPE string;
DEFINE FIELD created_at ON TABLE access_profile TYPE datetime DEFAULT time::now();
DEFINE INDEX access_profile_name_idx ON TABLE access_profile COLUMNS name UNIQUE;

-- "role": a bundle of access profiles for a job function. SailPoint v3 Roles.
DEFINE TABLE role SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD name ON TABLE role TYPE string;
DEFINE FIELD created_at ON TABLE role TYPE datetime DEFAULT time::now();
DEFINE INDEX role_name_idx ON TABLE role COLUMNS name UNIQUE;

-- "safe": a container that holds privileged accounts/credentials. CyberArk Safes (PAM).
DEFINE TABLE safe SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD name ON TABLE safe TYPE string;
DEFINE FIELD created_at ON TABLE safe TYPE datetime DEFAULT time::now();
DEFINE INDEX safe_name_idx ON TABLE safe COLUMNS name UNIQUE;

-- "schema_attribute": a governed attribute definition. Okta Schema property fields.
DEFINE TABLE schema_attribute SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD title ON TABLE schema_attribute TYPE string;
-- Okta property fields:
DEFINE FIELD type ON TABLE schema_attribute TYPE string
  ASSERT $value IN ["string", "integer", "number", "boolean", "array"];
DEFINE FIELD required ON TABLE schema_attribute TYPE bool DEFAULT false;
DEFINE FIELD mutability ON TABLE schema_attribute TYPE option<string>;
DEFINE FIELD permissions ON TABLE schema_attribute TYPE option<string>;
DEFINE FIELD master ON TABLE schema_attribute TYPE option<string>;
DEFINE FIELD created_at ON TABLE schema_attribute TYPE datetime DEFAULT time::now();

-- ---------------------------------------------------------------------------
-- Edges (the knowledge graph). Directed RELATION tables.
-- ---------------------------------------------------------------------------

-- An agent identity holds an account. (SailPoint: identities own accounts.)
DEFINE TABLE holds_account TYPE RELATION IN agent_identity OUT account SCHEMAFULL PERMISSIONS NONE;
-- An account lives on a source.
DEFINE TABLE account_on_source TYPE RELATION IN account OUT source SCHEMAFULL PERMISSIONS NONE;
-- A privileged account is stored in a safe. (CyberArk PAM.)
DEFINE TABLE stored_in TYPE RELATION IN account OUT safe SCHEMAFULL PERMISSIONS NONE;
-- An entitlement is defined on a source.
DEFINE TABLE entitlement_on_source TYPE RELATION IN entitlement OUT source SCHEMAFULL PERMISSIONS NONE;
-- An access profile grants entitlements.
DEFINE TABLE profile_grants TYPE RELATION IN access_profile OUT entitlement SCHEMAFULL PERMISSIONS NONE;
-- A role includes access profiles.
DEFINE TABLE role_includes TYPE RELATION IN role OUT access_profile SCHEMAFULL PERMISSIONS NONE;
-- An agent identity is assigned an access profile. (SailPoint Access Request / assignment.)
DEFINE TABLE assigned_access TYPE RELATION IN agent_identity OUT access_profile SCHEMAFULL PERMISSIONS NONE;
-- An agent identity is assigned a role.
DEFINE TABLE assigned_role TYPE RELATION IN agent_identity OUT role SCHEMAFULL PERMISSIONS NONE;
-- An agent identity has a governed attribute. (Okta schema property.)
DEFINE TABLE has_attribute TYPE RELATION IN agent_identity OUT schema_attribute SCHEMAFULL PERMISSIONS NONE;
