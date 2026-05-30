-- ============================================================================
-- Agent Identity and Lifecycle Management System - SurrealQL
-- ============================================================================
-- Based on: OpenID Foundation "Identity Management for Agentic AI" (2025)
-- Database: SurrealDB with SurrealQL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- NAMESPACE & DATABASE SETUP
-- ----------------------------------------------------------------------------

-- Create namespace for agent identity system
DEFINE NAMESPACE IF NOT EXISTS agentic_ai;

-- Create database
USE NS agentic_ai;
USE DB agentic_ai;

-- ----------------------------------------------------------------------------
-- ENUMS / TYPES (Using constants for enum-like behavior in SurrealQL)
-- ----------------------------------------------------------------------------

-- Agent Types
DEFINE PARAM $AGENT_TYPE_AUTONOMOUS = "autonomous";
DEFINE PARAM $AGENT_TYPE_ASSISTANT = "assistant";
DEFINE PARAM $AGENT_TYPE_TOOL = "tool";
DEFINE PARAM $AGENT_TYPE_HYBRID = "hybrid";

-- Lifecycle States
DEFINE PARAM $STATE_CREATED = "created";
DEFINE PARAM $STATE_PROVISIONED = "provisioned";
DEFINE PARAM $STATE_ACTIVE = "active";
DEFINE PARAM $STATE_SUSPENDED = "suspended";
DEFINE PARAM $STATE_REVOKED = "revoked";
DEFINE PARAM $STATE_DELETED = "deleted";

-- Audit Event Types
DEFINE PARAM $AUDIT_AGENT_REGISTERED = "agent_registered";
DEFINE PARAM $AUDIT_AGENT_PROVISIONED = "agent_provisioned";
DEFINE PARAM $AUDIT_AGENT_ACTIVATED = "agent_activated";
DEFINE PARAM $AUDIT_AGENT_SUSPENDED = "agent_suspended";
DEFINE PARAM $AUDIT_AGENT_RESUMED = "agent_resumed";
DEFINE PARAM $AUDIT_AGENT_REVOKED = "agent_revoked";
DEFINE PARAM $AUDIT_AGENT_DELETED = "agent_deleted";
DEFINE PARAM $AUDIT_TOKEN_ISSUED = "token_issued";
DEFINE PARAM $AUDIT_TOKEN_REFRESHED = "token_refreshed";
DEFINE PARAM $AUDIT_TOKEN_REVOKED = "token_revoked";
DEFINE PARAM $AUDIT_DELEGATION_CREATED = "delegation_created";
DEFINE PARAM $AUDIT_DELEGATION_ATENUATED = "delegation_attenuated";

-- ----------------------------------------------------------------------------
-- TABLE: agents
-- ----------------------------------------------------------------------------
-- Main table for storing agent identities and state

DEFINE TABLE agents SCHEMAFULL;

DEFINE FIELD id ON agents TYPE string;
DEFINE FIELD name ON agents TYPE string;
DEFINE FIELD agent_type ON agents TYPE string;
DEFINE FIELD provider ON agents TYPE string;
DEFINE FIELD model ON agents TYPE string;
DEFINE FIELD version ON agents TYPE string;
DEFINE FIELD owner_id ON agents TYPE string;
DEFINE FIELD capabilities ON agents TYPE array;
DEFINE FIELD description ON agents TYPE option<string>;
DEFINE FIELD created_at ON agents TYPE datetime;
DEFINE FIELD trust_level ON agents TYPE string;
DEFINE FIELD metadata ON agents TYPE object;
DEFINE FIELD lifecycle_state ON agents TYPE string;
DEFINE FIELD current_scopes ON agents TYPE array;
DEFINE FIELD workload_identity ON agents TYPE option<record>;
DEFINE FIELD last_active_at ON agents TYPE option<datetime>;
DEFINE FIELD suspended_at ON agents TYPE option<datetime>;
DEFINE FIELD deleted_at ON agents TYPE option<datetime>;

-- Indexes for common queries
DEFINE INDEX agents_id ON agents FIELDS id UNIQUE;
DEFINE INDEX agents_owner ON agents FIELDS owner_id;
DEFINE INDEX agents_state ON agents FIELDS lifecycle_state;
DEFINE INDEX agents_type ON agents FIELDS agent_type;

-- ----------------------------------------------------------------------------
-- TABLE: workload_identities
-- ----------------------------------------------------------------------------
-- SPIFFE-style workload identities for agents

DEFINE TABLE workload_identities SCHEMAFULL;

DEFINE FIELD id ON workload_identities TYPE string;
DEFINE FIELD spiffe_id ON workload_identities TYPE string;
DEFINE FIELD agent_id ON workload_identities TYPE string;
DEFINE FIELD public_key ON workload_identities TYPE string;
DEFINE FIELD issued_at ON workload_identities TYPE datetime;
DEFINE FIELD expires_at ON workload_identities TYPE datetime;
DEFINE FIELD revoked ON workload_identities TYPE bool;
DEFINE FIELD created_at ON workload_identities TYPE datetime;

DEFINE INDEX wi_spiffe ON workload_identities FIELDS spiffe_id UNIQUE;
DEFINE INDEX wi_agent ON workload_identities FIELDS agent_id;
DEFINE INDEX wi_expires ON workload_identities FIELDS expires_at;

-- ----------------------------------------------------------------------------
-- TABLE: delegation_tokens
-- ----------------------------------------------------------------------------
-- Tokens for delegation chains with scope attenuation

DEFINE TABLE delegation_tokens SCHEMAFULL;

DEFINE FIELD id ON delegation_tokens TYPE string;
DEFINE FIELD issuer_id ON delegation_tokens TYPE string;
DEFINE FIELD holder_id ON delegation_tokens TYPE string;
DEFINE FIELD issued_at ON delegation_tokens TYPE datetime;
DEFINE FIELD expires_at ON delegation_tokens TYPE datetime;
DEFINE FIELD scope ON delegation_tokens TYPE array;
DEFINE FIELD max_executions ON delegation_tokens TYPE option<int>;
DEFINE FIELD max_duration_seconds ON delegation_tokens TYPE option<int>;
DEFINE FIELD allowed_resources ON delegation_tokens TYPE option<array>;
DEFINE FIELD denied_resources ON delegation_tokens TYPE option<array>;
DEFINE FIELD parent_token_id ON delegation_tokens TYPE option<string>;
DEFINE FIELD revoked ON delegation_tokens TYPE bool;
DEFINE FIELD execution_count ON delegation_tokens TYPE int;
DEFINE FIELD agent_id ON delegation_tokens TYPE string;

DEFINE INDEX dt_id ON delegation_tokens FIELDS id UNIQUE;
DEFINE INDEX dt_issuer ON delegation_tokens FIELDS issuer_id;
DEFINE INDEX dt_holder ON delegation_tokens FIELDS holder_id;
DEFINE INDEX dt_parent ON delegation_tokens FIELDS parent_token_id;
DEFINE INDEX dt_expires ON delegation_tokens FIELDS expires_at;

-- ----------------------------------------------------------------------------
-- TABLE: audit_events
-- ----------------------------------------------------------------------------
-- Complete audit trail for compliance and governance

DEFINE TABLE audit_events SCHEMAFULL;

DEFINE FIELD id ON audit_events TYPE string;
DEFINE FIELD timestamp ON audit_events TYPE datetime;
DEFINE FIELD event_type ON audit_events TYPE string;
DEFINE FIELD agent_id ON audit_events TYPE option<string>;
DEFINE FIELD actor_id ON audit_events TYPE option<string>;
DEFINE FIELD details ON audit_events TYPE object;
DEFINE FIELD ip_address ON audit_events TYPE option<string>;
DEFINE FIELD user_agent ON audit_events TYPE option<string>;

DEFINE INDEX ae_agent ON audit_events FIELDS agent_id;
DEFINE INDEX ae_type ON audit_events FIELDS event_type;
DEFINE INDEX ae_timestamp ON audit_events FIELDS timestamp;
DEFINE INDEX ae_actor ON audit_events FIELDS actor_id;

-- ----------------------------------------------------------------------------
-- TABLE: scopes
-- ----------------------------------------------------------------------------
-- Available scopes for agents

DEFINE TABLE scopes SCHEMAFULL;

DEFINE FIELD id ON scopes TYPE string;
DEFINE FIELD name ON scopes TYPE string;
DEFINE FIELD description ON scopes TYPE string;
DEFINE FIELD risk_level ON scopes TYPE string;
DEFINE FIELD created_at ON scopes TYPE datetime;

DEFINE INDEX scope_name ON scopes FIELDS name UNIQUE;

-- ----------------------------------------------------------------------------
-- INSERT: Default Scopes
-- ----------------------------------------------------------------------------

INSERT INTO scopes [
    {
        id: "scope_read",
        name: "read",
        description: "Read access to resources",
        risk_level: "low",
        created_at: time::now()
    },
    {
        id: "scope_write",
        name: "write",
        description: "Write access to resources",
        risk_level: "medium",
        created_at: time::now()
    },
    {
        id: "scope_delete",
        name: "delete",
        description: "Delete resources",
        risk_level: "high",
        created_at: time::now()
    },
    {
        id: "scope_execute",
        name: "execute",
        description: "Execute actions",
        risk_level: "high",
        created_at: time::now()
    },
    {
        id: "scope_admin",
        name: "admin",
        description: "Administrative access",
        risk_level: "critical",
        created_at: time::now()
    },
    {
        id: "scope_code_generation",
        name: "code_generation",
        description: "Generate code",
        risk_level: "medium",
        created_at: time::now()
    },
    {
        id: "scope_code_review",
        name: "code_review",
        description: "Review code changes",
        risk_level: "low",
        created_at: time::now()
    },
    {
        id: "scope_git_operations",
        name: "git_operations",
        description: "Git operations",
        risk_level: "medium",
        created_at: time::now()
    },
    {
        id: "scope_web_search",
        name: "web_search",
        description: "Web search capability",
        risk_level: "low",
        created_at: time::now()
    },
    {
        id: "scope_file_read",
        name: "file_read",
        description: "Read files",
        risk_level: "low",
        created_at: time::now()
    },
    {
        id: "scope_file_write",
        name: "file_write",
        description: "Write files",
        risk_level: "medium",
        created_at: time::now()
    },
    {
        id: "scope_terminal_execute",
        name: "terminal_execute",
        description: "Execute terminal commands",
        risk_level: "high",
        created_at: time::now()
    },
    {
        id: "scope_api_call",
        name: "api_call",
        description: "Make API calls",
        risk_level: "medium",
        created_at: time::now()
    },
    {
        id: "scope_mcp_tool_use",
        name: "mcp_tool_use",
        description: "Use MCP tools",
        risk_level: "medium",
        created_at: time::now()
    }
] RETURN id, name;

-- ----------------------------------------------------------------------------
-- FUNCTIONS: Lifecycle Management
-- ----------------------------------------------------------------------------

-- Create a new agent (CREATED state)
CREATE FUNCTION create_agent(
    name: string,
    agent_type: string,
    owner_id: string,
    capabilities: array,
    provider: string,
    model: string,
    version: string,
    description: option<string>,
    trust_level: string,
    metadata: object
) {
    -- Generate unique ID
    LET $agent_id = string::uuid();
    LET $now = time::now();
    
    -- Create the agent
    CREATE agents CONTENT {
        id: $agent_id,
        name: name,
        agent_type: agent_type,
        provider: provider,
        model: model,
        version: version,
        owner_id: owner_id,
        capabilities: capabilities,
        description: description,
        created_at: $now,
        trust_level: trust_level,
        metadata: metadata,
        lifecycle_state: "created",
        current_scopes: capabilities
    };
    
    -- Log audit event
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_registered",
        agent_id: $agent_id,
        actor_id: owner_id,
        details: {
            name: name,
            agent_type: agent_type,
            capabilities: capabilities
        }
    };
    
    RETURN (SELECT * FROM agents WHERE id = $agent_id LIMIT 1)[0];
};

-- Provision agent (CREATED -> PROVISIONED)
CREATE FUNCTION provision_agent(agent_id: string, identity_ttl_days: int) {
    LET $now = time::now();
    LET $expires = $now + (identity_ttl_days * 86400000); -- Convert days to milliseconds
    LET $spiffe_id = "spiffe://agentic-ai.org/agent/" + agent_id;
    
    -- Generate key pair (simplified - use crypto in production)
    LET $private_key = crypto::sha256::hash(string::uuid());
    LET $public_key = crypto::sha256::hash(string::uuid());
    
    -- Create workload identity
    CREATE workload_identities CONTENT {
        id: string::uuid(),
        spiffe_id: $spiffe_id,
        agent_id: agent_id,
        public_key: $public_key,
        issued_at: $now,
        expires_at: $expires,
        revoked: false,
        created_at: $now
    };
    
    -- Update agent state
    UPDATE agents SET 
        lifecycle_state = "provisioned",
        workload_identity = $spiffe_id,
        current_scopes = capabilities
    WHERE id = agent_id;
    
    -- Log audit event
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_provisioned",
        agent_id: agent_id,
        details: {
            spiffe_id: $spiffe_id,
            expires_at: $expires
        }
    };
    
    RETURN (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
};

-- Activate agent (PROVISIONED -> ACTIVE)
CREATE FUNCTION activate_agent(agent_id: string) {
    LET $now = time::now();
    
    UPDATE agents SET 
        lifecycle_state = "active",
        last_active_at: $now
    WHERE id = agent_id;
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_activated",
        agent_id: agent_id,
        details: {}
    };
    
    RETURN (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
};

-- Suspend agent (ACTIVE -> SUSPENDED)
CREATE FUNCTION suspend_agent(agent_id: string, reason: string) {
    LET $now = time::now();
    
    -- Revoke all active tokens
    FOR $token IN (SELECT id FROM delegation_tokens WHERE agent_id = agent_id AND revoked = false) {
        UPDATE delegation_tokens SET revoked = true WHERE id = id;
    };
    
    UPDATE agents SET 
        lifecycle_state = "suspended",
        suspended_at: $now
    WHERE id = agent_id;
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_suspended",
        agent_id: agent_id,
        details: { reason: reason }
    };
    
    RETURN (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
};

-- Resume agent (SUSPENDED -> ACTIVE)
CREATE FUNCTION resume_agent(agent_id: string) {
    LET $now = time::now();
    
    UPDATE agents SET 
        lifecycle_state = "active",
        last_active_at: $now
    WHERE id = agent_id;
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_resumed",
        agent_id: agent_id,
        details: {}
    };
    
    RETURN (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
};

-- Revoke agent credentials
CREATE FUNCTION revoke_agent(agent_id: string, reason: string) {
    LET $now = time::now();
    
    -- Revoke workload identity
    UPDATE workload_identities SET revoked = true WHERE agent_id = agent_id;
    
    -- Revoke all tokens
    FOR $token IN (SELECT id FROM delegation_tokens WHERE agent_id = agent_id) {
        UPDATE delegation_tokens SET revoked = true WHERE id = id;
    };
    
    UPDATE agents SET lifecycle_state = "revoked" WHERE id = agent_id;
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_revoked",
        agent_id: agent_id,
        details: { reason: reason }
    };
    
    RETURN (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
};

-- De-provision agent (complete removal)
CREATE FUNCTION deprovision_agent(agent_id: string, reason: string) {
    LET $now = time::now();
    
    -- Revoke workload identity
    UPDATE workload_identities SET revoked = true WHERE agent_id = agent_id;
    
    -- Revoke all tokens
    FOR $token IN (SELECT id FROM delegation_tokens WHERE agent_id = agent_id) {
        UPDATE delegation_tokens SET revoked = true WHERE id = id;
    };
    
    UPDATE agents SET 
        lifecycle_state = "deleted",
        deleted_at: $now
    WHERE id = agent_id;
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "agent_deleted",
        agent_id: agent_id,
        details: { reason: reason }
    };
};

-- ----------------------------------------------------------------------------
-- FUNCTIONS: Delegation Management
-- ----------------------------------------------------------------------------

-- Create delegation (On-Behalf-Of)
CREATE FUNCTION delegate_to_agent(
    delegator_id: string,
    delegatee_id: string,
    scope: array,
    max_executions: option<int>,
    max_duration_seconds: option<int>,
    allowed_resources: option<array>,
    denied_resources: option<array>,
    ttl_minutes: int
) {
    LET $now = time::now();
    LET $expires = $now + (ttl_minutes * 60000);
    LET $token_id = string::uuid();
    
    -- Get delegator to validate state
    LET $delegator = (SELECT * FROM agents WHERE id = delegator_id LIMIT 1)[0];
    
    -- Validate delegator is active
    IF $delegator.lifecycle_state != "active" {
        THROW "Delegator must be ACTIVE";
    };
    
    -- Attenuate scope: only include scopes the delegator has
    LET $valid_scopes = scope FILTER $s IN $delegator.current_scopes;
    
    IF array::len($valid_scopes) == 0 {
        THROW "Requested scope contains permissions not held by delegator";
    };
    
    -- Create delegation token
    CREATE delegation_tokens CONTENT {
        id: $token_id,
        issuer_id: delegator_id,
        holder_id: delegatee_id,
        issued_at: $now,
        expires_at: $expires,
        scope: $valid_scopes,
        max_executions: max_executions,
        max_duration_seconds: max_duration_seconds,
        allowed_resources: allowed_resources,
        denied_resources: denied_resources,
        parent_token_id: NONE,
        revoked: false,
        execution_count: 0,
        agent_id: delegatee_id
    };
    
    -- Log audit event
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "delegation_created",
        agent_id: delegator_id,
        actor_id: delegator_id,
        details: {
            token_id: $token_id,
            delegatee_id: delegatee_id,
            scope: $valid_scopes
        }
    };
    
    RETURN (SELECT * FROM delegation_tokens WHERE id = $token_id LIMIT 1)[0];
};

-- Attenuate scope (create down-scoped token)
CREATE FUNCTION attenuate_scope(
    token_id: string,
    new_scope: array,
    max_executions: option<int>,
    ttl_minutes: int
) {
    LET $now = time::now();
    LET $expires = $now + (ttl_minutes * 60000);
    LET $new_token_id = string::uuid();
    
    -- Get parent token
    LET $parent = (SELECT * FROM delegation_tokens WHERE id = token_id LIMIT 1)[0];
    
    IF !$parent OR $parent.revoked {
        THROW "Parent token is invalid or revoked";
    };
    
    IF time::now() > $parent.expires_at {
        THROW "Parent token has expired";
    };
    
    -- Attenuate scope
    LET $valid_scopes = new_scope FILTER $s IN $parent.scope;
    
    IF array::len($valid_scopes) == 0 {
        THROW "Attenuated scope must be subset of parent scope";
    };
    
    -- Create attenuated token
    CREATE delegation_tokens CONTENT {
        id: $new_token_id,
        issuer_id: $parent.holder_id,
        holder_id: $parent.holder_id,
        issued_at: $now,
        expires_at: $expires,
        scope: $valid_scopes,
        max_executions: max_executions,
        max_duration_seconds: $parent.max_duration_seconds,
        allowed_resources: $parent.allowed_resources,
        denied_resources: $parent.denied_resources,
        parent_token_id: token_id,
        revoked: false,
        execution_count: 0,
        agent_id: $parent.agent_id
    };
    
    -- Log audit event
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "delegation_attenuated",
        agent_id: $parent.agent_id,
        details: {
            parent_token_id: token_id,
            new_token_id: $new_token_id,
            scope: $valid_scopes
        }
    };
    
    RETURN (SELECT * FROM delegation_tokens WHERE id = $new_token_id LIMIT 1)[0];
};

-- Verify delegation chain
CREATE FUNCTION verify_delegation_chain(token_id: string) {
    LET $visited = [];
    LET $current_id = token_id;
    
    WHILE $current_id != NONE {
        -- Check for cycles
        IF $current_id IN $visited {
            RETURN false;
        };
        
        SET $visited = array::combine($visited, [$current_id]);
        
        -- Get token
        LET $token = (SELECT * FROM delegation_tokens WHERE id = $current_id LIMIT 1)[0];
        
        IF !$token {
            RETURN false;
        };
        
        IF $token.revoked OR time::now() > $token.expires_at {
            RETURN false;
        };
        
        SET $current_id = $token.parent_token_id;
    };
    
    RETURN true;
};

-- ----------------------------------------------------------------------------
-- FUNCTIONS: Token Management
-- ----------------------------------------------------------------------------

-- Issue access token
CREATE FUNCTION issue_token(
    agent_id: string,
    scope: array,
    ttl_minutes: int
) {
    LET $now = time::now();
    LET $expires = $now + (ttl_minutes * 60000);
    LET $token_id = string::uuid();
    
    -- Get agent
    LET $agent = (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
    
    IF $agent.lifecycle_state NOT IN ["active", "provisioned"] {
        THROW "Agent must be ACTIVE or PROVISIONED";
    };
    
    CREATE delegation_tokens CONTENT {
        id: $token_id,
        issuer_id: agent_id,
        holder_id: agent_id,
        issued_at: $now,
        expires_at: $expires,
        scope: scope,
        parent_token_id: NONE,
        revoked: false,
        execution_count: 0,
        agent_id: agent_id
    };
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "token_issued",
        agent_id: agent_id,
        details: { token_id: $token_id, scope: scope }
    };
    
    RETURN (SELECT * FROM delegation_tokens WHERE id = $token_id LIMIT 1)[0];
};

-- Refresh token
CREATE FUNCTION refresh_token(
    old_token_id: string,
    new_scope: option<array>,
    ttl_minutes: int
) {
    LET $now = time::now();
    LET $expires = $now + (ttl_minutes * 60000);
    LET $new_token_id = string::uuid();
    
    LET $old = (SELECT * FROM delegation_tokens WHERE id = old_token_id LIMIT 1)[0];
    
    IF !$old {
        THROW "Token not found";
    };
    
    LET $scope = new_scope ?? $old.scope;
    LET $valid_scope = $scope FILTER $s IN $old.scope;
    
    -- Revoke old token
    UPDATE delegation_tokens SET revoked = true WHERE id = old_token_id;
    
    -- Create new token
    CREATE delegation_tokens CONTENT {
        id: $new_token_id,
        issuer_id: $old.issuer_id,
        holder_id: $old.holder_id,
        issued_at: $now,
        expires_at: $expires,
        scope: $valid_scope,
        max_executions: $old.max_executions,
        max_duration_seconds: $old.max_duration_seconds,
        allowed_resources: $old.allowed_resources,
        denied_resources: $old.denied_resources,
        parent_token_id: old_token_id,
        revoked: false,
        execution_count: 0,
        agent_id: $old.agent_id
    };
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "token_refreshed",
        agent_id: $old.agent_id,
        details: { old_token_id: old_token_id, new_token_id: $new_token_id }
    };
    
    RETURN (SELECT * FROM delegation_tokens WHERE id = $new_token_id LIMIT 1)[0];
};

-- Revoke single token
CREATE FUNCTION revoke_token(token_id: string) {
    LET $now = time::now();
    
    UPDATE delegation_tokens SET revoked = true WHERE id = token_id;
    
    CREATE audit_events CONTENT {
        id: string::uuid(),
        timestamp: $now,
        event_type: "token_revoked",
        details: { token_id: token_id }
    };
};

-- Propagate revocation through delegation chain
CREATE FUNCTION propagate_revocation(root_token_id: string) {
    LET $now = time::now();
    LET $revoked_count = 0;
    LET $to_revoke = [root_token_id];
    LET $visited = [];
    
    WHILE array::len($to_revoke) > 0 {
        LET $current = array::pop($to_revoke);
        
        IF $current IN $visited {
            CONTINUE;
        };
        
        SET $visited = array::combine($visited, [$current]);
        
        -- Revoke this token
        LET $updated = (UPDATE delegation_tokens SET revoked = true WHERE id = $current AND revoked = false RETURN id)[0];
        
        IF $updated {
            SET $revoked_count = $revoked_count + 1;
        };
        
        -- Find child tokens and add to queue
        LET $children = SELECT id FROM delegation_tokens WHERE parent_token_id = $current;
        
        FOR $child IN $children {
            SET $to_revoke = array::combine($to_revoke, [$child.id]);
        };
    };
    
    RETURN { revoked_count: $revoked_count };
};

-- ----------------------------------------------------------------------------
-- FUNCTIONS: Agent Operations
-- ----------------------------------------------------------------------------

-- Register and provision agent in one step
CREATE FUNCTION register_and_provision(
    name: string,
    agent_type: string,
    owner_id: string,
    capabilities: array,
    provider: string,
    model: string,
    version: string
) {
    -- Create agent
    LET $agent = create_agent(name, agent_type, owner_id, capabilities, provider, model, version, NONE, "medium", {});
    
    -- Provision
    LET $provisioned = provision_agent($agent.id, 30);
    
    -- Activate
    LET $activated = activate_agent($agent.id);
    
    RETURN $activated;
};

-- Get agent status
CREATE FUNCTION get_agent_status(agent_id: string) {
    LET $agent = (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
    
    IF !$agent {
        THROW "Agent not found";
    };
    
    LET $wi = (SELECT * FROM workload_identities WHERE agent_id = agent_id LIMIT 1)[0];
    LET $active_tokens = (SELECT count() as cnt FROM delegation_tokens WHERE agent_id = agent_id AND revoked = false)[0].cnt;
    
    RETURN {
        agent_id: $agent.id,
        name: $agent.name,
        state: $agent.lifecycle_state,
        lifecycle_state: $agent.lifecycle_state,
        provider: $agent.provider,
        model: $agent.model,
        current_scopes: $agent.current_scopes,
        workload_identity: $wi.spiffe_id,
        active_tokens: $active_tokens,
        created_at: $agent.created_at,
        last_active: $agent.last_active_at
    };
};

-- Get audit trail for agent
CREATE FUNCTION get_audit_trail(agent_id: string, limit: int) {
    LET $events = (SELECT * FROM audit_events 
        WHERE agent_id = agent_id 
        ORDER BY timestamp DESC 
        LIMIT limit
    );
    
    RETURN $events;
};

-- Authorize action
CREATE FUNCTION authorize_action(agent_id: string, required_scope: string) {
    LET $agent = (SELECT * FROM agents WHERE id = agent_id LIMIT 1)[0];
    
    IF !$agent {
        RETURN { authorized: false, reason: "Agent not found" };
    };
    
    IF $agent.lifecycle_state != "active" {
        RETURN { authorized: false, reason: "Agent not active" };
    };
    
    IF required_scope NOT IN $agent.current_scopes {
        RETURN { authorized: false, reason: "Insufficient scope" };
    };
    
    RETURN { authorized: true, reason: "" };
};

-- Check token validity
CREATE FUNCTION validate_token(token_id: string) {
    LET $token = (SELECT * FROM delegation_tokens WHERE id = token_id LIMIT 1)[0];
    
    IF !$token {
        RETURN false;
    };
    
    IF $token.revoked {
        RETURN false;
    };
    
    IF time::now() > $token.expires_at {
        RETURN false;
    };
    
    IF $token.max_executions AND $token.execution_count >= $token.max_executions {
        RETURN false;
    };
    
    RETURN true;
};

-- ----------------------------------------------------------------------------
-- VIEWS: Convenient Aggregations
-- ----------------------------------------------------------------------------

-- View: Active agents with their workload identities
DEFINE VIEW active_agents AS
SELECT 
    a.id,
    a.name,
    a.agent_type,
    a.provider,
    a.model,
    a.current_scopes,
    a.last_active_at,
    w.spiffe_id as workload_identity,
    w.expires_at as identity_expires
FROM agents a
LEFT JOIN workload_identities w ON w.agent_id = a.id
WHERE a.lifecycle_state = "active"
ORDER BY a.last_active_at DESC;

-- View: Agents needing identity renewal
DEFINE VIEW expired_identities AS
SELECT 
    a.id,
    a.name,
    w.spiffe_id,
    w.expires_at
FROM agents a
JOIN workload_identities w ON w.agent_id = a.id
WHERE w.expires_at < time::now() + (7 * 86400000)  -- Expiring within 7 days
AND w.revoked = false;

-- View: Agent delegation chains
DEFINE VIEW delegation_chains AS
SELECT 
    dt.id,
    dt.issuer_id,
    dt.holder_id,
    dt.scope,
    dt.expires_at,
    dt.revoked,
    a_issuer.name as issuer_name,
    a_holder.name as holder_name
FROM delegation_tokens dt
JOIN agents a_issuer ON a_issuer.id = dt.issuer_id
JOIN agents a_holder ON a_holder.id = dt.holder_id
WHERE dt.parent_token_id = NONE
ORDER BY dt.issued_at DESC;
