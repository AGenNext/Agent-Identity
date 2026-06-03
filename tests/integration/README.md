# Integration tests

A SurrealDB integration suite, structured after the per-feature pattern used in
[Talos's k8s integration tests](https://github.com/siderolabs/talos/tree/main/internal/integration/k8s):
one file per feature, a central client/orchestrator, and a shared setup that loads
the schema + seeds once per session.

| File | Feature (Talos analogue: one `.go` per feature) |
| --- | --- |
| `surreal_client.py` | HTTP client + schema/seed load order (≈ `k8s.go` orchestration) |
| `conftest.py` | session setup/teardown — loads schema + seeds (≈ `SetupSuite`) |
| `test_lifecycle.py` | state-machine grammar guard, create guard, audit log |
| `test_delegation.py` | scope-attenuation guard |
| `test_did.py` | DID document + verification method |
| `test_verification.py` | identity verification request → verified |
| `test_access_review.py` | open → certify; enum guard |
| `test_knowledge_graph.py` | role assignment + edge traversal |
| `test_onboarding.py` | end-to-end onboarding orchestration |

## Running

These are **gated** like Talos's `//go:build integration` tag: if no SurrealDB is
reachable the whole suite skips, so the default `pytest -q` stays green without one.

```bash
# start a throwaway SurrealDB
surreal start --username root --password root --bind 127.0.0.1:8000 memory &

# run the suite
SURREAL_URL=http://127.0.0.1:8000 pytest tests/integration -v -m integration
```

Env vars (defaults): `SURREAL_URL=http://127.0.0.1:8000`, `SURREAL_NS=agent_identity`,
`SURREAL_DB=dev`, `SURREAL_USER=root`, `SURREAL_PASS=root`.

CI runs this automatically in `.github/workflows/integration-tests.yml` (stdlib only —
no extra Python deps; talks to SurrealDB's stable `/sql` HTTP endpoint).
