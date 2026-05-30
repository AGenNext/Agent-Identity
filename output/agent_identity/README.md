# Agent Identity System - Rust Version

A Rust implementation of the Agent Identity and Lifecycle Management System.

## Based On

- **OpenID Foundation**: "Identity Management for Agentic AI" (October 2025)

## Project Structure

```
agent_identity/
├── Cargo.toml
└── src/
    ├── lib.rs      # Core library (AgentRegistry, types, etc.)
    └── main.rs     # Demo application
```

## Dependencies

Add to `Cargo.toml`:
```toml
[dependencies]
chrono = { version = "0.4", features = ["serde"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
uuid = { version = "1.0", features = ["v4", "serde"] }
thiserror = "1.0"
```

## Features

### Core Components

| Component | Description |
|----------|-------------|
| `AgentRegistry` | Main registry for all agents |
| `Agent` | Agent entity with identity, state, tokens |
| `DelegationToken` | Tokens with scope attenuation |
| `WorkloadIdentity` | SPIFFE-style workload identities |

### Lifecycle States

```
CREATED → PROVISIONED → ACTIVE → SUSPENDED → REVOKED → DELETED
                                       ↘ RESUMED ↗
```

### Key Methods

**Lifecycle:**
- `create_agent()` - Register new agent
- `provision_agent()` - Issue credentials (CREATED → PROVISIONED)
- `activate_agent()` - Enable operations (PROVISIONED → ACTIVE)
- `suspend_agent()` - Temporarily disable
- `resume_agent()` - Re-enable suspended agent
- `deprovision_agent()` - Complete removal

**Delegation:**
- `delegate_to_agent()` - On-Behalf-Of delegation
- `attenuate_scope()` - Create down-scoped token
- `verify_delegation_chain()` - Verify chain integrity

**Tokens:**
- `issue_token()` - Issue access token
- `refresh_token()` - Refresh with same/narrowed scope
- `revoke_token()` - Invalidate single token
- `propagate_revocation()` - Cascade revocation
- `validate_token()` - Check validity

## Build & Run

```bash
# Build
cd output/agent_identity
cargo build --release

# Run demo
cargo run

# Run tests
cargo test
```

## Example Usage

```rust
use agent_identity::{AgentRegistry, AgentType};

let mut registry = AgentRegistry::new();

// Register and provision in one step
let agent = registry.register_and_provision(
    "coding-assistant",
    AgentType::Autonomous,
    "user_001",
    vec!["code_generation".to_string(), "git_operations".to_string()],
    "anthropic",
    "claude-sonnet-4",
    "1.0.0",
);

// Get status
let status = registry.get_agent_status(&agent.identity.agent_id)?;
println!("Agent state: {}", status.state);

// Create delegation
let token = registry.delegate_to_agent(
    &primary_id,
    &sub_id,
    vec!["read".to_string()],
    Some(10),
    60,
)?;

// Check token validity
if registry.validate_token(&token.id) {
    println!("Token is valid!");
}

// Propagate revocation through chain
let revoked = registry.propagate_revocation(&root_token_id);
println!("Revoked {} tokens", revoked);
```

## License

MIT - Based on OpenID Foundation standards.
