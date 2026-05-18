from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "site/index.html",
    "site/docs.html",
    "site/api.html",
    "site/swagger.html",
    "site/sdk.html",
    "site/security.html",
    "site/openapi.json",
    "site/sitemap.xml",
    "site/robots.txt",
    "site/styles.css",
    "site/assets/architecture.svg",
    ".github/workflows/pages.yml",
    "docs/GITHUB_PAGES_DEPLOYMENT.md",
]


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def main() -> None:
    missing = [file for file in REQUIRED_FILES if not (ROOT / file).exists()]
    if missing:
        fail("Missing required launch files:\n" + "\n".join(f"- {file}" for file in missing))

    openapi_path = ROOT / "site/openapi.json"
    try:
        spec = json.loads(openapi_path.read_text())
    except json.JSONDecodeError as exc:
        fail(f"Invalid OpenAPI JSON: {exc}")

    if spec.get("openapi") is None:
        fail("OpenAPI spec is missing the 'openapi' version field")

    if not spec.get("paths"):
        fail("OpenAPI spec must define at least one path")

    sitemap = (ROOT / "site/sitemap.xml").read_text()
    for page in ["docs.html", "api.html", "swagger.html", "sdk.html", "security.html", "openapi.json"]:
        if page not in sitemap:
            fail(f"Sitemap is missing {page}")

    print("✅ Agent Identity launch assets look ready.")


if __name__ == "__main__":
    main()
