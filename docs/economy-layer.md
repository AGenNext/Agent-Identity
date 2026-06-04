# The Economic Layer

Agent Identity's scope extends to the **agent economy**: letting an agent transact on a
principal's behalf within signed, auditable limits. Grounded in the OpenID whitepaper
§3.6 *"The Economic Layer: Identity, Payments, and Financial Transactions."*

This layer is **protocol-first, vendor-neutral, and lightweight**: it models the open protocols
(AP2, KYAPay, FAPI) rather than any one payment provider, carries no single-vendor assumption,
and adds only two record tables — so it drops into the same SurrealDB control plane (CNCF /
Kubernetes-native, runnable on K3s) as the rest of the model.

## Building blocks

| Concept | What it is | In the model |
| --- | --- | --- |
| **AP2 Mandate** | A cryptographically-signed, auditable instruction from a principal. | `payment_mandate` |
| **Intent Mandate** | A signed high-level instruction with the limits the agent must stay within. | `payment_mandate.type = "intent"` |
| **Cart Mandate** | The principal's signed approval of a specific purchase. | `payment_mandate.type = "cart"` |
| **Verifiable Credential binding** | Binds a mandate to the principal's identity. | `payment_mandate.vc_ref` |
| **Transaction** | A financial action executed under a mandate. | `agent_transaction` |
| **FAPI** | The security profile for high-consequence APIs. | `agent_transaction.fapi_secured` |
| **KYAPay / Know Your Agent** | KYC/KYB-style verification of the agent itself. | `identity_verification.method = "kya"` |

## The flow

```
Know Your Agent (kya verification)
   → principal signs an Intent Mandate (limits)
      → agent finds an option meeting the criteria
         → principal signs a Cart Mandate (this purchase)
            → agent records a transaction under the mandate
               → transaction settles (FAPI-secured for high-consequence APIs)
```

Every transaction traces back through its mandate to the human who authorized it — the
"non-repudiable audit trail" AP2 is designed to produce (§3.6). Two invariants are enforced in
the database:

- A transaction may not exceed its mandate's `amount_limit` (`agent_transaction_limit` event).
- A mandate type must be `intent` or `cart`; statuses are constrained by schema asserts.

## Why this matters

This is what turns a digital twin from something that *fetches* into something that can *act
economically*. With a verified identity (`kya`), bounded authority (mandates), and a settled,
auditable trail, an agent can buy, sell, and settle on a person's behalf — so **anyone**, not
just platforms, can put an agent to work. See `surreal/flows/economy.flows.surql` and
`surreal/queries/economy.queries.surql`.
