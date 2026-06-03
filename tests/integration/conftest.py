"""Shared setup for the SurrealDB integration suite (mirrors Talos SetupSuite).

The `surreal` fixture connects to a SurrealDB instance, loads the schema and
seeds once per session, and yields a client. If no SurrealDB is reachable the
whole suite is skipped — so the default `pytest -q` stays green without one.

Point it at an instance with env vars (defaults shown):
  SURREAL_URL=http://127.0.0.1:8000  SURREAL_NS=agent_identity  SURREAL_DB=dev
  SURREAL_USER=root  SURREAL_PASS=root
"""
import os

import pytest

from surreal_client import SCHEMA_FILES, SEED_FILES, SurrealClient


@pytest.fixture(scope="session")
def surreal():
    client = SurrealClient(
        url=os.environ.get("SURREAL_URL", "http://127.0.0.1:8000"),
        ns=os.environ.get("SURREAL_NS", "agent_identity"),
        db=os.environ.get("SURREAL_DB", "dev"),
        user=os.environ.get("SURREAL_USER", "root"),
        pwd=os.environ.get("SURREAL_PASS", "root"),
    )
    if not client.available():
        pytest.skip("SurrealDB not reachable; set SURREAL_URL to run integration tests")
    for rel in SCHEMA_FILES + SEED_FILES:
        client.run_file(rel)
    return client
