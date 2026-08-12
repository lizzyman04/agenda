# application/shared/locale

Owns the **active app locale** and persists the user's choice.

## Responsibility

Resolve the startup locale from `SharedPreferences`, expose it as state,
and write the user's toggle back to storage. Nothing else — the widget
translations themselves live in `generated/l10n/`.

## Files

| File | Lines | Role |
|------|------:|------|
| `locale_cubit.dart` | 50 | `LocaleCubit` — reads the stored locale on construction, exposes `supportedLocales` (`pt_BR`, `en`), and `setLocale` persists then emits. Defaults to PT-BR when nothing is stored (D-21) |
| `locale_state.dart` | 13 | `LocaleState` — a single immutable `Locale` value |

## Conventions in this slice

- **PT-BR is the default**, not the device locale — a deliberate product
  decision (D-21), not an oversight.
- **Persist before emitting.** `setLocale` awaits the `SharedPreferences`
  write first, so a state change always corresponds to a durable choice.
- The cubit is consumed by `AgendaApp` to drive `MaterialApp.locale`, which
  is why it is registered as a singleton rather than per-screen.

## Upstream dependencies

`core/constants/storage_keys.dart` · `shared_preferences` ·
`flutter/widgets.dart` (for the `Locale` type only).
