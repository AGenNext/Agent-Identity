-- ============================================================================
-- SurrealQL Usage Examples
-- ============================================================================
-- Run these queries after setting up the schema from agent_identity_system.surql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. REGISTERING & PROVISIONING AGENTS
-- ----------------------------------------------------------------------------

-- Create and provision a primary coding agent
CALL register_and_provision(
    "coding-assistant",
    "autonomous",
    "user_001",
    ["code_generation", "git_operations", "code_review", "terminal_execute"],
    "anthropic",
    "claude-sonnet-4",
    "1.0.0"
);

-- Create review agent (separate registration)
LET $review_identity = create_agent(
    "review-bot",
    "assistant",
    "user_001",
    ["code_review", "read", "file_read"],
    "openai",
    "gpt-5",
    "1.0.0",
    NONE,
    "medium",
    {}
);
CALL provision_agent($review_identity.id, 30);
CALL activate_agent($review_identity.id);

-- ----------------------------------------------------------------------------
-- 2. QUERYING AGENTS
-- ----------------------------------------------------------------------------

-- Get all active agents
SELECT * FROM agents WHERE lifecycle_state = "active" ORDER BY created_at DESC;

-- Get agent by ID
SELECT * FROM agents WHERE id = "agent_id_here" LIMIT 1;

-- Get agent status
CALL get_agent_status("agent_id_here");

-- List all scopedefault scopes
SELECT * FROM scopes;

-- ----------------------------------------------------------------------------
-- 3. DELEGATION & SCOPE ATTENUATION
-- ----------------------------------------------------------------------------

-- First, get the IDs of the agents
LET $primary = (SELECT id FROM agents WHERE name = "coding-assistant" LIMIT 1)[0].id;
LET $review = (SELECT id FROM agents WHERE name = "review-bot" LIMIT 1)[0].id;

-- Create delegation (primary agent delegates to review bot)
LET $delegation = delegate_to_agent(
    $primary,
    $review,
    ["code_review", "read", "file_read"],
    10,  -- max_executions
    NONE,
    ["repository", "pr"],
    NONE,
    60   -- ttl_minutes
);

-- Attenuate scope for sub-agent
LET $attenuated = attenuate_scope(
    $delegation.id,
    ["code_review", "read"],
    5,   -- max_executions
    30   -- ttl_minutes
);

-- Verify delegation chain
CALL verify_delegation_chain($attenuated.id);

-- Show all delegations from primary agent
SELECT * FROM delegation_tokens WHERE issuer_id = $primary;

-- Show delegation chain for a specific token
SELECT 
    dt.*,
    parent.spiffe_id as parent_token
FROM delegation_tokens dt
LEFT JOIN delegation_tokens parent ON parent.id = dt.parent_token_id
WHERE dt.id = $attenuated.id;

-- ----------------------------------------------------------------------------
-- 4. TOKEN MANAGEMENT
-- ----------------------------------------------------------------------------

-- Issue token for primary agent
LET $token = issue_token($primary, ["code_generation", "git_operations", "mcp_tool_use"], 30);

-- Check token validity
CALL validate_token($token.id);

-- Refresh token (narrowing scope)
LET $new_token = refresh_token($token.id, ["code_generation", "git_operations"], 60);

-- See all tokens for agent
SELECT * FROM delegation_tokens WHERE agent_id = $primary;

-- Check active tokens count
SELECT count() as active_tokens FROM delegation_tokens WHERE agent_id = $primary AND revoked = false;

-- ----------------------------------------------------------------------------
-- 5. LIFECYCLE TRANSITIONS
-- ----------------------------------------------------------------------------

-- Suspend agent
CALL suspend_agent($primary, "Maintenance");

-- Check status after suspension
CALL get_agent_status($primary);

-- Resume agent
CALL resume_agent($primary);

-- Status after resume
CALL get_agent_status($primary);

-- ----------------------------------------------------------------------------
-- 6. AUDIT TRAIL
-- ----------------------------------------------------------------------------

-- Get audit trail for agent
CALL get_audit_trail($primary, 50);

-- Get all audit events of a specific type
SELECT * FROM audit_events WHERE event_type = "delegation_created" ORDER BY timestamp DESC;

-- Get recent audit events by owner
SELECT * FROM audit_events 
WHERE actor_id = "user_001" 
ORDER BY timestamp DESC 
LIMIT 20;

-- Get audit trail by time range
-- (in SurrealDB, use datetime comparison)
SELECT * FROM audit_events 
WHERE agent_id = $primary 
AND timestamp > "2026-01-01T00:00:00Z"
ORDER BY timestamp DESC;

-- ----------------------------------------------------------------------------
-- 7. REVOCATION PROPAGATION
-- ----------------------------------------------------------------------------

-- Propagate revocation through chain
CALL propagate_revocation($delegation.id);

-- Check that tokens are revoked
SELECT id, revoked, parent_token_id FROM delegation_tokens WHERE issuer_id = $primary;

-- Count revoked vs active tokens
SELECT 
    sum(revoked = true) as revoked_count,
    sum(revoked = false) as active_count
FROM delegation_tokens WHERE agent_id = $primary GROUP ALL;

-- ----------------------------------------------------------------------------
-- 8. WORKLOAD IDENTITIES
-- ----------------------------------------------------------------------------

-- Get workload identity for agent
SELECT * FROM workload_identities WHERE agent_id = $primary;

-- Check for expiring identities
SELECT * FROM workload_identities WHERE expires_at < (time::now() + (7 * 86400000));

-- View: Agents needing identity renewal
SELECT * FROM expired_identities;

-- Revoke a specific identity
UPDATE workload_identities SET revoked = true WHERE agent_id = $primary;

-- ----------------------------------------------------------------------------
-- 9. VIEWS & REPORTS
-- ----------------------------------------------------------------------------

-- View: Active agents with workload identities
SELECT * FROM active_agents;

-- View: Delegation chains
SELECT * FROM delegation_chains;

-- Agent summary report
SELECT 
    a.id,
    a.name,
    a.lifecycle_state,
    count((SELECT id FROM delegation_tokens WHERE agent_id = a.id AND revoked = false)) as active_tokens,
    a.last_active_at,
    w.expires_at as identity_expires
FROM agents a
LEFT JOIN workload_identities w ON w.agent_id = a.id
GROUP BY a.id
ORDER BY a.created_at DESC;

-- ----------------------------------------------------------------------------
-- 10. DE-PROVISIONING
-- ----------------------------------------------------------------------------

-- Full de-provisioning (complete removal)
CALL deprovision_agent($primary, "End of project");

-- Verify agent is deleted
SELECT * FROM agents WHERE id = $primary;

-- Verify all tokens revoked
SELECT * FROM delegation_tokens WHERE agent_id = $primary;

-- ----------------------------------------------------------------------------
-- 11. GRAPH QUERIES (Multi-model)
-- ----------------------------------------------------------------------------

-- Note: These assume relationships have been defined

-- Find agents related through delegation graph
-- (This requires graph edges to be set up)
-- SELECT <-delegated_to-> FROM agents:r16s8s93z7t;

-- Find all tokens that an agent holds (incoming delegations)
-- SELECT <-issued_to-> FROM agents:r16s8s93z7t;

-- ----------------------------------------------------------------------------
-- 12. REAL-TIME LIVE QUERIES
-- ----------------------------------------------------------------------------

-- Watch for new agents in real-time
LIVE SELECT * FROM agents WHERE lifecycle_state = "created";

-- Watch for token revocations in real-time
LIVE SELECT * FROM delegation_tokens WHERE revoked = true;

-- Watch for audit events
LIVE SELECT * FROM audit_events;

-- ----------------------------------------------------------------------------
-- INTEGRATION WITH PYTHON (using surrealdb library)
-- ----------------------------------------------------------------------------

/*
from surrealdb import SurrealDB

async def main():
    db = SurrealDB("ws://localhost:8000/rpc")
    await db.signin({"user": "root", "pass": "root"})
    await db.use("agentic_ai", "agentic_ai")
    
    # Load the schema
    with open("agent_identity_system.surql") as f:
        schema = f.read()
        for statement in schema.split(";"):
            if statement.strip():
                await db.query(statement)
    
    # Register and provision an agent
    result = await db.query(
        'CALL register_and_provision("my-agent", "autonomous", "user_1", ["code_generation"], "anthropic", "claude", "1.0.0")'
    )
    agent = result[0]
    print(f"Created agent: {agent['name']}")
    
    # Get agent status
    status = await db.query(f'CALL get_agent_status("{agent['id']}")')
    print(f"Status: {status}")

if __name__ == "__main__":
    asyncio.run(main())
*/
