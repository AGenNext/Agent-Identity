# Agent Identity

**The enterprise, agent-native platform for decentralized identity, access management,
lifecycle management, and governance of AI agents.**

Agent Identity treats every autonomous agent as a first-class, governed identity: a verifiable
identifier, scoped and attenuable authority, a state-machine lifecycle, and a complete audit
trail — grounded in the OpenID Foundation's *Identity Management for Agentic AI* and W3C DID 1.1.

## What's here

- **Executable model (SurrealQL)** — `surreal/`: identity, lifecycle, verification, DID
  documents, delegation (with enforced scope attenuation), the governance knowledge graph, and
  access reviews, plus flows, queries, and seeds.
- **Grounded vocabulary** — `vocabulary/` (machine-readable) + `docs/agent-identity-glossary.md`
  (plain English), kept in sync and source-cited by `scripts/validate_lifecycle.py`.
- **Integrations** — declarative connector manifests (`connectors/`) for Okta, SailPoint,
  CyberArk, and SCIM, plus an MCP server (`mcp/`). See [`docs/integrations.md`](docs/integrations.md).
- **Site** — `site/`: the story (Web 1.0 → the agentic web), docs, API, SDK, security, and the
  design system; deployed via GitHub Pages.
- **Tests & CI** — a SurrealDB integration suite (`tests/integration/`) and validation/release
  workflows under `.github/workflows/`.

## Local development

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
make run
```

## Validate the model

```bash
make validate          # vocabulary grounding + consistency
make validate-release  # full release gate
make smoke             # run the SurrealQL against a local SurrealDB
```

## Docker

```bash
cp .env.example .env
docker compose up --build
```

## Health check

- http://localhost:8000/health
- http://localhost:8000/ready
- http://localhost:8000/docs
