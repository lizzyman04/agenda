# presentation/shared

Cross-slice presentation pieces: widgets that two or more feature slices
(`tasks/`, `finance/`, ...) render.

## Responsibility

Render what they are given. Nothing here imports a cubit, a repository or
a feature slice; a shared widget takes plain data plus callbacks.

## Layout

```
shared/
└── widgets/   cross-slice widgets (AppEmptyState)
```

## Conventions in this slice

- **A widget lives here only when two or more slices use it.** A widget
  used by a single slice stays in that slice's `widgets/` directory and
  moves up here the moment a second slice needs it.
- **Slice wrappers delegate, they do not fork.** A slice may keep a thin
  wrapper with its own constructor (for example `FinanceEmptyState`), but
  its `build` returns the shared widget so the visuals cannot drift.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`flutter/material.dart` only.
