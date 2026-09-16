# Agent Identity MCP Server (scaffold)

Exposes the Agent Identity flows as [Model Context Protocol](https://modelcontextprotocol.io)
tools, so an MCP-capable agent host can manage agent identities directly.

## Tools

| Tool | Maps to flow |
| --- | --- |
| `resolve_agent(identity)` | resolve identity + lifecycle state |
| `verify_agent(identity, method, verifier)` | `identity_verification` (did/oidc/vc/spiffe/kya/registry) |
| `provision_agent(identity, subject)` | register + `provision` |
| `activate_agent(identity)` | lifecycle `activate` |
| `revoke_agent(identity, reason)` | lifecycle `revoke` |
| `list_entitlements(identity)` | read `agent_lifecycle.entitlements` |

## Run

```bash
pip install -r mcp/requirements.txt

# point at a SurrealDB with the schema + seeds loaded (see scripts/surreal_smoke_test.sh)
SURREAL_URL=http://127.0.0.1:8000 python mcp/agent_identity_server.py
```

Env (defaults): `SURREAL_URL=http://127.0.0.1:8000`, `SURREAL_NS=agent_identity`,
`SURREAL_DB=dev`, `SURREAL_USER=root`, `SURREAL_PASS=root`.

## Status

This is a **scaffold**. It runs the same SurrealQL as `surreal/flows/`, using SurrealDB's
stable `/sql` HTTP endpoint. Before production: add caller auth (the API already uses Logto
JWTs), input validation/escaping, scoped permissions, and structured error mapping.
