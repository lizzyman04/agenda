# presentation/shared/widgets

Widgets rendered by two or more presentation slices.

## Responsibility

Pure presentation: plain data and callbacks in, widgets out. No BLoC, no
repository, no slice imports.

## Files

| File | Lines | Role |
|------|------:|------|
| `app_empty_state.dart` | 75 | `AppEmptyState` — the UX-04 empty-state layout (72px icon, `titleMedium` heading, `bodyMedium` body, gaps 16/8/24, horizontal padding 32) with an optional CTA `FilledButton` that renders only when both `ctaLabel` and `onCta` are given. Used by the task list, the GTD filter and, through `FinanceEmptyState`, every finance list |

## Conventions in this directory

- **Optional CTA, never a dead button.** A CTA appears only when the
  caller can act on it; the no-search-match and GTD empty states pass no
  CTA at all.
- **Visual changes here change every empty state.** The layout values are
  pinned by `test/presentation/shared/app_empty_state_test.dart` and by
  the unchanged `test/presentation/finance/finance_empty_state_test.dart`.

## Upstream dependencies

`flutter/material.dart` only.
