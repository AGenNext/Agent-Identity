# Agent Lifecycle Model

Agent Identity treats AI agents as digital workers with HRMS-style lifecycle states.

This makes the model easy for enterprises to understand because agents move through onboarding, activation, probation, leave, suspension, termination, alumni, and archival states similar to employees and contractors.

## Lifecycle States

### onboarding

The IT or platform team initiates the agent identity.

During onboarding, the agent receives:

- Base identity record
- Policy assignments
- Company context
- Identity card or agent profile
- Basic tool access
- Initial credentials
- Initial audit profile

The agent is not yet trusted for full production work.

### active

The agent joins the team or project and begins normal work.

During active state, the agent receives:

- Team context
- Project context
- Role-specific skills
- Actual production tools
- Expanded policies
- Operational scopes

### probation

The agent operates for a defined reliability evaluation period.

An Agent Evaluation Framework decides whether the agent is reliable enough to remain active or receive broader access.

Evaluation inputs may include:

- Task success rate
- Hallucination rate
- Policy violations
- Human feedback
- Security events
- Tool-use accuracy
- Audit outcomes

### leave

The agent is conceptually on leave when the user or supervising human is also on leave.

The exception is when the user explicitly remote-controls or authorizes the agent to continue work during that period.

In leave state, access should usually be reduced, paused, or limited to approved background tasks.

### suspended

The agent is suspended due to risk or performance concerns.

Suspension triggers can include:

- Hallucination
- Incorrect performance
- Policy violation
- Security breach
- Abnormal tool usage
- Human escalation

Suspension should pause or sharply reduce access while investigation happens.

### terminated

The agent is permanently disabled.

Termination means:

- Complete access revocation
- Credential revocation
- Tool access removal
- Policy detachment
- Delegation termination
- Audit record preservation

### alumni

The agent is no longer active but remains associated with the company, team, or creator that produced it.

This state is useful for:

- Historical reference
- Auditability
- Provenance
- Knowledge transfer
- Reinstatement analysis

### archived

The agent blueprint is archived or becomes legacy and unsupported.

Archived agents or blueprints are retained for history, compliance, reproducibility, or migration reference, but they should not receive active credentials or production tool access.

## Recommended State Transition

```txt
onboarding -> active -> probation -> active
active -> leave -> active
active -> suspended -> active
active -> terminated -> alumni -> archived
suspended -> terminated
```

## Product Rule

An agent should not receive production-level access until it is `active` or explicitly approved through a probation policy.

`terminated` and `archived` agents must not receive new credentials.
