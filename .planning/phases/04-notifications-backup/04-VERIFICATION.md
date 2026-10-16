---
phase: 04-notifications-backup
verified: 2026-10-16T12:00:00Z
status: gaps_found
score: 4/7 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/04-notifications-backup/04-01-PLAN.md
  - .planning/phases/04-notifications-backup/04-01-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-02-PLAN.md
  - .planning/phases/04-notifications-backup/04-02-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-03-PLAN.md
  - .planning/phases/04-notifications-backup/04-03-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-04-PLAN.md
  - .planning/phases/04-notifications-backup/04-04-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-05-PLAN.md
  - .planning/phases/04-notifications-backup/04-05-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-06-PLAN.md
  - .planning/phases/04-notifications-backup/04-06-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-07-PLAN.md
  - .planning/phases/04-notifications-backup/04-07-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-08-PLAN.md
  - .planning/phases/04-notifications-backup/04-08-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-09-PLAN.md
  - .planning/phases/04-notifications-backup/04-09-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-10-PLAN.md
  - .planning/phases/04-notifications-backup/04-10-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-11-PLAN.md
  - .planning/phases/04-notifications-backup/04-11-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-12-PLAN.md
  - .planning/phases/04-notifications-backup/04-12-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-13-PLAN.md
  - .planning/phases/04-notifications-backup/04-13-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-14-PLAN.md
  - .planning/phases/04-notifications-backup/04-14-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-15-PLAN.md
  - .planning/phases/04-notifications-backup/04-15-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-16-PLAN.md
  - .planning/phases/04-notifications-backup/04-16-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-17-PLAN.md
  - .planning/phases/04-notifications-backup/04-17-SUMMARY.md
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/xml/backup_rules.xml
  - android/app/src/main/res/xml/data_extraction_rules.xml
  - ios/Runner/AppDelegate.swift
  - lib/application/backup/backup_cubit.dart
  - lib/application/notifications/budget_alert_evaluator.dart
  - lib/application/notifications/goal_alert_evaluator.dart
  - lib/config/startup/notification_startup.dart
  - lib/data/backup/dao/backup_dao.dart
  - lib/data/backup/import/backup_importer.dart
  - lib/data/backup/import/safety_backup_store.dart
  - lib/domain/notifications/planner/reminder_planner.dart
  - lib/infrastructure/backup/backup_repository_impl.dart
  - lib/infrastructure/backup/csv_export_builder.dart
  - lib/infrastructure/backup/import_session.dart
  - lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart
  - lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart
covered_digest: "v1:sha256:f8518d26ebfb6b3aa85785e136bd231c3cfae36d67b1e88ff5f636fe2ad94cf1"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "No data leaves the device: the plaintext safety backups written by this phase are kept out of every OS cloud backup (project privacy constraint; D-13 intent)"
    status: failed
    reason: "D-13 was implemented for Android only (allowBackup=false, fullBackupContent, dataExtractionRules). On iOS, SafetyBackupStore writes up to three complete plaintext JSON dumps to <Documents>/backups, which iOS includes in iCloud/iTunes backups by default. No NSURLIsExcludedFromBackupKey / isExcludedFromBackup is set anywhere in lib, ios or android (grep returns no match), and AppDelegate.swift has no exclusion code. Confirmed review finding CR-01."
    artifacts:
      - path: "lib/data/backup/import/safety_backup_store.dart"
        issue: "Creates <Application Documents>/backups with no iOS backup exclusion; its doc comment claims D-13 exclusion that only exists on Android"
      - path: "ios/Runner/AppDelegate.swift"
        issue: "No platform channel or code that sets isExcludedFromBackup"
    missing:
      - "Exclude the safety-backup directory from iOS backup (set isExcludedFromBackup = true after dir.create, via a small method channel, or write to Application Support and exclude that directory)"
      - "Also exclude the Isar database directory (IsarService uses getApplicationDocumentsDirectory); this part pre-dates Phase 4, but the same fix closes it and Phase 5 does not cover it"
      - "Optionally apply NSFileProtectionComplete to the safety-backup files"
      - "Add a test or contract check that pins the iOS exclusion, like manifest_contract_test does for Android"
  - truth: "A CSV import restores every row in the file: rows are not silently overwritten or lost, and the reported count matches what was stored"
    status: failed
    reason: "Every CSV mapper uses id ?? Isar.autoIncrement. When blank-id rows precede an explicit-id row, putAll assigns an auto id that equals the later explicit id and the later put overwrites the earlier row with no error. Reproduced in this verification with a temporary real-Isar test (deleted afterwards): the snapshot [blank 'a', blank 'b', id=2 'explicit2'] reported counts={items: 3} but stored only [1:a, 2:explicit2]; row 'b' was silently lost. Confirms review finding WR-01. Affects DATA-04 (CSV import of a user-edited spreadsheet)."
    artifacts:
      - path: "lib/data/backup/import/backup_importer.dart"
        issue: "putAll is called in file order with mixed autoIncrement and explicit ids"
      - path: "lib/data/backup/import/snapshot_validator.dart"
        issue: "Only checks explicit ids against each other; blank-id rows are assumed never to collide"
    missing:
      - "Assign ids deterministically before putAll (explicit-id rows first, or give each blank-id row ++maxExplicitId)"
      - "Add a regression test in import_atomicity_test.dart for the mixed blank/explicit id case"
behavior_unverified_items:
  - truth: "Rebooting the device does not cancel pending notifications; they are rescheduled on next boot (ROADMAP SC2)"
    test: "Schedule a task due in about 35 minutes with reminders on, reboot the device, wait for the 30-minute lead time"
    expected: "The reminder still fires after the reboot with no app launch; the settings page shows the same waiting count"
    why_human: "The boot receiver and RECEIVE_BOOT_COMPLETED are declared and pinned by manifest_contract_test, and the app also reconciles on every start/resume, but no automated test can reboot a device. Presence of the receiver does not prove the plugin restores the schedule."
human_verification:
  - test: "Android: build and launch the debug APK"
    expected: "flutter build apk --debug completes (after accepting SDK licences); manifest merge and core-library desugaring succeed; app launches with the task list unchanged"
    why_human: "The 04-05 build timed out on the host and Android licences are not accepted, so manifest merge and desugaring are unverified by a real Gradle build"
  - test: "Android and iOS: each reminder kind fires at the expected time"
    expected: "Task due reminder (30 min lead), recurring task reminder, morning briefing, debt due, goal off-track, recurring payment and a budget alert at 80% and 100% each arrive; a quote notification arrives only after being enabled"
    why_human: "Real OS delivery, real clock and notification permission cannot run on the host VM"
  - test: "Reboot survival and swipe-kill"
    expected: "Pending reminders still fire after a reboot and after the app is swiped away"
    why_human: "Needs a physical device (see behavior_unverified_items)"
  - test: "Quiet hours and time zone"
    expected: "A reminder due at 23:00 is shown at 07:00; a budget alert raised at 23:00 is deferred to 07:00; changing the device time zone and reopening re-times reminders"
    why_human: "Needs device clock and real delivery"
  - test: "Permission flows"
    expected: "Prompt appears in context (not at launch for a fresh install with no goals); denying then using the Allow banner behaves sensibly; exact-alarm banner upgrades scheduling mode on return"
    why_human: "System permission dialogs. Note WR-06 and WR-07 below affect this flow"
  - test: "File picker and scoped storage"
    expected: "JSON export and the six CSV exports save through the system dialog; picking a JSON or CSV files shows the confirmation screen with record counts and date range; a truncated file is rejected with data unchanged; a CSV import replaces only the entities it contains"
    why_human: "System file picker and scoped storage cannot run on the host (assumptions A5, A6)"
  - test: "Android Auto Backup is off"
    expected: "adb shell dumpsys backup shows the app is not eligible for backup"
    why_human: "Device backup manager"
  - test: "iOS: more than 64 pending items and notification tap routing"
    expected: "No crash above 64 pending reminders, the settings page shows the waiting count, tapping a delivered notification routes to the right screen"
    why_human: "No Xcode or iOS device on the build host"
  - test: "iOS: confirm safety backups are excluded from iCloud/iTunes backup after the CR-01 fix"
    expected: "The backups directory and database directory report isExcludedFromBackup = true"
    why_human: "Needs an iOS device or simulator build"
---

# Phase 4: Notifications + Backup Verification Report

**Phase Goal:** All notification types are scheduled, delivered reliably after device reboot, and controlled by the user; data can be exported as JSON or CSV and restored from backup with transactional safety.
**Verified:** 2026-10-16
**Status:** gaps_found
**Re-verification:** No, initial verification

## Goal Achievement

The notification and backup engines exist, are substantive and are wired end to end. The full test suite (809 tests) passes and `tool/check_architecture.dart` passes. Two defects were confirmed in the real code and keep the phase from `passed`: an iOS privacy leak of the new safety backups (CR-01) and a reproducible silent row loss on CSV import (WR-01). Everything that needs a physical device is listed under `human_verification`, not as a gap.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Task due, morning briefing, recurring task, budget 80%/100%, debt, goal off-track and recurring payment notifications are each planned and scheduled (ROADMAP SC1) | VERIFIED (planning and scheduling; delivery in human_verification) | `ReminderPlanner` composed in `notifications_module.dart` from six `KindPlanner`s (task, briefing, debt, payment, goal, quote); budget alerts raised by `BudgetAlertEvaluator` (watches transaction and budget changes, once per category per threshold per month) through `ImmediateAlertDispatcher`. `FlutterLocalNotificationsGateway.schedule` calls `zonedSchedule` with exact or inexact mode from the exact-alarm permission. Planner, evaluator, dispatcher, slot-budget and diff tests all pass. |
| 2 | Rebooting does not cancel pending notifications; they are rescheduled on boot (ROADMAP SC2) | PRESENT_BEHAVIOR_UNVERIFIED | `AndroidManifest.xml` declares `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationBootReceiver` (BOOT_COMPLETED, MY_PACKAGE_REPLACED, QUICKBOOT) and `ScheduledNotificationReceiver`, pinned by `manifest_contract_test`. `startNotifications()` also runs a reconcile on every start and `NotificationLifecycleObserver` on every resume. No test can reboot a device. See behavior_unverified_items. |
| 3 | Quotes default OFF with configurable frequency and time; quiet hours default 22:00-07:00, configurable, and respected by all kinds (ROADMAP SC3) | VERIFIED | `NotificationPrefs.defaults()` sets quotes false, quiet hours on, 22:00 to 07:00; `isEnabled` treats quotes as opt-in. `ReminderPlanner.plan` defers every planned entry out of quiet hours (briefing included) and `ImmediateAlertDispatcher.dispatch` defers budget and goal alerts the same way. Settings UI (`notification_settings_body.dart`) has one switch per kind (NOTF-09), briefing time, `QuotesSection` (frequency and time) and `QuietHoursSection`. Settings, planner and dispatcher tests pass. |
| 4 | User can export all data as JSON and CSV containing every record (ROADMAP SC4) | VERIFIED | `BackupDao.readAll` reads all seven collections uncapped in one read transaction, soft-deleted rows included. `exportJson` builds a versioned envelope with seven codecs; `buildCsvExport` produces six per-entity files with a formula-injection guard. `BackupCubit` saves through `BackupFileGateway`. `export_completeness_test`, `json_roundtrip_test`, `csv_export_test`, `csv_roundtrip_test` pass. Note: CSV omits soft-deleted rows by design; JSON is the complete backup. |
| 5 | Import shows a confirmation screen with record counts and date range, takes a safety backup first, and is atomic; a failed import leaves the database unchanged (ROADMAP SC5) | VERIFIED | `ImportPreview` carries `counts`, `earliest`, `latest`; `ImportConfirmScreen` shows it. `ImportSession.commit` exports JSON and writes it with `SafetyBackupStore` before `BackupImporter.replace`, which clears and rewrites all affected collections inside one `isar.writeTxn` with no inner catch. `import_atomicity_test` (real Isar), `import_flow_test`, `safety_backup_store_test`, `backup_cubit_import_test` pass. Post-import hooks reseed alert markers and reconcile. Caveat: truth 7 below. |
| 6 | No data leaves the device: the safety backups this phase writes are excluded from OS cloud backup (CLAUDE.md privacy constraint; D-13) | FAILED | Android only. No iOS exclusion exists; see gap 1. |
| 7 | A CSV import restores every row of the file with a count that matches what is stored (DATA-04) | FAILED | Reproduced silent loss; see gap 2. |

**Score:** 4/7 truths verified (1 present, behavior-unverified; 2 failed)

### CR-01 Decision

CR-01 is a gap, not an advisory item. Reasons:

- The project constraint is explicit: "No data may leave the device". Phase 4 deliberately closed the Android route (D-13, three XML files, a contract test) because it knew full plaintext finance dumps would otherwise be uploaded. Leaving the equivalent iOS route open is an incomplete implementation of the same decision.
- The leak is introduced by this phase: each import adds up to three complete plaintext JSON copies of the user's tasks, transactions, debts, goals and budgets under `<Documents>/backups`, and iOS backs `Documents/` up to iCloud by default.
- I verified the absence directly: no `isExcludedFromBackup` or `NSURLIsExcludedFromBackupKey` in `lib`, `ios` or `android`, and `AppDelegate.swift` contains only the notification delegate and plugin registration.
- Later phases do not cover it. Phase 5 (app lock, settings, onboarding) and Phase 6 (already complete) contain nothing about iOS backup exclusion, so it cannot be deferred under Step 9b. Phase 5's onboarding screen will state "Your data never leaves this device", which makes the gap sharper.
- The fix is small (a method channel or a path in Application Support plus one resource-value call) and pinning it with a test is cheap.

It does not invalidate the notification work or the export/import mechanics, so it blocks `passed` for the privacy constraint only.

### Deferred Items

None. No later phase addresses either gap.

### Advisory (New Scope, Unevidenced)

Not applicable (initial verification).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/domain/notifications/planner/*.dart` (6 kind planners + `reminder_planner.dart`) | Pure planning of every scheduled kind | VERIFIED | Substantive, composed in DI, covered by tests |
| `lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart` | Plugin wrapper, `zonedSchedule`, channels | VERIFIED | Registered `@LazySingleton`, used by reconcile runner and dispatcher |
| `lib/infrastructure/notifications/sync/notification_sync_coordinator.dart` + `reconcile_runner.dart` | Debounced reconcile on data, prefs, locale changes | VERIFIED | Started from `startNotifications()` in `main()` |
| `lib/application/notifications/budget_alert_evaluator.dart`, `goal_alert_evaluator.dart` | Event-driven alerts | VERIFIED | Started from `startNotifications()` and the lifecycle observer |
| `lib/presentation/notifications/screens/notification_settings_*.dart` | Per-kind toggles, quiet hours, quotes | VERIFIED | Reachable from `task_list_settings_menu.dart` |
| `android/app/src/main/AndroidManifest.xml`, `res/xml/backup_rules.xml`, `data_extraction_rules.xml` | Permissions, boot receiver, Auto Backup off | VERIFIED | Present and contract-tested |
| `ios/Runner/AppDelegate.swift` | Notification delegate | VERIFIED (for delegate); no backup exclusion, see gap 1 | |
| `lib/data/backup/dao/backup_dao.dart`, `json/*`, `csv/*` | Uncapped export engines | VERIFIED | |
| `lib/data/backup/import/backup_importer.dart`, `snapshot_parser/validator`, `safety_backup_store.dart` | Atomic import with safety backup | VERIFIED with gaps | WR-01 data loss; CR-01 iOS exposure |
| `lib/presentation/backup/screens/backup_screen.dart`, `import_confirm_screen.dart` | Export/import UI | VERIFIED | Reachable from the task-list overflow menu |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `main.dart` | notification stack | `startNotifications()` | WIRED | Timezone, gateway init, reconciler, budget and goal evaluators, lifecycle observer |
| settings cubit | reconciler | `requestReconcile(prefsChange)` | WIRED | |
| `BackupCubit.confirmImport` | alert reseed + reconcile | `runPostImportHooks` | WIRED | Each step isolated |
| `ImportSession.commit` | `SafetyBackupStore` then `BackupImporter.replace` | sequential, safety backup first | WIRED | |
| task-list menu | `NotificationSettingsScreen`, `BackupScreen` | `MaterialPageRoute` | WIRED | Temporary entry point until Phase 5 settings screen |
| notification tap | navigation | `tapPayloads` + `launchPayload` -> `tap_navigator` | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Notification schedule | `PlannerInput.items/debts/goals/payments` | `snapshot_loader` over Isar DAOs (uncapped, sorted reminder reads) | Yes | FLOWING |
| Export files | `BackupRows` | `BackupDao.readAll` | Yes | FLOWING |
| Import preview | `ImportPreview` | parsed `BackupSnapshot` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Whole suite | `flutter test` (run once) | 809 tests, all passed | PASS |
| Architecture guard | `dart run tool/check_architecture.dart` | PASS | PASS |
| Static analysis | `flutter analyze` | 64 issues, all info level, no errors or warnings | PASS |
| CSV mixed blank/explicit ids | Temporary real-Isar test (deleted after run) | counts=3, stored=2 (row lost) | FAIL (gap 2) |
| iOS backup exclusion | grep for `isExcludedFromBackup` / `NSURLIsExcluded` in lib, ios, android | no match | FAIL (gap 1) |

### Probe Execution

No probes declared by the phase plans; none found under `scripts/*/tests/`. Step 7c skipped.

### Requirements Coverage

All 14 requirement IDs in the task prompt are claimed by at least one PLAN frontmatter and appear in REQUIREMENTS.md (marked Complete). No orphaned requirements: REQUIREMENTS.md maps no other ID to Phase 4.

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| NOTF-01 | 03, 06, 09, 10, 12, 13 | Task reminders | SATISFIED (delivery: human) | `TaskReminderPlanner`, 30 min lead, tests |
| NOTF-02 | 02, 06, 09, 12, 13 | Daily morning briefing | SATISFIED (delivery: human) | `BriefingPlanner`, uncapped briefing-window read |
| NOTF-03 | 02, 09, 13, 14 | Budget alerts at 80% and 100% | SATISFIED (delivery: human) | `BudgetAlertEvaluator`, `budget_threshold` |
| NOTF-04 | 02, 06, 09, 12 | Recurring task reminders | SATISFIED | `recurringTaskReminder` kind, one open row per series |
| NOTF-05 | 07, 12, 13 | Debt due reminders | SATISFIED (delivery: human) | `DebtReminderPlanner` |
| NOTF-06 | 07, 12, 13, 14 | Goal off-track alerts | SATISFIED (WR-06 caveat) | `GoalOffTrackPlanner`, `GoalAlertEvaluator` |
| NOTF-07 | 07, 09, 12, 13 | Recurring payment reminders | SATISFIED (delivery: human) | `PaymentReminderPlanner` |
| NOTF-08 | 07, 12, 15 | Motivational quotes, default OFF, configurable | SATISFIED | `QuotePlanner`, `QuotesSection`, defaults |
| NOTF-09 | 03, 10, 15 | Per-kind toggles | SATISFIED | One tile per kind |
| NOTF-10 | 03, 10, 14, 15 | Quiet hours | SATISFIED | Planner and dispatcher both defer |
| NOTF-11 | 03, 05, 10, 12 | Reschedule after reboot | PRESENT_BEHAVIOR_UNVERIFIED | Boot receiver declared; needs device |
| DATA-02 | 04, 16 | JSON export | SATISFIED | |
| DATA-03 | 01, 08, 16 | CSV export | SATISFIED | |
| DATA-04 | 01, 05, 08, 11, 17 | Import with safety backup and atomic transaction | PARTIAL | Atomic and safety backup verified; WR-01 silent loss on CSV; CR-01 iOS exposure of safety backups |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/data/backup/import/safety_backup_store.dart` | 39-42 | Plaintext finance dumps with no iOS backup exclusion (CR-01) | Blocker | Gap 1 |
| `lib/data/backup/import/backup_importer.dart` | 53-80 | Mixed auto and explicit ids in `putAll` (WR-01) | Blocker | Gap 2, reproduced |
| `lib/data/backup/import/csv_category_resolver.dart` | 55-57 | `category_id` trusted over `category_name` (WR-02) | Warning | Silent mis-categorisation on cross-device CSV |
| `lib/infrastructure/backup/import_session.dart` | 41, 80-96 | Stale `lastSafetyBackupPath` reported after a failed import (WR-03) | Warning | Misleading recovery message |
| `lib/presentation/backup/widgets/backup_error_text.dart` | 24-25 | Safety backup only reachable by a printed private path; no restore, share or delete (WR-04) | Warning | D-12 recovery story is not usable on a non-rooted device, and plaintext copies cannot be deleted |
| `lib/data/backup/import/safety_backup_store.dart` | 55-56, 75-78 | Rotation failure aborts the import after the backup was written (WR-05) | Warning | Fails safe but refuses a valid import |
| `lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart` | 46 | On-open goal evaluator can raise the permission prompt at launch (WR-06) | Warning | Contradicts the "never at launch" design; confirmed in code |
| `lib/application/notifications/notification_settings_cubit.dart` | 102-106 | Allow button is a no-op after permanent denial (WR-07) | Warning | No route to system settings |
| `lib/infrastructure/backup/file_picker_backup_file_gateway.dart` | 46-66 | Picked files never cleared from plugin cache; no count or total cap (WR-08) | Warning | Plaintext copies persist; memory risk |
| `lib/data/backup/csv/csv_row_reader.dart` | 97-104 | `amount_cents` silently overrides an edited `amount` (WR-09) | Warning | Surprising for spreadsheet editing |
| Info items IN-01 to IN-08 | various | See 04-REVIEW.md | Info | Not goal-blocking |

No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers found in `lib`.

WR-02 to WR-09 are warnings only: none breaks a roadmap success criterion, but WR-04 and WR-08 touch the privacy posture of backups and should be scheduled together with the CR-01 fix.

### Human Verification Required

See the `human_verification` list in the frontmatter (device build, delivery of every kind, reboot and swipe-kill survival, quiet hours and time zone, permission flows, file picker and scoped storage, Auto Backup state, iOS 64-pending limit and tap routing, iOS backup exclusion after the fix). These are expected to be run on a physical device and are not counted as gaps.

### Gaps Summary

Two root causes block `passed`:

1. **iOS backup exclusion missing (CR-01).** D-13 closed Android Auto Backup but nothing stops iOS from uploading `Documents/backups` (and the Isar database directory) to iCloud. This is a direct conflict with the project's "no data may leave the device" constraint and it is made worse by this phase's new plaintext safety copies.
2. **CSV import can silently lose rows (WR-01).** Reproduced: blank-id rows placed before an explicit-id row collide on auto-assigned ids; the result reports all rows written while one is gone.

Both are small, local fixes. Recommended closure plan: one plan for the iOS exclusion (channel or Application Support path plus contract test) that also covers WR-04/WR-08 cleanup of plaintext copies, and one for deterministic id assignment in `BackupImporter` with a regression test. WR-03, WR-05, WR-06 and WR-07 are cheap and can ride along. After closure, run the device checklist above.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
