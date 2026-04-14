---
plan: 260413-ty6
type: quick
subsystem: site
tags: [astro, github-pages, landing-page, i18n]
key-files:
  created:
    - site/astro.config.mjs
    - site/package.json
    - site/tsconfig.json
    - site/public/CNAME
    - site/public/.nojekyll
    - site/public/assets/img/agenda-logo.png
    - site/public/assets/img/agenda.png
    - site/src/styles/global.css
    - site/src/i18n/translations.ts
    - site/src/layouts/Layout.astro
    - site/src/pages/index.astro
    - site/src/pages/terms/index.astro
    - docs/index.html
    - docs/terms/index.html
    - docs/CNAME
    - docs/.nojekyll
  modified:
    - .gitignore
    - docs/assets/ (rebuilt by Astro)
decisions:
  - Use data-i18n attributes for runtime PT/EN switching via localStorage — avoids SSR complexity for two-language static site
  - Use data-lang blocks for terms page body content — long-form content is easier to maintain per-language than key-per-sentence
  - outDir set to ../docs relative to site/ so Astro outputs directly into the GitHub Pages source directory
metrics:
  completed: 2026-04-14
  files-created: 16
  files-modified: 3
  build-status: success
  pages: 2
---

# Quick Task 260413-ty6: Rebuild GitHub Pages with Astro

**One-liner:** Astro 5 static site with indigo design system, full PT/EN i18n via data-i18n attributes, and complete landing + terms pages built into docs/.

## What Was Built

Replaced broken plain-HTML GitHub Pages with a fully-featured Astro 5 static site. The site lives in `site/` and builds into `docs/` (GitHub Pages source).

### Pages

**Landing page (index.astro):** 9 sections — nav with language toggle, hero with animated logo, screenshot placeholders, features cards (task management, finance, privacy principles), tech stack table, getting started with code blocks, project structure tree, roadmap with phase badges, contributing CTA, footer.

**Terms page (terms/index.astro):** Full PT and EN versions of terms of use and privacy policy using `data-lang` blocks toggled at runtime. Covers: what the app is, why use it, productivity frameworks (Eisenhower, 1-3-5, GTD), finance module, data storage details (local-only, Isar Community), notifications, app lock, pricing, about.

### i18n System

- `translations.ts` — 80+ string keys in PT and EN, `as const` typed
- `Layout.astro` client script — reads `localStorage('agenda-lang')`, applies translations to all `[data-i18n]` elements and toggles `[data-lang]` blocks on page load and button click
- Default language: PT-BR

### Design System

Indigo CSS custom properties (`--primary: #6366f1`), Inter font, sticky frosted-glass nav, hero gradient background with `@keyframes rise` animation, responsive cards grid, principles grid, syntax-highlighted code blocks, dark tree view, roadmap numbered items, hover lift effects.

## Build Verification

- `docs/index.html` — exists
- `docs/terms/index.html` — exists
- `docs/CNAME` — contains "agenda.omeu.space"
- `docs/.nojekyll` — exists
- Build time: 3.24s, 0 errors, 0 warnings

## Removed Files

- `docs/_config.yml` — Jekyll config no longer needed
- `docs/assets/css/style.css` — replaced by Astro-bundled CSS
- `docs/assets/js/i18n.js` — replaced by Astro client script

## Deviations from Plan

None — plan executed exactly as specified.

## Commit

- `1a8134c` — feat(site): rebuild GitHub Pages with Astro — indigo theme, full i18n, all sections (25 files changed, 6383 insertions, 908 deletions)

## Self-Check

- [x] docs/index.html exists
- [x] docs/terms/index.html exists
- [x] docs/CNAME contains agenda.omeu.space
- [x] docs/.nojekyll exists
- [x] site/ source files committed (excluding node_modules)
- [x] Commit 1a8134c verified

## Self-Check: PASSED
