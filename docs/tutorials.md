# Tutorials

Four hands-on walkthroughs against the real model: **register** an agent, **issue a
credential**, **rotate a key**, and **verify trust**. Every step is runnable SurrealQL (the
same statements the flows use) with the equivalent MCP tool noted.

## Setup

Load the schema and seeds into a SurrealDB, exactly as the smoke test does:

```bash
surreal start --username root --password root --bind 127.0.0.1:8000 memory &
# import surreal/schema/*.surql then surreal/seeds/*.surql (see scripts/surreal_smoke_test.sh)
```

Then open a SQL session (or use the MCP server in `mcp/`):

```bash
surreal sql --endpoint http://127.0.0.1:8000 --username root --password root \
  --namespace agent_identity --database dev --pretty
```

---

## 1. Register an agent

Create the identity, provision its lifecycle, and activate it (the onboarding flow).

```surql
CREATE agent_identity:acme_bot CONTENT {
  subject: "agent:acme-bot",
  oidc_issuer: "https://identity.agennext.dev",
  oidc_subject: "agent:acme-bot",
  status: "active"
};

CREATE agent_lifecycle CONTENT {
  identity: agent_identity:acme_bot,
  state: "provisioned",
  owners: ["Acme"],
  entitlements: ["agent.identity"]
};

UPDATE agent_lifecycle SET previous_state = state, state = "active"
WHERE identity = agent_identity:acme_bot;
```

**Check:**

```surql
SELECT VALUE state FROM agent_lifecycle WHERE identity = agent_identity:acme_bot;
-- → ["active"]
```

**MCP:** `provision_agent(identity="acme_bot", subject="agent:acme-bot")` then `activate_agent("acme_bot")`.

---

## 2. Issue a credential

Record a Verifiable Credential for the agent — a `credential_subject` plus a `vc` verification
(§3.6 "signed using Verifiable Credentials").

```surql
CREATE credential_subject CONTENT {
  identity: agent_identity:acme_bot,
  subject_id: "agent:acme-bot",
  subject_type: "agent",
  claims: { capabilities: ["research"], issuer: "did:web:identity.agennext.dev" }
};

LET $v = (CREATE ONLY identity_verification CONTENT {
  identity: agent_identity:acme_bot,
  verifier: "did:web:identity.agennext.dev",
  method: "vc",
  evidence_ref: "vc:acme-bot:001",
  status: "verified",
  verified_at: time::now()
});
RELATE agent_identity:acme_bot->verified_by->$v.id;
```

**Check:**

```surql
SELECT method, status FROM identity_verification WHERE identity = agent_identity:acme_bot;
-- → method "vc", status "verified"
```

**MCP:** `verify_agent(identity="acme_bot", method="vc", verifier="did:web:identity.agennext.dev")`.

---

## 3. Rotate a key

Add a new DID verification method, point `authentication` at it, and retire the old key (it stays
in `verificationMethod` for history but is no longer authoritative). W3C DID 1.1 §5.2–§5.3.

```surql
-- The agent's DID document with its first key.
CREATE did_document:acme_bot CONTENT {
  identity: agent_identity:acme_bot,
  id: "did:web:agents.agennext.dev:acme-bot",
  controller: "did:web:agennext.dev"
};
LET $k1 = (CREATE ONLY verification_method CONTENT {
  document: did_document:acme_bot,
  id: "did:web:agents.agennext.dev:acme-bot#key-1",
  type: "Multikey", controller: "did:web:agennext.dev",
  publicKeyMultibase: "z6MkOldKeyMaterial"
});
RELATE did_document:acme_bot->has_verification_method->$k1.id;
UPDATE did_document:acme_bot SET verificationMethod += $k1.id, authentication += $k1.id;

-- ROTATE: introduce key-2, make it the only authentication key, retire key-1.
LET $k2 = (CREATE ONLY verification_method CONTENT {
  document: did_document:acme_bot,
  id: "did:web:agents.agennext.dev:acme-bot#key-2",
  type: "Multikey", controller: "did:web:agennext.dev",
  publicKeyMultibase: "z6MkNewKeyMaterial"
});
RELATE did_document:acme_bot->has_verification_method->$k2.id;
UPDATE did_document:acme_bot SET
  verificationMethod += $k2.id,
  authentication = [$k2.id];
```

**Check:**

```surql
SELECT authentication FROM did_document:acme_bot;
-- → authentication now lists only #key-2
```

---

## 4. Verify trust (before acting)

A downstream service should not trust an agent on its say-so. Confirm three things in one query:
it is **active**, it has at least one **verified** credential, and it **operates in** a trust
domain.

```surql
-- place the agent in a trust domain (seeded)
RELATE agent_identity:acme_bot->operates_in->trust_domain:agennext_public_registry;

-- the trust check
SELECT
  (SELECT VALUE state FROM ONLY agent_lifecycle
     WHERE identity = agent_identity:acme_bot LIMIT 1) AS state,
  count(SELECT id FROM identity_verification
     WHERE identity = agent_identity:acme_bot AND status = "verified") AS verified_count,
  ->operates_in->trust_domain.name AS trust_domains
FROM agent_identity:acme_bot;
```

**Decision:** trust the agent only if `state = "active"`, `verified_count >= 1`, and
`trust_domains` is non-empty. If the agent were `revoked` or `deprovisioned`, step 4 fails and the
service refuses — which is the whole point of the lifecycle.

---

## Where to go next

- The full model and grammar: [glossary](./agent-identity-glossary.md).
- Wire an external system: [integrations](./integrations.md).
- Drive these from an agent host: [`mcp/`](../mcp/README.md).
