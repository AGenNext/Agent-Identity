# GitHub Pages Deployment Guide

This repository includes a static documentation site in the `site/` directory and a GitHub Actions workflow at `.github/workflows/pages.yml`.

## Enable GitHub Pages

1. Open repository Settings.
2. Navigate to Pages.
3. Under Build and deployment, set Source to **GitHub Actions**.
4. Save the settings.

## Trigger Deployment

Push any commit to the `main` branch.

## Default URL

```text
https://agennext.github.io/Agent-Identity/
```

## Included Pages

- `/`
- `/docs.html`
- `/api.html`
- `/swagger.html`
- `/sdk.html`
- `/security.html`
- `/openapi.json`

## Custom Domain (Recommended)

Suggested domain:

```text
identity.agennext.ai
```

After configuring DNS, add a `site/CNAME` file containing:

```text
identity.agennext.ai
```

## Troubleshooting

### Deployment does not start
- Confirm Pages source is set to GitHub Actions.
- Check the Actions tab for workflow errors.

### Assets not loading
- Verify files exist under `site/`.
- Confirm relative paths are used (`./styles.css`, `./assets/...`).

### Custom domain not working
- Confirm DNS records.
- Ensure HTTPS is enabled in GitHub Pages settings.
