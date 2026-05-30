/*
 * Agent Identity SDK - Rust
 * Based on OpenID Foundation "Identity Management for Agentic AI" (October 2025)
 */

use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;
use uuid::Uuid;

// ============================================================================
// ERROR TYPES
// ============================================================================

#[derive(Error, Debug, Clone, Serialize, Deserialize)]
pub enum AgentError {
    #[error("Agent not found: {0}")]
    AgentNotFound(String),
    #[error("Invalid state transition from {from} to {to}")]
    InvalidStateTransition { from: String, to: String },
    #[error("Invalid scope")]
    InvalidScope,
    #[error("Token not found: {0}")]
    TokenNotFound(String),
    #[error("Token expired")]
    TokenExpired,
    #[error("Token revoked")]
    TokenRevoked,
}

// ============================================================================
// ENUMS
// ============================================================================

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AgentType {
    Autonomous,
    Assistant,
    Tool,
    Hybrid,
}

impl AgentType {
    pub fn as_str(&self) -> &'static str {
        match self {
            AgentType::Autonomous => "autonomous",
            AgentType::Assistant => "assistant",
            AgentType::Tool => "tool",
            AgentType::Hybrid => "hybrid",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum LifecycleState {
    Provisioned,
    Active,
    Revoked,
    Deprovisioned,
}

impl LifecycleState {
    pub fn as_str(&self) -> &'static str {
        match self {
            LifecycleState::Provisioned => "provisioned",
            LifecycleState::Active => "active",
            LifecycleState::Revoked => "revoked",
            LifecycleState::Deprovisioned => "deprovisioned",
        }
    }
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkloadIdentity {
    pub spiffe_id: String,
    pub public_key: String,
    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub revoked: bool,
}

impl WorkloadIdentity {
    pub fn new(agent_id: &str, ttl_days: i64) -> Self {
        Self {
            spiffe_id: format!("spiffe://agentic-ai.org/agent/{}", agent_id),
            public_key: Uuid::new_v4().to_string(),
            issued_at: Utc::now(),
            expires_at: Utc::now() + Duration::days(ttl_days),
            revoked: false,
        }
    }
    
    pub fn is_valid(&self) -> bool {
        !self.revoked && Utc::now() < self.expires_at
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenConstraints {
    pub max_executions: Option<i32>,
    pub max_duration_seconds: Option<i64>,
    pub allowed_resources: Option<Vec<String>>,
    pub denied_resources: Option<Vec<String>>,
}

impl Default for TokenConstraints {
    fn default() -> Self {
        Self {
            max_executions: None,
            max_duration_seconds: None,
            allowed_resources: None,
            denied_resources: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DelegationToken {
    pub token_id: String,
    pub issuer_id: String,
    pub holder_id: String,
    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub scope: Vec<String>,
    pub constraints: TokenConstraints,
    pub parent_token_id: Option<String>,
    pub revoked: bool,
    pub execution_count: i32,
}

impl DelegationToken {
    pub fn new(
        issuer_id: &str,
        holder_id: &str,
        scope: Vec<String>,
        ttl_minutes: i64,
        constraints: TokenConstraints,
        parent_token_id: Option<String>,
    ) -> Self {
        let now = Utc::now();
        Self {
            token_id: Uuid::new_v4().to_string(),
            issuer_id: issuer_id.to_string(),
            holder_id: holder_id.to_string(),
            issued_at: now,
            expires_at: now + Duration::minutes(ttl_minutes),
            scope,
            constraints,
            parent_token_id,
            revoked: false,
            execution_count: 0,
        }
    }
    
    pub fn is_valid(&self) -> bool {
        if self.revoked { return false; }
        if Utc::now() >= self.expires_at { return false; }
        if let Some(max) = self.constraints.max_executions {
            if self.execution_count >= max { return false; }
        }
        true
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEvent {
    pub event_id: String,
    pub timestamp: DateTime<Utc>,
    pub event_type: String,
    pub agent_id: Option<String>,
    pub actor_id: Option<String>,
    pub from_state: Option<String>,
    pub to_state: Option<String>,
    pub details: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentIdentity {
    pub agent_id: String,
    pub name: String,
    pub agent_type: AgentType,
    pub owner_id: String,
    pub capabilities: Vec<String>,
    pub provider: String,
    pub model: String,
    pub version: String,
    pub created_at: DateTime<Utc>,
    pub did: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    pub identity: AgentIdentity,
    pub state: LifecycleState,
    pub workload_identity: Option<WorkloadIdentity>,
    pub delegation_tokens: Vec<DelegationToken>,
    pub current_scopes: Vec<String>,
    pub audit_trail: Vec<AuditEvent>,
    pub entered_state_at: DateTime<Utc>,
    pub owners: Vec<String>,
    pub entitlements: Vec<String>,
}

impl Agent {
    pub fn new(
        name: &str,
        agent_type: AgentType,
        owner_id: &str,
        capabilities: Vec<String>,
        provider: &str,
        model: &str,
        version: &str,
    ) -> Self {
        let identity = AgentIdentity {
            agent_id: Uuid::new_v4().to_string(),
            name: name.to_string(),
            agent_type,
            owner_id: owner_id.to_string(),
            capabilities: capabilities.clone(),
            provider: provider.to_string(),
            model: model.to_string(),
            version: version.to_string(),
            created_at: Utc::now(),
            did: None,
        };
        
        Self {
            identity,
            state: LifecycleState::Provisioned,
            workload_identity: None,
            delegation_tokens: Vec::new(),
            current_scopes: capabilities.clone(),
            audit_trail: Vec::new(),
            entered_state_at: Utc::now(),
            owners: vec![owner_id.to_string()],
            entitlements: capabilities,
        }
    }
}

// ============================================================================
// AGENT REGISTRY
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentStatus {
    pub agent_id: String,
    pub name: String,
    pub state: String,
    pub provider: String,
    pub model: String,
    pub current_scopes: Vec<String>,
    pub active_tokens: usize,
}

pub struct AgentRegistry {
    agents: HashMap<String, Agent>,
    audit_log: Vec<AuditEvent>,
}

impl AgentRegistry {
    pub fn new() -> Self {
        Self {
            agents: HashMap::new(),
            audit_log: Vec::new(),
        }
    }
    
    // Valid lifecycle transitions
    fn valid_transitions(from: &Self, state: &LifecycleState) -> Option<Vec<LifecycleState>> {
        match state {
            LifecycleState::Provisioned => Some(vec![LifecycleState::Active, LifecycleState::Deprovisioned]),
            LifecycleState::Active => Some(vec![LifecycleState::Revoked, LifecycleState::Deprovisioned]),
            LifecycleState::Revoked => Some(vec![LifecycleState::Deprovisioned]),
            LifecycleState::Deprovisioned => None,
        }
    }
    
    pub fn create_agent(
        &mut self,
        name: &str,
        agent_type: AgentType,
        owner_id: &str,
        capabilities: Vec<String>,
        provider: &str,
        model: &str,
        version: &str,
    ) -> Agent {
        let agent = Agent::new(
            name, agent_type, owner_id, capabilities,
            provider, model, version,
        );
        
        self.log_event("agent_created", Some(&agent.identity.agent_id), None,
                      Some("provisioned"), None, HashMap::new());
        
        let id = agent.identity.agent_id.clone();
        let clone = agent.clone();
        self.agents.insert(id, agent);
        clone
    }
    
    pub fn provision(&mut self, agent_id: &str, ttl_days: i64) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if agent.state != LifecycleState::Provisioned {
            return Err(AgentError::InvalidStateTransition {
                from: agent.state.as_str().to_string(),
                to: "active".to_string(),
            });
        }
        
        agent.workload_identity = Some(WorkloadIdentity::new(agent_id, ttl_days));
        self.transition_state(agent, LifecycleState::Active, None);
        Ok(agent.clone())
    }
    
    pub fn activate(&mut self, agent_id: &str) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        self.transition_state(agent, LifecycleState::Active, None);
        Ok(agent.clone())
    }
    
    pub fn revoke(&mut self, agent_id: &str, reason: &str) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        for token in &mut agent.delegation_tokens {
            token.revoked = true;
        }
        
        let mut details = HashMap::new();
        details.insert("reason".to_string(), reason.to_string());
        self.log_event("agent_revoked", Some(agent_id), None,
                      Some("active"), Some("revoked"), details);
        
        agent.state = LifecycleState::Revoked;
        agent.entered_state_at = Utc::now();
        Ok(agent.clone())
    }
    
    pub fn deprovision(&mut self, agent_id: &str, reason: &str) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if let Some(ref mut wi) = agent.workload_identity {
            wi.revoked = true;
        }
        
        for token in &mut agent.delegation_tokens {
            token.revoked = true;
        }
        
        let mut details = HashMap::new();
        details.insert("reason".to_string(), reason.to_string());
        self.log_event("agent_deprovisioned", Some(agent_id), None,
                      None, Some("deprovisioned"), details);
        
        agent.state = LifecycleState::Deprovisioned;
        agent.entitlements.clear();
        agent.entered_state_at = Utc::now();
        Ok(agent.clone())
    }
    
    pub fn delegate(
        &mut self,
        delegator_id: &str,
        delegatee_id: &str,
        scope: Vec<String>,
        max_executions: Option<i32>,
        ttl_minutes: i64,
    ) -> Result<DelegationToken, AgentError> {
        let delegator = self.agents.get(delegator_id)
            .ok_or_else(|| AgentError::AgentNotFound(delegator_id.to_string()))?;
        
        if delegator.state != LifecycleState::Active {
            return Err(AgentError::InvalidStateTransition {
                from: delegator.state.as_str().to_string(),
                to: "active".to_string(),
            });
        }
        
        // Attenuate scope
        let valid_scopes: Vec<String> = scope
            .into_iter()
            .filter(|s| delegator.current_scopes.contains(s))
            .collect();
        
        if valid_scopes.is_empty() {
            return Err(AgentError::InvalidScope);
        }
        
        let _delegatee = self.agents.get_mut(delegatee_id)
            .ok_or_else(|| AgentError::AgentNotFound(delegatee_id.to_string()))?;
        
        let constraints = TokenConstraints { max_executions, ..Default::default() };
        
        let token = DelegationToken::new(
            delegator_id,
            delegatee_id,
            valid_scopes.clone(),
            ttl_minutes,
            constraints,
            None,
        );
        
        let mut details = HashMap::new();
        details.insert("delegatee_id".to_string(), delegatee_id.to_string());
        details.insert("scope".to_string(), valid_scopes.join(","));
        self.log_event("delegation_created", Some(delegator_id), Some(delegator_id),
                      None, None, details);
        
        if let Some(agent) = self.agents.get_mut(delegatee_id) {
            agent.delegation_tokens.push(token.clone());
        }
        
        Ok(token)
    }
    
    pub fn attenuate_scope(
        &mut self,
        token_id: &str,
        new_scope: Vec<String>,
        max_executions: Option<i32>,
        ttl_minutes: i64,
    ) -> Result<DelegationToken, AgentError> {
        let (parent_token, agent_id) = self.find_token(token_id)
            .ok_or_else(|| AgentError::TokenNotFound(token_id.to_string()))?;
        
        if !parent_token.is_valid() {
            return Err(AgentError::TokenExpired);
        }
        
        let valid_scopes: Vec<String> = new_scope
            .into_iter()
            .filter(|s| parent_token.scope.contains(s))
            .collect();
        
        if valid_scopes.is_empty() {
            return Err(AgentError::InvalidScope);
        }
        
        let mut constraints = parent_token.constraints.clone();
        constraints.max_executions = max_executions;
        
        let new_token = DelegationToken::new(
            &parent_token.holder_id,
            &parent_token.holder_id,
            valid_scopes.clone(),
            ttl_minutes,
            constraints,
            Some(token_id.to_string()),
        );
        
        let mut details = HashMap::new();
        details.insert("parent_token".to_string(), token_id.to_string());
        details.insert("new_scope".to_string(), valid_scopes.join(","));
        self.log_event("scope_attenuated", Some(&agent_id), None, None, None, details);
        
        if let Some(agent) = self.agents.get_mut(&agent_id) {
            agent.delegation_tokens.push(new_token.clone());
        }
        
        Ok(new_token)
    }
    
    pub fn verify_delegation_chain(&self, token_id: &str) -> bool {
        let mut visited = std::collections::HashSet::new();
        let mut current = token_id.to_string();
        
        loop {
            if visited.contains(&current) {
                return false;
            }
            visited.insert(current.clone());
            
            match self.find_token(&current) {
                Some((token, _)) => {
                    if token.revoked || !token.is_valid() {
                        return false;
                    }
                    match &token.parent_token_id {
                        Some(parent) => current = parent.clone(),
                        None => break,
                    }
                }
                None => return false,
            }
        }
        true
    }
    
    pub fn issue_token(
        &mut self,
        agent_id: &str,
        scope: Vec<String>,
        ttl_minutes: i64,
    ) -> Result<DelegationToken, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        let token = DelegationToken::new(
            agent_id,
            agent_id,
            scope,
            ttl_minutes,
            TokenConstraints::default(),
            None,
        );
        
        self.log_event("token_issued", Some(agent_id), None, None, None, HashMap::new());
        agent.delegation_tokens.push(token.clone());
        Ok(token)
    }
    
    pub fn revoke_token(&mut self, token_id: &str) -> Result<(), AgentError> {
        for agent in self.agents.values_mut() {
            for token in &mut agent.delegation_tokens {
                if token.token_id == token_id {
                    token.revoked = true;
                    return Ok(());
                }
            }
        }
        Err(AgentError::TokenNotFound(token_id.to_string()))
    }
    
    pub fn propagate_revocation(&mut self, root_token_id: &str) -> usize {
        let mut revoked = 0;
        let mut to_revoke = vec![root_token_id.to_string()];
        let mut processed = std::collections::HashSet::new();
        
        while let Some(current) = to_revoke.pop() {
            if processed.contains(&current) {
                continue;
            }
            processed.insert(current.clone());
            
            for agent in self.agents.values_mut() {
                for token in &mut agent.delegation_tokens {
                    if token.token_id == current && !token.revoked {
                        token.revoked = true;
                        revoked += 1;
                    }
                }
            }
            
            for agent in self.agents.values() {
                for token in &agent.delegation_tokens {
                    if token.parent_token_id.as_ref() == Some(&current) {
                        to_revoke.push(token.token_id.clone());
                    }
                }
            }
        }
        revoked
    }
    
    pub fn validate_token(&self, token_id: &str) -> bool {
        self.find_token(token_id).map(|(t, _)| t.is_valid()).unwrap_or(false)
    }
    
    fn find_token(&self, token_id: &str) -> Option<(&DelegationToken, String)> {
        for (id, agent) in &self.agents {
            for token in &agent.delegation_tokens {
                if token.token_id == token_id {
                    return Some((token, id.clone()));
                }
            }
        }
        None
    }
    
    fn transition_state(&mut self, agent: &mut Agent, new_state: LifecycleState, _reason: Option<&str>) {
        let old_state = agent.state.as_str().to_string();
        let new_state_str = new_state.as_str().to_string();
        
        self.log_event("lifecycle_changed", Some(&agent.identity.agent_id), None,
                      Some(&old_state), Some(&new_state_str), HashMap::new());
        
        agent.state = new_state;
        agent.entered_state_at = Utc::now();
    }
    
    fn log_event(
        &mut self,
        event_type: &str,
        agent_id: Option<&str>,
        actor_id: Option<&str>,
        from_state: Option<&str>,
        to_state: Option<&str>,
        details: HashMap<String, String>,
    ) {
        let event = AuditEvent {
            event_id: Uuid::new_v4().to_string(),
            timestamp: Utc::now(),
            event_type: event_type.to_string(),
            agent_id: agent_id.map(|s| s.to_string()),
            actor_id: actor_id.map(|s| s.to_string()),
            from_state: from_state.map(|s| s.to_string()),
            to_state: to_state.map(|s| s.to_string()),
            details,
        };
        
        if let Some(id) = agent_id {
            if let Some(agent) = self.agents.get_mut(id) {
                agent.audit_trail.push(event.clone());
            }
        }
        
        self.audit_log.push(event);
    }
    
    pub fn get_agent(&self, agent_id: &str) -> Option<&Agent> {
        self.agents.get(agent_id)
    }
    
    pub fn list_agents(&self) -> Vec<&Agent> {
        self.agents.values().collect()
    }
}

// ============================================================================
// TESTS
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_lifecycle() {
        let mut registry = AgentRegistry::new();
        
        let agent = registry.create_agent(
            "test-agent",
            AgentType::Autonomous,
            "user_001",
            vec!["code_generation".to_string()],
            "test",
            "test",
            "1.0.0",
        );
        
        assert_eq!(agent.state, LifecycleState::Provisioned);
        
        let activated = registry.provision(&agent.identity.agent_id, 30).unwrap();
        assert_eq!(activated.state, LifecycleState::Active);
    }
}

// ============================================================================
// MAIN / DEMO
// ============================================================================

#[cfg(feature = "demo")]
pub fn demo() {
    println!("\n═══════════════════════════════════════════════════════════════════════");
    println!("🤖 AGENT IDENTITY SDK - RUST DEMO");
    println!("═══════════════════════════════════════════════════════════════════════\n");
    
    let mut registry = AgentRegistry::new();
    let owner_id = "user_001";
    
    println!("👤 Owner: {}\n", owner_id);
    
    // Create agent
    let primary = registry.create_agent(
        "coding-assistant",
        AgentType::Autonomous,
        owner_id,
        vec!["code_generation".to_string(), "git_operations".to_string()],
        "anthropic",
        "claude-sonnet-4",
        "1.0.0",
    );
    
    println!("✅ Created: {}", primary.identity.name);
    println!("   State: {:?}", primary.state);
    
    // Provision and activate
    registry.provision(&primary.owner_id, 30).expect("Provision failed");
    println!("\n✅ Provisioned & activated");
    
    // Delegation
    let review = registry.create_agent(
        "review-bot",
        AgentType::Assistant,
        owner_id,
        vec!["code_review".to_string()],
        "openai",
        "gpt-5",
        "1.0.0",
    );
    registry.provision(&review.identity.agent_id, 30).expect("Provision failed");
    
    let token = registry.delegate(
        &primary.identity.agent_id,
        &review.identity.agent_id,
        vec!["code_review".to_string()],
        Some(10),
        60,
    ).expect("Delegate failed");
    
    println!("🔗 Delegation: {}", &token.token_id[..8]);
    
    println!("\n═══════════════════════════════════════════════════════════════════════");
    println!("✅ DEMONSTRATION COMPLETE");
    println!("═══════════════════════════════════════════════════════════════════════");
}
