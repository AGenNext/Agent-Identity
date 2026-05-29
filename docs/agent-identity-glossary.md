# Agent Identity Lifecycle Glossary

This glossary is the human-readable companion to the machine-readable
[`vocabulary/agent-lifecycle.vocabulary.json`](../vocabulary/agent-lifecycle.vocabulary.json).
Both files describe the **same** controlled vocabulary and must stay in sync — the
repo validator (`scripts/validate_lifecycle.py`) checks this on every push and pull request.

Every word in this vocabulary comes from one source document:
**"Identity Management for Agentic AI"** (OpenID Foundation, edited by Tobin South,
October 2025). Nothing here is invented outside that paper. The "Source" column tells
you exactly where each term comes from so the grounding can always be checked.

## How to read this

- **Term** — the exact word used in the database and in code.
- **Plain English** — what it means, in common English.
- **Source** — where the word comes from in the whitepaper.
- **schema.org** — how the term maps to [schema.org](https://schema.org) so the data can
  be published as JSON-LD (see [`agent-lifecycle.context.jsonld`](../vocabulary/agent-lifecycle.context.jsonld)).

## Lifecycle states

An agent identity is always in exactly one of these four states.

| Term | Plain English | Source | schema.org |
| --- | --- | --- | --- |
| `provisioned` | The agent has been created and registered, but is not working yet. | §2.9 ("agent provisioning"); §3.7 ("from provisioning to … de-provisioning") | [PotentialActionStatus](https://schema.org/PotentialActionStatus) |
| `active` | The agent has live credentials and is doing real work. | Key Terms, *Revocation* ("an agent's active credentials … current session") | [ActiveActionStatus](https://schema.org/ActiveActionStatus) |
| `revoked` | The agent's live credentials have been switched off and its session ended. Its registration may still exist. | Key Terms, *Revocation*; §3.2 "The Revocation Challenge" | [FailedActionStatus](https://schema.org/FailedActionStatus) |
| `deprovisioned` | The agent's identity and all of its access have been permanently removed everywhere. This is the last step. | Key Terms, *De-provisioning*; §3.2 "De-provisioning & Off-boarding" | [CompletedActionStatus](https://schema.org/CompletedActionStatus) |

## Lifecycle grammar (allowed moves)

The agent can only move between states along these arrows. Any other move is rejected by the
database (`fn::lifecycle_allows` and the `agent_lifecycle_guard` event).

```text
provisioned -> active
provisioned -> deprovisioned
active      -> revoked
active      -> deprovisioned
revoked     -> deprovisioned
```

In plain English: a new agent is **provisioned**, then becomes **active**. From active it can
either be **revoked** (paused — credentials off) or **deprovisioned** (deleted for good). A
revoked agent can only go on to be **deprovisioned**. Once deprovisioned, it stays that way.

## Triggers (why a change happened)

When an agent is revoked or deprovisioned, the audit log can record why.

| Term | Plain English | Source |
| --- | --- | --- |
| `security_alert` | A security alert caused the change. | §3.2 ("triggered by an event like a security alert") |
| `compromise` | The agent is believed to be hacked or misused. | §3.2 ("a compromise or end-of-life event") |
| `end_of_life` | The agent has simply reached the end of its useful life. | §3.2 ("a compromise or end-of-life event") |

## Attributes (the fields we store)

| Term | Plain English | Source | schema.org |
| --- | --- | --- | --- |
| `owners` | Who is accountable for the agent. | §2.9 ("its own attributes, owners, and group memberships") | [owner](https://schema.org/owns) |
| `entitlements` | What the agent is allowed to access. | §2.9 ("all its associated entitlements"); §3.2 | [permissions](https://schema.org/permissions) |
| `actor` | The agent that performed the action. | §2.11 ("the act (actor) claim … identify the acting party") | [agent](https://schema.org/agent) |
| `principal` | The human who granted the authority. | §2.11 ("both the human principal and the agent actor") | [participant](https://schema.org/participant) |

## Decentralized Identifier (DID) properties

The agent can have a W3C **DID document** (`surreal/schema/agent_did.surql`). The DID
*concept* comes from the whitepaper (§3.1 "Sovereign and Portable Agent Identity" —
"schemes like DIDs"); the exact property *names* come from the W3C spec
[Decentralized Identifiers (DIDs) v1.1](https://www.w3.org/TR/did-1.1/), §5 Core Properties.
A DID document is published as JSON-LD using the context `https://www.w3.org/ns/did/v1.1`.

| Term | Plain English | Source |
| --- | --- | --- |
| `id` | The identifier itself (the DID). | W3C DID 1.1 §5.1.1 |
| `controller` | Who controls the DID document. | W3C DID 1.1 §5.1.2 |
| `alsoKnownAs` | Other identifiers for the same agent. | W3C DID 1.1 §5.1.3 |
| `verificationMethod` | The keys used to prove identity. | W3C DID 1.1 §5.2 |
| `authentication` | Keys allowed to prove control of the DID. | W3C DID 1.1 §5.3.1 |
| `assertionMethod` | Keys allowed to make signed claims. | W3C DID 1.1 §5.3.2 |
| `keyAgreement` | Keys used to agree on shared secrets. | W3C DID 1.1 §5.3.3 |
| `capabilityInvocation` | Keys allowed to use a capability. | W3C DID 1.1 §5.3.4 |
| `capabilityDelegation` | Keys allowed to hand a capability to someone else. | W3C DID 1.1 §5.3.5 |
| `service` | Where to reach services for this agent. | W3C DID 1.1 §5.4 |

## Objects (the tables) and their schema.org types

| Table | Plain English | schema.org |
| --- | --- | --- |
| `agent_identity` | The agent itself, treated as a piece of software. | [SoftwareApplication](https://schema.org/SoftwareApplication) |
| `agent_lifecycle` | The agent's current lifecycle state. | (state maps to [ActionStatusType](https://schema.org/ActionStatusType)) |
| `lifecycle_audit_log` | A record of each lifecycle change. | [UpdateAction](https://schema.org/UpdateAction) |

## Graph layer

The graph layer connects identity records to each other using SurrealDB's native graph
edges (`surreal/schema/agent_graph.surql`). Every edge name comes from the whitepaper.

**Nodes** (the things being connected):

| Node | Plain English |
| --- | --- |
| `agent_identity` | An agent. |
| `trust_domain` | A system or environment with one governing authority. |
| `identity_issuer` | Who issued the agent's identity. |
| `lifecycle_audit_log` | A record of a lifecycle change. |

**Edges** (the arrows between nodes). JSON-LD is the reference graph model: each edge is a
predicate in [`agent-lifecycle.context.jsonld`](../vocabulary/agent-lifecycle.context.jsonld),
mapped to schema.org where one exists and to the `agennext:` namespace otherwise.

| Edge | Plain English | Direction | JSON-LD predicate | Source |
| --- | --- | --- | --- | --- |
| `delegates_to` | One agent hands a subset of its authority to another agent (a delegation chain). The `attenuated` flag marks where permissions were narrowed. | agent → agent | `agennext:delegatesTo` | Key Terms *Recursive Delegation*, *Scope Attenuation*; §3.2 |
| `acts_on_behalf_of` | An agent is acting for a human principal, while staying distinct from them. | agent → agent (with `principal`) | `agennext:actsOnBehalfOf` | Key Terms *On-Behalf-Of (OBO) Flow*, *Delegated Authority*; §3.2 |
| `operates_in` | An agent works inside a given trust domain (it may operate in several). | agent → trust_domain | [`schema:memberOf`](https://schema.org/memberOf) | Key Terms *Trust Domain* |
| `audited_by` | An agent is linked to each of its lifecycle change records. | agent → lifecycle_audit_log | `agennext:auditedBy` | §2.11 *enriched audit logs* |
| `has_verification_method` | A DID document links to its keys. | did_document → verification_method | `did:verificationMethod` | W3C DID 1.1 §5.2 |
| `has_service` | A DID document links to its service endpoints. | did_document → service | `did:service` | W3C DID 1.1 §5.4 |

In plain English: agents **delegate to** other agents (and that authority can be narrowed
along the chain), agents **act on behalf of** people, and agents **operate in** trust domains.
Every lifecycle change is **audited**. You can walk these arrows with the graph queries in
`surreal/queries/agent_graph.queries.surql`.

## Whitepaper key terms (background)

These terms come straight from the *Key Terms and Acronyms* table of the source whitepaper
("Identity Management for Agentic AI", OpenID Foundation, Oct 2025). They are background for
readers; the enforced controlled vocabulary is only the lifecycle states, triggers, attributes,
and DID properties listed earlier. Definitions are paraphrased in common English.

| Term | Plain English |
| --- | --- |
| AI Agent | Software, usually backed by a language model, that can decide and act on its own to reach a goal — not just answer questions. |
| Authentication | Proving who someone (or what software) is. For agents this means proving both the agent itself and the human delegating to it. |
| Authorization | Deciding what an authenticated agent or user is allowed to do. |
| Identity and Access Management (IAM) | The whole set of policies and tools that make sure the right people and agents get the right access. |
| OAuth 2.1 | The modern standard that lets an app get limited access to a user's account; the base for securing agent access to APIs. |
| Model Context Protocol (MCP) | The leading protocol for connecting AI models to outside tools and data so agents can act. |
| Agent-to-Agent (A2A) | A protocol for agents to talk to and hand work to other agents. |
| Single Sign-On (SSO) | Logging in once to reach many systems; used in companies to manage access to agent platforms. |
| SCIM | A standard for automating identity lifecycle (create, update, de-provision) across systems, for users and agents. |
| Workload Identity | A verifiable identity for a piece of software (like an agent) so it can authenticate without static secrets like API keys. |
| SPIFFE / SPIRE | A framework and runtime that hand out strong, auto-rotating workload identities to software. |
| Delegated Identity | A durable, first-class identity for an agent, separate from the user, so it can work on its own over long periods. |
| Delegated Authority | A model where a user explicitly lets an agent act for them within a limited scope. |
| On-Behalf-Of (OBO) Flow | The pattern that puts two identities in one token: the user who granted authority and the agent doing the work. |
| Impersonation | The risky case where an agent acts exactly like the user (e.g. using their credentials), leaving no clear accountability. |
| Client Initiated Backchannel Authentication (CIBA) | A standard that lets an agent ask for approval out-of-band, good for long tasks or risky actions. |
| Recursive Delegation | One agent passing a sub-task and part of its authority to another agent, forming a chain. |
| Scope Attenuation | Narrowing permissions at each step of a delegation chain to keep least privilege. |
| Revocation | Immediately switching off an agent's active credentials to end its current session. |
| De-provisioning | Permanently removing an agent's identity and all its access from every system — the last lifecycle step. |
| Consent Fatigue | When users get so many approval prompts that they start clicking "approve" without thinking, which is a security risk. |
| Policy Enforcement Point (PEP) | The component (e.g. an API gateway) that intercepts a request and enforces the access decision. |
| Policy Decision Point (PDP) | The service that actually makes the allow/deny decision, which the PEP then enforces. |
| Trust Domain | A system or environment where one authority handles authentication and authorization; agents often cross several. |
| Guardrails | Technical limits that keep agents safe and in-bounds, e.g. masking sensitive data or capping resource use. |
| Web Bot Auth | An emerging protocol letting a legitimate agent cryptographically prove its identity in its HTTP requests. |

## Related identity references (background only)

These are external identity systems and references noted for context. They are **not**
part of the enforced controlled vocabulary above (so the validator does not require them
in the schema). They are documented here, in plain English, for orientation only. If any
of them is later promoted into the controlled vocabulary, it must be added to
`vocabulary/agent-lifecycle.vocabulary.json` with a real `source` citation first.

| Reference | Plain English | Link / status |
| --- | --- | --- |
| DigiLocker | India's government digital document wallet. Citizens store and share official documents (licences, certificates). It is Aadhaar-linked and exposes OAuth 2.0-based Issuer and Pull Document APIs with explicit, consent-based document sharing — a real-world verifiable-credential issuer/verifier model. | [digilocker.gov.in](https://www.digilocker.gov.in/) |
| IBM — Access Management | A conceptual overview of access management (IAM): authentication, authorization, single sign-on, least privilege, and MFA. It aligns with the same access-management concepts the OpenID whitepaper builds on; useful as background, not as a vocabulary source. | [ibm.com/think/topics/access-management](https://www.ibm.com/think/topics/access-management) |
| Okta — Management API schema | Okta's Management API includes a Schema resource that describes the attributes (properties) of users and apps as JSON schema. It is a real-world example of how an IAM platform models identity attributes and could inform a future attribute-schema mapping for agents. Background only, not a vocabulary source. | [developer.okta.com — Schema API](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/schema) |
| Identique | A referenced digital-identity initiative. **Not yet grounded:** the site ([identique.org](https://identique.org/)) returned HTTP 403 to automated fetching and no reliable public specification was found, so no vocabulary has been derived from it. Provide an accessible source or text to ground it. | [identique.org](https://identique.org/) — pending an accessible source |

### Okta Schema API — important entries (background)

Okta's Management **Schema API** is a useful real-world model for describing identity
attributes, and could inform a future attribute-schema layer for agents. The entries below
are background only (not part of the enforced vocabulary). Source:
[Okta Schema API](https://developer.okta.com/docs/api/openapi/okta-management/management/tags/schema)
(the live page blocked automated fetch, so this reflects Okta's established, documented model).

**Schema resources**

| Entry | Plain English |
| --- | --- |
| User Schema | Describes the attributes of a user (per user type). |
| Group Schema | Describes the attributes of a group. |
| App User Schema | Describes the attributes of a user *for a specific app*. |

**Subschemas (where attributes live)**

| Entry | Plain English |
| --- | --- |
| `base` | Okta-defined, fixed attributes (e.g. login, email, firstName, lastName). |
| `custom` | Admin-defined custom attributes added on top of base. |

**Attribute (schema property) definition fields**

| Entry | Plain English |
| --- | --- |
| `title` / `description` | Human-readable name and explanation of the attribute. |
| `type` | Data type: string, integer, number, boolean, array. |
| `required` | Whether the attribute must be present. |
| `scope` | Whether the attribute is per-user (`SELF`) or not (`NONE`). |
| `permissions` | Who can read/write it (principal + `READ_ONLY` / `READ_WRITE` / `HIDE`). |
| `mutability` | Whether/when the value can change. |
| `minLength` / `maxLength` | Length limits for strings. |
| `minimum` / `maximum` | Range limits for numbers. |
| `enum` / `oneOf` | The allowed set of values. |
| `unique` | Whether the value must be unique (`UNIQUE_VALIDATED` / `NOT_UNIQUE`). |
| `master` | The source of truth for the value (profile master: `PROFILE_MASTER` / `OKTA` / `OVERRIDE`). |
| `externalName` / `externalNamespace` | How the attribute maps to an external system. |
| `items` | The element definition for array-typed attributes. |

These map naturally onto an agent attribute schema: the SCIM *AgenticIdentity* idea in the
whitepaper (§2.9) plus Okta's property fields (`type`, `required`, `mutability`, `permissions`)
would let agents be described as first-class identities with governed attributes. Promoting any
of this into the enforced vocabulary requires adding it to
`vocabulary/agent-lifecycle.vocabulary.json` with a real `source` first.

## Keeping it grounded

If you want to add a new word to this vocabulary, you must:

1. Find it in the source whitepaper and note the section.
2. Add it to `vocabulary/agent-lifecycle.vocabulary.json` with its `source`.
3. Add it to this glossary.
4. Use it in the SurrealQL schema.

The validator fails the build if these drift apart, so the vocabulary, the docs, and the
database can never disagree.
