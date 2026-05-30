# Agent Identity & Lifecycle System - SurrealQL Version

This is the **SurrealDB/SurrealQL** implementation of the Agent Identity and Lifecycle Management System.

## Reference Documents

- **OpenID Foundation**: "Identity Management for Agentic AI" (October 2025)
- **SurrealDB Documentation**: https://surrealdb.com/docs

## Files

| File | Description |
|------|-------------|
| `agent_identity_system.surql` | Complete schema, functions, and tables |
| `agent_identity_examples.surql` | Usage examples and query patterns |

## Quick Start

### 1. Start SurrealDB

```bash
# Using Docker
docker run --rm -p 8000:8000 surrealdb/surrealdb:latest start

# Or install and run
surreal start --bind 0.0.0.0:8000
```

### 2. Connect and Setup

```bash
# Using surreal CLI
surreal sql --conn ws://localhost:8000 --user root --pass root --namespace agentic_ai --database agentic_ai

# Or with authentication
surreal sql --conn ws://localhost:8000 -u username -p password
```

### 3. Load the Schema

```sql
-- In the SurrealDB SQL shell, run:
SOURCE /path/to/output/agent_identity_system.surql;
```

Or execute the file directly:
```bash
surreal import --conn ws://localhost:8000 --user root --pass root agent_identity_system.surql
```

## Core Tables

| Table | Purpose |
|-------|---------|
| `agents` | Master table for agent identities and state |
| `workload_identities` | SPIFFE-style workload identities |
| `delegation_tokens` | Tokens for delegation chains |
| `audit_events` | Complete audit trail |
| `scopes` | Available permission scopes |

## Key Functions

### Lifecycle Management

| Function | Description | Transition |
|----------|-------------|------------|
| `create_agent()` | Register new agent | → CREATED |
| `provision_agent()` | Issue credentials | CREATED → PROVISIONED |
| `activate_agent()` | Enable operations | PROVISIONED → ACTIVE |
| `suspend_agent()` | Temporarily disable | ACTIVE → SUSPENDED |
| `resume_agent()` | Re-enable agent | SUSPENDED → ACTIVE |
| `revoke_agent()` | Invalidate credentials | → REVOKED |
| `deprovision_agent()` | Complete removal | → DELETED |

### Delegation

| Function | Description |
|----------|-------------|
| `delegate_to_agent()` | Create On-Behalf-Of delegation |
| `attenuate_scope()` | Create down-scoped token |
| `verify_delegation_chain()` | Verify chain integrity |

### Token Management

| Function | Description |
|----------|-------------|
| `issue_token()` | Issue access token |
| `refresh_token()` | Refresh with scope narrowing |
| `revoke_token()` | Invalidate single token |
| `propagate_revocation()` | Cascade revocation |
| `validate_token()` | Check token validity |

### Utilities

| Function | Description |
|----------|-------------|
| `register_and_provision()` | One-step registration |
| `get_agent_status()` | Comprehensive status |
| `authorize_action()` | Check authorization |
| `get_audit_trail()` | Retrieve audit events |

## Example Workflow

```sql
-- 1. Register and provision in one step
CALL register_and_provision(
    "my-agent",
    "autonomous",
    "user_001",
    ["code_generation", "git_operations"],
    "anthropic",
    "claude-sonnet-4",
    "1.0.0"
);

-- 2. Check status
CALL get_agent_status("<agent_id>");

-- 3. Create delegation to another agent
LET $delegation = delegate_to_agent(
    "<primary_agent_id>",
    "<sub_agent_id>",
    ["code_generation", "read"],
    10,  -- max_executions
    NONE,
    ["files"],
    NONE,
    60   -- ttl_minutes
);

-- 4. Attenuate scope for sub-agent
CALL attenuate_scope($delegation.id, ["code_review"], 5, 30);

-- 5. Suspend when needed
CALL suspend_agent("<agent_id>", "Maintenance reason");

-- 6. Resume when ready
CALL resume_agent("<agent_id>");

-- 7. Complete de-provisioning
CALL deprovision_agent("<agent_id>", "Project completed");
```

## Lifecycle States

```
┌─────────┐
│ CREATED │  (Agent registered)
└────┬────┘
     │ provision()
     ▼
┌────────────┐
│ PROVISIONED│  (Credentials issued)
└────┬───────┘
     │ activate()
     ▼
┌────────┐    suspend()    ┌───────────┐
│ ACTIVE │◄───────────────│ SUSPENDED │
└────┬───┘                └─────┬─────┘
     │ resume()                  │
     │ deprovision()         deprovision()
     ▼                            ▼
┌────────┐                   ┌──────────┐
│REVOKED │                   │ DELETED  │
└────────┘                   └──────────┘
```

## Graph Features

SurrealDB's multi-model capabilities allow for graph relationships:

```sql
-- Assuming graph edges are set up
SELECT ->delegated_to-> FROM agents:my_agent;
SELECT <-delegated_to-> FROM agents:sub_agent;
```

## Real-Time Subscriptions

Watch for changes live:

```sql
LIVE SELECT * FROM agents;
LIVE SELECT * FROM delegation_tokens WHERE revoked = true;
LIVE SELECT * FROM audit_events;
```

## Views

Pre-built views for common queries:

| View | Description |
|------|-------------|
| `active_agents` | Active agents with workload identities |
| `expired_identities` | Identities expiring within 7 days |
| `delegation_chains` | Top-level delegation chains |

## Indexes

Optimized indexes for common queries:

- `agents.id` - Unique agent lookup
- `agents.owner_id` - Owner's agents
- `agents.lifecycle_state` - State filtering
- `delegation_tokens.parent_token_id` - Chain traversal
- `audit_events.agent_id` - Agent audit trail

## Integration with Python

```python
from surrealdb import SurrealDB
import asyncio

async def main():
    db = SurrealDB("ws://localhost:8000/rpc")
    await db.signin({"user": "root", "pass": "root"})
    await db.use("agentic_ai", "agentic_ai")
    
    # Register agent
    result = await db.query('''
        CALL register_and_provision(
            "my-agent",
            "autonomous",
            "user_001",
            ["code_generation"],
            "anthropic",
            "claude",
            "1.0.0"
        )
    ''')
    print(result)

asyncio.run(main())
```

## Performance Considerations

1. **Indexes**: Created on all foreign keys and commonly queried fields
2. **Schemafull**: Tables are defined with types for better performance
3. **TTL**: Set reasonable expiration on tokens to auto-cleanup
4. **Real-time**: Use LIVE queries sparingly for high-volume data

## Security

- Record-level permissions can be added via SurrealDB's ACCESS
- JWT authentication supported
- Consider enabling authentication before production use:

```sql
DEFINE USER IF NOT EXISTS agentic_admin ON ROOT NAMESPACE SCHEMAFULL
    PASSROOT "strong_password_here"
    ROLES OWNER;
```

## License

Same as the OpenID Foundation specification - open for implementation.
