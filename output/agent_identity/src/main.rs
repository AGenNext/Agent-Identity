/*
 * Agent Identity System - Rust Demo
 * Based on: OpenID Foundation "Identity Management for Agentic AI" (2025)
 */

use crate::{AgentRegistry, AgentType};

fn main() {
    println!("\n╔══════════════════════════════════════════════════════════════════════════╗");
    println!("║                                                                          ║");
    println!("║          🦀 AGENT IDENTITY SYSTEM - RUST VERSION                       ║");
    println!("║                                                                          ║");
    println!("╚══════════════════════════════════════════════════════════════════════════╝\n");
    
    demonstrate();
    
    println!("\n✅ Run tests with: cargo test");
}

fn demonstrate() {
    let mut registry = AgentRegistry::new();
    let user_id = "user_001";
    
    println!("👤 User: {}\n", user_id);
    
    // 1. Register and provision
    println!("{}", "─".repeat(50));
    println!("1️⃣  REGISTERING & PROVISIONING AGENTS");
    println!("{}", "─".repeat(50));
    
    let primary = registry.register_and_provision(
        "coding-assistant",
        AgentType::Autonomous,
        user_id,
        vec![
            "code_generation".to_string(),
            "git_operations".to_string(),
            "code_review".to_string(),
            "terminal_execute".to_string(),
        ],
        "anthropic",
        "claude-sonnet-4",
        "1.0.0",
    );
    println!("✅ Created: {} ({})", primary.identity.name, &primary.identity.agent_id[..8]);
    println!("   State: {:?}", primary.lifecycle_state);
    println!("   Scopes: {:?}", primary.current_scopes);
    
    let review = registry.register_and_provision(
        "review-bot",
        AgentType::Assistant,
        user_id,
        vec![
            "code_review".to_string(),
            "read".to_string(),
            "file_read".to_string(),
        ],
        "openai",
        "gpt-5",
        "1.0.0",
    );
    println!("\n✅ Created: {} ({})", review.identity.name, &review.identity.agent_id[..8]);
    println!("   State: {:?}", review.lifecycle_state);
    
    // 2. Delegation
    println!("\n{}", "─".repeat(50));
    println!("2️⃣  DELEGATION & SCOPE ATTENUATION");
    println!("{}", "─".repeat(50));
    
    let delegation = registry.delegate_to_agent(
        &primary.identity.agent_id,
        &review.identity.agent_id,
        vec!["code_review".to_string(), "read".to_string()],
        Some(10),
        60,
    ).expect("Delegate failed");
    
    println!("🔗 Delegation: {}", &delegation.id[..8]);
    println!("   Scope: {:?}", delegation.scope);
    println!("   Max executions: {:?}", delegation.constraints.max_executions);
    
    let attenuated = registry.attenuate_scope(
        &delegation.id,
        vec!["code_review".to_string()],
        Some(5),
        30,
    ).expect("Attenuate failed");
    
    println!("\n📉 Attenuated: {}", &attenuated.id[..8]);
    println!("   New scope: {:?}", attenuated.scope);
    println!("   Max executions: {:?}", attenuated.constraints.max_executions);
    
    let chain_valid = registry.verify_delegation_chain(&attenuated.id);
    println!("\n🔍 Chain valid: {}", chain_valid);
    
    // 3. Token management
    println!("\n{}", "─".repeat(50));
    println!("3️⃣  TOKEN MANAGEMENT");
    println!("{}", "─".repeat(50));
    
    let token = registry.issue_token(
        &primary.identity.agent_id,
        vec!["code_generation".to_string(), "git_operations".to_string()],
        30,
    ).expect("Issue token failed");
    
    println!("🎫 Token: {}", &token.id[..8]);
    println!("   Scope: {:?}", token.scope);
    println!("   Valid: {}", registry.validate_token(&token.id));
    
    let new_token = registry.refresh_token(&token.id, 60).expect("Refresh failed");
    let parent_short = new_token.parent_token_id.as_ref().map(|s| &s[..8]).unwrap_or("none");
    println!("\n🔄 Refreshed: {} (parent: {}...)", &new_token.id[..8], parent_short);
    
    // 4. Lifecycle transitions
    println!("\n{}", "─".repeat(50));
    println!("4️⃣  LIFECYCLE TRANSITIONS");
    println!("{}", "─".repeat(50));
    
    let status = registry.get_agent_status(&primary.identity.agent_id)
        .expect("Get status failed");
    println!("📊 Status: {}", status.state);
    
    registry.suspend_agent(&primary.identity.agent_id, "Maintenance")
        .expect("Suspend failed");
    let status = registry.get_agent_status(&primary.identity.agent_id)
        .expect("Get status failed");
    println!("⏸️  After suspend: {}", status.state);
    
    registry.resume_agent(&primary.identity.agent_id).expect("Resume failed");
    let status = registry.get_agent_status(&primary.identity.agent_id)
        .expect("Get status failed");
    println!("▶️  After resume: {}", status.state);
    
    // 5. Audit trail
    println!("\n{}", "─".repeat(50));
    println!("5️⃣  AUDIT TRAIL");
    println!("{}", "─".repeat(50));
    
    let trail = registry.get_audit_trail(&primary.identity.agent_id);
    println!("📋 Total events: {}", trail.len());
    for event in trail.iter().rev().take(5) {
        println!("   - {}", event.event_type.as_str());
    }
    
    // 6. Revocation propagation
    println!("\n{}", "─".repeat(50));
    println!("6️⃣  REVOCATION PROPAGATION");
    println!("{}", "─".repeat(50));
    
    let revoked = registry.propagate_revocation(&delegation.id);
    println!("🚫 Tokens revoked: {}", revoked);
    
    let chain_valid = registry.verify_delegation_chain(&attenuated.id);
    println!("🔍 Chain valid after revocation: {}", chain_valid);
    
    println!("\n{}", "═".repeat(60));
    println!("✅ DEMONSTRATION COMPLETE");
    println!("{}", "═".repeat(60));
}
