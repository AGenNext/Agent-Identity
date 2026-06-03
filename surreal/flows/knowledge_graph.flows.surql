-- AGenNext Agent Identity
-- Knowledge-graph flows (SailPoint IGA + Okta + CyberArk). Execute against
-- surreal/schema/agent_knowledge_graph.surql. All node/edge names are grounded
-- in vocabulary/agent-lifecycle.vocabulary.json.

-- ---- Node create flows ----

-- KG Flow: create_source  (SailPoint Sources)
CREATE source CONTENT { name: $name, type: $type };

-- KG Flow: create_account  (SailPoint Accounts)
CREATE account CONTENT { native_identity: $native_identity };

-- KG Flow: create_entitlement  (SailPoint Entitlements)
CREATE entitlement CONTENT { value: $value, privileged: $privileged };

-- KG Flow: create_access_profile  (SailPoint Access Profiles)
CREATE access_profile CONTENT { name: $name };

-- KG Flow: create_role  (SailPoint Roles)
CREATE role CONTENT { name: $name };

-- KG Flow: create_safe  (CyberArk Safes)
CREATE safe CONTENT { name: $name };

-- KG Flow: create_schema_attribute  (Okta Schema property)
CREATE schema_attribute CONTENT {
  title: $title, type: $type, required: $required,
  mutability: $mutability, permissions: $permissions, master: $master
};

-- ---- Edge link flows ----

-- KG Flow: link_holds_account            agent -> account
RELATE agent_identity:$identity->holds_account->account:$account;

-- KG Flow: link_account_on_source         account -> source
RELATE account:$account->account_on_source->source:$source;

-- KG Flow: link_stored_in                 account -> safe (CyberArk)
RELATE account:$account->stored_in->safe:$safe;

-- KG Flow: link_entitlement_on_source     entitlement -> source
RELATE entitlement:$entitlement->entitlement_on_source->source:$source;

-- KG Flow: link_profile_grants            access_profile -> entitlement
RELATE access_profile:$access_profile->profile_grants->entitlement:$entitlement;

-- KG Flow: link_role_includes             role -> access_profile
RELATE role:$role->role_includes->access_profile:$access_profile;

-- KG Flow: assign_access                  agent -> access_profile
RELATE agent_identity:$identity->assigned_access->access_profile:$access_profile;

-- KG Flow: assign_role                    agent -> role
RELATE agent_identity:$identity->assigned_role->role:$role;

-- KG Flow: attach_attribute               agent -> schema_attribute
RELATE agent_identity:$identity->has_attribute->schema_attribute:$schema_attribute;

-- ---- Revoke (unlink) flows ----

-- KG Flow: revoke_access
DELETE assigned_access
WHERE in = agent_identity:$identity AND out = access_profile:$access_profile;

-- KG Flow: revoke_role
DELETE assigned_role
WHERE in = agent_identity:$identity AND out = role:$role;
