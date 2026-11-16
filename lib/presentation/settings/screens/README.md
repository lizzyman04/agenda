# presentation/settings/screens

The Settings page.

## Responsibility

Lay out the sections in the D-10 order and route each link row to its feature
page. The only state it owns is the Security section's
`SecuritySettingsCubit`.

## Files

| File | Lines | Role |
|------|------:|------|
| `settings_screen.dart` | 145 | `SettingsScreen` (stateful, `WidgetsBindingObserver`) — takes `getIt<SecuritySettingsCubit>()` in `initState` (calls `start()`), closes it in `dispose`, and calls `refreshAvailability()` on `resumed` so a fingerprint enrolled in device settings shows up (D-08). `Scaffold` + `AppBar(settingsTitle)` + `ListView` with no dividers: General (`LanguageTile`), Security (`SecuritySection` under `BlocProvider.value`), Notifications (pushes `NotificationSettingsScreen`), Data (pushes `BackupScreen`), About (private `_AboutRows`: Privacidade pushes `PrivacyStatementScreen(readOnly: true)`, Versão shows `AppConfig.version` with no tap action), then `SizedBox(height: 32)`. The private `_LinkTile` is the shared icon + title + wrapping subtitle + chevron row |

## Conventions in this slice

- **Mount, never rebuild.** Link rows push the existing feature pages with
  their no-argument constructors; nothing is passed in or provided around
  them.
- **Scroll, never overflow.** At 200% text on a 320x568 viewport the list
  scrolls to the version row with no overflow.

## Upstream dependencies

`application/settings/` · `config/di/` · `../security/` · `../widgets/` · `presentation/notifications/screens/` ·
`presentation/backup/screens/` · `presentation/onboarding/screens/` ·
`core/config/` · `generated/l10n/`.
