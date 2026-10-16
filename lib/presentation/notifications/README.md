# presentation/notifications

Presentation slice for **notifications**: what happens in the UI when the
user taps one, and (from plan 04-15) the screens and widgets that configure
them.

## Responsibility

Turn notification events into navigation and, later, host the notification
settings UI. Scheduling, planning and permission logic never live here: they
sit in `domain/notifications/` and `infrastructure/notifications/`.

## Layout

```
notifications/
├── routing/   tap handling: payload -> target -> screen
├── screens/   arrives with plan 04-15
└── widgets/   arrives with plan 04-15
```

## Conventions in this slice

- **Payloads are untrusted.** Every tap goes through `resolveTapTarget`
  (`domain/notifications/rules/tap_target.dart`) before anything is shown.
- **Degrade, never throw.** An unknown, malformed or stale tap lands on the
  Tasks tab or the app root.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`domain/notifications/` · `domain/tasks/` · `domain/finance/goal/` ·
`presentation/shell/` · `config/di/injection.dart`.
