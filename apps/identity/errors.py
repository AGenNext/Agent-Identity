"""
Agent Identity SDK - Error Types
Based on OpenID Foundation "Identity Management for Agentic AI" (October 2025)
"""


class AgentError(Exception):
    """Base exception for agent identity errors."""
    pass


class AgentNotFoundError(AgentError):
    """Raised when agent is not found in registry."""
    pass


class InvalidLifecycleTransitionError(AgentError):
    """Raised when lifecycle state transition is invalid."""
    pass


class TokenError(AgentError):
    """Base exception for token-related errors."""
    pass


class TokenNotFoundError(TokenError):
    """Raised when token is not found."""
    pass


class TokenExpiredError(TokenError):
    """Raised when token has expired."""
    pass


class TokenRevokedError(TokenError):
    """Raised when token has been revoked."""
    pass


class InsufficientScopeError(AgentError):
    """Raised when agent lacks required scope."""
    pass


class DelegationError(AgentError):
    """Raised when delegation fails."""
    pass


class DelegationChainBrokenError(DelegationError):
    """Raised when delegation chain verification fails."""
    pass
