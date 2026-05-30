# Agent Identity SDK

Python SDK for agent identity and lifecycle management based on OpenID Foundation's "Identity Management for Agentic AI" (October 2025).

## Overview

This SDK provides the core infrastructure for managing AI agent identities through their complete lifecycle, from registration through de-provisioning.

## Features

- **Agent Identity**: Verifiable unique identities with SPIFFE-style workload identities
- **Lifecycle Management**: Complete state machine (provisioned → active → revoked → deprovisioned)
- **Delegated Authorization**: On-Behalf-Of (OBO) flows with scope attenuation
- **Token Management**: OAuth-style tokens with validation and cascade revocation
- **Audit Trail**: Complete logging for compliance and governance

## Quick Start

```python
from apps.identity import AgentRegistry, AgentType, LifecycleState

# Create registry
registry = AgentRegistry()

# Create and provision agent
agent = registry.create_agent(
    name="coding-assistant",
    agent_type=AgentType.AUTONOMOUS,
    owner_id="user_001",
    capabilities=["code_generation", "git_operations", "code_review"],
    provider="anthropic",
    model="claude-sonnet-4"
)

# Activate
registry.provision(agent.agent_id)
registry.activate(agent.agent_id)

# Delegate to another agent
token = registry.delegate(
    delegator_id=agent.agent_id,
    delegatee_id=review_agent_id,
    scope=["code_review"],
    max_executions=10
)
```

## Lifecycle States

| State | Description |
|-------|-------------|
| `provisioned` | Agent registered, credentials issued |
| `active` | Agent working with valid credentials |
| `revoked` | Credentials invalidated, session ended |
| `deprovisioned` | Identity and access permanently removed |

## Delegation Pattern

The SDK implements the On-Behalf-Of (OBO) delegation pattern:

```
User → Sub-Agent → Primary Agent → Resource
                (scope attenuated at each step)
```

## Modules

### `registry`
Core agent registry with:
- `AgentRegistry` - Main registry class
- `AgentType` - Enum for agent types
- `LifecycleState` - Enum for lifecycle states
- `Agent` - Complete agent entity
- `DelegationToken` - Token with scope and constraints

### `errors`
Custom exceptions:
- `AgentNotFoundError`
- `InvalidLifecycleTransitionError`
- `TokenError`
- `InsufficientScopeError`

## Running the Demo

```bash
python -m apps.identity.demo
```

## SurrealQL Schema

For database integration, load `surreal/schema/agent_identity_sdk.surql`.

See also:
- `surreal/schema/agent_identity.surql` - Core identity schema
- `surreal/schema/agent_lifecycle.surql` - Lifecycle schema

## Reference

Based on:
- [OpenID Foundation: Identity Management for Agentic AI](https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf)
- [W3C DID Core](https://www.w3.org/TR/did-core/)
- [OAuth 2.0 OBO Flow](https://datatracker.ietf.org/doc/html/rfc7522)
