/*
 * Agent Identity and Lifecycle Management System - Rust
 * Based on: OpenID Foundation "Identity Management for Agentic AI" (2025)
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
    AgentNotFound(String),
    #[error("Invalid state transition from {from} to {to}")]
    InvalidStateTransition { from: String, to: String },
    #[error("Invalid scope: must be subset of parent scope")]
    InvalidScope,
    #[error("Token not found: {0}")]
    TokenNotFound(String),
    #[error("Invalid token state")]
    InvalidTokenState,
    #[error("Delegator must be ACTIVE")]
    DelegatorNotActive,
    #[error("Agent must be ACTIVE")]
    AgentNotActive,
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
    Created,
    Provisioned,
    Active,
    Suspended,
    Revoked,
    Deleted,
}

impl LifecycleState {
    pub fn as_str(&self) -> &'static str {
        match self {
            LifecycleState::Created => "created",
            LifecycleState::Provisioned => "provisioned",
            LifecycleState::Active => "active",
            LifecycleState::Suspended => "suspended",
            LifecycleState::Revoked => "revoked",
            LifecycleState::Deleted => "deleted",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AuditEventType {
    AgentRegistered,
    AgentProvisioned,
    AgentActivated,
    AgentSuspended,
    AgentResumed,
    AgentRevoked,
    AgentDeleted,
    TokenIssued,
    TokenRefreshed,
    TokenRevoked,
    DelegationCreated,
    DelegationAttenuated,
}

impl AuditEventType {
    pub fn as_str(&self) -> &'static str {
        match self {
            AuditEventType::AgentRegistered => "agent_registered",
            AuditEventType::AgentProvisioned => "agent_provisioned",
            AuditEventType::AgentActivated => "agent_activated",
            AuditEventType::AgentSuspended => "agent_suspended",
            AuditEventType::AgentResumed => "agent_resumed",
            AuditEventType::AgentRevoked => "agent_revoked",
            AuditEventType::AgentDeleted => "agent_deleted",
            AuditEventType::TokenIssued => "token_issued",
            AuditEventType::TokenRefreshed => "token_refreshed",
            AuditEventType::TokenRevoked => "token_revoked",
            AuditEventType::DelegationCreated => "delegation_created",
            AuditEventType::DelegationAttenuated => "delegation_attenuated",
        }
    }
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentIdentity {
    pub agent_id: String,
    pub name: String,
    pub agent_type: AgentType,
    pub provider: String,
    pub model: String,
    pub version: String,
    pub owner_id: String,
    pub capabilities: Vec<String>,
    pub created_at: DateTime<Utc>,
    pub trust_level: String,
}

impl AgentIdentity {
    pub fn new(
        name: &str,
        agent_type: AgentType,
        owner_id: &str,
        capabilities: Vec<String>,
        provider: &str,
        model: &str,
        version: &str,
    ) -> Self {
        Self {
            agent_id: Uuid::new_v4().to_string(),
            name: name.to_string(),
            agent_type,
            provider: provider.to_string(),
            model: model.to_string(),
            version: version.to_string(),
            owner_id: owner_id.to_string(),
            capabilities: capabilities.clone(),
            created_at: Utc::now(),
            trust_level: "medium".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkloadIdentity {
    pub id: String,
    pub spiffe_id: String,
    pub agent_id: String,
    pub public_key: String,
    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub revoked: bool,
}

impl WorkloadIdentity {
    pub fn new(agent_id: &str, ttl_days: i64) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            spiffe_id: format!("spiffe://agentic-ai.org/agent/{}", agent_id),
            agent_id: agent_id.to_string(),
            public_key: Uuid::new_v4().to_string(),
            issued_at: now,
            expires_at: now + Duration::days(ttl_days),
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
    pub id: String,
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
            id: Uuid::new_v4().to_string(),
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
pub struct Agent {
    pub identity: AgentIdentity,
    pub lifecycle_state: LifecycleState,
    pub workload_identity: Option<WorkloadIdentity>,
    pub delegation_tokens: Vec<DelegationToken>,
    pub current_scopes: Vec<String>,
    pub audit_trail: Vec<AuditEvent>,
    pub last_active_at: Option<DateTime<Utc>>,
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
        let identity = AgentIdentity::new(
            name, agent_type, owner_id, capabilities.clone(),
            provider, model, version,
        );
        Self {
            identity,
            lifecycle_state: LifecycleState::Created,
            workload_identity: None,
            delegation_tokens: Vec::new(),
            current_scopes: capabilities,
            audit_trail: Vec::new(),
            last_active_at: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEvent {
    pub id: String,
    pub timestamp: DateTime<Utc>,
    pub event_type: AuditEventType,
    pub agent_id: Option<String>,
    pub actor_id: Option<String>,
    pub details: HashMap<String, String>,
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
    pub workload_identity: Option<String>,
    pub active_tokens: usize,
    pub created_at: String,
    pub last_active: Option<String>,
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
    
    // -------------------------------------------------------------------------
    // Lifecycle Management
    // -------------------------------------------------------------------------
    
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
        
        self.log_event(
            AuditEventType::AgentRegistered,
            Some(&agent.identity.agent_id),
            Some(owner_id),
            vec![("name", name), ("agent_type", agent_type.as_str())],
        );
        
        let agent_id = agent.identity.agent_id.clone();
        let agent_clone = agent.clone();
        self.agents.insert(agent_id, agent);
        agent_clone
    }
    
    pub fn provision_agent(&mut self, agent_id: &str, ttl_days: i64) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if agent.lifecycle_state != LifecycleState::Created {
            return Err(AgentError::InvalidStateTransition {
                from: agent.lifecycle_state.as_str().to_string(),
                to: "provisioned".to_string(),
            });
        }
        
        let workload_identity = WorkloadIdentity::new(agent_id, ttl_days);
        let spiffe_id = workload_identity.spiffe_id.clone();
        agent.workload_identity = Some(workload_identity);
        
        self.log_event(
            AuditEventType::AgentProvisioned,
            Some(agent_id),
            None,
            vec![("spiffe_id", &spiffe_id)],
        );
        
        agent.lifecycle_state = LifecycleState::Provisioned;
        Ok(agent.clone())
    }
    
    pub fn activate_agent(&mut self, agent_id: &str) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if agent.lifecycle_state != LifecycleState::Provisioned {
            return Err(AgentError::InvalidStateTransition {
                from: agent.lifecycle_state.as_str().to_string(),
                to: "active".to_string(),
            });
        }
        
        self.log_event(AuditEventType::AgentActivated, Some(agent_id), None, vec![]);
        
        agent.lifecycle_state = LifecycleState::Active;
        agent.last_active_at = Some(Utc::now());
        Ok(agent.clone())
    }
    
    pub fn suspend_agent(&mut self, agent_id: &str, reason: &str) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if agent.lifecycle_state != LifecycleState::Active {
            return Err(AgentError::InvalidStateTransition {
                from: agent.lifecycle_state.as_str().to_string(),
                to: "suspended".to_string(),
            });
        }
        
        // Revoke all tokens
        for token in &mut agent.delegation_tokens {
            token.revoked = true;
        }
        
        self.log_event(
            AuditEventType::AgentSuspended,
            Some(agent_id),
            None,
            vec![("reason", reason)],
        );
        
        agent.lifecycle_state = LifecycleState::Suspended;
        Ok(agent.clone())
    }
    
    pub fn resume_agent(&mut self, agent_id: &str) -> Result<Agent, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if agent.lifecycle_state != LifecycleState::Suspended {
            return Err(AgentError::InvalidStateTransition {
                from: agent.lifecycle_state.as_str().to_string(),
                to: "active".to_string(),
            });
        }
        
        self.log_event(AuditEventType::AgentResumed, Some(agent_id), None, vec![]);
        
        agent.lifecycle_state = LifecycleState::Active;
        agent.last_active_at = Some(Utc::now());
        Ok(agent.clone())
    }
    
    pub fn deprovision_agent(&mut self, agent_id: &str, reason: &str) -> Result<(), AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if let Some(ref mut wi) = agent.workload_identity {
            wi.revoked = true;
        }
        
        for token in &mut agent.delegation_tokens {
            token.revoked = true;
        }
        
        self.log_event(
            AuditEventType::AgentDeleted,
            Some(agent_id),
            None,
            vec![("reason", reason)],
        );
        
        agent.lifecycle_state = LifecycleState::Deleted;
        Ok(())
    }
    
    // -------------------------------------------------------------------------
    // Delegation
    // -------------------------------------------------------------------------
    
    pub fn delegate_to_agent(
        &mut self,
        delegator_id: &str,
        delegatee_id: &str,
        scope: Vec<String>,
        max_executions: Option<i32>,
        ttl_minutes: i64,
    ) -> Result<DelegationToken, AgentError> {
        let delegator = self.agents.get(delegator_id)
            .ok_or_else(|| AgentError::AgentNotFound(delegator_id.to_string()))?;
        
        if delegator.lifecycle_state != LifecycleState::Active {
            return Err(AgentError::DelegatorNotActive);
        }
        
        // Attenuate scope - only include what delegator has
        let valid_scopes: Vec<String> = scope
            .into_iter()
            .filter(|s| delegator.current_scopes.contains(s))
            .collect();
        
        if valid_scopes.is_empty() {
            return Err(AgentError::InvalidScope);
        }
        
        let _delegatee = self.agents.get_mut(delegatee_id)
            .ok_or_else(|| AgentError::AgentNotFound(delegatee_id.to_string()))?;
        
        let constraints = TokenConstraints {
            max_executions,
            ..Default::default()
        };
        
        let token = DelegationToken::new(
            delegator_id,
            delegatee_id,
            valid_scopes.clone(),
            ttl_minutes,
            constraints,
            None,
        );
        
        self.log_event(
            AuditEventType::DelegationCreated,
            Some(delegator_id),
            Some(delegator_id),
            {
                let mut v = vec![("delegatee_id", delegatee_id)];
                v.push(("scope", &valid_scopes.join(",")));
                v
            },
        );
        
        // Add to delegatee's tokens
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
            return Err(AgentError::InvalidTokenState);
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
        
        self.log_event(
            AuditEventType::DelegationAttenuated,
            Some(&agent_id),
            None,
            vec![("parent_token", token_id), ("new_scope", &valid_scopes.join(","))],
        );
        
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
    
    fn find_token(&self, token_id: &str) -> Option<(&DelegationToken, String)> {
        for (id, agent) in &self.agents {
            for token in &agent.delegation_tokens {
                if token.id == token_id {
                    return Some((token, id.clone()));
                }
            }
        }
        None
    }
    
    // -------------------------------------------------------------------------
    // Token Management
    // -------------------------------------------------------------------------
    
    pub fn issue_token(
        &mut self,
        agent_id: &str,
        scope: Vec<String>,
        ttl_minutes: i64,
    ) -> Result<DelegationToken, AgentError> {
        let agent = self.agents.get_mut(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        if agent.lifecycle_state != LifecycleState::Active 
            && agent.lifecycle_state != LifecycleState::Provisioned {
            return Err(AgentError::AgentNotActive);
        }
        
        let token = DelegationToken::new(
            agent_id,
            agent_id,
            scope,
            ttl_minutes,
            TokenConstraints::default(),
            None,
        );
        
        self.log_event(AuditEventType::TokenIssued, Some(agent_id), None, vec![]);
        
        agent.delegation_tokens.push(token.clone());
        Ok(token)
    }
    
    pub fn refresh_token(
        &mut self,
        old_token_id: &str,
        ttl_minutes: i64,
    ) -> Result<DelegationToken, AgentError> {
        let (old_token, agent_id) = self.find_token(old_token_id)
            .ok_or_else(|| AgentError::TokenNotFound(old_token_id.to_string()))?;
        
        let new_token = DelegationToken::new(
            &old_token.issuer_id,
            &old_token.holder_id,
            old_token.scope.clone(),
            ttl_minutes,
            old_token.constraints.clone(),
            Some(old_token_id.to_string()),
        );
        
        // Revoke old token
        for agent in self.agents.values_mut() {
            for token in &mut agent.delegation_tokens {
                if token.id == old_token_id {
                    token.revoked = true;
                }
            }
        }
        
        if let Some(agent) = self.agents.get_mut(&agent_id) {
            agent.delegation_tokens.push(new_token.clone());
        }
        
        self.log_event(
            AuditEventType::TokenRefreshed,
            Some(&agent_id),
            None,
            vec![("old_token", old_token_id)],
        );
        
        Ok(new_token)
    }
    
    pub fn revoke_token(&mut self, token_id: &str) -> Result<(), AgentError> {
        for agent in self.agents.values_mut() {
            for token in &mut agent.delegation_tokens {
                if token.id == token_id {
                    token.revoked = true;
                    self.log_event(
                        AuditEventType::TokenRevoked,
                        None,
                        None,
                        vec![("token_id", token_id)],
                    );
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
                    if token.id == current && !token.revoked {
                        token.revoked = true;
                        revoked += 1;
                    }
                }
            }
            
            // Find child tokens
            for agent in self.agents.values() {
                for token in &agent.delegation_tokens {
                    if token.parent_token_id.as_ref() == Some(&current) {
                        to_revoke.push(token.id.clone());
                    }
                }
            }
        }
        
        revoked
    }
    
    pub fn validate_token(&self, token_id: &str) -> bool {
        match self.find_token(token_id) {
            Some((token, _)) => token.is_valid(),
            None => false,
        }
    }
    
    // -------------------------------------------------------------------------
    // Utilities
    // -------------------------------------------------------------------------
    
    pub fn register_and_provision(
        &mut self,
        name: &str,
        agent_type: AgentType,
        owner_id: &str,
        capabilities: Vec<String>,
        provider: &str,
        model: &str,
        version: &str,
    ) -> Agent {
        let agent = self.create_agent(
            name, agent_type, owner_id, capabilities,
            provider, model, version,
        );
        
        let agent_id = agent.identity.agent_id.clone();
        
        // Provision
        let _provisioned = self.provision_agent(&agent_id, 30).expect("Provision failed");
        
        // Activate
        let activated = self.activate_agent(&agent_id).expect("Activate failed");
        activated
    }
    
    pub fn get_agent_status(&self, agent_id: &str) -> Result<AgentStatus, AgentError> {
        let agent = self.agents.get(agent_id)
            .ok_or_else(|| AgentError::AgentNotFound(agent_id.to_string()))?;
        
        let active_tokens = agent.delegation_tokens.iter()
            .filter(|t| t.is_valid())
            .count();
        
        let workload_identity = agent.workload_identity.as_ref()
            .map(|wi| wi.spiffe_id.clone());
        
        Ok(AgentStatus {
            agent_id: agent.identity.agent_id.clone(),
            name: agent.identity.name.clone(),
            state: agent.lifecycle_state.as_str().to_string(),
            provider: agent.identity.provider.clone(),
            model: agent.identity.model.clone(),
            current_scopes: agent.current_scopes.clone(),
            workload_identity,
            active_tokens,
            created_at: agent.identity.created_at.to_rfc3339(),
            last_active: agent.last_active_at.map(|t| t.to_rfc3339()),
        })
    }
    
    pub fn get_agent(&self, agent_id: &str) -> Option<&Agent> {
        self.agents.get(agent_id)
    }
    
    pub fn list_agents(&self) -> Vec<&Agent> {
        self.agents.values().collect()
    }
    
    pub fn get_audit_trail(&self, agent_id: &str) -> Vec<&AuditEvent> {
        match self.agents.get(agent_id) {
            Some(agent) => agent.audit_trail.iter().collect(),
            None => Vec::new(),
        }
    }
    
    fn log_event(
        &mut self,
        event_type: AuditEventType,
        agent_id: Option<&str>,
        actor_id: Option<&str>,
        details: Vec<(&str, &str)>,
    ) {
        let mut details_map = HashMap::new();
        for (key, value) in details {
            details_map.insert(key.to_string(), value.to_string());
        }
        
        let event = AuditEvent {
            id: Uuid::new_v4().to_string(),
            timestamp: Utc::now(),
            event_type,
            agent_id: agent_id.map(|s| s.to_string()),
            actor_id: actor_id.map(|s| s.to_string()),
            details: details_map,
        };
        
        if let Some(id) = agent_id {
            if let Some(agent) = self.agents.get_mut(id) {
                agent.audit_trail.push(event.clone());
            }
        }
        
        self.audit_log.push(event);
    }
}

// ============================================================================
// TESTS
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_agent_lifecycle() {
        let mut registry = AgentRegistry::new();
        
        let agent = registry.register_and_provision(
            "test-agent",
            AgentType::Autonomous,
            "user_001",
            vec!["code_generation".to_string()],
            "anthropic",
            "claude-sonnet-4",
            "1.0.0",
        );
        
        assert_eq!(agent.lifecycle_state, LifecycleState::Active);
        
        let suspended = registry.suspend_agent(&agent.identity.agent_id, "Maintenance")
            .expect("Suspend failed");
        assert_eq!(suspended.lifecycle_state, LifecycleState::Suspended);
        
        let resumed = registry.resume_agent(&agent.identity.agent_id)
            .expect("Resume failed");
        assert_eq!(resumed.lifecycle_state, LifecycleState::Active);
    }
    
    #[test]
    fn test_delegation() {
        let mut registry = AgentRegistry::new();
        
        let primary = registry.register_and_provision(
            "primary",
            AgentType::Autonomous,
            "user_001",
            vec!["code_generation".to_string(), "read".to_string()],
            "anthropic",
            "claude",
            "1.0.0",
        );
        
        let sub = registry.register_and_provision(
            "sub",
            AgentType::Assistant,
            "user_001",
            vec!["read".to_string()],
            "openai",
            "gpt-5",
            "1.0.0",
        );
        
        let token = registry.delegate_to_agent(
            &primary.identity.agent_id,
            &sub.identity.agent_id,
            vec!["read".to_string()],
            Some(10),
            60,
        ).expect("Delegate failed");
        
        assert_eq!(token.scope, vec!["read".to_string()]);
        assert!(!token.revoked);
    }
    
    #[test]
    fn test_token_validation() {
        let mut registry = AgentRegistry::new();
        
        let agent = registry.register_and_provision(
            "test",
            AgentType::Autonomous,
            "user_001",
            vec!["code_generation".to_string()],
            "test",
            "test",
            "1.0.0",
        );
        
        let token = registry.issue_token(
            &agent.identity.agent_id,
            vec!["code_generation".to_string()],
            30,
        ).expect("Issue token failed");
        
        assert!(registry.validate_token(&token.id));
        
        registry.revoke_token(&token.id).expect("Revoke failed");
        assert!(!registry.validate_token(&token.id));
    }
}
