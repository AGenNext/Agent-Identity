"""Minimal SurrealDB HTTP client for integration tests (stdlib only).

Talks to SurrealDB's stable `/sql` endpoint, which is version-robust (unlike the
evolving Python SDK). Used by the per-feature integration suites — mirroring the
central orchestration file in Talos's k8s integration tests (k8s.go).
"""
from __future__ import annotations

import base64
import json
import pathlib
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
TESTDATA = pathlib.Path(__file__).resolve().parent / "testdata"


def load_testdata(name: str) -> dict:
    """Load a JSON fixture from tests/integration/testdata/."""
    return json.loads((TESTDATA / name).read_text())

# Schema, in dependency order (agent_identity defines the base tables others use).
SCHEMA_FILES = [
    "surreal/schema/agent_identity.surql",
    "surreal/schema/agent_lifecycle.surql",
    "surreal/schema/agent_did.surql",
    "surreal/schema/agent_graph.surql",
    "surreal/schema/agent_knowledge_graph.surql",
    "surreal/schema/access_review.surql",
    "surreal/schema/agent_economy.surql",
]
SEED_FILES = [
    "surreal/seeds/agent_identity.seed.surql",
    "surreal/seeds/agent_lifecycle.seed.surql",
    "surreal/seeds/agent_graph.seed.surql",
]


class SurrealClient:
    def __init__(self, url: str, ns: str, db: str, user: str, pwd: str):
        self.url = url.rstrip("/")
        self.ns, self.db, self.user, self.pwd = ns, db, user, pwd

    def _post(self, surql: str):
        req = urllib.request.Request(self.url + "/sql", data=surql.encode(), method="POST")
        token = base64.b64encode(f"{self.user}:{self.pwd}".encode()).decode()
        req.add_header("Authorization", "Basic " + token)
        req.add_header("Accept", "application/json")
        req.add_header("Content-Type", "text/plain")
        # Header names differ across SurrealDB versions; set both spellings.
        for key, value in (("NS", self.ns), ("DB", self.db),
                           ("surreal-ns", self.ns), ("surreal-db", self.db)):
            req.add_header(key, value)
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.loads(resp.read().decode())

    def available(self) -> bool:
        try:
            self._post("INFO FOR DB;")
            return True
        except Exception:
            return False

    def run(self, surql: str):
        """Run statements; return the raw list of per-statement result objects."""
        return self._post(surql)

    def run_file(self, rel_path: str):
        return self._post((ROOT / rel_path).read_text())

    def result(self, surql: str):
        """Return the `result` of the last statement."""
        res = self._post(surql)
        return res[-1].get("result") if res else None

    def errors(self, surql: str) -> list[str]:
        """Return error messages from any statement that failed (incl. THROW)."""
        try:
            res = self._post(surql)
        except urllib.error.HTTPError as exc:
            return [exc.read().decode(errors="replace")]
        out = []
        for r in res:
            if r.get("status") == "ERR":
                out.append(str(r.get("result") or r.get("detail") or ""))
        return out
