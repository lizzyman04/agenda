# presentation/settings

Presentation slice for the **Settings screen** (D-09, D-10, D-11, UX-01): one
scrollable list reached from the gear in the Tasks AppBar.

## Responsibility

Group every user-facing preference in one place, in the D-10 order: General
(language), Security (PIN lock, added by 05-13), Notifications, Data and
About. Feature pages are mounted here, not rebuilt.

## Layout

```
settings/
├── screens/   SettingsScreen (the list, its link rows and the About rows)
└── widgets/   SettingsGearButton (AppBar entry point), SettingsSectionHeader,
               LanguageTile + showLanguageDialog
```

## Conventions in this slice

- **Settings mounts feature pages unchanged.** The Notifications and Data rows
  push `NotificationSettingsScreen` and `BackupScreen` exactly as Phase 4
  built them; each owns its own cubit. About pushes
  `PrivacyStatementScreen(readOnly: true)` (D-14).
- **Settings owns no feature state**, except the Security section (05-13).
  The language row reads and writes the app-wide `LocaleCubit`.
- **One entry point.** Only the Tasks AppBar carries the gear; Settings is
  not a shell tab (D-09).
- **Exactly two languages** (D-11): PT-BR and English, shown as endonyms.
  There is no "follow system" option.
- **Scroll, never clip.** The list is a `ListView` and no subtitle sets
  `maxLines`, so 200% text wraps and scrolls.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`application/shared/locale/` (`LocaleCubit`) · `core/config/` (`AppConfig`)
· `presentation/notifications/` · `presentation/backup/` ·
`presentation/onboarding/` · `generated/l10n/`.
