# Unboxd Platform Integration

How the Agent Identity model maps onto the [Unboxd Platform](https://github.com/unboxd-cloud/platform)
— an open-source, CNCF-native "AWS alternative" Go control plane. Background/reference, not
enforced vocabulary. (Summarized from the public repo README; some internals weren't accessible.)

## Where the pieces line up

| Unboxd Platform | What it is | Maps to (Agent Identity) |
| --- | --- | --- |
| **ADL** (Agent Description Language, `web/adl-runtime/`) | Declarative agent definitions. | An ADL document is an onboarding input: ingest it into `agent_identity` + `agent_lifecycle` (provision/activate) + DID + access. See the onboarding flow and `tests/integration/testdata/agent_onboarding.json`. |
| **STS** (Dex + **SPIFFE/SPIRE**) | Issues short-lived workload identities (SVIDs). | `identity_verification` method **`spiffe`** (grounded in whitepaper §2.8). An agent verified by the STS gets a `verified` record with `method = "spiffe"`. |
| **catalog** (service catalog/registries) | Discovery of services. | `registry` verification method (§3.3); `source` nodes in the knowledge graph. |
| **compliance** (frameworks + residency) | Compliance evaluation, multi-tenant. | `access_review` (certification) + `lifecycle_audit_log` (audit trail, §2.11). |
| **multi-tenant `TenantID`** | Tenant isolation axis. | `trust_domain` + the `operates_in` edge (an agent operates within a tenant/trust domain). |
| **metering / billing** | Usage and rating. | Out of scope for identity; would attach to `agent_identity` as a downstream consumer. |

## ADL → SurrealQL onboarding

An ADL agent definition carries the same fields our onboarding fixture does
(`identity`, `subject`, `did`, `owners`, `entitlements`, `role`, `trust_domain`). The
end-to-end path is already implemented:

1. `agent_identity` — register the agent (subject, OIDC).
2. `did_document` — bind its DID (W3C DID 1.1).
3. `identity_verification` — verify via `spiffe` (STS/SPIRE), `oidc`, `did`, `vc`, or `registry`.
4. `agent_lifecycle` — `provision` → `activate`.
5. `operates_in` — place it in a trust domain (≈ tenant).
6. `assigned_role` / `assigned_access` — grant initial access.

See `surreal/flows/onboarding.flows.surql` and `tests/integration/test_onboarding.py`.

## Notes

- This is a mapping for orientation; it does not call Unboxd APIs. The grounded, enforced
  piece is the `spiffe` verification method (§2.8) — everything else here is reference.
- If the ADL schema is shared, the next step is an explicit ADL→SurrealQL importer flow that
  parses an ADL document and runs the onboarding sequence.
