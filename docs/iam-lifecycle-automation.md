# IAM Lifecycle Automation

Agent Identity should automate agent lifecycle transitions by integrating with enterprise IAM, IGA, HRMS, and security tools.

## Goal

Treat agents as digital workers whose access changes automatically as their lifecycle status changes.

## Integration Sources

- HRMS: employee/user state, manager, department, leave status
- IAM/IdP: users, groups, roles, sessions, SSO identity
- IGA: access requests, approvals, reviews, certifications
- PAM: privileged access grants and vault access
- SIEM/SOAR: security events, incident response, suspension triggers
- Agent Evaluation Framework: reliability, hallucination, tool-use accuracy, policy violations

## Lifecycle Automation Rules

### onboarding

Triggered when IT, security, or a platform owner initiates an agent project.

Automation actions:

- Create agent identity record
- Assign owner and supervising human
- Attach company context
- Issue identity card/profile
- Attach baseline policies
- Grant basic tool access
- Create initial audit profile

### active

Triggered when the agent joins a team or project.

Automation actions:

- Attach team and project context
- Grant production tools
- Apply role-specific policies
- Assign skills and capabilities
- Start operational audit monitoring

### probation

Triggered when the agent is allowed to work but still under evaluation.

Automation actions:

- Apply limited scopes
- Increase audit sampling
- Route sensitive actions for human approval
- Send metrics to Agent Evaluation Framework
- Promote to active only after passing reliability thresholds

### leave

Triggered when the supervising user is on leave or the project is paused.

Automation actions:

- Pause non-essential credentials
- Disable interactive actions
- Allow only approved background tasks
- Re-enable when the supervising user returns or manually authorizes remote work

### suspended

Triggered by hallucination, incorrect performance, policy violation, abnormal behavior, or security breach.

Automation actions:

- Freeze credentials
- Revoke active sessions
- Disable tool access
- Create security/audit event
- Notify owner/security team
- Require review before reactivation

### terminated

Triggered when the agent is permanently disabled.

Automation actions:

- Revoke all credentials
- Remove all tool access
- Terminate delegations
- Detach active policies
- Preserve audit records
- Mark identity as non-operational

### alumni

Triggered after termination when the identity should remain historically associated with the company, creator, or project.

Automation actions:

- Preserve provenance
- Preserve audit trail
- Disable credential issuance
- Allow read-only historical lookup

### archived

Triggered when the agent blueprint is legacy or unsupported.

Automation actions:

- Archive blueprint
- Disable active runtime use
- Retain metadata for compliance, reproducibility, and migration

## IAM Mapping

| Agent Identity | IAM/IGA Equivalent |
|---|---|
| Agent registry | Non-human identity inventory |
| Agent owner | Manager / sponsor |
| Lifecycle status | Joiner-mover-leaver state |
| Capabilities | Entitlements |
| Policies | Access packages / roles |
| Delegations | On-behalf-of grants |
| Credential revocation | Session and token revocation |
| Audit ledger | Compliance evidence |

## Automation Events

Recommended event names:

```txt
agent.created
agent.onboarding.started
agent.activated
agent.probation.started
agent.probation.passed
agent.leave.started
agent.leave.ended
agent.suspended
agent.reactivated
agent.terminated
agent.alumni.marked
agent.archived
credential.issued
credential.revoked
delegation.created
delegation.revoked
policy.attached
policy.detached
```

## Connector Targets

Initial integrations should target:

- Okta
- Microsoft Entra ID
- Auth0
- Workday
- ServiceNow
- SailPoint
- Saviynt
- HashiCorp Vault
- Cloudflare Access
- GitHub Enterprise

## Product Principle

No lifecycle transition should happen silently. Every automated transition must produce an audit event explaining:

- What changed
- Why it changed
- Which system triggered it
- Which policy was applied
- Which credentials or tools were affected
