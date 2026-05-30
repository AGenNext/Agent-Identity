# Agent Identity SDK
# Based on OpenID Foundation "Identity Management for Agentic AI" (October 2025)

from .registry import AgentRegistry, AgentType, LifecycleState
from .errors import (
    AgentError,
    AgentNotFoundError,
    InvalidLifecycleTransitionError,
    TokenError,
)

__all__ = [
    "AgentRegistry",
    "AgentType", 
    "LifecycleState",
    "AgentError",
    "AgentNotFoundError",
    "InvalidLifecycleTransitionError",
    "TokenError",
]

__version__ = "0.1.0"
