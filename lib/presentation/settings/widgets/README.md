# presentation/settings/widgets

The Settings entry point and the list's building blocks.

## Responsibility

Open Settings from the Tasks AppBar, title each section, and let the user
switch the app language.

## Files

| File | Lines | Role |
|------|------:|------|
| `settings_gear_button.dart` | 26 | `SettingsGearButton` — `IconButton(Icons.settings_outlined)` with tooltip `settingsTitle` that pushes `SettingsScreen` (D-09). Lives in `TaskListScreen`'s AppBar actions only |
| `settings_section_header.dart` | 18 | `SettingsSectionHeader` — `Padding(fromLTRB(16, 16, 16, 4))` around a `titleMedium` title, default `onSurface`, no divider |
| `language_dialog.dart` | 75 | `LanguageTile` (`Icons.language`, `languageLabel`, current endonym watched from `LocaleCubit`, chevron) and `showLanguageDialog` — an `AlertDialog` whose two `RadioListTile<Locale>` sit under one `RadioGroup<Locale>` (no deprecated per-tile `groupValue`/`onChanged`). Selecting calls `LocaleCubit.setLocale` and pops at once; the only action is Cancel |

## Conventions in this slice

- **Exactly two languages, no system option** (D-11). The labels are the
  `languageNamePtBr` / `languageNameEn` endonyms, identical in both locales.
- **Radios use `RadioGroup`.** Flutter 3.41 deprecates `groupValue` and
  `onChanged` on `RadioListTile`; the group ancestor owns them.

## Upstream dependencies

`application/shared/locale/` (`LocaleCubit`) · `../screens/` ·
`generated/l10n/`.
