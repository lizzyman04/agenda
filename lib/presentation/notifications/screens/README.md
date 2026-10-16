# presentation/notifications/screens

Route-level widgets for notification settings: the page and its wiring.

## Responsibility

Own the page's cubit and the app-lifecycle observer, and wire state to the
widgets in `../widgets/`. No layout primitives and no preference rules live
here.

## Files

| File | Lines | Role |
|------|------:|------|
| `notification_settings_screen.dart` | 74 | `NotificationSettingsScreen` — standalone page (D-09) that creates `NotificationSettingsCubit` from `getIt`, calls `start()`, closes it on dispose, refreshes permissions on app resume, and passes the privacy note to the body as its footer |
| `notification_settings_body.dart` | 109 | `NotificationSettingsBody` — the loaded page: denied-permission and exact-alarm banners (exact only on Android), one switch per kind, briefing time, quotes, quiet hours and the "N reminders waiting" text; each control calls one cubit method |

## Conventions in this slice

- **The page is self-contained.** It needs no provider above it, so the
  Phase 5 Settings screen can push or embed it unchanged.
- **Resume refreshes permissions.** The OS state is re-read every time the app
  returns to the foreground; a granted state is never trusted across a resume
  (T-04-15-03).

## Upstream dependencies

`application/notifications/` (`NotificationSettingsCubit` and its state) ·
`domain/notifications/` (`NotificationKind`) · `../widgets/` ·
`generated/l10n/` · `config/di/injection.dart`.
