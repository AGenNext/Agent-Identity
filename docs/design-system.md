# Agent Identity Design System

One consistent visual language across the marketing site, design files, and UI components.

## Source of truth: tokens

[`site/design-tokens.json`](../site/design-tokens.json) holds the design tokens in the
**W3C Design Tokens** format (color, radius, shadow, typography, spacing). It mirrors the CSS
custom properties in [`site/styles.css`](../site/styles.css). Change a token once and every
surface follows.

```
site/design-tokens.json   ← single source of truth (W3C format)
        │
        ├── site/styles.css        (the website, via :root custom properties)
        ├── Penpot                 (design — import via the Tokens feature)
        └── Storybook              (components — consumed as CSS vars / Style Dictionary)
```

## Tooling

- **Penpot** ([penpot.app](https://penpot.app)) — open-source design tool. Import
  `design-tokens.json` through its Tokens feature so mockups use the exact same palette,
  radii, and type scale as production. Keeping it open-source fits the project's open ethos.
- **Storybook** — when the `apps/web` React components grow beyond the current pages, add
  Storybook so each component (button, card, nav, section) is developed and reviewed in
  isolation against these tokens. The tokens are exposed as CSS custom properties, so stories
  consume `var(--accent)` etc. directly.
- **Claude frontend-design plugin** ([claude.com/plugins/frontend-design](https://claude.com/plugins/frontend-design))
  — used as the working guide for layout, hierarchy, and component consistency.

## The living styleguide

[`site/styleguide.html`](../site/styleguide.html) renders the system in the browser: color
swatches, the type scale, buttons, cards, and section/code surfaces — all using the real
stylesheet. It is the human-facing companion to `design-tokens.json`.

## Components (current)

| Component | Class | Notes |
| --- | --- | --- |
| Nav | `.nav` | Identical across every page (Home · Story · Docs · API · Swagger · SDK · Security · GitHub). |
| Button | `.button`, `.secondary`, `.small` | Pill buttons; primary uses the accent gradient. |
| Eyebrow | `.eyebrow` | Uppercase category label above a title. |
| Card | `.card` (in `.grid.cards`) | One idea per card on a raised surface. |
| Section | `.section`, `.split`, `.section-head` | Primary content blocks; `split` pairs prose with code/media. |
| CTA | `.cta` | Centered call-to-action band. |
| Footer | `footer` | Identical across every page; links back to this design system. |

## Rules

1. **Tokens before hex.** Never hard-code a color/size in a page; use a token (`var(--…)`).
2. **One nav, one footer.** Every page uses the identical nav and footer markup.
3. **Reuse components.** Compose pages from the classes above rather than bespoke styles.
4. **Tokens flow one way** — edit `design-tokens.json` / `styles.css`, then propagate to Penpot
   and Storybook, never the reverse.
