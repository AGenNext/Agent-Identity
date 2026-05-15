const agents = new Map();
const capabilities = new Map();
const credentials = new Map();
const delegations = [];
const policies = new Map();
const audits = [];

const now = () => new Date().toISOString();

export function seedStore() {
  const agent = {
    id: 'agent:research_assistant',
    name: 'Research Assistant',
    description: 'Autonomous research agent',
    provider: 'OpenAI',
    model: 'gpt-5',
    version: '1.0.0',
    status: 'active',
    created_at: now()
  };

  const capability = {
    id: 'capability:search_web',
    name: 'search.web',
    description: 'Search the public web'
  };

  agents.set(agent.id, agent);
  capabilities.set(capability.id, capability);
}

export function listAgents() {
  return Array.from(agents.values());
}

export function createAgent(input) {
  const id = input.id || `agent:${crypto.randomUUID()}`;
  const agent = {
    id,
    name: input.name,
    description: input.description || null,
    owner: input.owner || null,
    provider: input.provider || null,
    model: input.model || null,
    version: input.version || null,
    status: input.status || 'active',
    created_at: now()
  };
  agents.set(id, agent);
  return agent;
}

export function getAgent(id) {
  return agents.get(id);
}

export function createCapability(input) {
  const id = input.id || `capability:${crypto.randomUUID()}`;
  const capability = { id, name: input.name, description: input.description || null };
  capabilities.set(id, capability);
  return capability;
}

export function listCapabilities() {
  return Array.from(capabilities.values());
}

export function createCredential(input) {
  const id = input.id || `credential:${crypto.randomUUID()}`;
  const credential = {
    id,
    subject: input.subject,
    type: input.type,
    algorithm: input.algorithm || null,
    expires_at: input.expires_at || null,
    revoked: false,
    created_at: now()
  };
  credentials.set(id, credential);
  return credential;
}

export function revokeCredential(id) {
  const credential = credentials.get(id);
  if (!credential) return null;
  credential.revoked = true;
  credential.revoked_at = now();
  return credential;
}

export function listCredentials() {
  return Array.from(credentials.values());
}

export function createDelegation(input) {
  const delegation = {
    id: `delegation:${crypto.randomUUID()}`,
    principal: input.principal,
    agent: input.agent,
    scopes: input.scopes || [],
    expires_at: input.expires_at || null,
    status: 'active',
    created_at: now()
  };
  delegations.push(delegation);
  return delegation;
}

export function listDelegations() {
  return delegations;
}

export function createPolicy(input) {
  const id = input.id || `policy:${crypto.randomUUID()}`;
  const policy = {
    id,
    name: input.name,
    effect: input.effect || 'allow',
    actions: input.actions || [],
    resources: input.resources || ['*'],
    agents: input.agents || ['*'],
    created_at: now()
  };
  policies.set(id, policy);
  return policy;
}

export function listPolicies() {
  return Array.from(policies.values());
}

export function evaluatePolicy(input) {
  const matched = Array.from(policies.values()).filter((policy) => {
    const agentMatches = policy.agents.includes('*') || policy.agents.includes(input.agent);
    const actionMatches = policy.actions.includes('*') || policy.actions.includes(input.action);
    const resourceMatches = policy.resources.includes('*') || policy.resources.includes(input.resource);
    return agentMatches && actionMatches && resourceMatches;
  });

  const denied = matched.find((policy) => policy.effect === 'deny');
  const allowed = matched.find((policy) => policy.effect === 'allow');
  const decision = denied ? 'deny' : allowed ? 'allow' : 'deny';

  const audit = recordAudit({
    actor: input.agent,
    principal: input.principal || null,
    action: input.action,
    resource: input.resource,
    decision,
    metadata: { matched_policies: matched.map((policy) => policy.id) }
  });

  return { decision, matched_policies: matched, audit_id: audit.id };
}

export function recordAudit(input) {
  const audit = {
    id: `audit:${crypto.randomUUID()}`,
    actor: input.actor,
    principal: input.principal || null,
    action: input.action,
    resource: input.resource || null,
    decision: input.decision || null,
    metadata: input.metadata || {},
    created_at: now()
  };
  audits.push(audit);
  return audit;
}

export function listAudits() {
  return audits;
}
