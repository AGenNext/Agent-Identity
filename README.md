# Agent Identity and Lifecycle Management System

A comprehensive implementation of agent identity and lifecycle management based on the **OpenID Foundation's "Identity Management for Agentic AI"** (October 2025) whitepaper.

## Overview

This system provides:

- **Agent Identity** - Verifiable, unique identities with SPIFFE-style workload identities
- **Lifecycle Management** - Complete provisioning, operation, and de-provisioning
- **Delegated Authorization** - On-Behalf-Of (OBO) flows with scope attenuation
- **Token Management** - OAuth-style tokens with validation and cascade revocation
- **Audit Trail** - Complete logging for compliance and governance

## Reference Documents

- [OpenID Foundation: Identity Management for Agentic AI](https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf)
- [SurrealDB Documentation](https://surrealdb.com/docs)
- [Okta Data Model](https://developer.okta.com/docs/concepts/okta-data-model/)

## Implementations

### 1. Python (`output/`)

Pure Python implementation with async support.

```bash
python3 output/agentic_identity_system.py
```

**Files:**
- `agentic_identity_system.py` - Main implementation + demo
- `agent_identity_surreal_db.py` - SurrealDB integration demo

### 2. SurrealQL/SurrealDB (`output/`)

Database schema and stored procedures for SurrealDB.

```bash
# Start SurrealDB
docker run --rm -p 8000:8000 surrealdb/surrealdb:latest start

# Load schema
surreal import --conn ws://localhost:8000 agent_identity_system.surql
```

**Files:**
- `agent_identity_system.surql` - Complete schema (tables, functions, views)
- `agent_identity_examples.surql` - Usage examples
- `README_SURREALQL.md` - Documentation

### 3. Rust (`output/agent_identity/`)

High-performance Rust implementation.

```bash
cd output/agent_identity
cargo build --release
cargo run
cargo test
```

**Files:**
- `Cargo.toml` - Dependencies
- `src/lib.rs` - Core library
- `src/main.rs` - Demo binary
- `README.md` - Documentation

## Architecture

### Lifecycle States

```
┌─────────┐     ┌────────────┐     ┌────────┐     ┌───────────┐
│ CREATED │ ─▶ │ PROVISIONED│ ─▶  │ ACTIVE │ ─▶  │ SUSPENDED │
└─────────┘     └────────────┘     └───┬────┘     └─────┬─────┘
                                       │               │
                                       └───────────────┘
                                           resume()

                   ┌────────┐     ┌──────────┐     ┌──────────┐
                   │ REVOKED│ ─▶ │ PROVISIONED│ or │ DELETED  │
                   └────────┘     └───────────┘     └──────────┘
```

### Delegation Chain (On-Behalf-Of)

```
User ──▶ Primary Agent ──▶ Sub-Agent ──▶ Resource
  │           │                 │            │
 scope    scope attenuated   scope further  API access
  ↓           ↓                 ↓            ↓
[full]   [read+write]      [read-only]    [data]
```

Each delegation step narrows the permission scope (Scope Attenuation).

## Core Components

### AgentIdentityManager
- `register_agent()` - Register new agent with unique identity
- `verify_agent_identity()` - Verify cryptographic identity
- `get_agent_identity()` - Retrieve agent details

### LifecycleManager
- `create_agent()` - Initial registration (CREATED)
- `provision_agent()` - Issue credentials (PROVISIONED)
- `activate_agent()` - Enable operations (ACTIVE)
- `suspend_agent()` - Temporary disable
- `resume_agent()` - Re-enable
- `deprovision_agent()` - Complete removal

### DelegationManager
- `delegate_to_agent()` - Create OBO delegation
- `attenuate_scope()` - Create down-scoped token
- `verify_delegation_chain()` - Verify chain integrity
- `authorize_action()` - Check authorization

### TokenManager
- `issue_token()` - Issue access token
- `refresh_token()` - Refresh with scope narrowing
- `revoke_token()` - Invalidate token
- `propagate_revocation()` - Cascade revocation

### GuardrailManager
- `enforce_guardrails()` - Apply behavioral constraints
- `check_data_access()` - Validate data access

## Security Features

1. **Least Privilege** - Always attenuate scope when delegating
2. **Execution Bounds** - Limit tokens by execution count
3. **Audit Trails** - Log all identity and authorization events
4. **Revocation Propagation** - Cascade revocation through delegation chains
5. **Identity Binding** - Bind tokens to specific agent instances

## License

MIT - Based on OpenID Foundation specifications.
