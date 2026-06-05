#!/usr/bin/env python3
"""Agent Identity MCP server (scaffold).

Exposes the Agent Identity flows as MCP tools so an MCP-capable agent host can
resolve, verify, and manage agent identities. Talks to SurrealDB over its stable
`/sql` HTTP endpoint (stdlib only for the DB client).

Run:
    pip install -r mcp/requirements.txt
    SURREAL_URL=http://127.0.0.1:8000 python mcp/agent_identity_server.py

Env (defaults): SURREAL_URL=http://127.0.0.1:8000, SURREAL_NS=agent_identity,
SURREAL_DB=dev, SURREAL_USER=root, SURREAL_PASS=root.

This is a scaffold: the tools build and run the same SurrealQL as the flows in
surreal/flows/. Add auth, input validation, and error mapping before production use.
"""
from __future__ import annotations

import base64
import json
import os
import urllib.request

from mcp.server.fastmcp import FastMCP  # pip install mcp

mcp = FastMCP("agent-identity")


def _sql(query: str):
    url = os.environ.get("SURREAL_URL", "http://127.0.0.1:8000").rstrip("/")
    user = os.environ.get("SURREAL_USER", "root")
    pwd = os.environ.get("SURREAL_PASS", "root")
    ns = os.environ.get("SURREAL_NS", "agent_identity")
    db = os.environ.get("SURREAL_DB", "dev")
    req = urllib.request.Request(url + "/sql", data=query.encode(), method="POST")
    req.add_header("Authorization", "Basic " + base64.b64encode(f"{user}:{pwd}".encode()).decode())
    req.add_header("Accept", "application/json")
    for k, v in (("NS", ns), ("DB", db), ("surreal-ns", ns), ("surreal-db", db)):
        req.add_header(k, v)
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode())


@mcp.tool()
def resolve_agent(identity: str) -> dict:
    """Resolve an agent identity and its current lifecycle state."""
    return {
        "result": _sql(
            f"SELECT *, (SELECT VALUE state FROM ONLY agent_lifecycle "
            f"WHERE identity = agent_identity:{identity} LIMIT 1) AS lifecycle_state "
            f"FROM agent_identity:{identity};"
        )
    }


@mcp.tool()
def verify_agent(identity: str, method: str = "registry", verifier: str = "mcp") -> dict:
    """Record a verification (method: did/oidc/vc/spiffe/kya/registry) and link it."""
    return {
        "result": _sql(
            f'LET $v = (CREATE ONLY identity_verification CONTENT {{ '
            f'identity: agent_identity:{identity}, verifier: "{verifier}", '
            f'method: "{method}", status: "verified", verified_at: time::now() }}); '
            f"RELATE agent_identity:{identity}->verified_by->$v.id;"
        )
    }


@mcp.tool()
def provision_agent(identity: str, subject: str) -> dict:
    """Provision a new agent: create the identity and its lifecycle record."""
    return {
        "result": _sql(
            f'CREATE agent_identity:{identity} CONTENT {{ subject: "{subject}", status: "active" }}; '
            f"CREATE agent_lifecycle CONTENT {{ identity: agent_identity:{identity}, state: \"provisioned\" }};"
        )
    }


@mcp.tool()
def activate_agent(identity: str) -> dict:
    """Move a provisioned agent to active."""
    return {
        "result": _sql(
            f'UPDATE agent_lifecycle SET previous_state = state, state = "active" '
            f"WHERE identity = agent_identity:{identity};"
        )
    }


@mcp.tool()
def revoke_agent(identity: str, reason: str = "") -> dict:
    """Revoke an active agent's credentials."""
    return {
        "result": _sql(
            f'UPDATE agent_lifecycle SET previous_state = state, state = "revoked", '
            f'reason = "{reason}" WHERE identity = agent_identity:{identity};'
        )
    }


@mcp.tool()
def list_entitlements(identity: str) -> dict:
    """List the entitlements currently held by an agent."""
    return {
        "result": _sql(
            f"SELECT VALUE entitlements FROM agent_lifecycle "
            f"WHERE identity = agent_identity:{identity};"
        )
    }


if __name__ == "__main__":
    mcp.run()
