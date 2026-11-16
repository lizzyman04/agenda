---
phase: 05-app-lock-settings-polish
plan: 07
subsystem: ui
tags: [flutter, settings, l10n, locale, radio-group, ux-01, sc-3]
status: complete

requires:
  - phase: 05-app-lock-settings-polish
    provides: "05-01 ARB keys (settingsTitle, settingsSection*, languageLabel, settingsLanguageDialogTitle, languageName*, settings*Desc, settingsPrivacyLabel, settingsVersionLabel)"
  - phase: 05-app-lock-settings-polish
    provides: "05-04 PrivacyStatementScreen(readOnly: true)"
  - phase: 04
    provides: "NotificationSettingsScreen and BackupScreen as self-contained routes (Phase 4 D-09, D-15)"
provides:
  - "SettingsScreen (stateless): General (LanguageTile), Security insertion marker, Notifications, Data, About, SizedBox(32)"
  - "SettingsGearButton: Icons.settings_outlined + tooltip settingsTitle, pushes SettingsScreen (D-09)"
  - "SettingsSectionHeader(String title): fromLTRB(16,16,16,4) titleMedium"
  - "LanguageTile + showLanguageDialog(BuildContext): RadioGroup<Locale> of exactly two endonym RadioListTiles, setLocale + pop, Cancel only"
  - "Deleted TaskListSettingsMenu + TaskListSettingsDestination and its test"
affects: [05-13 settings security section (makes SettingsScreen stateful, inserts Security between General and Notifications)]

actuals:
  tokens: 7623
  tasks: 2
  commits: 2
plan_head_before: 16ec160cd31d1587043ee2c23323e779437d612a
plan_head_after: 54a9b0b1a444cc9cfb5c40785909bad01387f18c

tech-stack:
  added: []
  patterns:
    - "Radios use a RadioGroup<T> ancestor (Flutter 3.41 deprecates RadioListTile groupValue/onChanged)"
    - "Settings link rows: private _LinkTile (icon, title, wrapping subtitle, chevron) pushing a WidgetBuilder"
    - "Route-target tests: tap without pumping, read the recorded MaterialPageRoute and call its builder, so pushed feature pages need no DI"

key-files:
  created:
    - lib/presentation/settings/screens/settings_screen.dart
    - lib/presentation/settings/widgets/settings_gear_button.dart
    - lib/presentation/settings/widgets/settings_section_header.dart
    - lib/presentation/settings/widgets/language_dialog.dart
    - lib/presentation/settings/README.md
    - lib/presentation/settings/screens/README.md
    - lib/presentation/settings/widgets/README.md
    - test/presentation/settings/settings_screen_test.dart
  modified:
    - lib/presentation/tasks/screens/task_list_screen.dart
    - lib/presentation/tasks/screens/README.md
    - lib/presentation/tasks/widgets/README.md
  deleted:
    - lib/presentation/tasks/widgets/task_list_settings_menu.dart
    - test/presentation/tasks/task_list_settings_menu_test.dart

key-decisions:
  - "The language dialog reads LocaleCubit.supportedLocales for its two options, so the dialog and the cubit's accept-list cannot drift apart"
  - "showLanguageDialog captures the LocaleCubit from the caller's context before showDialog, so the dialog route needs no provider of its own"

requirements-completed: [UX-01]

coverage:
  - deliverable: "Tasks AppBar gear opens SettingsScreen; temporary menu deleted (D-09)"
    human_judgment: false
    verification:
      - kind: widget-test
        ref: "test/presentation/settings/settings_screen_test.dart#the Tasks AppBar gear opens Settings"
        status: pass
  - deliverable: "Language dialog with exactly two options switches the whole app at once (D-11, UX-01)"
    human_judgment: false
    verification:
      - kind: widget-test
        ref: "test/presentation/settings/settings_screen_test.dart#choosing English re-renders the app at once"
        status: pass
      - kind: widget-test
        ref: "test/presentation/settings/settings_screen_test.dart#Cancel closes the dialog without changing the language"
        status: pass
  - deliverable: "Sections in D-10 order; Notifications, Data, Privacy rows push the existing pages; Version row is inert"
    human_judgment: false
    verification:
      - kind: widget-test
        ref: "test/presentation/settings/settings_screen_test.dart#Sections (D-10)"
        status: pass
  - deliverable: "Settings list scrolls at 200% text on 320x568 without overflow"
    human_judgment: false
    verification:
      - kind: widget-test
        ref: "test/presentation/settings/settings_screen_test.dart#scrolls at 200% text on 320x568 with no overflow"
        status: pass
  - deliverable: "Visual fit of the Settings list against the UI-SPEC mock on a device"
    human_judgment: true
    rationale: "Spacing and typography match is a visual judgment no widget test asserts"

duration: 7min
completed: 2026-11-16
---

# Phase 5 Plan 07: Settings Shell and Language Toggle Summary

**The Tasks AppBar gear opens one Settings list. It has a two-option PT-BR/English dialog that re-renders the app at once, and rows that mount the Phase 4 notification and backup pages and the read-only privacy statement unchanged.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-11-16T19:56:57Z
- **Completed:** 2026-11-16T20:04:23Z
- **Tasks:** 2
- **Files:** 13 (8 created, 3 modified, 2 deleted)

## Accomplishments

- `SettingsGearButton` sits in the Tasks AppBar where the temporary Phase 4 menu was. The menu, its destination enum and its test are deleted. `task_list_screen.dart` is still 147 lines.
- `LanguageTile` shows the current endonym. `showLanguageDialog` puts exactly two `RadioListTile<Locale>` under one `RadioGroup<Locale>`, so the analyzer reports no new deprecation infos. Picking one calls `LocaleCubit.setLocale` and closes the dialog right away. Cancel is the only action.
- `SettingsScreen` lists General, then a marker comment for 05-13's Security section, then Notifications (`NotificationSettingsScreen`), Data (`BackupScreen`) and About. About has Privacidade, which pushes `PrivacyStatementScreen(readOnly: true)`, and Versão, which shows `AppConfig.version` and has no tap action. There are no dividers, and the file is 106 lines.
- There are three new READMEs under `lib/presentation/settings/`. The tasks READMEs no longer mention the deleted menu.
- 9 widget tests cover:
  - the gear opening Settings
  - switching to English and the app re-rendering
  - Cancel leaving the language unchanged
  - the order of the section headers
  - the version row
  - the three rows that push other pages
  - 200% text on 320x568

## Task Commits

1. **Task 1 (tracer): gear, Settings screen, language dialog** - `62de0aa` (feat)
2. **Task 2: Notifications, Data, About sections; READMEs** - `54a9b0b` (feat)

## Verification

- `flutter test --no-pub test/presentation/settings test/presentation/tasks`: all passed (tracer gate re-run: passed)
- `flutter test --no-pub` (full suite): 1040 tests, all passed
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (budget 65). None of the 64 is in a file this plan created.
- `dart run tool/check_architecture.dart`: PASS

## Deviations from Plan

None. The plan was executed as written. `dart format` changed the line wrapping of `settings_gear_button.dart` after Task 1, and that change went into the Task 2 commit. It is formatting only.

## Known Stubs

None.

## Next Phase Readiness

05-13 can make `SettingsScreen` stateful and put the Security section where the marker comment is, between General and Notifications.

## Self-Check: PASSED

- All 8 created files exist; both deleted files are gone.
- Commits `62de0aa` and `54a9b0b` are ancestors of HEAD.
