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

## Keeping it grounded

If you want to add a new word to this vocabulary, you must:

1. Find it in the source whitepaper and note the section.
2. Add it to `vocabulary/agent-lifecycle.vocabulary.json` with its `source`.
3. Add it to this glossary.
4. Use it in the SurrealQL schema.

The validator fails the build if these drift apart, so the vocabulary, the docs, and the
database can never disagree.
