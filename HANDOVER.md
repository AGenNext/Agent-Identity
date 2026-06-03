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

## Code review fixes applied
- **`previous_state` bug:** flows now assign `previous_state = state` *before* `state = ...`
  so the prior value is captured regardless of SurrealDB SET evaluation order.
- **CREATE grammar bypass:** `agent_lifecycle_create_guard` event forces new records to
  start in `provisioned`; the audit event is simplified to the UPDATE path.
- **Enriched audit:** `agent_lifecycle` now carries `actor`/`principal`/`trigger`, which the
  revoke/deprovision flows set and the audit event copies into `lifecycle_audit_log`.
- **CI robustness:** smoke workflow fails hard if SurrealDB never becomes ready; the
  release script's tuple-trick was replaced with a `run_local` helper.

### Still open from the review (not yet done)
- Graph-layer edges (`delegates_to`, `acts_on_behalf_of`, `operates_in`, `audited_by`,
  `has_verification_method`, `has_service`) are not yet in the machine-readable vocabulary
  and are not cross-checked against the JSON-LD context — add them to
  `vocabulary/agent-lifecycle.vocabulary.json` with `source` citations and extend the
  validator, to close the grounding/consistency gap.
- The validator's SurrealQL parsing is regex-based and brittle to reformatting; longer term,
  generate the schema/glossary from the vocabulary instead of re-parsing.
- The four repeated state-array literals were left in place because the validator's regex
  depends on the inline list; dedup requires updating the parser in lockstep.

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
4. **Live SurrealDB execution added (best-effort).** `scripts/surreal_smoke_test.sh` +
   `.github/workflows/surreal-smoke.yml` install SurrealDB, import the schema in
   dependency order, run the seeds (which exercise the events/functions at runtime),
   and assert the positive path, an audit-log entry, and that the transition guard
   rejects an illegal move. **Not yet executed locally** — SurrealDB could not be
   installed in the authoring environment (network-restricted), so verify the CLI
   flags (`is-ready`, `--endpoint`, `import`) against the runner's SurrealDB version
   on first run and adjust if needed.
