-- Agent Identity SDK - SurrealQL Schema
-- Based on OpenID Foundation "Identity Management for Agentic AI" (October 2025)
-- 
-- This schema extends the existing surreal/schema/agent_identity.surql
-- with lifecycle management and delegation capabilities.
-- 
-- Execute AFTER agent_identity.surql and agent_lifecycle.surql

-- ============================================================================
-- SCOPE ATTENUATION
-- ============================================================================
-- From OpenID whitepaper: "Scope Attenuation" (§3.2)
-- The process of progressively narrowing permissions at each delegation step.

-- Scope definitions
DEFINE TABLE agent_scope SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD name ON TABLE agent_scope TYPE string;
DEFINE FIELD description ON TABLE agent_scope TYPE string;
DEFINE FIELD risk_level ON TABLE agent_scope TYPE string
  ASSERT $value IN ["low", "medium", "high", "critical"];
DEFINE FIELD created_at ON TABLE agent_scope TYPE datetime DEFAULT time::now();

DEFINE INDEX agent_scope_name_idx ON TABLE agent_scope COLUMNS name UNIQUE;

-- Default scopes (from OpenID whitepaper capabilities)
INSERT INTO agent_scope [
  {name: "read", description: "Read access to resources", risk_level: "low", created_at: time::now()},
  {name: "write", description: "Write access to resources", risk_level: "medium", created_at: time::now()},
  {name: "delete", description: "Delete resources", risk_level: "high", created_at: time::now()},
  {name: "execute", description: "Execute actions", risk_level: "high", created_at: time::now()},
  {name: "admin", description: "Administrative access", risk_level: "critical", created_at: time::now()},
  {name: "code_generation", description: "Generate code", risk_level: "medium", created_at: time::now()},
  {name: "code_review", description: "Review code changes", risk_level: "low", created_at: time::now()},
  {name: "git_operations", description: "Git operations", risk_level: "medium", created_at: time::now()},
  {name: "web_search", description: "Web search capability", risk_level: "low", created_at: time::now()},
  {name: "file_read", description: "Read files", risk_level: "low", created_at: time::now()},
  {name: "file_write", description: "Write files", risk_level: "medium", created_at: time::now()},
  {name: "terminal_execute", description: "Execute terminal commands", risk_level: "high", created_at: time::now()},
  {name: "api_call", description: "Make API calls", risk_level: "medium", created_at: time::now()},
  {name: "mcp_tool_use", description: "Use MCP tools", risk_level: "medium", created_at: time::now()}
];

-- ============================================================================
-- DELEGATION TOKENS
-- ============================================================================
-- From OpenID whitepaper: "On-Behalf-Of Flow" and "Recursive Delegation" (§3.2)

DEFINE TABLE delegation_token SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD identity ON TABLE delegation_token TYPE record<agent_identity>;
DEFINE FIELD token_id ON TABLE delegation_token TYPE string;
DEFINE FIELD issuer_id ON TABLE delegation_token TYPE string;
DEFINE FIELD holder_id ON TABLE delegation_token TYPE string;
DEFINE FIELD scope ON TABLE delegation_token TYPE array<string>;
DEFINE FIELD issued_at ON TABLE delegation_token TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON TABLE delegation_token TYPE datetime;
DEFINE FIELD max_executions ON TABLE delegation_token TYPE option<int>;
DEFINE FIELD execution_count ON TABLE delegation_token TYPE int DEFAULT 0;
DEFINE FIELD allowed_resources ON TABLE delegation_token TYPE option<array<string>>;
DEFINE FIELD denied_resources ON TABLE delegation_token TYPE option<array<string>>;
DEFINE FIELD parent_token_id ON TABLE delegation_token TYPE option<string>;
DEFINE FIELD revoked ON TABLE delegation_token TYPE bool DEFAULT false;
DEFINE FIELD revoked_at ON TABLE delegation_token TYPE option<datetime>;
DEFINE FIELD created_at ON TABLE delegation_token TYPE datetime DEFAULT time::now();

DEFINE INDEX delegation_token_id_idx ON TABLE delegation_token COLUMNS token_id UNIQUE;
DEFINE INDEX delegation_token_issuer_idx ON TABLE delegation_token COLUMNS issuer_id;
DEFINE INDEX delegation_token_holder_idx ON TABLE delegation_token COLUMNS holder_id;
DEFINE INDEX delegation_token_parent_idx ON TABLE delegation_token COLUMNS parent_token_id;

-- Validate token on read
DEFINE FUNCTION fn::validate_delegation_token($token_id: string) {
  LET $token = (SELECT * FROM delegation_token WHERE token_id = $token_id LIMIT 1)[0];
  IF !$token {
    RETURN { valid: false, reason: "Token not found" };
  };
  IF $token.revoked {
    RETURN { valid: false, reason: "Token revoked" };
  };
  IF time::now() > $token.expires_at {
    RETURN { valid: false, reason: "Token expired" };
  };
  IF $token.max_executions AND $token.execution_count >= $token.max_executions {
    RETURN { valid: false, reason: "Max executions reached" };
  };
  RETURN { valid: true, reason: "" };
};

-- ============================================================================
-- SCOPE ATTENUATION FUNCTION
-- ============================================================================
-- From OpenID whitepaper: "Scope Attenuation" - progressively narrowing permissions

DEFINE FUNCTION fn::attenuate_scope($parent_scope: array, $new_scope: array, $factor: float) {
  -- Filter to only scopes in parent
  LET $valid = $new_scope FILTER $s IN $parent_scope;
  -- Calculate number of scopes to keep
  LET $num_keep = math::ceil(float::len($valid) * $factor);
  LET $num_keep = int($num_keep);
  -- Prioritize safer scopes
  LET $priority = ["read", "file_read", "code_generation", "code_review", "write", "file_write"];
  LET $sorted = $valid ORDER BY (
    LET $idx = $priority::position($s);
    IF $idx < 0 { 999 } ELSE { $idx }
  );
  -- Return limited scope
  RETURN array::slice($sorted, 0, $num_keep);
};

-- ============================================================================
-- DELEGATION CHAIN VERIFICATION
-- ============================================================================
-- From OpenID whitepaper: "transitive trust" and delegation chain verification

DEFINE FUNCTION fn::verify_delegation_chain($token_id: string) {
  LET $visited = [];
  LET $current = $token_id;
  
  WHILE $current != NONE {
    IF $current IN $visited {
      RETURN false; -- Cycle detected
    };
    SET $visited = array::combine($visited, [$current]);
    
    LET $token = (SELECT * FROM delegation_token WHERE token_id = $current LIMIT 1)[0];
    IF !$token {
      RETURN false;
    };
    IF $token.revoked {
      RETURN false;
    };
    IF time::now() > $token.expires_at {
      RETURN false;
    };
    SET $current = $token.parent_token_id;
  };
  
  RETURN true;
};

-- ============================================================================
-- REVOCATION PROPAGATION
-- ============================================================================
-- From OpenID whitepaper: "The Revocation Challenge" - propagating revocation

DEFINE FUNCTION fn::propagate_revocation($root_token_id: string) {
  LET $revoked = 0;
  LET $queue = [$root_token_id];
  LET $processed = [];
  
  WHILE array::len($queue) > 0 {
    LET $current = array::pop($queue);
    
    IF $current IN $processed {
      CONTINUE;
    };
    SET $processed = array::combine($processed, [$current]);
    
    LET $updated = (UPDATE delegation_token SET revoked = true, revoked_at = time::now() 
      WHERE token_id = $current AND revoked = false RETURN id)[0];
    
    IF $updated {
      SET $revoked = $revoked + 1;
    };
    
    -- Find child tokens
    LET $children = SELECT token_id FROM delegation_token WHERE parent_token_id = $current;
    FOR $child IN $children {
      SET $queue = array::combine($queue, [$child.token_id]);
    };
  };
  
  RETURN { revoked_count: $revoked };
};

-- ============================================================================
-- LIFECYCLE TRANSITION HELPERS
-- ============================================================================
-- These extend the lifecycle schema with SDK-specific helpers

DEFINE FUNCTION fn::provision_agent($identity_id: string, $ttl_days: int) {
  -- Create workload identity
  LET $spiffe_id = "spiffe://agentic-ai.org/agent/" + $identity_id;
  LET $public_key = string::uuid();
  LET $expires = time::now() + ($ttl_days * 86400000);
  
  -- Update lifecycle to active
  LET $lifecycle = (SELECT * FROM agent_lifecycle WHERE identity = $identity_id LIMIT 1)[0];
  
  IF $lifecycle.state != "provisioned" {
    THROW "Agent must be in 'provisioned' state";
  };
  
  UPDATE agent_lifecycle SET 
    state = "active",
    previous_state = "provisioned",
    reason = NONE,
    entered_state_at = time::now()
  WHERE identity = $identity_id;
  
  -- Create audit entry
  CREATE lifecycle_audit_log CONTENT {
    identity: $identity_id,
    from_state: "provisioned",
    to_state: "active",
    trigger: NONE,
    reason: "Agent provisioned and activated"
  };
  
  RETURN (SELECT * FROM agent_lifecycle WHERE identity = $identity_id LIMIT 1)[0];
};

DEFINE FUNCTION fn::revoke_agent($identity_id: string, $reason: string) {
  LET $lifecycle = (SELECT * FROM agent_lifecycle WHERE identity = $identity_id LIMIT 1)[0];
  
  IF $lifecycle.state != "active" {
    THROW "Agent must be in 'active' state";
  };
  
  -- Revoke all delegation tokens
  FOR $token IN (SELECT id FROM delegation_token WHERE identity = $identity_id AND revoked = false) {
    fn::propagate_revocation($token.token_id);
  };
  
  UPDATE agent_lifecycle SET 
    state = "revoked",
    previous_state = "active",
    reason = $reason,
    entered_state_at = time::now()
  WHERE identity = $identity_id;
  
  -- Audit
  CREATE lifecycle_audit_log CONTENT {
    identity: $identity_id,
    from_state: "active",
    to_state: "revoked",
    trigger: "security_alert",
    reason: $reason
  };
  
  RETURN (SELECT * FROM agent_lifecycle WHERE identity = $identity_id LIMIT 1)[0];
};

DEFINE FUNCTION fn::deprovision_agent($identity_id: string, $reason: string) {
  -- Revoke all tokens
  FOR $token IN (SELECT id FROM delegation_token WHERE identity = $identity_id) {
    fn::propagate_revocation($token.token_id);
  };
  
  UPDATE agent_lifecycle SET 
    state = "deprovisioned",
    previous_state = $before.state,
    reason = $reason,
    entered_state_at = time::now()
  WHERE identity = $identity_id;
  
  -- Audit
  CREATE lifecycle_audit_log CONTENT {
    identity: $identity_id,
    from_state: $before.state,
    to_state: "deprovisioned",
    trigger: "end_of_life",
    reason: $reason
  };
};

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Active agents with their delegation status
DEFINE VIEW active_agents_with_delegations AS
SELECT 
  ai.id,
  ai.subject as name,
  al.state,
  count((SELECT id FROM delegation_token WHERE identity = ai.id AND revoked = false)) as active_tokens,
  al.entered_state_at
FROM agent_identity ai
JOIN agent_lifecycle al ON al.identity = ai.id
WHERE al.state = "active"
ORDER BY al.entered_state_at DESC;

-- Delegation chains
DEFINE VIEW delegation_chains AS
SELECT 
  dt.token_id,
  dt.issuer_id,
  dt.holder_id,
  dt.scope,
  dt.expires_at,
  dt.revoked,
  dt.parent_token_id
FROM delegation_token dt
WHERE dt.parent_token_id = NONE
ORDER BY dt.issued_at DESC;

-- Expiring tokens
DEFINE VIEW expiring_tokens AS
SELECT 
  dt.token_id,
  dt.identity,
  dt.scope,
  dt.expires_at
FROM delegation_token dt
WHERE dt.revoked = false
AND dt.expires_at < (time::now() + (7 * 86400000))
ORDER BY dt.expires_at ASC;
