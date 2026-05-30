"""
Agent Identity SDK - Demo
Based on OpenID Foundation "Identity Management for Agentic AI" (October 2025)

This demonstrates the agent identity lifecycle and delegation patterns.
"""

from apps.identity import AgentRegistry, AgentType, LifecycleState


def main():
    print("""
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║          🤖 AGENT IDENTITY SDK DEMO                                    ║
║          Based on OpenID Foundation "Identity Management for Agentic AI"  ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
""")
    
    registry = AgentRegistry()
    owner_id = "user_001"
    
    print(f"👤 Owner: {owner_id}\n")
    
    # 1. Register agents
    print("─" * 50)
    print("1️⃣  AGENT REGISTRATION")
    print("─" * 50)
    
    # Primary coding agent
    primary = registry.create_agent(
        name="coding-assistant",
        agent_type=AgentType.AUTONOMOUS,
        owner_id=owner_id,
        capabilities=["code_generation", "git_operations", "code_review", "terminal_execute"],
        provider="anthropic",
        model="claude-sonnet-4",
        version="1.0.0"
    )
    primary_id = primary.agent_id
    print(f"✅ Created: {primary.identity.name}")
    print(f"   State: {primary.state.value}")
    print(f"   Capabilities: {primary.identity.capabilities}")
    
    # Review agent
    review = registry.create_agent(
        name="review-bot",
        agent_type=AgentType.ASSISTANT,
        owner_id=owner_id,
        capabilities=["code_review", "read", "file_read"],
        provider="openai",
        model="gpt-5"
    )
    review_id = review.agent_id
    print(f"\n✅ Created: {review.identity.name}")
    print(f"   State: {review.state.value}")
    
    # 2. Provision and activate
    print("\n" + "─" * 50)
    print("2️⃣  PROVISION & ACTIVATION")
    print("─" * 50)
    
    registry.provision(primary_id)
    primary = registry.get_agent(primary_id)
    print(f"✅ {primary.identity.name} provisioned & activated")
    print(f"   Workload Identity: {primary.workload_identity.spiffe_id}")
    
    registry.provision(review_id)
    review = registry.get_agent(review_id)
    print(f"✅ {review.identity.name} provisioned & activated")
    
    # 3. Delegation
    print("\n" + "─" * 50)
    print("3️⃣  DELEGATION (On-Behalf-Of)")
    print("─" * 50)
    
    delegation = registry.delegate(
        delegator_id=primary_id,
        delegatee_id=review_id,
        scope=["code_review", "read", "file_read"],
        max_executions=10
    )
    print(f"🔗 Delegation created")
    print(f"   Token: {delegation.token_id[:8]}...")
    print(f"   Scope: {delegation.scope}")
    print(f"   Max executions: {delegation.constraints.max_executions}")
    
    # Attenuate scope
    attenuated = registry.attenuate_scope(
        token_id=delegation.token_id,
        new_scope=["code_review"],
        max_executions=5
    )
    print(f"\n📉 Scope attenuated")
    print(f"   New scope: {attenuated.scope}")
    print(f"   Max executions: {attenuated.constraints.max_executions}")
    
    # Verify chain
    chain_valid = registry.verify_delegation_chain(attenuated.token_id)
    print(f"\n🔍 Delegation chain valid: {chain_valid}")
    
    # 4. Token management
    print("\n" + "─" * 50)
    print("4️⃣  TOKEN MANAGEMENT")
    print("─" * 50)
    
    token = registry.issue_token(
        agent_id=primary_id,
        scope=["code_generation", "git_operations"]
    )
    print(f"🎫 Token issued: {token.token_id[:8]}...")
    print(f"   Valid: {registry.validate_token(token.token_id)}")
    
    new_token = registry.refresh_token(token.token_id)
    print(f"\n🔄 Token refreshed: {new_token.token_id[:8]}...")
    
    # 5. Revocation
    print("\n" + "─" * 50)
    print("5️⃣  REVOCATION & PROPAGATION")
    print("─" * 50)
    
    revoked = registry.propagate_revocation(delegation.token_id)
    print(f"🚫 Propagated revocation: {revoked} tokens revoked")
    print(f"   Chain valid after: {registry.verify_delegation_chain(attenuated.token_id)}")
    
    # 6. Agent lifecycle
    print("\n" + "─" * 50)
    print("6️⃣  AGENT LIFECYCLE")
    print("─" * 50)
    
    print(f"📊 Current state: {registry.get_agent(primary_id).state.value}")
    
    registry.revoke(primary_id, "Security incident")
    print(f"⛔ After revoke: {registry.get_agent(primary_id).state.value}")
    
    registry.deprovision(primary_id, "End of project")
    print(f"🗑️  After deprovision: {registry.get_agent(primary_id).state.value}")
    
    # 7. Audit trail
    print("\n" + "─" * 50)
    print("7️⃣  AUDIT TRAIL")
    print("─" * 50)
    
    trail = registry.get_audit_trail(primary_id)
    print(f"📋 Total events: {len(trail)}")
    for event in trail[-5:]:
        state_info = f" ({event.from_state} → {event.to_state})" if event.to_state else ""
        print(f"   - {event.event_type}{state_info}")
    
    print("\n" + "=" * 60)
    print("✅ DEMONSTRATION COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
