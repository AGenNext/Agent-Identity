#!/usr/bin/env python3
"""Validate connector manifests against connectors/manifest.schema.json.

Stdlib only. Enforces the schema's required fields and enums (read from the schema
file, which stays the source of truth), and cross-checks that every `mapping`
target is a real Agent Identity model term. Runs in CI.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONNECTORS = ROOT / "connectors"
SCHEMA = CONNECTORS / "manifest.schema.json"
VOCAB = ROOT / "vocabulary" / "agent-lifecycle.vocabulary.json"

errors: list[str] = []


def model_targets() -> set[str]:
    """The set of model terms a connector mapping may point at."""
    core = {"agent_identity", "owners", "entitlements", "schema_attribute", "access_review"}
    vocab = json.loads(VOCAB.read_text())
    kg = vocab.get("knowledgeGraph", {})
    core |= {n["term"] for n in kg.get("nodes", [])}
    return core


def main() -> int:
    if not SCHEMA.exists():
        print("❌ Missing connectors/manifest.schema.json")
        return 1
    schema = json.loads(SCHEMA.read_text())
    props = schema["properties"]
    required = schema["required"]
    categories = set(props["category"]["enum"])
    auth_types = set(props["auth"]["properties"]["type"]["enum"])
    capabilities = set(props["capabilities"]["items"]["enum"])
    actions = set(props["events"]["items"]["properties"]["action"]["enum"])
    targets = model_targets()

    manifests = sorted(CONNECTORS.glob("*.connector.json"))
    if not manifests:
        print("❌ No connector manifests found.")
        return 1

    for path in manifests:
        name = path.name
        try:
            m = json.loads(path.read_text())
        except json.JSONDecodeError as exc:
            errors.append(f"{name}: invalid JSON ({exc})")
            continue
        for key in required:
            if key not in m:
                errors.append(f"{name}: missing required field '{key}'")
        if m.get("category") not in categories:
            errors.append(f"{name}: category '{m.get('category')}' not in {sorted(categories)}")
        auth = m.get("auth", {})
        if auth.get("type") not in auth_types:
            errors.append(f"{name}: auth.type '{auth.get('type')}' not allowed")
        for cap in m.get("capabilities", []):
            if cap not in capabilities:
                errors.append(f"{name}: capability '{cap}' not allowed")
        for ev in m.get("events", []):
            if ev.get("action") not in actions:
                errors.append(f"{name}: event action '{ev.get('action')}' not allowed")
        mapping = m.get("mapping", {})
        if not mapping:
            errors.append(f"{name}: mapping must not be empty")
        for src, target in mapping.items():
            if target not in targets:
                errors.append(f"{name}: mapping '{src}' -> '{target}' is not a known model term {sorted(targets)}")

    if errors:
        print("❌ Connector validation failed:\n" + "\n".join(f"- {e}" for e in errors))
        return 1
    print(f"✅ {len(manifests)} connector manifests valid and mapped to the model.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
