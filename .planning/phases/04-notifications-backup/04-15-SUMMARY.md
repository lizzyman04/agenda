---
phase: 04-notifications-backup
plan: 15
subsystem: notifications-settings-ui
tags: [flutter_bloc, cubit, injectable, settings, permissions, time-picker, l10n]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-03 NotificationKind, NotificationPrefs, QuoteFrequency"
  - phase: 04-notifications-backup
    provides: "04-10 NotificationPrefsRepository, NotificationPermissionService, NotificationReconciler.truncatedCount, FakeNotificationPermissionService"
  - phase: 04-notifications-backup
    provides: "04-02 notifSettings* and notifChannel* strings"
  - phase: 04-notifications-backup
    provides: "04-12 coordinator that reconciles from the prefs stream"
provides:
  - "NotificationSettingsCubit and NotificationSettingsState (Initial, Loaded)"
  - "NotificationSettingsScreen: standalone page, mountable in Settings (D-09)"
  - "NotificationTypeTile, TimeSettingTile, PermissionBanner, QuotesSection, QuietHoursSection, notificationTypeLabel/Description"
  - "TaskListSettingsMenu and TaskListSettingsDestination (temporary entry point, D-15)"
affects: [04-16, 04-17, phase-05-settings]

plan_head_before: 25415ae6e4210f7f7ce8c49a9aba4e26549f9096
commits: 3
actuals:
  tokens: 16000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Settings cubit persists through the prefs repository, then emits; it never schedules (the coordinator reacts to prefs.watch())"
    - "Screen owns a cubit resolved from getIt, closes it on dispose and refreshes OS permissions on every app resume"
    - "Presentation widgets own no preference logic: time pickers and sections report values through callbacks"

key-files:
  created:
    - lib/application/notifications/notification_settings_state.dart
    - lib/application/notifications/notification_settings_cubit.dart
    - lib/presentation/notifications/screens/notification_settings_screen.dart
    - lib/presentation/notifications/screens/notification_settings_body.dart
    - lib/presentation/notifications/screens/README.md
    - lib/presentation/notifications/widgets/notification_type_labels.dart
    - lib/presentation/notifications/widgets/notification_type_tile.dart
    - lib/presentation/notifications/widgets/time_setting_tile.dart
    - lib/presentation/notifications/widgets/permission_banner.dart
    - lib/presentation/notifications/widgets/quotes_section.dart
    - lib/presentation/notifications/widgets/quiet_hours_section.dart
    - lib/presentation/notifications/widgets/README.md
    - lib/presentation/tasks/widgets/task_list_settings_menu.dart
    - test/application/notifications/notification_settings_cubit_test.dart
    - test/presentation/notifications/notification_settings_screen_test.dart
    - test/presentation/tasks/task_list_settings_menu_test.dart
  modified:
    - lib/presentation/tasks/screens/task_list_screen.dart
    - lib/config/di/injection.config.dart
    - lib/application/notifications/README.md
    - lib/presentation/notifications/README.md
    - lib/presentation/tasks/screens/README.md
    - lib/presentation/tasks/widgets/README.md

key-decisions:
  - "The screen creates the cubit once in initState via getIt and closes it in dispose, instead of BlocProvider(create:), so the lifecycle observer can call refreshPermissions() on the same instance"
  - "The page body lives in screens/notification_settings_body.dart (screen-level wiring to the cubit), keeping widgets/ presentation-only and at exactly six files while every file stays under 150 lines"
  - "Enabling a kind while the OS permission is not granted prompts first, then saves the preference regardless of the answer, so the denied banner (not a silently reverted switch) tells the user what is missing"

patterns-established:
  - "Settings cubit: _save(change) reads Loaded, persists, then emits; _update(f) ignores closed/not-Loaded states"
  - "Widget tests for lazy ListViews use a tall test viewport instead of scrolling"

requirements-completed: [NOTF-08, NOTF-09, NOTF-10]

coverage:
  - id: D1
    description: "Every notification kind has its own persisted switch; quotes default off"
    requirement: "NOTF-09"
    verification:
      - kind: unit
        ref: "test/presentation/notifications/notification_settings_screen_test.dart#renders eight switches with the PT-BR channel names"
        status: pass
      - kind: unit
        ref: "test/application/notifications/notification_settings_cubit_test.dart#persists BEFORE emitting"
        status: pass
    human_judgment: false
  - id: D2
    description: "Briefing time, quote frequency and time, and quiet-hours switch with start and end pickers; minutes clamped to 0..1439"
    requirement: "NOTF-10"
    verification:
      - kind: unit
        ref: "test/presentation/notifications/notification_settings_screen_test.dart#quotes"
        status: pass
      - kind: unit
        ref: "test/application/notifications/notification_settings_cubit_test.dart#minutes are clamped to 0..1439"
        status: pass
    human_judgment: false
  - id: D3
    description: "Denied-permission banner, Android exact-alarm banner, permission refresh on resume, waiting-count text"
    requirement: "NOTF-08"
    verification:
      - kind: unit
        ref: "test/presentation/notifications/notification_settings_screen_test.dart#permission banners"
        status: pass
      - kind: unit
        ref: "test/application/notifications/notification_settings_cubit_test.dart#refreshPermissions re-reads the OS state"
        status: pass
    human_judgment: false
  - id: D4
    description: "Settings page reachable from the task list through the temporary overflow menu"
    verification:
      - kind: unit
        ref: "test/presentation/tasks/task_list_settings_menu_test.dart#selecting Notifications opens the settings page"
        status: pass
    human_judgment: false
  - id: D5
    description: "OS permission dialogs, real-clock quiet hours and delivery, quote delivery at the chosen time, iOS 64-request cap behaviour"
    verification: []
    human_judgment: true
    rationale: "System permission dialogs, wall-clock delivery inside and after quiet hours and iOS hardware limits cannot run on the host VM (NOTF-09/10 manual-only rows)"

duration: 11 min
completed: 2026-10-16
---

# Phase 4 Plan 15: Notification settings page Summary

**A standalone Notification Settings page with per-kind switches, briefing and quote times, quiet hours, denied-permission and exact-alarm banners and a waiting-reminders count, driven by a cubit that persists first and emits second, reachable from a temporary AppBar overflow menu on the task list.**

## Performance

- **Duration:** 11 min (2026-10-16T08:07:13Z to 08:18:27Z, before SUMMARY authoring)
- **Tasks:** 3 of 3
- **Files:** 22 (16 created, 6 modified; plus the regenerated DI file)

## Accomplishments

- `NotificationSettingsCubit` (injectable factory) over the prefs repository, permission service and reconciler. `start()` reads prefs, OS permission and exact capability, then follows `truncatedCount` and `prefs.watch()`; both subscriptions are cancelled in `close()`. Every setter calls `save(...)` and emits only afterwards; minutes are clamped to 0..1439; all methods are no-ops before `Loaded`.
- `setEnabled(kind, enabled: true)` raises the system permission prompt in context when the permission is not granted; `refreshPermissions()` re-reads the OS state so a granted state is never cached across resumes (T-04-15-03).
- `NotificationSettingsScreen` is self-contained (own cubit from `getIt`, `start()` on init, `close()` on dispose, permission refresh on app resume), so Phase 5 can mount it inside Settings unchanged.
- Page content: eight `NotificationTypeTile`s in the planned order, briefing `TimeSettingTile` (disabled while the briefing kind is off), `QuotesSection` (hint while off; daily/weekly `SegmentedButton` plus time while on), `QuietHoursSection` (switch plus start and end, pickers disabled while off), the "N reminders waiting" text when `waitingCount > 0` and the privacy note.
- Banners: denied-permission always on denial; exact-alarm only when `Theme.of(context).platform` is Android and exact scheduling is unavailable.
- `TaskListSettingsMenu` (`Icons.settings_outlined`, tooltip `settingsTitle`) added to the task list AppBar; `task_list_screen.dart` is 149 lines. `TaskListSettingsDestination` is ready for plan 04-16 to append the backup entry.
- 768/768 tests pass; `flutter analyze --no-fatal-infos --fatal-warnings` exits 0 with 65 issues (the budget, zero new); architecture guard passes. No ARB file was edited.

## Task Commits

1. **Task 1 (tracer): cubit, state and per-kind switches page** - `f82ea7d` (feat)
2. **Task 2: time pickers, quotes, quiet hours and permission banners** - `b1cae53` (feat)
3. **Task 3: temporary settings overflow menu and DI regeneration** - `56f3728` (feat)

Tracer feedback gate: `workflow.auto_advance` is false, `human_verify_mode` is `end-of-phase` and the tracer's `<verify>` is automated-only, so its tests, analyzer and architecture guard were re-run after the commit-ready state and passed before Task 2 ("Tracer verified end-to-end").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Screen would exceed the 150-line cap; body split into the screens directory**
- **Found during:** Task 2 (the screen reached 165 lines)
- **Issue:** The plan asks for the page content in `notification_settings_screen.dart` and for every file to stay at or under 150 lines, but the widgets/ directory is specified as six files.
- **Fix:** Extracted `NotificationSettingsBody` into `screens/notification_settings_body.dart` (it calls cubit methods, so it is screen-level wiring, not a presentation-only widget). The screen passes the privacy note in as the body's `footer`, so `notifSettingsPrivacyNote` still appears in the screen file as the acceptance criterion requires.
- **Files modified:** `lib/presentation/notifications/screens/notification_settings_body.dart`, `notification_settings_screen.dart`, `screens/README.md`
- **Commit:** `b1cae53`

**2. [Rule 1 - Bug] Own the cubit in State instead of `BlocProvider(create:)`**
- **Found during:** Task 1
- **Issue:** The resume observer must call `refreshPermissions()` on the same instance the tree uses; reading it through `BlocProvider(create:)` would need a context-bound lookup from outside the build.
- **Fix:** The State resolves the cubit from `getIt` once, `BlocBuilder(bloc: _cubit)` consumes it, and `dispose()` closes it. Behavior matches the plan (page-local cubit, started on mount).
- **Files modified:** `lib/presentation/notifications/screens/notification_settings_screen.dart`
- **Commit:** `f82ea7d`

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug-avoidance). **Impact:** none on behavior or scope; file layout differs slightly from the plan's file list (one extra screens/ file).

## Authentication Gates

None.

## Issues Encountered

- First test runs failed for three test-harness reasons, all fixed in the tests (no production change): the Cupertino localization delegate was missing for the `pt_BR` locale, the lazy `ListView` needed a tall test viewport, and the quiet-hours `SwitchListTile` made a raw `SwitchListTile` count 9 (assertions now count `NotificationTypeTile`).
- `pumpAndSettle` hangs on the Initial-state spinner in the menu test; it now pumps a fixed duration.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub` (full suite) | 768/768 pass |
| `flutter test --no-pub test/application/notifications/notification_settings_cubit_test.dart test/presentation/notifications` | pass (14 cubit tests, 26 presentation tests incl. routing) |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 65 issues (budget 65) |
| `dart run build_runner build --delete-conflicting-outputs` | exit 0; `NotificationSettingsCubit` registered as a factory |
| `dart run tool/check_architecture.dart` | PASS |
| `grep notifSettingsPrivacyNote` in the screen file | match |
| `grep TaskListSettingsMenu` in `task_list_screen.dart`; `wc -l` | match; 149 lines |

## Human verification outstanding

- Android device: Tasks > settings menu > Notifications. Deny the permission prompt when first enabling a kind, then use the in-page Allow button; toggle each kind, set quiet hours to start 10 minutes from now, create a task due inside the window, set briefing and quote times. Expect switches to persist across a restart, the denied banner to clear after granting in system settings and returning, a reminder inside quiet hours to arrive when the window ends, and a quote at the chosen time without repeating within the cycle.
- iOS device (if available): create more than 64 pending items and open the page; expect the waiting count, no crash, and the nearest reminders still firing.

## Threat Flags

None beyond the plan's register. T-04-15-01 (clamp to 0..1439 in the cubit; repository clamps again on load) and T-04-15-03 (permission re-read on start and every resume) are implemented; T-04-15-02 is accepted (the page shows only toggles, times and a count).

## Known Stubs

None.

## Next Phase Readiness

Plan 04-16 (backup UI) can append a `backup` value to `TaskListSettingsDestination` and a second `PopupMenuItem` in `task_list_settings_menu.dart`; the file is 48 lines and `tasks/widgets/` holds 8 of 10 allowed files.

## Self-Check: PASSED

All 16 created files verified on disk; commits `f82ea7d`, `b1cae53`, `56f3728` present.
