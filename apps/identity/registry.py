"""
Agent Identity SDK - Core Registry
Based on OpenID Foundation "Identity Management for Agentic AI" (October 2025)

This module provides the core agent identity management functionality including:
- Agent registration with unique identities
- Lifecycle state machine (provisioned → active → revoked → deprovisioned)
- Delegation with scope attenuation
- Token management with cascade revocation
- Audit trail
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional
import uuid


class AgentType(Enum):
    """
    Agent types based on autonomy level.
    From: OpenID Foundation Agentic AI Identity
    """
    AUTONOMOUS = "autonomous"
    ASSISTANT = "assistant"
    TOOL = "tool"
    HYBRID = "hybrid"


class LifecycleState(Enum):
    """
    Agent lifecycle states grounded in OpenID whitepaper terminology.
    
    States:
    - provisioned: Agent created and registered but not working
    - active: Agent has live credentials and is doing work
    - revoked: Credentials switched off, session ended
    - deprovisioned: Identity and access permanently removed
    
    Source: OpenID Foundation "Identity Management for Agentic AI" Key Terms
    """
    PROVISIONED = "provisioned"
    ACTIVE = "active"
    REVOKED = "revoked"
    DEPROVISIONED = "deprovisioned"


@dataclass
class WorkloadIdentity:
    """
    SPIFFE-style workload identity for agents.
    Provides verifiable identity for agent-to-agent and agent-to-service communication.
    """
    spiffe_id: str
    public_key: str
    issued_at: datetime
    expires_at: datetime
    revoked: bool = False
    
    def is_valid(self) -> bool:
        return not self.revoked and datetime.utcnow() < self.expires_at


@dataclass 
class TokenConstraints:
    """
    Constraints on token usage to enforce least privilege.
    Based on OpenID whitepaper: scope attenuation and execution bounds.
    """
    max_executions: Optional[int] = None
    max_duration_seconds: Optional[int] = None
    allowed_resources: Optional[List[str]] = None
    denied_resources: Optional[List[str]] = None


@dataclass
class DelegationToken:
    """
    Delegated authority token with scope attenuation.
    Implements On-Behalf-Of pattern from OpenID whitepaper.
    """
    token_id: str
    issuer_id: str
    holder_id: str
    issued_at: datetime
    expires_at: datetime
    scope: List[str]
    constraints: TokenConstraints
    parent_token_id: Optional[str] = None
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


@dataclass
class AuditEvent:
    """Audit event for logging agent actions."""
    event_id: str
    timestamp: datetime
    event_type: str
    agent_id: Optional[str] = None
    actor_id: Optional[str] = None
    from_state: Optional[str] = None
    to_state: Optional[str] = None
    details: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AgentIdentity:
    """Agent identity with unique identifier and metadata."""
    agent_id: str
    name: str
    agent_type: AgentType
    owner_id: str
    capabilities: List[str]
    provider: str
    model: str
    version: str
    created_at: datetime
    did: Optional[str] = None
    oidc_subject: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Agent:
    """Complete agent entity with identity, state, and credentials."""
    identity: AgentIdentity
    state: LifecycleState
    workload_identity: Optional[WorkloadIdentity] = None
    delegation_tokens: List[DelegationToken] = field(default_factory=list)
    current_scopes: List[str] = field(default_factory=list)
    audit_trail: List[AuditEvent] = field(default_factory=list)
    entered_state_at: datetime = field(default_factory=datetime.utcnow)
    owners: List[str] = field(default_factory=list)
    entitlements: List[str] = field(default_factory=list)
    
    @property
    def agent_id(self) -> str:
        return self.identity.agent_id


class AgentRegistry:
    """
    Main registry for agent identity management.
    
    Implements the lifecycle state machine from the OpenID whitepaper:
    - provisioned: Initial state after registration
    - active: Agent working with valid credentials
    - revoked: Credentials invalidated, session ended
    - deprovisioned: Complete removal of identity and access
    
    Features:
    - Lifecycle state machine with transition guards
    - On-Behalf-Of delegation with scope attenuation
    - Token management with cascade revocation
    - Complete audit trail for compliance
    """
    
    # Valid lifecycle transitions (grounded in OpenID whitepaper)
    VALID_TRANSITIONS = {
        LifecycleState.PROVISIONED: [LifecycleState.ACTIVE, LifecycleState.DEPROVISIONED],
        LifecycleState.ACTIVE: [LifecycleState.REVOKED, LifecycleState.DEPROVISIONED],
        LifecycleState.REVOKED: [LifecycleState.DEPROVISIONED],
        LifecycleState.DEPROVISIONED: [],
    }
    
    def __init__(self):
        self._agents: Dict[str, Agent] = {}
        self._audit_log: List[AuditEvent] = []
    
    def create_agent(
        self,
        name: str,
        agent_type: AgentType,
        owner_id: str,
        capabilities: List[str],
        provider: str = "unknown",
        model: str = "unknown",
        version: str = "1.0.0",
        did: Optional[str] = None,
        **metadata
    ) -> Agent:
        """
        Create and register a new agent.
        
        The agent is created in 'provisioned' state.
        Use provision() to issue credentials and activate() to start operations.
        """
        agent_id = str(uuid.uuid4())
        
        identity = AgentIdentity(
            agent_id=agent_id,
            name=name,
            agent_type=agent_type,
            owner_id=owner_id,
            capabilities=capabilities,
            provider=provider,
            model=model,
            version=version,
            created_at=datetime.utcnow(),
            did=did,
            metadata=metadata
        )
        
        agent = Agent(
            identity=identity,
            state=LifecycleState.PROVISIONED,
            current_scopes=list(capabilities),
            owners=[owner_id],
            entitlements=list(capabilities)
        )
        
        self._agents[agent_id] = agent
        self._log_event("agent_created", agent_id, owner_id, None, "provisioned")
        
        return agent
    
    def provision(self, agent_id: str, ttl_days: int = 30) -> Agent:
        """
        Issue credentials and set up access for agent.
        
        Transitions: provisioned → active
        """
        agent = self._get_agent(agent_id)
        
        # Already active? Skip
        if agent.state == LifecycleState.ACTIVE:
            return agent
        
        self._validate_transition(agent.state, LifecycleState.ACTIVE)
        
        # Generate workload identity (SPIFFE-style)
        spiffe_id = f"spiffe://agentic-ai.org/agent/{agent_id}"
        workload_identity = WorkloadIdentity(
            spiffe_id=spiffe_id,
            public_key=str(uuid.uuid4()),
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(days=ttl_days)
        )
        
        agent.workload_identity = workload_identity
        self._transition_state(agent, LifecycleState.ACTIVE, "provisioned")
        
        return agent
    
    def activate(self, agent_id: str) -> Agent:
        """
        Activate agent for operations.
        
        Agent must be in 'provisioned' state.
        """
        agent = self._get_agent(agent_id)
        # Can only activate from provisioned state
        if agent.state == LifecycleState.PROVISIONED:
            self._transition_state(agent, LifecycleState.ACTIVE, None)
        elif agent.state == LifecycleState.ACTIVE:
            pass  # Already active
        else:
            raise InvalidLifecycleTransitionError(
                f"Cannot activate from {agent.state.value} state"
            )
        return agent
    
    def revoke(self, agent_id: str, reason: str = "") -> Agent:
        """
        Revoke agent credentials and end session.
        
        Transitions: active → revoked
        Source: OpenID whitepaper "The Revocation Challenge"
        """
        agent = self._get_agent(agent_id)
        self._transition_state(agent, LifecycleState.REVOKED, reason)
        
        # Revoke all active tokens
        for token in agent.delegation_tokens:
            if not token.revoked:
                token.revoked = True
        
        return agent
    
    def deprovision(self, agent_id: str, reason: str = "") -> Agent:
        """
        Permanently remove agent identity and all access.
        
        This is the final step in the lifecycle.
        Source: OpenID whitepaper "De-provisioning & Off-boarding"
        """
        agent = self._get_agent(agent_id)
        
        # Revoke workload identity
        if agent.workload_identity:
            agent.workload_identity.revoked = True
        
        # Revoke all tokens
        for token in agent.delegation_tokens:
            token.revoked = True
        
        # Clear entitlements
        agent.entitlements = []
        
        self._transition_state(agent, LifecycleState.DEPROVISIONED, reason)
        return agent
    
    def delegate(
        self,
        delegator_id: str,
        delegatee_id: str,
        scope: List[str],
        max_executions: Optional[int] = None,
        ttl_minutes: int = 60
    ) -> DelegationToken:
        """
        Create On-Behalf-Of delegation.
        
        Implements delegation pattern from OpenID whitepaper.
        Scope is attenuated to only include permissions the delegator holds.
        """
        delegator = self._get_agent(delegator_id)
        
        if delegator.state != LifecycleState.ACTIVE:
            raise InvalidLifecycleTransitionError(
                f"Delegator must be ACTIVE, currently: {delegator.state.value}"
            )
        
        # Attenuate scope - only include what delegator has
        valid_scopes = [s for s in scope if s in delegator.current_scopes]
        if not valid_scopes:
            raise InsufficientScopeError("Requested scope not held by delegator")
        
        delegatee = self._get_agent(delegatee_id)
        
        token = DelegationToken(
            token_id=str(uuid.uuid4()),
            issuer_id=delegator_id,
            holder_id=delegatee_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=valid_scopes,
            constraints=TokenConstraints(max_executions=max_executions)
        )
        
        delegatee.delegation_tokens.append(token)
        self._log_event("delegation_created", delegator_id, delegator_id, 
                        details={"delegatee_id": delegatee_id, "scope": valid_scopes})
        
        return token
    
    def attenuate_scope(
        self,
        token_id: str,
        new_scope: List[str],
        max_executions: Optional[int] = None,
        ttl_minutes: int = 30
    ) -> DelegationToken:
        """
        Create down-scoped token from existing token.
        
        Implements scope attenuation from OpenID whitepaper.
        """
        parent = self._find_token(token_id)
        if not parent or not parent.is_valid():
            raise TokenExpiredError("Parent token is invalid or expired")
        
        # Attenuate scope
        valid_scopes = [s for s in new_scope if s in parent.scope]
        if not valid_scopes:
            raise InsufficientScopeError("Attenuated scope must be subset of parent")
        
        new_token = DelegationToken(
            token_id=str(uuid.uuid4()),
            issuer_id=parent.holder_id,
            holder_id=parent.holder_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=valid_scopes,
            constraints=TokenConstraints(max_executions=max_executions),
            parent_token_id=token_id
        )
        
        holder = self._get_agent(parent.holder_id)
        holder.delegation_tokens.append(new_token)
        
        self._log_event("scope_attenuated", parent.holder_id, None,
                        details={"parent_token": token_id, "new_scope": valid_scopes})
        
        return new_token
    
    def verify_delegation_chain(self, token_id: str) -> bool:
        """
        Verify complete delegation chain back to original issuer.
        
        Detects cycles and broken chains.
        """
        visited = set()
        current_id = token_id
        
        while current_id:
            if current_id in visited:
                return False
            visited.add(current_id)
            
            token = self._find_token(current_id)
            if not token or token.revoked or not token.is_valid():
                return False
            
            current_id = token.parent_token_id
        
        return True
    
    def issue_token(
        self,
        agent_id: str,
        scope: List[str],
        ttl_minutes: int = 60
    ) -> DelegationToken:
        """Issue access token for agent."""
        agent = self._get_agent(agent_id)
        
        if agent.state not in [LifecycleState.ACTIVE, LifecycleState.PROVISIONED]:
            raise InvalidLifecycleTransitionError("Agent must be ACTIVE or PROVISIONED")
        
        token = DelegationToken(
            token_id=str(uuid.uuid4()),
            issuer_id=agent_id,
            holder_id=agent_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=scope,
            constraints=TokenConstraints()
        )
        
        agent.delegation_tokens.append(token)
        self._log_event("token_issued", agent_id)
        
        return token
    
    def refresh_token(self, token_id: str, ttl_minutes: int = 60) -> DelegationToken:
        """Refresh token with same scope."""
        old = self._find_token(token_id)
        if not old:
            raise TokenNotFoundError(f"Token {token_id} not found")
        
        new_token = DelegationToken(
            token_id=str(uuid.uuid4()),
            issuer_id=old.issuer_id,
            holder_id=old.holder_id,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
            scope=old.scope,
            constraints=old.constraints,
            parent_token_id=token_id
        )
        
        old.revoked = True
        
        holder = self._get_agent(old.holder_id)
        holder.delegation_tokens.append(new_token)
        
        self._log_event("token_refreshed", old.issuer_id,
                        details={"old_token": token_id, "new_token": new_token.token_id})
        
        return new_token
    
    def revoke_token(self, token_id: str) -> None:
        """Immediately invalidate token."""
        for agent in self._agents.values():
            for token in agent.delegation_tokens:
                if token.token_id == token_id:
                    token.revoked = True
                    self._log_event("token_revoked", agent.agent_id,
                                   details={"token_id": token_id})
                    return
        raise TokenNotFoundError(f"Token {token_id} not found")
    
    def propagate_revocation(self, root_token_id: str) -> int:
        """
        Propagate revocation through delegation chain.
        
        Source: OpenID whitepaper "The Revocation Challenge"
        """
        revoked = 0
        to_revoke = [root_token_id]
        visited = set()
        
        while to_revoke:
            current = to_revoke.pop()
            if current in visited:
                continue
            visited.add(current)
            
            token = self._find_token(current)
            if token and not token.revoked:
                token.revoked = True
                revoked += 1
            
            # Find child tokens
            for agent in self._agents.values():
                for t in agent.delegation_tokens:
                    if t.parent_token_id == current:
                        to_revoke.append(t.token_id)
        
        return revoked
    
    def validate_token(self, token_id: str) -> bool:
        """Validate token integrity and freshness."""
        token = self._find_token(token_id)
        return token is not None and token.is_valid()
    
    def get_agent(self, agent_id: str) -> Optional[Agent]:
        """Get agent by ID."""
        return self._agents.get(agent_id)
    
    def list_agents(self, state: Optional[LifecycleState] = None) -> List[Agent]:
        """List all agents, optionally filtered by state."""
        agents = list(self._agents.values())
        if state:
            agents = [a for a in agents if a.state == state]
        return agents
    
    def get_audit_trail(self, agent_id: str) -> List[AuditEvent]:
        """Get audit trail for agent."""
        agent = self._get_agent(agent_id)
        return list(agent.audit_trail)
    
    def _get_agent(self, agent_id: str) -> Agent:
        if agent_id not in self._agents:
            raise AgentNotFoundError(f"Agent {agent_id} not found")
        return self._agents[agent_id]
    
    def _validate_transition(self, from_state: LifecycleState, to_state: LifecycleState) -> None:
        if to_state not in self.VALID_TRANSITIONS.get(from_state, []):
            raise InvalidLifecycleTransitionError(
                f"Cannot transition from {from_state.value} to {to_state.value}"
            )
    
    def _transition_state(self, agent: Agent, new_state: LifecycleState, reason: Optional[str]) -> None:
        old_state = agent.state
        
        # Skip if no change
        if old_state == new_state:
            return
        
        self._validate_transition(old_state, new_state)
        
        agent.state = new_state
        agent.entered_state_at = datetime.utcnow()
        
        self._log_event(
            "lifecycle_changed",
            agent.agent_id,
            from_state=old_state.value,
            to_state=new_state.value,
            details={"reason": reason} if reason else {}
        )
    
    def _log_event(
        self,
        event_type: str,
        agent_id: Optional[str] = None,
        actor_id: Optional[str] = None,
        from_state: Optional[str] = None,
        to_state: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ) -> None:
        event = AuditEvent(
            event_id=str(uuid.uuid4()),
            timestamp=datetime.utcnow(),
            event_type=event_type,
            agent_id=agent_id,
            actor_id=actor_id,
            from_state=from_state,
            to_state=to_state,
            details=details or {}
        )
        
        self._audit_log.append(event)
        
        if agent_id and agent_id in self._agents:
            self._agents[agent_id].audit_trail.append(event)
    
    def _find_token(self, token_id: str) -> Optional[DelegationToken]:
        for agent in self._agents.values():
            for token in agent.delegation_tokens:
                if token.token_id == token_id:
                    return token
        return None


# Import errors for convenience
from .errors import (
    AgentNotFoundError,
    InvalidLifecycleTransitionError,
    TokenNotFoundError,
    TokenExpiredError,
    InsufficientScopeError,
)
