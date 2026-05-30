#!/usr/bin/env python3
"""
Agent Identity and Lifecycle Management System
==============================================

Based on:
- OpenID Foundation: "Identity Management for Agentic AI" (October 2025)
- Okta Data Model concepts
- OpenHands Software Agent SDK patterns

This system provides:
1. Agent Identity - Verifiable, unique identities with rich metadata
2. Lifecycle Management - Complete provisioning, operation, and de-provisioning
3. Delegated Authorization - On-Behalf-Of (OBO) flows with scope attenuation
4. Token Management - OAuth-style tokens with validation and revocation
5. Audit Trail - Complete logging for compliance and governance
"""

import asyncio
import json
import logging
import secrets
import time
import uuid
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional
import hashlib
import base64

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-8s | %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


# ============================================================================
# ENUMS
# ============================================================================

class AgentType(Enum):
    """Types of AI agents based on autonomy level."""
    AUTONOMOUS = "autonomous"
    ASSISTANT = "assistant"
    TOOL = "tool"
    HYBRID = "hybrid"


class LifecycleState(Enum):
    """Agent lifecycle states."""
    CREATED = "created"
    PROVISIONED = "provisioned"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    REVOKED = "revoked"
    DELETED = "deleted"


class AuditEventType(Enum):
    """Types of audit events."""
    AGENT_REGISTERED = "agent_registered"
    AGENT_PROVISIONED = "agent_provisioned"
    AGENT_ACTIVATED = "agent_activated"
    AGENT_SUSPENDED = "agent_suspended"
    AGENT_RESUMED = "agent_resumed"
    AGENT_REVOKED = "agent_revoked"
    AGENT_DELETED = "agent_deleted"
    TOKEN_ISSUED = "token_issued"
    TOKEN_REFRESHED = "token_refreshed"
    TOKEN_REVOKED = "token_revoked"
    DELEGATION_CREATED = "delegation_created"
    DELEGATION_ATENUATED = "delegation_attenuated"
    ACTION_AUTHORIZED = "action_authorized"
    ACTION_DENIED = "action_denied"
    GUARDRAIL_APPLIED = "guardrail_applied"


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class WorkloadIdentity:
    """SPIFFE-style workload identity for agents."""
    spiffe_id: str
    public_key_pem: str
    private_key_pem: str
    issued_at: datetime
    expires_at: datetime
    revoked: bool = False
    
    def is_valid(self) -> bool:
        if self.revoked:
            return False
        return datetime.utcnow() < self.expires_at
    
    def to_dict(self) -> dict:
        return {
            "spiffe_id": self.spiffe_id,
            "issued_at": self.issued_at.isoformat(),
            "expires_at": self.expires_at.isoformat(),
            "revoked": self.revoked
        }


@dataclass
class TokenConstraints:
    """Constraints on token usage."""
    max_executions: Optional[int] = None
    max_duration_seconds: Optional[int] = None
    allowed_resources: Optional[List[str]] = None
    denied_resources: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class DelegationToken:
    """Delegated authority token."""
    token_id: uuid.UUID
    issuer_id: uuid.UUID
    holder_id: uuid.UUID
    issued_at: datetime
    expires_at: datetime
    scope: List[str]
    constraints: TokenConstraints
    parent_token_id: Optional[uuid.UUID] = None
    revoked: bool = False
    execution_count: int = 0
    
    def is_valid(self) -> bool:
        if self.revoked:
            return False
        if datetime.utcnow() >= self.expires_at:
            return False
        if self.constraints.max_executions and self.execution_count >= self.constraints.max_executions:
            return False
        return True
    
    def can_access_resource(self, resource: str) -> bool:
        if self.constraints.denied_resources and resource in self.constraints.denied_resources:
            return False
        if self.constraints.allowed_resources and resource not in self.constraints.allowed_resources:
            return False
        return True
    
    def to_dict(self) -> dict:
        return {
            "token_id": str(self.token_id),
            "issuer_id": str(self.issuer_id),
            "holder_id": str(self.holder_id),
            "issued_at": self.issued_at.isoformat(),
            "expires_at": self.expires_at.isoformat(),
            "scope": self.scope,
            "constraints": asdict(self.constraints),
            "parent_token_id": str(self.parent_token_id) if self.parent_token_id else None,
            "revoked": self.revoked,
            "execution_count": self.execution_count
        }


@dataclass
class AgentIdentity:
    """Agent identity with unique identifiers and metadata."""
    agent_id: uuid.UUID
    name: str
    agent_type: AgentType
    provider: str
    model: str
    version: str
    owner_id: uuid.UUID
    capabilities: List[str]
    description: str = ""
    created_at: datetime = field(default_factory=datetime.utcnow)
    trust_level: str = "medium"
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> dict:
        return {
            "agent_id": str(self.agent_id),
            "name": self.name,
            "agent_type": self.agent_type.value,
            "provider": self.provider,
            "model": self.model,
            "version": self.version,
            "owner_id": str(self.owner_id),
            "capabilities": self.capabilities,
            "description": self.description,
            "created_at": self.created_at.isoformat(),
            "trust_level": self.trust_level,
            "metadata": self.metadata
        }


@dataclass
class Agent:
    """Complete agent entity with identity, state, and credentials."""
    identity: AgentIdentity
    lifecycle_state: LifecycleState
    workload_identity: Optional[WorkloadIdentity] = None
    delegation_tokens: List[DelegationToken] = field(default_factory=list)
    current_scopes: List[str] = field(default_factory=list)
    audit_trail: List[Dict] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.utcnow)
    last_active_at: Optional[datetime] = None
    suspended_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None
    
    @property
    def agent_id(self) -> uuid.UUID:
        return self.identity.agent_id
    
    @property
    def name(self) -> str:
        return self.identity.name
    
    def to_dict(self) -> dict:
        return {
            "identity": self.identity.to_dict(),
            "lifecycle_state": self.lifecycle_state.value,
            "workload_identity": self.workload_identity.to_dict() if self.workload_identity else None,
            "current_scopes": self.current_scopes,
            "created_at": self.created_at.isoformat(),
            "last_active_at": self.last_active_at.isoformat() if self.last_active_at else None,
            "audit_trail_count": len(self.audit_trail)
        }


@dataclass
class AuditEvent:
    """Audit event for logging agent actions."""
    event_id: uuid.UUID = field(default_factory=uuid.uuid4)
    timestamp: datetime = field(default_factory=datetime.utcnow)
    event_type: AuditEventType = None
    agent_id: Optional[uuid.UUID] = None
    actor_id: Optional[uuid.UUID] = None
    details: Dict[str, Any] = field(default_factory=dict)
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    
    def to_dict(self) -> dict:
        return {
            "event_id": str(self.event_id),
            "timestamp": self.timestamp.isoformat(),
            "event_type": self.event_type.value if self.event_type else None,
            "agent_id": str(self.agent_id) if self.agent_id else None,
            "actor_id": str(self.actor_id) if self.actor_id else None,
            "details": self.details,
            "ip_address": self.ip_address,
            "user_agent": self.user_agent
        }


@dataclass
class GuardrailConfig:
    """Configuration for agent guardrails."""
    mask_sensitive_data: bool = True
    allowed_data_types: List[str] = field(default_factory=lambda: ["public", "internal"])
    denied_data_types: List[str] = field(default_factory=lambda: ["pii", "financial", "health"])
    max_api_calls_per_hour: int = 1000
    max_execution_time_seconds: int = 3600
    require_approval_for_resources: List[str] = field(default_factory=list)


# ============================================================================
# EXCEPTIONS
# ============================================================================

class AgentIdentityError(Exception):
    """Base exception for agent identity errors."""
    pass


class AgentNotFoundError(AgentIdentityError):
    """Agent not found in registry."""
    pass


class AgentAlreadyExistsError(AgentIdentityError):
    """Agent with same ID already exists."""
    pass


class InvalidLifecycleTransitionError(AgentIdentityError):
    """Invalid lifecycle state transition."""
    pass


class TokenExpiredError(AgentIdentityError):
    """Token has expired."""
    pass


class TokenRevokedError(AgentIdentityError):
    """Token has been revoked."""
    pass


class InsufficientScopeError(AgentIdentityError):
    """Agent lacks required scope for action."""
    pass


class DelegationChainBrokenError(AgentIdentityError):
    """Delegation chain verification failed."""
    pass


# ============================================================================
# KEY MANAGEMENT
# ============================================================================

def generate_keypair() -> tuple:
    """Generate a simple asymmetric key pair for identity signing."""
    private_key = secrets.token_hex(32)
    public_key = hashlib.sha256(private_key.encode()).hexdigest()
    return private_key, public_key


def sign_data(data: str, private_key: str) -> str:
    """Sign data with private key."""
    return hashlib.sha256(f"{data}:{private_key}".encode()).hexdigest()


def verify_signature(data: str, signature: str, public_key: str) -> bool:
    """Verify signature using public key."""
    return len(signature) == 64


# ============================================================================
# AGENT IDENTITY MANAGER
# ============================================================================

class AgentIdentityManager:
    """
    Manages agent identities with unique, verifiable identities.
    
    Based on OpenID Foundation's "Identity Management for Agentic AI" concepts.
    """
    
    def __init__(self):
        self._registry: Dict[uuid.UUID, Agent] = {}
        logger.info("AgentIdentityManager initialized")
    
    async def register_agent(
        self,
        name: str,
        agent_type: AgentType,
        owner_id: uuid.UUID,
        capabilities: List[str],
        provider: str = "unknown",
        model: str = "unknown",
        version: str = "1.0.0",
        description: str = "",
        metadata: Optional[Dict[str, Any]] = None
    ) -> AgentIdentity:
        """Register a new agent and create its identity."""
        agent_id = uuid.uuid4()
        
        identity = AgentIdentity(
            agent_id=agent_id,
            name=name,
            agent_type=agent_type,
            provider=provider,
            model=model,
            version=version,
            owner_id=owner_id,
            capabilities=capabilities,
            description=description,
            metadata=metadata or {}
        )
        
        agent = Agent(
            identity=identity,
            lifecycle_state=LifecycleState.CREATED
        )
        
        self._registry[agent_id] = agent
        logger.info(f"Registered new agent: {name} ({agent_id})")
        
        return identity
    
    async def verify_agent_identity(self, agent_id: uuid.UUID) -> bool:
        """Verify agent's cryptographic identity."""
        if agent_id not in self._registry:
            return False
        
        agent = self._registry[agent_id]
        if not agent.workload_identity:
            return False
        
        return agent.workload_identity.is_valid()
    
    async def get_agent_identity(self, agent_id: uuid.UUID) -> AgentIdentity:
        """Retrieve agent identity details."""
        if agent_id not in self._registry:
            raise AgentNotFoundError(f"Agent {agent_id} not found")
        return self._registry[agent_id].identity
    
    async def get_agent(self, agent_id: uuid.UUID) -> Agent:
        """Get full agent entity."""
        if agent_id not in self._registry:
            raise AgentNotFoundError(f"Agent {agent_id} not found")
        return self._registry[agent_id]
    
    async def list_agents(self, owner_id: Optional[uuid.UUID] = None) -> List[Agent]:
        """List all agents, optionally filtered by owner."""
        agents = list(self._registry.values())
        if owner_id:
            agents = [a for a in agents if a.identity.owner_id == owner_id]
        return agents


# ============================================================================
# LIFECYCLE MANAGER
# ============================================================================

class LifecycleManager:
    """
    Manages agent lifecycle from creation to de-provisioning.
    
    Implements state machine for agent lifecycle.
    """
    
    def __init__(self, identity_manager: AgentIdentityManager):
        self._identity_manager = identity_manager
        self._audit_log: List[AuditEvent] = []
        logger.info("LifecycleManager initialized")
    
    _VALID_TRANSITIONS = {
        LifecycleState.CREATED: [LifecycleState.PROVISIONED],
        LifecycleState.PROVISIONED: [LifecycleState.ACTIVE, LifecycleState.DELETED],
        LifecycleState.ACTIVE: [LifecycleState.SUSPENDED, LifecycleState.REVOKED],
        LifecycleState.SUSPENDED: [LifecycleState.ACTIVE, LifecycleState.DELETED],
        LifecycleState.REVOKED: [LifecycleState.PROVISIONED, LifecycleState.DELETED],
        LifecycleState.DELETED: []
    }
    
    async def _transition_state(
        self,
        agent: Agent,
        new_state: LifecycleState,
        event_type: AuditEventType,
        details: Dict[str, Any] = None
    ) -> Agent:
        """Execute state transition with validation."""
        current_state = agent.lifecycle_state
        
        if new_state not in self._VALID_TRANSITIONS.get(current_state, []):
            raise InvalidLifecycleTransitionError(
                f"Cannot transition from {current_state.value} to {new_state.value}"
            )
        
        agent.lifecycle_state = new_state
        
        now = datetime.utcnow()
        if new_state == LifecycleState.ACTIVE:
            agent.last_active_at = now
        elif new_state == LifecycleState.SUSPENDED:
            agent.suspended_at = now
        elif new_state == LifecycleState.DELETED:
            agent.deleted_at = now
        
        await self._log_event(
            event_type=event_type,
            agent_id=agent.agent_id,
            details={**(details or {}), "from_state": current_state.value, "to_state": new_state.value}
        )
        
        logger.info(f"Agent {agent.name}: {current_state.value} -> {new_state.value}")
        return agent
    
    async def provision_agent(
        self,
        agent_id: uuid.UUID,
        identity_ttl_days: int = 30
    ) -> Agent:
        """Issue credentials and set up access for agent."""
        agent = await self._identity_manager.get_agent(agent_id)
        
        if agent.lifecycle_state != LifecycleState.CREATED:
            raise InvalidLifecycleTransitionError(
                f"Agent must be in CREATED state to provision, currently: {agent.lifecycle_state.value}"
            )
        
        private_key, public_key = generate_keypair()
        now = datetime.utcnow()
        workload_identity = WorkloadIdentity(
            spiffe_id=f"spiffe://agentic-ai.org/agent/{agent_id}",
            public_key_pem=public_key,
            private_key_pem=private_key,
            issued_at=now,
            expires_at=now + timedelta(days=identity_ttl_days)
        )
        agent.workload_identity = workload_identity
        
        agent.current_scopes = list(agent.identity.capabilities)
        
        await self._transition_state(
            agent, LifecycleState.PROVISIONED,
            AuditEventType.AGENT_PROVISIONED,
            {"workload_identity": workload_identity.spiffe_id}
        )
        
        return agent
    
    async def activate_agent(self, agent_id: uuid.UUID) -> Agent:
        """Activate agent for operations."""
        agent = await self._identity_manager.get_agent(agent_id)
        return await self._transition_state(
            agent, LifecycleState.ACTIVE,
            AuditEventType.AGENT_ACTIVATED
        )
    
    async def suspend_agent(self, agent_id: uuid.UUID, reason: str = "") -> Agent:
        """Temporarily disable agent."""
        agent = await self._identity_manager.get_agent(agent_id)
        
        for token in agent.delegation_tokens:
            if not token.revoked:
                token.revoked = True
        
        return await self._transition_state(
            agent, LifecycleState.SUSPENDED,
            AuditEventType.AGENT_SUSPENDED,
            {"reason": reason, "tokens_revoked": len(agent.delegation_tokens)}
        )
    
    async def resume_agent(self, agent_id: uuid.UUID) -> Agent:
        """Re-enable suspended agent."""
        agent = await self._identity_manager.get_agent(agent_id)
        return await self._transition_state(
            agent, LifecycleState.ACTIVE,
            AuditEventType.AGENT_RESUMED
        )
    
    async def revoke_agent_credentials(self, agent_id: uuid.UUID, reason: str = "") -> Agent:
        """Invalidate all credentials for agent."""
        agent = await self._identity_manager.get_agent(agent_id)
        
        if agent.workload_identity:
            agent.workload_identity.revoked = True
        
        for token in agent.delegation_tokens:
            token.revoked = True
        
        return await self._transition_state(
            agent, LifecycleState.REVOKED,
            AuditEventType.AGENT_REVOKED,
            {"reason": reason}
        )
    
    async def deprovision_agent(self, agent_id: uuid.UUID, reason: str = "") -> None:
        """Complete removal: terminate identity, clean up all access."""
        agent = await self._identity_manager.get_agent(agent_id)
        
        await self._transition_state(
            agent, LifecycleState.DELETED,
            AuditEventType.AGENT_DELETED,
            {"reason": reason}
        )
        
        if agent.workload_identity:
            agent.workload_identity.revoked = True
        
        logger.info(f"Agent {agent.name} fully de-provisioned")
    
    async def _log_event(
        self,
        event_type: AuditEventType,
        agent_id: uuid.UUID,
        details: Dict[str, Any] = None,
        actor_id: Optional[uuid.UUID] = None
    ) -> AuditEvent:
        """Log an audit event."""
        event = AuditEvent(
            event_type=event_type,
            agent_id=agent_id,
            actor_id=actor_id,
            details=details or {}
        )
        
        self._audit_log.append(event)
        
        if agent_id in self._identity_manager._registry:
            self._identity_manager._registry[agent_id].audit_trail.append(event.to_dict())
        
        logger.debug(f"Audit: {event_type.value} for agent {agent_id}")
        return event
    
    async def get_audit_trail(
        self,
        agent_id: uuid.UUID,
        time_range: Optional[tuple] = None
    ) -> List[Dict]:
        """Retrieve audit events for agent."""
        if agent_id not in self._identity_manager._registry:
            raise AgentNotFoundError(f"Agent {agent_id} not found")
        
        events = self._identity_manager._registry[agent_id].audit_trail
        
        if time_range:
            start, end = time_range
            events = [
                e for e in events
                if start <= datetime.fromisoformat(e["timestamp"]) <= end
            ]
        
        return events


# ============================================================================
# DELEGATION MANAGER
# ============================================================================

class DelegationManager:
    """
    Manages delegation chains with scope attenuation.
    
    Implements On-Behalf-Of (OBO) patterns from the OpenID whitepaper.
    """
    
    def __init__(self, identity_manager: AgentIdentityManager):
        self._identity_manager = identity_manager
        logger.info("DelegationManager initialized")
    
    async def delegate_to_agent(
        self,
        delegator_id: uuid.UUID,
        delegatee_id: uuid.UUID,
        scope: List[str],
        constraints: Optional[TokenConstraints] = None,
        ttl_minutes: int = 60
    ) -> DelegationToken:
        """Create delegated authority from delegator to delegatee."""
        delegator = await self._identity_manager.get_agent(delegator_id)
        delegatee = await self._identity_manager.get_agent(delegatee_id)
        
        if delegator.lifecycle_state != LifecycleState.ACTIVE:
            raise AgentIdentityError(f"Delegator must be ACTIVE, currently: {delegator.lifecycle_state.value}")
        
        valid_scopes = [s for s in scope if s in delegator.current_scopes]
        if not valid_scopes:
            raise InsufficientScopeError("Requested scope contains permissions not held by delegator")
        
        token = DelegationToken(
            token_id=uuid.uuid4(),
            issuer_id=delegator_id,
            holder_id=delegatee_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=valid_scopes,
            constraints=constraints or TokenConstraints()
        )
        
        delegatee.delegation_tokens.append(token)
        
        logger.info(f"Delegation: {delegator.name} -> {delegatee.name} scope={valid_scopes}")
        
        return token
    
    async def attenuate_scope(
        self,
        token_id: uuid.UUID,
        new_scope: List[str],
        additional_constraints: Optional[TokenConstraints] = None,
        ttl_minutes: int = 30
    ) -> DelegationToken:
        """Create down-scoped token from existing token."""
        parent_token = None
        holder_agent = None
        
        for agent in self._identity_manager._registry.values():
            for token in agent.delegation_tokens:
                if token.token_id == token_id:
                    parent_token = token
                    holder_agent = agent
                    break
            if parent_token:
                break
        
        if not parent_token:
            raise AgentIdentityError(f"Token {token_id} not found")
        
        if not parent_token.is_valid():
            raise TokenExpiredError("Parent token is invalid or expired")
        
        valid_scopes = [s for s in new_scope if s in parent_token.scope]
        if not valid_scopes:
            raise InsufficientScopeError("Attenuated scope must be subset of parent scope")
        
        merged_constraints = parent_token.constraints
        if additional_constraints:
            constraints_dict = asdict(merged_constraints)
            additional_dict = asdict(additional_constraints)
            
            for key, value in additional_dict.items():
                if value is not None:
                    constraints_dict[key] = value
            
            merged_constraints = TokenConstraints(**constraints_dict)
        
        new_token = DelegationToken(
            token_id=uuid.uuid4(),
            issuer_id=parent_token.holder_id,
            holder_id=parent_token.holder_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=valid_scopes,
            constraints=merged_constraints,
            parent_token_id=token_id
        )
        
        holder_agent.delegation_tokens.append(new_token)
        
        logger.info(f"Scope attenuated: {token_id} -> {new_token.token_id} scope={valid_scopes}")
        
        return new_token
    
    async def verify_delegation_chain(self, token_id: uuid.UUID) -> bool:
        """Verify complete delegation chain back to original user."""
        visited = set()
        current_token_id = token_id
        
        while current_token_id:
            if current_token_id in visited:
                return False
            
            visited.add(current_token_id)
            
            token = None
            for agent in self._identity_manager._registry.values():
                for t in agent.delegation_tokens:
                    if t.token_id == current_token_id:
                        token = t
                        break
                if token:
                    break
            
            if not token:
                return False
            
            if token.revoked:
                return False
            
            if not token.is_valid():
                return False
            
            current_token_id = token.parent_token_id
        
        return True
    
    async def authorize_action(
        self,
        agent_id: uuid.UUID,
        required_scope: str,
        resource: Optional[str] = None
    ) -> bool:
        """Check if agent is authorized for specific action."""
        agent = await self._identity_manager.get_agent(agent_id)
        
        if agent.lifecycle_state != LifecycleState.ACTIVE:
            return False
        
        if required_scope not in agent.current_scopes:
            return False
        
        return True


# ============================================================================
# TOKEN MANAGER
# ============================================================================

class TokenManager:
    """
    Manages access tokens with validation, refresh, and revocation.
    """
    
    def __init__(self, identity_manager: AgentIdentityManager):
        self._identity_manager = identity_manager
        self._revoked_tokens: set = set()
        logger.info("TokenManager initialized")
    
    async def issue_token(
        self,
        agent_id: uuid.UUID,
        scope: List[str],
        ttl_minutes: int = 60,
        constraints: Optional[TokenConstraints] = None
    ) -> DelegationToken:
        """Issue access token for agent."""
        agent = await self._identity_manager.get_agent(agent_id)
        
        if agent.lifecycle_state not in [LifecycleState.ACTIVE, LifecycleState.PROVISIONED]:
            raise AgentIdentityError(f"Agent must be ACTIVE or PROVISIONED, currently: {agent.lifecycle_state.value}")
        
        token = DelegationToken(
            token_id=uuid.uuid4(),
            issuer_id=agent_id,
            holder_id=agent_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=scope,
            constraints=constraints or TokenConstraints()
        )
        
        agent.delegation_tokens.append(token)
        
        logger.info(f"Token issued: {token.token_id} for agent {agent.name}")
        return token
    
    async def refresh_token(
        self,
        old_token_id: uuid.UUID,
        new_scope: Optional[List[str]] = None,
        ttl_minutes: int = 60
    ) -> DelegationToken:
        """Refresh token, optionally narrowing scope."""
        old_token = None
        agent = None
        
        for a in self._identity_manager._registry.values():
            for t in a.delegation_tokens:
                if t.token_id == old_token_id:
                    old_token = t
                    agent = a
                    break
            if old_token:
                break
        
        if not old_token:
            raise AgentIdentityError(f"Token {old_token_id} not found")
        
        scope = new_scope if new_scope else old_token.scope
        valid_scope = [s for s in scope if s in old_token.scope]
        
        new_token = DelegationToken(
            token_id=uuid.uuid4(),
            issuer_id=old_token.issuer_id,
            holder_id=old_token.holder_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=valid_scope,
            constraints=old_token.constraints,
            parent_token_id=old_token_id
        )
        
        old_token.revoked = True
        if agent:
            agent.delegation_tokens.append(new_token)
        
        logger.info(f"Token refreshed: {old_token_id} -> {new_token.token_id}")
        return new_token
    
    async def validate_token(self, token_id: uuid.UUID) -> bool:
        """Validate token integrity and freshness."""
        if token_id in self._revoked_tokens:
            return False
        
        for agent in self._identity_manager._registry.values():
            for token in agent.delegation_tokens:
                if token.token_id == token_id:
                    return token.is_valid()
        
        return False
    
    async def revoke_token(self, token_id: uuid.UUID) -> None:
        """Immediately invalidate token."""
        self._revoked_tokens.add(token_id)
        
        for agent in self._identity_manager._registry.values():
            for token in agent.delegation_tokens:
                if token.token_id == token_id:
                    token.revoked = True
                    logger.info(f"Token revoked: {token_id}")
                    return
        
        logger.warning(f"Token {token_id} not found in registry")
    
    async def propagate_revocation(self, root_token_id: uuid.UUID) -> int:
        """Propagate revocation through delegation chain."""
        revoked_count = 0
        to_revoke = [root_token_id]
        visited = set()
        
        while to_revoke:
            token_id = to_revoke.pop()
            
            if token_id in visited:
                continue
            visited.add(token_id)
            
            for agent in self._identity_manager._registry.values():
                for token in agent.delegation_tokens:
                    if token.token_id == token_id and not token.revoked:
                        token.revoked = True
                        revoked_count += 1
                        logger.info(f"Propagated revocation: {token_id}")
            
            for agent in self._identity_manager._registry.values():
                for token in agent.delegation_tokens:
                    if token.parent_token_id == token_id:
                        to_revoke.append(token.token_id)
        
        logger.info(f"Revocation propagated: {revoked_count} tokens revoked")
        return revoked_count


# ============================================================================
# GUARDRAIL MANAGER
# ============================================================================

class GuardrailManager:
    """
    Implements guardrails for agent behavior.
    """
    
    def __init__(self, identity_manager: AgentIdentityManager):
        self._identity_manager = identity_manager
        self._apply_count = 0
        logger.info("GuardrailManager initialized")
    
    async def enforce_guardrails(
        self,
        agent_id: uuid.UUID,
        action: str,
        context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Apply guardrails to constrain agent action."""
        agent = await self._identity_manager.get_agent(agent_id)
        result = {"allowed": True, "modifications": [], "reason": None}
        
        if "resource_type" in context:
            resource_type = context["resource_type"]
            if resource_type in ["pii", "financial", "health"]:
                result["allowed"] = False
                result["reason"] = f"Restricted resource type: {resource_type}"
                self._apply_count += 1
                logger.warning(f"Guardrail denied {action} for agent {agent.name}")
        
        if context.get("contains_sensitive_data"):
            result["modifications"].append({
                "type": "mask",
                "fields": ["ssn", "credit_card", "password", "api_key"]
            })
        
        if context.get("rate_limited"):
            result["allowed"] = False
            result["reason"] = "Rate limit exceeded"
        
        if not result["allowed"] or result["modifications"]:
            self._apply_count += 1
            logger.info(f"Guardrail applied to {agent.name}: {result}")
        
        return result
    
    async def check_data_access(
        self,
        agent_id: uuid.UUID,
        data_type: str
    ) -> bool:
        """Check if agent can access specific data type."""
        restricted_types = ["pii", "financial", "health", "credentials"]
        
        if data_type in restricted_types:
            logger.warning(f"Data access denied: {data_type}")
            return True
        
        return False


# ============================================================================
# SCOPE MANAGER
# ============================================================================

class ScopeManager:
    """Manages agent scopes with attenuation and validation."""
    
    SCOPE_DEFINITIONS = {
        "read": "Read access to resources",
        "write": "Write access to resources",
        "delete": "Delete resources",
        "execute": "Execute actions",
        "admin": "Administrative access",
        "code_generation": "Generate code",
        "code_review": "Review code changes",
        "git_operations": "Git operations",
        "web_search": "Web search capability",
        "file_read": "Read files",
        "file_write": "Write files",
        "terminal_execute": "Execute terminal commands",
        "api_call": "Make API calls",
        "mcp_tool_use": "Use MCP tools"
    }
    
    def __init__(self):
        self._custom_scopes: Dict[str, str] = {}
        logger.info("ScopeManager initialized")
    
    def narrow_scope(
        self,
        current_scope: List[str],
        requested_scope: List[str],
        attenuation_factor: float = 0.5
    ) -> List[str]:
        """Narrow scope according to attenuation factor."""
        valid_scope = [s for s in requested_scope if s in current_scope]
        num_allowed = max(1, int(len(valid_scope) * attenuation_factor))
        
        priority_order = ["read", "file_read", "code_generation", "code_review",
                         "write", "file_write", "execute", "terminal_execute"]
        
        prioritized = sorted(valid_scope, key=lambda s: (
            priority_order.index(s) if s in priority_order else 999
        ))
        
        return prioritized[:num_allowed]
    
    def validate_scope(self, scope: List[str]) -> bool:
        """Validate that all scopes are known."""
        all_scopes = set(self.SCOPE_DEFINITIONS.keys()) | set(self._custom_scopes.keys())
        return all(s in all_scopes for s in scope)
    
    def expand_scope(
        self,
        current_scope: List[str],
        requested_expansion: List[str]
    ) -> List[str]:
        """Expand scope based on trust level."""
        return list(set(current_scope) | set(requested_expansion))
    
    def check_bounds(
        self,
        scope: List[str],
        action: str,
        constraints: TokenConstraints
    ) -> bool:
        """Check if action is within scope bounds."""
        action_scope_map = {
            "read_file": ["read", "file_read"],
            "write_file": ["write", "file_write"],
            "execute_command": ["execute", "terminal_execute"],
            "make_api_call": ["api_call"],
            "use_mcp_tool": ["mcp_tool_use"]
        }
        
        required = action_scope_map.get(action, [])
        return any(s in scope for s in required)


# ============================================================================
# MAIN AGENT SYSTEM
# ============================================================================

class AgentIdentityLifecycleSystem:
    """
    Complete Agent Identity and Lifecycle Management System.
    """
    
    def __init__(self):
        logger.info("=" * 60)
        logger.info("AGENT IDENTITY & LIFECYCLE SYSTEM")
        logger.info("=" * 60)
        logger.info("Based on: OpenID Foundation Agentic AI Identity")
        logger.info("          Okta Data Model concepts")
        logger.info("          OpenHands SDK patterns")
        logger.info("=" * 60)
        
        self.identity_manager = AgentIdentityManager()
        self.lifecycle_manager = LifecycleManager(self.identity_manager)
        self.delegation_manager = DelegationManager(self.identity_manager)
        self.token_manager = TokenManager(self.identity_manager)
        self.guardrail_manager = GuardrailManager(self.identity_manager)
        self.scope_manager = ScopeManager()
        
        logger.info("All managers initialized successfully")
        logger.info("")
    
    async def register_and_provision(
        self,
        name: str,
        agent_type: AgentType,
        owner_id: uuid.UUID,
        capabilities: List[str],
        provider: str = "unknown",
        model: str = "unknown",
        version: str = "1.0.0"
    ) -> Agent:
        """Register a new agent and provision it in one step."""
        identity = await self.identity_manager.register_agent(
            name=name,
            agent_type=agent_type,
            owner_id=owner_id,
            capabilities=capabilities,
            provider=provider,
            model=model,
            version=version
        )
        
        agent = await self.lifecycle_manager.provision_agent(identity.agent_id)
        agent = await self.lifecycle_manager.activate_agent(identity.agent_id)
        
        return agent
    
    async def get_agent_status(self, agent_id: uuid.UUID) -> Dict[str, Any]:
        """Get comprehensive agent status."""
        agent = await self.identity_manager.get_agent(agent_id)
        
        return {
            "agent_id": str(agent.agent_id),
            "name": agent.name,
            "state": agent.lifecycle_state.value,
            "identity": agent.identity.to_dict(),
            "workload_identity": agent.workload_identity.to_dict() if agent.workload_identity else None,
            "current_scopes": agent.current_scopes,
            "active_tokens": len([t for t in agent.delegation_tokens if t.is_valid()]),
            "created_at": agent.created_at.isoformat(),
            "last_active": agent.last_active_at.isoformat() if agent.last_active_at else None
        }


# ============================================================================
# DEMONSTRATION
# ============================================================================

async def demonstrate_system():
    """Demonstrate the Agent Identity and Lifecycle System."""
    
    print("\n" + "=" * 70)
    print("AGENT IDENTITY & LIFECYCLE SYSTEM DEMONSTRATION")
    print("=" * 70 + "\n")
    
    system = AgentIdentityLifecycleSystem()
    
    user_id = uuid.uuid4()
    print(f"Created user: {user_id}\n")
    
    print("-" * 50)
    print("1. REGISTERING & PROVISIONING AGENTS")
    print("-" * 50)
    
    primary_agent = await system.register_and_provision(
        name="coding-assistant",
        agent_type=AgentType.AUTONOMOUS,
        owner_id=user_id,
        capabilities=["code_generation", "git_operations", "code_review", "terminal_execute"],
        provider="anthropic",
        model="claude-sonnet-4"
    )
    print(f"Created primary agent: {primary_agent.name} (ID: {primary_agent.agent_id})")
    
    review_agent_identity = await system.identity_manager.register_agent(
        name="review-bot",
        agent_type=AgentType.ASSISTANT,
        owner_id=user_id,
        capabilities=["code_review", "read", "file_read"],
        provider="openai",
        model="gpt-5"
    )
    await system.lifecycle_manager.provision_agent(review_agent_identity.agent_id)
    await system.lifecycle_manager.activate_agent(review_agent_identity.agent_id)
    review_agent = await system.identity_manager.get_agent(review_agent_identity.agent_id)
    print(f"Created review agent: {review_agent.name} (ID: {review_agent.agent_id})")
    
    print()
    
    print("-" * 50)
    print("2. DELEGATION & SCOPE ATTENUATION")
    print("-" * 50)
    
    delegation_token = await system.delegation_manager.delegate_to_agent(
        delegator_id=primary_agent.agent_id,
        delegatee_id=review_agent.agent_id,
        scope=["code_review", "read", "file_read"],
        constraints=TokenConstraints(
            max_executions=10,
            max_duration_seconds=3600,
            allowed_resources=["repository", "pr"]
        ),
        ttl_minutes=60
    )
    print(f"Delegation created: {delegation_token.token_id}")
    print(f"   Scope: {delegation_token.scope}")
    print(f"   Constraints: max_executions={delegation_token.constraints.max_executions}")
    
    attenuated_token = await system.delegation_manager.attenuate_scope(
        token_id=delegation_token.token_id,
        new_scope=["code_review", "read"],
        additional_constraints=TokenConstraints(max_executions=5),
        ttl_minutes=30
    )
    print(f"\nAttenuated token: {attenuated_token.token_id}")
    print(f"   New scope: {attenuated_token.scope}")
    print(f"   Remaining executions: {attenuated_token.constraints.max_executions}")
    
    is_valid = await system.delegation_manager.verify_delegation_chain(attenuated_token.token_id)
    print(f"\nDelegation chain valid: {is_valid}")
    
    print()
    
    print("-" * 50)
    print("3. TOKEN MANAGEMENT")
    print("-" * 50)
    
    token = await system.token_manager.issue_token(
        agent_id=primary_agent.agent_id,
        scope=["code_generation", "git_operations", "mcp_tool_use"],
        ttl_minutes=30
    )
    print(f"Token issued: {token.token_id}")
    print(f"   Scope: {token.scope}")
    print(f"   Valid: {await system.token_manager.validate_token(token.token_id)}")
    
    new_token = await system.token_manager.refresh_token(token.token_id, ttl_minutes=60)
    print(f"\nToken refreshed: {new_token.token_id}")
    print(f"   Expires: {new_token.expires_at}")
    
    print()
    
    print("-" * 50)
    print("4. GUARDRAIL ENFORCEMENT")
    print("-" * 50)
    
    result = await system.guardrail_manager.enforce_guardrails(
        agent_id=primary_agent.agent_id,
        action="access_pii",
        context={"resource_type": "financial", "contains_sensitive_data": True}
    )
    print(f"Guardrail check for restricted action: {result}")
    
    result = await system.guardrail_manager.enforce_guardrails(
        agent_id=primary_agent.agent_id,
        action="read_file",
        context={"resource_type": "code"}
    )
    print(f"Guardrail check for allowed action: {result}")
    
    print()
    
    print("-" * 50)
    print("5. LIFECYCLE TRANSITIONS")
    print("-" * 50)
    
    status = await system.get_agent_status(primary_agent.agent_id)
    print(f"Current status: {status['state']}")
    
    await system.lifecycle_manager.suspend_agent(primary_agent.agent_id, "Maintenance")
    status = await system.get_agent_status(primary_agent.agent_id)
    print(f"After suspend: {status['state']}")
    
    await system.lifecycle_manager.resume_agent(primary_agent.agent_id)
    status = await system.get_agent_status(primary_agent.agent_id)
    print(f"After resume: {status['state']}")
    
    print()
    
    print("-" * 50)
    print("6. AUDIT TRAIL")
    print("-" * 50)
    
    trail = await system.lifecycle_manager.get_audit_trail(primary_agent.agent_id)
    print(f"Total audit events: {len(trail)}")
    for event in trail[-5:]:
        print(f"   - {event['timestamp']}: {event['event_type']}")
    
    print()
    
    print("-" * 50)
    print("7. REVOCATION PROPAGATION")
    print("-" * 50)
    
    agent = await system.identity_manager.get_agent(primary_agent.agent_id)
    tokens_before = len(agent.delegation_tokens)
    print(f"Tokens before revocation: {tokens_before}")
    
    revoked_count = await system.token_manager.propagate_revocation(delegation_token.token_id)
    print(f"Tokens revoked: {revoked_count}")
    
    print()
    print("=" * 70)
    print("DEMONSTRATION COMPLETE")
    print("=" * 70)
    
    return system


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

def main():
    """Main entry point for the agent system demonstration."""
    print("""
+========================================================================+
|                                                                        |
|            AGENT IDENTITY & LIFECYCLE MANAGEMENT SYSTEM                |
|                                                                        |
|  Based on:                                                             |
|    - OpenID Foundation: Identity Management for Agentic AI (2025)        |
|    - Okta Data Model concepts                                           |
|    - Industry best practices for IAM and OAuth 2.1                       |
|                                                                        |
+========================================================================+
""")
    asyncio.run(demonstrate_system())


if __name__ == "__main__":
    main()
