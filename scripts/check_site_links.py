#!/usr/bin/env python3
"""Validate the static site: internal links resolve and pages carry basic SEO tags.

Catches broken relative links (href/src) and missing Open Graph titles before the
site is published. Runs in CI (.github/workflows/launch-check.yml).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"

EXTERNAL = ("http://", "https://", "mailto:", "tel:", "data:", "#")
errors: list[str] = []


def internal_targets(html: str) -> list[str]:
    refs = re.findall(r'(?:href|src)\s*=\s*"([^"]+)"', html)
    out = []
    for ref in refs:
        if ref.startswith(EXTERNAL) or not ref.strip():
            continue
        # strip query/fragment, leading ./
        path = ref.split("#", 1)[0].split("?", 1)[0]
        path = path[2:] if path.startswith("./") else path
        if path:
            out.append(path)
    return out


def main() -> int:
    pages = sorted(SITE.glob("*.html"))
    if not pages:
        print("❌ No HTML pages found under site/.")
        return 1

    for page in pages:
        html = page.read_text()
        # internal links must resolve relative to site/
        for target in internal_targets(html):
            if not (SITE / target).exists():
                errors.append(f"{page.name}: broken link → {target}")
        # content pages (those using the shared stylesheet) need an OG title
        if "styles.css" in html and 'property="og:title"' not in html:
            errors.append(f"{page.name}: missing Open Graph title")

    if errors:
        print("❌ Site validation failed:\n" + "\n".join(f"- {e}" for e in errors))
        return 1
    print(f"✅ Site OK: {len(pages)} pages, internal links resolve, OG tags present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
