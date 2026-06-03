#!/usr/bin/env python3
"""Repo-level validator for the Agent Identity lifecycle vocabulary.

This enforces that the controlled vocabulary stays grounded in the source
whitepaper and consistent across every place it is used:

  * vocabulary/agent-lifecycle.vocabulary.json   (machine-readable source of truth)
  * docs/agent-identity-glossary.md              (human-readable, common English)
  * surreal/schema/agent_lifecycle.surql         (the database schema + grammar)
  * vocabulary/agent-lifecycle.context.jsonld    (schema.org JSON-LD mapping)

It fails (exit 1) if any of them drift apart, if a term has no source citation,
or if the SurrealQL uses a lifecycle state outside the vocabulary.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "vocabulary" / "agent-lifecycle.vocabulary.json"
GLOSSARY = ROOT / "docs" / "agent-identity-glossary.md"
SCHEMA = ROOT / "surreal" / "schema" / "agent_lifecycle.surql"
DID_SCHEMA = ROOT / "surreal" / "schema" / "agent_did.surql"
KG_SCHEMA = ROOT / "surreal" / "schema" / "agent_knowledge_graph.surql"
IDENTITY_SCHEMA = ROOT / "surreal" / "schema" / "agent_identity.surql"
ACCESS_REVIEW_SCHEMA = ROOT / "surreal" / "schema" / "access_review.surql"
CONTEXT = ROOT / "vocabulary" / "agent-lifecycle.context.jsonld"
EXAMPLE = ROOT / "vocabulary" / "examples" / "agent.example.jsonld"

errors: list[str] = []


def err(message: str) -> None:
    errors.append(message)


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        err(f"Required file is missing: {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        err(f"Invalid JSON in {path.relative_to(ROOT)}: {exc}")
    return {}


def collect_array(literal: str) -> list[str]:
    """Pull the quoted string members out of a SurrealQL array literal."""
    return re.findall(r'"([^"]+)"', literal)


def parse_schema_states(text: str) -> set[str]:
    match = re.search(
        r'DEFINE FIELD state ON TABLE agent_lifecycle[^;]*?ASSERT \$value IN \[([^\]]*)\]',
        text,
        re.DOTALL,
    )
    if not match:
        err("Could not find the `state` ASSERT list in the schema.")
        return set()
    return set(collect_array(match.group(1)))


def parse_schema_transitions(text: str) -> dict[str, list[str]]:
    match = re.search(
        r'DEFINE FUNCTION fn::lifecycle_next_states.*?RETURN \{(.*?)\}\[\$from\]',
        text,
        re.DOTALL,
    )
    if not match:
        err("Could not find fn::lifecycle_next_states in the schema.")
        return {}
    body = match.group(1)
    transitions: dict[str, list[str]] = {}
    for state, arr in re.findall(r'(\w+):\s*\[([^\]]*)\]', body):
        transitions[state] = collect_array(arr)
    return transitions


def parse_schema_triggers(text: str) -> set[str]:
    match = re.search(
        r'DEFINE FIELD trigger ON TABLE lifecycle_audit_log[^;]*?IN \[([^\]]*)\]',
        text,
        re.DOTALL,
    )
    if not match:
        err("Could not find the `trigger` ASSERT list in the schema.")
        return set()
    return set(collect_array(match.group(1)))


def main() -> int:
    vocab = load_json(VOCAB)
    load_json(CONTEXT)  # validates JSON-LD is parseable
    if errors:
        return report()

    # --- grounding: every term must cite a source --------------------------------
    def require_sources(items: list[dict], kind: str) -> None:
        for item in items:
            if not item.get("source"):
                err(f"{kind} '{item.get('term')}' has no `source` citation (grounding lost).")

    require_sources(vocab.get("states", []), "State")
    require_sources(vocab.get("triggers", []), "Trigger")
    require_sources(vocab.get("attributes", []), "Attribute")
    require_sources(vocab.get("did", []), "DID property")
    require_sources(vocab.get("verification", {}).get("methods", []), "Verification method")
    require_sources(vocab.get("accessReview", {}).get("decisions", []), "Access-review decision")
    kg = vocab.get("knowledgeGraph", {})
    require_sources(kg.get("nodes", []), "Knowledge-graph node")
    require_sources(kg.get("edges", []), "Knowledge-graph edge")

    vocab_states = [s["term"] for s in vocab.get("states", [])]
    vocab_states_set = set(vocab_states)
    vocab_triggers = {t["term"] for t in vocab.get("triggers", [])}
    grammar = vocab.get("grammar", {}).get("transitions", {})

    if not GLOSSARY.exists():
        err("Required file is missing: docs/agent-identity-glossary.md")
        return report()
    if not SCHEMA.exists():
        err("Required file is missing: surreal/schema/agent_lifecycle.surql")
        return report()

    glossary_text = GLOSSARY.read_text()
    schema_text = SCHEMA.read_text()

    # --- schema states must equal vocabulary states ------------------------------
    schema_states = parse_schema_states(schema_text)
    if schema_states != vocab_states_set:
        err(
            "Schema `state` values do not match the vocabulary.\n"
            f"  schema:     {sorted(schema_states)}\n"
            f"  vocabulary: {sorted(vocab_states_set)}"
        )

    # --- schema grammar must equal vocabulary grammar ----------------------------
    schema_transitions = parse_schema_transitions(schema_text)
    norm = lambda d: {k: sorted(v) for k, v in d.items()}
    if norm(schema_transitions) != norm(grammar):
        err(
            "Lifecycle grammar in the schema does not match the vocabulary.\n"
            f"  schema:     {norm(schema_transitions)}\n"
            f"  vocabulary: {norm(grammar)}"
        )

    # grammar must only reference known states
    for src, dests in grammar.items():
        for state in [src, *dests]:
            if state not in vocab_states_set:
                err(f"Grammar references unknown state '{state}'.")

    # --- schema triggers must equal vocabulary triggers --------------------------
    schema_triggers = parse_schema_triggers(schema_text)
    if schema_triggers != vocab_triggers:
        err(
            "Schema `trigger` values do not match the vocabulary.\n"
            f"  schema:     {sorted(schema_triggers)}\n"
            f"  vocabulary: {sorted(vocab_triggers)}"
        )

    # --- human/machine sync: glossary must mention every term --------------------
    did_terms = [d["term"] for d in vocab.get("did", [])]
    for term in vocab_states + sorted(vocab_triggers) + [a["term"] for a in vocab.get("attributes", [])] + did_terms:
        if f"`{term}`" not in glossary_text:
            err(f"Glossary is missing the term `{term}` (human/machine docs out of sync).")

    # --- DID property names must appear in the DID schema ------------------------
    if did_terms:
        if not DID_SCHEMA.exists():
            err("Required file is missing: surreal/schema/agent_did.surql")
        else:
            did_schema_text = DID_SCHEMA.read_text()
            for term in did_terms:
                if not re.search(rf'DEFINE FIELD {re.escape(term)} ON TABLE', did_schema_text):
                    err(f"DID property `{term}` is in the vocabulary but not defined in agent_did.surql.")

    # --- knowledge-graph nodes/edges must be DEFINE TABLEs and in the glossary ---
    kg_terms = [n["term"] for n in kg.get("nodes", [])] + [e["term"] for e in kg.get("edges", [])]
    if kg_terms:
        if not KG_SCHEMA.exists():
            err("Required file is missing: surreal/schema/agent_knowledge_graph.surql")
        else:
            kg_schema_text = KG_SCHEMA.read_text()
            for term in kg_terms:
                if not re.search(rf'DEFINE TABLE {re.escape(term)} ', kg_schema_text):
                    err(f"Knowledge-graph term `{term}` is in the vocabulary but not a DEFINE TABLE in agent_knowledge_graph.surql.")
        for term in kg_terms:
            if f"`{term}`" not in glossary_text:
                err(f"Glossary is missing knowledge-graph term `{term}`.")

    # --- verification methods must appear in the identity_verification ASSERT ----
    verification = vocab.get("verification", {})
    vmethods = [m["term"] for m in verification.get("methods", [])]
    if vmethods:
        if not IDENTITY_SCHEMA.exists():
            err("Required file is missing: surreal/schema/agent_identity.surql")
        else:
            id_text = IDENTITY_SCHEMA.read_text()
            m = re.search(
                r'DEFINE FIELD method ON TABLE identity_verification[^;]*?IN \[([^\]]*)\]',
                id_text, re.DOTALL,
            )
            schema_methods = set(collect_array(m.group(1))) if m else set()
            if m is None:
                err("Could not find the identity_verification `method` ASSERT list in agent_identity.surql.")
            for term in vmethods:
                if term not in schema_methods:
                    err(f"Verification method `{term}` is in the vocabulary but not in the identity_verification method ASSERT.")
                if f"`{term}`" not in glossary_text:
                    err(f"Glossary is missing verification method `{term}`.")

    # --- access-review decisions must appear in the access_review ASSERT --------
    decisions = [d["term"] for d in vocab.get("accessReview", {}).get("decisions", [])]
    if decisions:
        if not ACCESS_REVIEW_SCHEMA.exists():
            err("Required file is missing: surreal/schema/access_review.surql")
        else:
            ar_text = ACCESS_REVIEW_SCHEMA.read_text()
            m = re.search(
                r'DEFINE FIELD decision ON TABLE access_review[^;]*?IN \[([^\]]*)\]',
                ar_text, re.DOTALL,
            )
            ar_decisions = set(collect_array(m.group(1))) if m else set()
            if m is None:
                err("Could not find the access_review `decision` ASSERT list.")
            for term in decisions:
                if term not in ar_decisions:
                    err(f"Access-review decision `{term}` is in the vocabulary but not in the access_review decision ASSERT.")
                if f"`{term}`" not in glossary_text:
                    err(f"Glossary is missing access-review decision `{term}`.")

    # --- edges: schema (RELATION) <-> vocabulary <-> JSON-LD context <-> glossary -
    ctx_keys: set[str] = set()
    ctx = load_json(CONTEXT).get("@context", [])
    for part in ctx if isinstance(ctx, list) else [ctx]:
        if isinstance(part, dict):
            ctx_keys.update(part.keys())

    graph_edges = vocab.get("graph", {}).get("edges", [])
    require_sources(graph_edges, "Graph edge")

    # Schema files that define this project's RELATION edges (excludes the base
    # agent_identity.surql, whose relations predate this vocabulary).
    relation_files = [
        ROOT / "surreal" / "schema" / "agent_graph.surql",
        ROOT / "surreal" / "schema" / "agent_lifecycle.surql",
        ROOT / "surreal" / "schema" / "agent_did.surql",
        KG_SCHEMA,
    ]
    schema_blob = "\n".join(p.read_text() for p in relation_files if p.exists())

    declared_edges = [e["term"] for e in graph_edges] + [e["term"] for e in kg.get("edges", [])]
    for term in declared_edges:
        if not re.search(rf'DEFINE TABLE {re.escape(term)} TYPE RELATION', schema_blob):
            err(f"Edge `{term}` is in the vocabulary but not a RELATION table in the schema.")
        if term not in ctx_keys:
            err(f"Edge `{term}` is not defined in the JSON-LD context.")
        if f"`{term}`" not in glossary_text:
            err(f"Glossary is missing edge `{term}`.")

    # Reverse: every RELATION table in those schema files must be declared in the vocabulary.
    declared_set = set(declared_edges)
    for match in re.finditer(r'DEFINE TABLE (\w+) TYPE RELATION', schema_blob):
        name = match.group(1)
        if name not in declared_set:
            err(f"RELATION table `{name}` is in the schema but not declared in the vocabulary (graph/knowledgeGraph edges).")

    # Knowledge-graph nodes should also resolve in the JSON-LD context.
    for node in kg.get("nodes", []):
        if node["term"] not in ctx_keys:
            err(f"Knowledge-graph node `{node['term']}` is not defined in the JSON-LD context.")

    # --- JSON-LD example must only use keys defined in the context ----------------
    if EXAMPLE.exists():
        example = load_json(EXAMPLE)
        defined = set(ctx_keys)
        # JSON-LD keywords and the documentation key are always allowed.
        allowed = defined | {"@context", "@type", "@id", "@vocab", "name", "value", "$comment"}
        def check_keys(obj: object) -> None:
            if isinstance(obj, dict):
                for key, val in obj.items():
                    if not key.startswith("@") and key not in allowed:
                        err(f"JSON-LD example uses key `{key}` not defined in the context.")
                    check_keys(val)
            elif isinstance(obj, list):
                for item in obj:
                    check_keys(item)
        check_keys(example)

    return report()


def report() -> int:
    if errors:
        print("❌ Lifecycle vocabulary validation failed:\n")
        for e in errors:
            print(f"- {e}")
        return 1
    print("✅ Lifecycle vocabulary is grounded and consistent across schema, glossary, and JSON-LD.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
