# Agent Identity — the narrative

## The problem

AI agents are becoming digital workers: they act on their own, call tools, spawn sub-agents,
and operate across organizations. The OpenID Foundation's *Identity Management for Agentic AI*
(Tobin South, Oct 2025) lays out why today's identity stack strains under this:

- **Fragmentation** — every vendor invents a proprietary agent identity, so nothing interoperates.
- **Impersonation instead of delegation** — agents act indistinguishably from users, so no one can
  tell who actually did what.
- **Lifecycle and de-provisioning** — agents must be provisioned, governed, and *verifiably*
  removed; a "rogue" agent left half-revoked is a persistent threat.
- **Auditability** — actions need an enriched trail tying every step to the human principal *and*
  the agent actor.

The whitepaper's call to action for enterprises is explicit: **treat agents as first-class
identities** with **robust lifecycle management, from provisioning to verifiable
de-provisioning**, plus governance and clear accountability.

## Our thesis

Agent Identity is that first-class model, implemented as **executable SurrealQL** with one hard
rule: **every term in the model is grounded in a cited source, and nothing is invented.** The
vocabulary lives in both machine-readable (`vocabulary/agent-lifecycle.vocabulary.json`) and
plain-English (`docs/agent-identity-glossary.md`) form, and a validator
(`scripts/validate_lifecycle.py`) fails the build if they ever drift or a term loses its citation.

If a term isn't in the OpenID whitepaper, W3C DID 1.1, schema.org, or a named vendor API, it does
not enter the enforced model. That discipline is the product.

## The layers

Each layer maps to the whitepaper and is implemented as SurrealQL schema + flows + queries.

| Layer | What it models | Grounded in |
| --- | --- | --- |
| **Identity** (`agent_identity`) | The agent as a subject with DID/OIDC metadata, issuers, trust domains. | §2.8 Identity for AI Agents |
| **Lifecycle** (`agent_lifecycle`) | `provisioned → active → revoked → deprovisioned`, enforced as a state machine. | §2.9 SCIM lifecycle; §3.2 revocation vs de-provisioning |
| **Verification** (`identity_verification`) | How the agent's identity is proven: `did`, `oidc`, `vc`, `spiffe`, `registry`. | §2.4 authentication; §2.8 SPIFFE; §3.1/§3.6 |
| **DID** (`did_document`) | A W3C DID document: verification methods, services, relationships. | W3C DID 1.1 §5 |
| **Graph** (`delegates_to`, `acts_on_behalf_of`, `operates_in`) | Delegation chains, on-behalf-of, trust-domain membership. | §3.2 delegation; Key Terms |
| **Knowledge graph** (`source`/`account`/`entitlement`/`access_profile`/`role`/`safe`) | Where an agent's access lives and how it's bundled. | SailPoint IGA, Okta Schema, CyberArk PAM |
| **Access review** (`access_review`) | Periodic re-approval (certification) of access. | §2.12 IGA; SailPoint Certifications |

JSON-LD is the reference graph model: every edge is a predicate in
`vocabulary/agent-lifecycle.context.jsonld`, mapped to schema.org where one exists.

## The arc, end to end

The whole story is one path an agent travels, and every step is a real flow in `surreal/flows/`:

```
register → bind DID → verify (did/oidc/vc/spiffe/registry)
   → provision → activate
      → delegate (scope attenuation enforced) / act-on-behalf-of
      → operate in a trust domain, hold accounts & entitlements
   → access review / certify (on a schedule)
→ revoke (credentials off) → deprovision (permanent removal)
```

Two invariants are enforced *inside the database*, not just documented:

- **Lifecycle grammar** — illegal transitions are rejected by a `DEFINE EVENT` guard, and a new
  record must start `provisioned`. Every state change writes an enriched
  `lifecycle_audit_log` entry (actor, principal, trigger) — closing the auditability gap (§2.11).
- **Scope attenuation** — a delegation may not grant more than the delegator holds; the
  `delegates_to_attenuation` event rejects an over-broad scope (§3.2/§4.4).

`surreal/flows/onboarding.flows.surql` stitches the front half into one orchestration.

## The ecosystem

The model is deliberately interoperable rather than a walled garden:

- **Okta** — Schema attributes → `schema_attribute`; SCIM lifecycle → provision/activate/revoke/
  deprovision (`docs/okta-integration.md`, `docs/okta-integration-catalog.md`).
- **SailPoint** — sources/accounts/entitlements/access-profiles/roles/certifications → the
  knowledge graph and access reviews.
- **CyberArk** — Safes → privileged-account storage (`stored_in`).
- **SPIFFE/SPIRE & Unboxd Platform** — workload identity → the `spiffe` verification method;
  Unboxd's ADL agent definitions → onboarding (`docs/unboxd-platform-integration.md`).
- **Autonomyx Identity Fabric** (`.claude/skills/`) — resolves identifiers into a unified identity
  graph across social/SSO providers.
- Consumer references (DigiLocker, GoIDC, IBM) are documented as background, kept out of the
  enforced vocabulary.

## Why it holds together

- **Grounded** — every enforced term cites its source; CI rejects ungrounded drift.
- **Machine + human** — the same vocabulary in JSON and plain English, kept in sync.
- **Executable & tested** — schema, flows, and queries run on SurrealDB; a Talos-style integration
  suite (`tests/integration/`) exercises the guards and the end-to-end onboarding against a real
  engine; release validation gates the whole thing.

The journey the whitepaper describes — from authenticating simple clients to trustworthy,
governable identities for autonomous agents — is, here, a model you can run.
