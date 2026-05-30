# Handover — Agent Identity lifecycle & knowledge graph

**Branch:** `claude/ecstatic-lamport-8TEON`
**PR:** [#7](https://github.com/AGenNext/Agent-Identity/pull/7) (draft)
**Status:** all local validators green; CI not observed running (see Open items).

## What this work delivers

Identity & lifecycle management for AI agents, implemented as **executable SurrealQL**,
with a **controlled vocabulary** grounded in source specs and mirrored in machine- and
human-readable form, plus a JSON-LD-referenced graph and a governance knowledge graph.

### Layers
| Layer | Files | Grounded in |
| --- | --- | --- |
| Lifecycle | `surreal/schema/agent_lifecycle.surql`, `flows/`, `queries/`, `seeds/` | OpenID *Identity Management for Agentic AI* (Oct 2025) |
| DID | `surreal/schema/agent_did.surql` | W3C DID 1.1 §5 |
| Graph | `surreal/schema/agent_graph.surql`, `surreal/queries/agent_graph.queries.surql` | Whitepaper Key Terms |
| Knowledge graph | `surreal/schema/agent_knowledge_graph.surql` | SailPoint v3 + Okta Schema + CyberArk |
| Vocabulary (machine) | `vocabulary/agent-lifecycle.vocabulary.json` | all of the above, per-term `source` |
| JSON-LD context | `vocabulary/agent-lifecycle.context.jsonld` | schema.org + W3C DID + `agennext:` |
| Glossary (human) | `docs/agent-identity-glossary.md` | plain English, same terms |
| Validation/CI | `scripts/validate_lifecycle.py`, `scripts/validate_release.py`, `.github/workflows/lifecycle-validation.yml`, `.github/workflows/release-validation.yml` | — |

### Lifecycle state machine
`provisioned → active → revoked → deprovisioned` (see grammar in the schema's
`fn::lifecycle_next_states`). Uses SurrealDB out-of-the-box features (ASSERT/VALUE/DEFAULT/
EVENT/RELATE); custom `DEFINE FUNCTION`s only for the state grammar. Transition guard,
state-entry stamping, and append-only audit log are enforced by `DEFINE EVENT`s.

## Ground rules to keep (the user was strict on these)
1. **Source grounding is mandatory.** No vocabulary term may exist without a `source`
   citation in `vocabulary/agent-lifecycle.vocabulary.json`. The validator enforces this.
2. **Vocabulary stays inside cited sources.** Don't invent terms. Lifecycle terms come
   from the OpenID whitepaper; DID terms from W3C DID 1.1; knowledge-graph terms from
   SailPoint/Okta/CyberArk API docs.
3. **Prefer SurrealDB out-of-the-box features**; write custom SurrealQL only when no
   built-in can do it (only the state grammar qualifies).
4. **Keep machine + human in sync.** Any new term must land in the vocabulary JSON,
   the glossary, the schema, and (if a graph term) the JSON-LD context. The validator
   fails the build if they drift.
5. **JSON-LD is the reference graph model** for graph/knowledge-graph edges.

## How to validate
```bash
python3 scripts/validate_lifecycle.py   # grounding + cross-file consistency
python3 scripts/validate_release.py     # release gate (lifecycle + launch + surql + version)
```

## Open items for OpenHands
1. **CI not running on PR #7.** `get_check_runs` returned 0 — GitHub Actions does not
   appear to be executing the new workflows in this environment. Confirm Actions is
   enabled for the repo and that `lifecycle-validation.yml` runs on PRs.
2. **identique.org is ungrounded.** https://identique.org/ returned HTTP 403 and no
   reliable public spec was found. It is documented in the glossary only as
   "pending an accessible source." Do **not** invent vocabulary for it — obtain the
   spec/text first, then add grounded terms.
3. **Background references not yet promoted to schema** (intentionally glossary-only):
   DigiLocker, IBM Access Management, and the broader Okta/SailPoint detail tables.
   Promote into the enforced vocabulary only with a real `source` per ground rule #1.
4. **No live SurrealDB run.** The SurrealQL has not been executed against a SurrealDB
   instance in CI. Consider adding a job that loads the schema/seed into SurrealDB to
   catch runtime errors (events, functions) beyond the static checks.
