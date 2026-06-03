#!/usr/bin/env python3
"""Repo-level release validation gate.

Aggregates every repo validation that must pass before a release is cut. Run by
the release CI/CD workflow on tags and by `make validate-release` locally.

Checks:
  1. Lifecycle vocabulary is grounded and consistent (scripts/validate_lifecycle.py).
  2. Launch assets are ready (scripts/check_launch_ready.py).
  3. Every SurrealQL file under surreal/ has balanced brackets and a source header.
  4. package.json has a version.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run_script(name: str) -> bool:
    print(f"\n=== {name} ===")
    result = subprocess.run([sys.executable, str(ROOT / "scripts" / name)])
    return result.returncode == 0


def check_surql() -> bool:
    ok = True
    surql_files = sorted((ROOT / "surreal").rglob("*.surql"))
    if not surql_files:
        print("❌ No SurrealQL files found under surreal/.")
        return False
    for path in surql_files:
        text = path.read_text()
        rel = path.relative_to(ROOT)
        for opener, closer in [("{", "}"), ("[", "]"), ("(", ")")]:
            if text.count(opener) != text.count(closer):
                print(f"❌ Unbalanced '{opener}{closer}' in {rel}")
                ok = False
        if not any(line.lstrip().startswith("--") for line in text.splitlines()):
            print(f"❌ Missing documentation comment in {rel}")
            ok = False
    if ok:
        print(f"✅ {len(surql_files)} SurrealQL files passed structural checks.")
    return ok


def check_version() -> bool:
    pkg = json.loads((ROOT / "package.json").read_text())
    if not pkg.get("version"):
        print("❌ package.json is missing a version.")
        return False
    print(f"✅ Release version: {pkg['version']}")
    return True


def run_local(label: str, check_fn) -> bool:
    print(f"\n=== {label} ===")
    return check_fn()


def main() -> int:
    results = {
        "lifecycle vocabulary": run_script("validate_lifecycle.py"),
        "launch readiness": run_script("check_launch_ready.py"),
        "surql structure": run_local("surql structure", check_surql),
        "release version": run_local("release version", check_version),
    }
    print("\n=== Release validation summary ===")
    for name, ok in results.items():
        print(f"  {'✅' if ok else '❌'} {name}")
    if not all(results.values()):
        print("\n❌ Release validation failed.")
        return 1
    print("\n✅ Release validation passed. Safe to release.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
