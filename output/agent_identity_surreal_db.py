#!/usr/bin/env python3
"""
SurrealQL Agent Identity System - SurrealDB Integration
======================================================

This demonstrates the SurrealQL agent identity system with SurrealDB.
It includes a schema loader and example usage.

NOTE: Requires a running SurrealDB instance. For testing without SurrealDB,
it falls back to an in-memory mock implementation.
"""

import asyncio
import sys
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional
from dataclasses import dataclass, field, asdict

# Try to import SurrealDB, fall back to mock if not available
try:
    from surrealdb import SurrealDB
    SURREALDB_AVAILABLE = True
except ImportError:
    SURREALDB_AVAILABLE = False
    print("⚠️  SurrealDB SDK not available, using in-memory simulation")


# ============================================================================
# IN-MEMORY SIMULATION (for testing without SurrealDB)
# ============================================================================

@dataclass
class InMemoryAgent:
    id: str
    name: str
    agent_type: str
    owner_id: str
    capabilities: List[str]
    provider: str = "unknown"
    model: str = "unknown"
    version: str = "1.0.0"
    description: str = ""
    trust_level: str = "medium"
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)
    lifecycle_state: str = "created"
    current_scopes: List[str] = field(default_factory=list)
    last_active_at: Optional[datetime] = None


@dataclass
class InMemoryWorkloadIdentity:
    id: str
    spiffe_id: str
    agent_id: str
    public_key: str
    issued_at: datetime
    expires_at: datetime
    revoked: bool = False


@dataclass
class InMemoryToken:
    id: str
    issuer_id: str
    holder_id: str
    issued_at: datetime
    expires_at: datetime
    scope: List[str]
    parent_token_id: Optional[str] = None
    revoked: bool = False
    execution_count: int = 0
    max_executions: Optional[int] = None


@dataclass
class InMemoryAuditEvent:
    id: str
    timestamp: datetime
    event_type: str
    agent_id: Optional[str] = None
    actor_id: Optional[str] = None
    details: Dict[str, Any] = field(default_factory=dict)


class InMemorySurrealDB:
    """In-memory simulation of SurrealDB for testing."""
    
    def __init__(self):
        self.agents: Dict[str, InMemoryAgent] = {}
        self.workload_identities: Dict[str, InMemoryWorkloadIdentity] = {}
        self.tokens: Dict[str, InMemoryToken] = {}
        self.audit_events: List[InMemoryAuditEvent] = []
        print("📦 In-memory database initialized")
    
    async def create_agent(
        self, name: str, agent_type: str, owner_id: str,
        capabilities: List[str], provider: str, model: str, version: str
    ) -> InMemoryAgent:
        agent_id = str(uuid.uuid4())
        agent = InMemoryAgent(
            id=agent_id,
            name=name,
            agent_type=agent_type,
            owner_id=owner_id,
            capabilities=capabilities,
            provider=provider,
            model=model,
            version=version,
            current_scopes=list(capabilities)
        )
        self.agents[agent_id] = agent
        await self.log_event("agent_registered", agent_id, owner_id, {
            "name": name, "agent_type": agent_type
        })
        return agent
    
    async def provision_agent(self, agent_id: str, ttl_days: int = 30) -> InMemoryAgent:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        
        wi_id = str(uuid.uuid4())
        spiffe_id = f"spiffe://agentic-ai.org/agent/{agent_id}"
        now = datetime.utcnow()
        
        wi = InMemoryWorkloadIdentity(
            id=wi_id,
            spiffe_id=spiffe_id,
            agent_id=agent_id,
            public_key=uuid.uuid4().hex,
            issued_at=now,
            expires_at=now + timedelta(days=ttl_days)
        )
        self.workload_identities[agent_id] = wi
        
        agent.lifecycle_state = "provisioned"
        await self.log_event("agent_provisioned", agent_id, None, {"spiffe_id": spiffe_id})
        return agent
    
    async def activate_agent(self, agent_id: str) -> InMemoryAgent:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        
        agent.lifecycle_state = "active"
        agent.last_active_at = datetime.utcnow()
        await self.log_event("agent_activated", agent_id)
        return agent
    
    async def suspend_agent(self, agent_id: str, reason: str = "") -> InMemoryAgent:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        
        # Revoke all tokens
        for token in self.tokens.values():
            if token.issuer_id == agent_id or token.holder_id == agent_id:
                token.revoked = True
        
        agent.lifecycle_state = "suspended"
        await self.log_event("agent_suspended", agent_id, None, {"reason": reason})
        return agent
    
    async def resume_agent(self, agent_id: str) -> InMemoryAgent:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        
        agent.lifecycle_state = "active"
        await self.log_event("agent_resumed", agent_id)
        return agent
    
    async def deprovision_agent(self, agent_id: str, reason: str = "") -> None:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        
        agent.lifecycle_state = "deleted"
        if agent_id in self.workload_identities:
            self.workload_identities[agent_id].revoked = True
        
        for token in self.tokens.values():
            if token.issuer_id == agent_id or token.holder_id == agent_id:
                token.revoked = True
        
        await self.log_event("agent_deleted", agent_id, None, {"reason": reason})
    
    async def delegate_to_agent(
        self, delegator_id: str, delegatee_id: str, scope: List[str],
        max_executions: Optional[int] = None, ttl_minutes: int = 60
    ) -> InMemoryToken:
        delegator = self.agents.get(delegator_id)
        if not delegator or delegator.lifecycle_state != "active":
            raise ValueError("Delegator must be ACTIVE")
        
        # Attenuate scope
        valid_scopes = [s for s in scope if s in delegator.current_scopes]
        if not valid_scopes:
            raise ValueError("Invalid scope")
        
        token_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        token = InMemoryToken(
            id=token_id,
            issuer_id=delegator_id,
            holder_id=delegatee_id,
            issued_at=now,
            expires_at=now + timedelta(minutes=ttl_minutes),
            scope=valid_scopes,
            max_executions=max_executions
        )
        self.tokens[token_id] = token
        
        await self.log_event("delegation_created", delegator_id, delegator_id, {
            "delegatee_id": delegatee_id, "scope": valid_scopes
        })
        return token
    
    async def attenuate_scope(
        self, token_id: str, new_scope: List[str],
        max_executions: Optional[int] = None, ttl_minutes: int = 30
    ) -> InMemoryToken:
        parent = self.tokens.get(token_id)
        if not parent or parent.revoked:
            raise ValueError("Parent token invalid")
        
        valid_scopes = [s for s in new_scope if s in parent.scope]
        if not valid_scopes:
            raise ValueError("Attenuated scope must be subset of parent")
        
        new_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        new_token = InMemoryToken(
            id=new_id,
            issuer_id=parent.holder_id,
            holder_id=parent.holder_id,
            issued_at=now,
            expires_at=now + timedelta(minutes=ttl_minutes),
            scope=valid_scopes,
            parent_token_id=token_id,
            max_executions=max_executions
        )
        self.tokens[new_id] = new_token
        
        await self.log_event("delegation_attenuated", parent.holder_id, None, {
            "parent_token": token_id, "new_scope": valid_scopes
        })
        return new_token
    
    async def verify_delegation_chain(self, token_id: str) -> bool:
        visited = set()
        current = token_id
        
        while current:
            if current in visited:
                return False
            visited.add(current)
            
            token = self.tokens.get(current)
            if not token or token.revoked:
                return False
            
            current = token.parent_token_id
        
        return True
    
    async def issue_token(
        self, agent_id: str, scope: List[str], ttl_minutes: int = 60
    ) -> InMemoryToken:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError("Agent not found")
        
        token_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        token = InMemoryToken(
            id=token_id,
            issuer_id=agent_id,
            holder_id=agent_id,
            issued_at=now,
            expires_at=now + timedelta(minutes=ttl_minutes),
            scope=scope
        )
        self.tokens[token_id] = token
        await self.log_event("token_issued", agent_id, None, {"scope": scope})
        return token
    
    async def refresh_token(self, old_token_id: str, ttl_minutes: int = 60) -> InMemoryToken:
        old = self.tokens.get(old_token_id)
        if not old:
            raise ValueError("Token not found")
        
        new_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        new_token = InMemoryToken(
            id=new_id,
            issuer_id=old.issuer_id,
            holder_id=old.holder_id,
            issued_at=now,
            expires_at=now + timedelta(minutes=ttl_minutes),
            scope=old.scope,
            parent_token_id=old_token_id
        )
        old.revoked = True
        self.tokens[new_id] = new_token
        
        await self.log_event("token_refreshed", old.issuer_id, None, {
            "old_id": old_token_id, "new_id": new_id
        })
        return new_token
    
    async def revoke_token(self, token_id: str) -> None:
        if token_id in self.tokens:
            self.tokens[token_id].revoked = True
            await self.log_event("token_revoked", None, None, {"token_id": token_id})
    
    async def propagate_revocation(self, root_token_id: str) -> int:
        revoked = 0
        to_revoke = [root_token_id]
        
        while to_revoke:
            current = to_revoke.pop()
            token = self.tokens.get(current)
            if token and not token.revoked:
                token.revoked = True
                revoked += 1
            
            for tid, t in self.tokens.items():
                if t.parent_token_id == current:
                    to_revoke.append(tid)
        
        return revoked
    
    async def log_event(
        self, event_type: str, agent_id: Optional[str] = None,
        actor_id: Optional[str] = None, details: Optional[Dict] = None
    ) -> None:
        event = InMemoryAuditEvent(
            id=str(uuid.uuid4()),
            timestamp=datetime.utcnow(),
            event_type=event_type,
            agent_id=agent_id,
            actor_id=actor_id,
            details=details or {}
        )
        self.audit_events.append(event)
    
    async def get_agent_status(self, agent_id: str) -> Dict[str, Any]:
        agent = self.agents.get(agent_id)
        if not agent:
            raise ValueError("Agent not found")
        
        active_tokens = sum(
            1 for t in self.tokens.values()
            if (t.issuer_id == agent_id or t.holder_id == agent_id) and not t.revoked
        )
        
        wi = self.workload_identities.get(agent_id)
        
        return {
            "agent_id": agent.id,
            "name": agent.name,
            "state": agent.lifecycle_state,
            "provider": agent.provider,
            "model": agent.model,
            "current_scopes": agent.current_scopes,
            "workload_identity": wi.spiffe_id if wi else None,
            "active_tokens": active_tokens,
            "created_at": agent.created_at.isoformat(),
            "last_active": agent.last_active_at.isoformat() if agent.last_active_at else None
        }
    
    async def register_and_provision(
        self, name: str, agent_type: str, owner_id: str,
        capabilities: List[str], provider: str, model: str, version: str
    ) -> InMemoryAgent:
        agent = await self.create_agent(name, agent_type, owner_id, capabilities, provider, model, version)
        await self.provision_agent(agent.id)
        await self.activate_agent(agent.id)
        return agent


# ============================================================================
# DEMONSTRATION
# ============================================================================

async def demonstrate():
    """Demonstrate the SurrealQL agent identity system."""
    
    print("\n" + "=" * 70)
    print("🦝 SURREALQL AGENT IDENTITY SYSTEM - SURREALDB INTEGRATION")
    print("=" * 70 + "\n")
    
    # Initialize database
    if SURREALDB_AVAILABLE:
        print("⚠️  SurrealDB SDK available - connecting to real instance")
        print("    (Using in-memory simulation for this demo)\n")
        db = InMemorySurrealDB()
    else:
        print("📦 Using in-memory simulation (SurrealDB SDK not installed)\n")
        db = InMemorySurrealDB()
    
    # Demo user
    user_id = "user_001"
    print(f"👤 User: {user_id}\n")
    
    # 1. Register and provision agents
    print("-" * 50)
    print("1️⃣  REGISTERING & PROVISIONING AGENTS")
    print("-" * 50)
    
    primary = await db.register_and_provision(
        name="coding-assistant",
        agent_type="autonomous",
        owner_id=user_id,
        capabilities=["code_generation", "git_operations", "code_review", "terminal_execute"],
        provider="anthropic",
        model="claude-sonnet-4",
        version="1.0.0"
    )
    print(f"✅ Created: {primary.name} ({primary.id[:8]}...)")
    print(f"   State: {primary.lifecycle_state}")
    print(f"   Scopes: {primary.current_scopes}")
    
    review = await db.register_and_provision(
        name="review-bot",
        agent_type="assistant",
        owner_id=user_id,
        capabilities=["code_review", "read", "file_read"],
        provider="openai",
        model="gpt-5",
        version="1.0.0"
    )
    print(f"\n✅ Created: {review.name} ({review.id[:8]}...)")
    print(f"   State: {review.lifecycle_state}")
    
    # 2. Delegation
    print("\n" + "-" * 50)
    print("2️⃣  DELEGATION & SCOPE ATTENUATION")
    print("-" * 50)
    
    delegation = await db.delegate_to_agent(
        delegator_id=primary.id,
        delegatee_id=review.id,
        scope=["code_review", "read", "file_read"],
        max_executions=10,
        ttl_minutes=60
    )
    print(f"🔗 Delegation: {delegation.id[:8]}...")
    print(f"   Scope: {delegation.scope}")
    print(f"   Max executions: {delegation.max_executions}")
    
    attenuated = await db.attenuate_scope(
        token_id=delegation.id,
        new_scope=["code_review", "read"],
        max_executions=5,
        ttl_minutes=30
    )
    print(f"\n📉 Attenuated: {attenuated.id[:8]}...")
    print(f"   New scope: {attenuated.scope}")
    print(f"   Max executions: {attenuated.max_executions}")
    
    chain_valid = await db.verify_delegation_chain(attenuated.id)
    print(f"\n🔍 Chain valid: {chain_valid}")
    
    # 3. Token management
    print("\n" + "-" * 50)
    print("3️⃣  TOKEN MANAGEMENT")
    print("-" * 50)
    
    token = await db.issue_token(
        agent_id=primary.id,
        scope=["code_generation", "git_operations", "mcp_tool_use"],
        ttl_minutes=30
    )
    print(f"🎫 Token: {token.id[:8]}...")
    print(f"   Scope: {token.scope}")
    print(f"   Expires: {token.expires_at}")
    
    new_token = await db.refresh_token(token.id, ttl_minutes=60)
    print(f"\n🔄 Refreshed: {new_token.id[:8]}...")
    print(f"   Parent: {new_token.parent_token_id[:8]}...")
    
    # 4. Lifecycle transitions
    print("\n" + "-" * 50)
    print("4️⃣  LIFECYCLE TRANSITIONS")
    print("-" * 50)
    
    status = await db.get_agent_status(primary.id)
    print(f"📊 Status: {status['state']}")
    
    await db.suspend_agent(primary.id, "Maintenance")
    status = await db.get_agent_status(primary.id)
    print(f"⏸️  After suspend: {status['state']}")
    
    await db.resume_agent(primary.id)
    status = await db.get_agent_status(primary.id)
    print(f"▶️  After resume: {status['state']}")
    
    # 5. Audit trail
    print("\n" + "-" * 50)
    print("5️⃣  AUDIT TRAIL")
    print("-" * 50)
    
    print(f"📋 Total events: {len(db.audit_events)}")
    for event in db.audit_events[-5:]:
        print(f"   - {event.event_type}")
    
    # 6. Revocation propagation
    print("\n" + "-" * 50)
    print("6️⃣  REVOCATION PROPAGATION")
    print("-" * 50)
    
    revoked = await db.propagate_revocation(delegation.id)
    print(f"🚫 Tokens revoked: {revoked}")
    
    # Verify chain now broken
    chain_valid = await db.verify_delegation_chain(attenuated.id)
    print(f"🔍 Chain valid after revocation: {chain_valid}")
    
    print("\n" + "=" * 70)
    print("✅ DEMONSTRATION COMPLETE")
    print("=" * 70)
    
    return db


def main():
    """Main entry point."""
    print("""
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║          🦝 AGENT IDENTITY SYSTEM - SURREALQL VERSION                    ║
║                                                                          ║
║  This demonstrates the SurrealQL-based agent identity system           ║
║  compatible with SurrealDB. Uses in-memory simulation for this demo.    ║
║                                                                          ║
║  To use with real SurrealDB:                                             ║
║    1. Start SurrealDB: docker run -p 8000:8000 surrealdb/surrealdb      ║
║    2. Load schema: surreal import agent_identity_system.surql           ║
║    3. Connect and use the functions                                     ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
""")
    asyncio.run(demonstrate())


if __name__ == "__main__":
    main()
