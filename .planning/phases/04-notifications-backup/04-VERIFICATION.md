---
phase: 04-notifications-backup
verified: 2026-10-17T12:00:00Z
status: human_needed
score: 6/7 must-haves verified
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
  - .planning/phases/04-notifications-backup/04-18-PLAN.md
  - .planning/phases/04-notifications-backup/04-18-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-19-PLAN.md
  - .planning/phases/04-notifications-backup/04-19-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-20-PLAN.md
  - .planning/phases/04-notifications-backup/04-20-SUMMARY.md
  - .planning/phases/04-notifications-backup/04-21-PLAN.md
  - .planning/phases/04-notifications-backup/04-21-SUMMARY.md
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt
  - android/app/src/main/res/xml/backup_rules.xml
  - android/app/src/main/res/xml/data_extraction_rules.xml
  - ios/Runner/AppDelegate.swift
  - lib/application/backup/backup_cubit.dart
  - lib/application/backup/safety_backups_cubit.dart
  - lib/application/notifications/goal_alert_evaluator.dart
  - lib/application/notifications/notification_settings_cubit.dart
  - lib/data/backup/import/backup_importer.dart
  - lib/data/backup/import/safety_backup_store.dart
  - lib/data/backup/import/snapshot_id_assigner.dart
  - lib/data/backup/import/snapshot_parser.dart
  - lib/infrastructure/backup/backup_repository_impl.dart
  - lib/infrastructure/backup/file_picker_backup_file_gateway.dart
  - lib/infrastructure/backup/import_session.dart
  - lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart
  - lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart
  - lib/presentation/backup/widgets/safety_backups_section.dart
  - test/data/backup/import_atomicity_test.dart
  - test/data/backup/ios_backup_exclusion_contract_test.dart
covered_digest: "v1:sha256:20f7bbecaea95c8bb99bd1fb493c5259107d0ea19836c340126d35ae5ff8d520"
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "Gap 1 / CR-01: safety backups and the Isar database are excluded from iOS iCloud/iTunes backup (plan 04-18)"
    - "Gap 2 / WR-01: CSV import no longer loses rows when blank-id rows precede explicit-id rows (plan 04-19)"
    - "WR-03: stale safety backup path after a failed import (plan 04-19)"
    - "WR-04: safety backups can be counted, saved to a user-chosen location and deleted (plan 04-20)"
    - "WR-05: rotation failure no longer aborts an import (plan 04-19)"
    - "WR-06: on-open goal evaluation never raises the permission prompt and keeps its week marker on failure (plan 04-21)"
    - "WR-07: denied banner flips to Open settings and opens the system settings (plan 04-21)"
    - "WR-08: picker cache cleared after reading; file count and total size capped (plan 04-19)"
  gaps_remaining: []
  regressions: []
behavior_unverified_items:
  - truth: "Rebooting the device does not cancel pending notifications; they are rescheduled on next boot (ROADMAP SC2)"
    test: "Schedule a task due in about 35 minutes with reminders on, reboot the device, wait for the 30-minute lead time"
    expected: "The reminder still fires after the reboot with no app launch; the settings page shows the same waiting count"
    why_human: "The boot receiver and RECEIVE_BOOT_COMPLETED are declared and pinned by manifest_contract_test, and the app also reconciles on every start/resume, but no automated test can reboot a device. Presence of the receiver does not prove the plugin restores the schedule."
human_verification:
  - test: "iOS: confirm the Documents directory and the backups directory are excluded from iCloud/iTunes backup"
    expected: "On a device or simulator build, URLResourceValues.isExcludedFromBackup reads true for Documents and Documents/backups after launch, and a fresh import adds files that stay excluded"
    why_human: "AppDelegate.excludeUserDataFromBackup() is present, runs on every launch before Dart starts and is pinned by ios_backup_exclusion_contract_test, but the OS effect needs an iOS build (no Xcode on the host)"
  - test: "Android: build and launch the debug APK"
    expected: "flutter build apk --debug completes (after accepting SDK licences); manifest merge and core-library desugaring succeed; the new MainActivity channel compiles; app launches with the task list unchanged"
    why_human: "The 04-05 build timed out on the host and Android licences are not accepted, so manifest merge, desugaring and Kotlin compilation are unverified by a real Gradle build"
  - test: "Android and iOS: each reminder kind fires at the expected time"
    expected: "Task due reminder (30 min lead), recurring task reminder, morning briefing, debt due, goal off-track, recurring payment and a budget alert at 80% and 100% each arrive; a quote notification arrives only after being enabled"
    why_human: "Real OS delivery, real clock and notification permission cannot run on the host VM"
  - test: "Reboot survival and swipe-kill"
    expected: "Pending reminders still fire after a reboot and after the app is swiped away"
    why_human: "Needs a physical device (see behavior_unverified_items)"
  - test: "Quiet hours and time zone"
    expected: "A reminder due at 23:00 is shown at 07:00; a budget alert raised at 23:00 is deferred to 07:00; changing the device time zone and reopening re-times reminders"
    why_human: "Needs device clock and real delivery"
  - test: "Permission flows including Open settings (WR-06, WR-07)"
    expected: "A fresh install with an off-track goal shows no permission prompt at launch. Denying in the settings screen flips the banner button to Open settings; tapping it opens the app notification page (Android) or the app page in Settings (iOS); granting there and returning removes the banner. Exact-alarm banner upgrades scheduling mode on return"
    why_human: "System permission dialogs and the system settings handoff cannot run on the host; the Kotlin and Swift handlers are pinned only by system_settings_channel_test (channel name and method)"
  - test: "File picker, scoped storage and picker cache"
    expected: "JSON export and the six CSV exports save through the system dialog; picking a JSON or CSV files shows the confirmation screen with record counts and date range; more than 6 files or more than 50 MiB is rejected; a truncated file is rejected with data unchanged; the picker cache holds no copy afterwards"
    why_human: "System file picker, scoped storage and FilePicker.clearTemporaryFiles cannot run on the host (assumptions A5, A6)"
  - test: "Safety backups section on the Backup screen (WR-04)"
    expected: "After an import the count shows 1; Save copy opens the system save dialog and the saved file imports back through Import; Delete asks for confirmation and the count returns to 0"
    why_human: "System save dialog and a real import on a device"
  - test: "Android Auto Backup is off"
    expected: "adb shell dumpsys backup shows the app is not eligible for backup"
    why_human: "Device backup manager"
  - test: "iOS: more than 64 pending items and notification tap routing"
    expected: "No crash above 64 pending reminders, the settings page shows the waiting count, tapping a delivered notification routes to the right screen"
    why_human: "No Xcode or iOS device on the build host"
---

# Phase 4: Notifications + Backup Verification Report

**Phase Goal:** All notification types are scheduled, delivered reliably after device reboot, and controlled by the user; data can be exported as JSON or CSV and restored from backup with transactional safety.
**Verified:** 2026-10-17
**Status:** human_needed
**Re-verification:** Yes, after gap closure plans 04-18 to 04-21

## Goal Achievement

Both gaps from the initial verification are closed in the code, and each is pinned by tests that I re-ran. The full suite (891 tests) passes, `tool/check_architecture.dart` passes and `flutter analyze` reports 0 errors and 0 warnings (64 info items, all in test files or pre-existing). What remains cannot be proven on the host: real notification delivery, reboot survival, the iOS exclusion taking effect, system dialogs, and a real Gradle/Xcode build. Those are listed in `human_verification`, so the status is `human_needed`, not `passed`.

### Prior Gaps: Re-verification

| Gap | Status | Evidence (read in the code, not taken from SUMMARY) |
|-----|--------|------------------------------------------------------|
| Gap 1 / CR-01: iOS backup exclusion | CLOSED (device confirmation pending) | `ios/Runner/AppDelegate.swift` declares `excludeUserDataFromBackup()` and calls it in `didFinishLaunchingWithOptions` before `super.application`. It creates `Documents/backups`, then sets `isExcludedFromBackup = true` on `Documents` and on `Documents/backups` through `setResourceValues`. Both storage paths (`IsarService` and `SafetyBackupStore`) resolve through `getApplicationDocumentsDirectory`, the directory excluded. `test/data/backup/ios_backup_exclusion_contract_test.dart` pins the Swift text, the launch-time call, the `backups` name match, the shared documents root, and fails if any `lib/` file uses an unexcluded persistent root (`getApplicationSupport*`, `getLibrary*`, `getExternalStorage*`, `getDownloads*`); a grep confirms none exists. The earlier "grep returns no match" condition no longer holds. |
| Gap 2 / WR-01: CSV import row loss | CLOSED | New `snapshot_id_assigner.dart` gives each blank-id row an id above the highest explicit id of its own collection, in file order, for all seven collections; explicit ids are untouched. `BackupImporter.replace` calls `assignMissingIds(snapshot)` before `isar.writeTxn`, and `_put` checks `collection.count() == rows.length` after `putAll`, throwing inside the transaction so Isar restores the clears. `import_atomicity_test.dart` runs real Isar with the exact reproduced case (`[blank a, blank b, explicit id 2]`) and asserts 3 rows stored, explicit id 2 kept, `a` and `b` above 2; a second test proves a residual duplicate id aborts with the data unchanged. `snapshot_id_assigner_test.dart` covers the assigner. |
| WR-03 stale safety path | CLOSED | `ImportSession.commit()` sets `lastSafetyBackupPath = null` right after `_committing = true`, and assigns it only from the result of `_store.write`. Tests in `import_flow_test.dart`. |
| WR-04 safety backups unmanageable | CLOSED | `SafetyBackupStore.list/newest/deleteAll` (generated-name regex only), repository methods `safetyBackupCount/latestSafetyBackup/deleteSafetyBackups`, `SafetyBackupsCubit` (registered in `injection.config.dart`), `SafetyBackupsSection` placed in `BackupScreen` after the import card, with a confirm dialog. The cubit and repository share the one `SafetyBackupStore` instance that `ImportSession` uses. The section never shows a path. Saved copies are ordinary JSON backups, restored through the existing Import. D-12 path message after a failed import is unchanged. |
| WR-05 rotation failure aborts import | CLOSED | `SafetyBackupStore.write` wraps `_rotate` in `try ... on FileSystemException`, so the written backup is returned and the import proceeds. Test in `safety_backup_store_test.dart`. |
| WR-06 prompt at launch | CLOSED | `ImmediateAlertDispatcher.dispatch(..., promptIfNeeded)` checks `notificationPermission() == granted` instead of calling `ensureAsked()` when false. `GoalAlertEvaluator.evaluateOnOpen` passes `promptIfNeeded: false` and removes the `gf:` marker when dispatch returns false. The only remaining `ensureAsked` callers are the reconcile runner (after a data change with something to schedule) and the in-context default dispatch (budget alerts). |
| WR-07 Allow no-op after denial | CLOSED (device confirmation pending) | `NotificationSettingsState.permissionRequested` flips after a refused request; `requestPermission()` then calls `openNotificationSettings()`; the banner label switches to Open settings. `NotificationPermissionServiceImpl` invokes channel `agenda/system_settings`; `MainActivity.kt` handles it with fixed intents (`ACTION_APP_NOTIFICATION_SETTINGS`, fallback app details) and `AppDelegate.swift` opens `UIApplication.openSettingsURLString`. Nothing from Dart reaches an intent or URL. |
| WR-08 picker cache and caps | CLOSED | `FilePickerBackupFileGateway.pickFiles` runs `importLimitViolation` (max 6 files, 25 MiB each, 50 MiB total) on the picked sizes before reading, returns `tooLarge`, and clears the plugin cache in `finally` once files were picked. `parseBackupFiles` applies the same limits. |

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Task due, morning briefing, recurring task, budget 80%/100%, debt, goal off-track and recurring payment notifications are each planned and scheduled (ROADMAP SC1) | VERIFIED (planning and scheduling; delivery in human_verification) | Unchanged from the initial verification: six `KindPlanner`s composed in `ReminderPlanner`, `BudgetAlertEvaluator` plus `ImmediateAlertDispatcher`, `zonedSchedule` with exact or inexact mode. Planner, evaluator, dispatcher and diff tests pass in the 891-test run. Goal alert path re-read after 04-21 and still correct. |
| 2 | Rebooting does not cancel pending notifications; they are rescheduled on boot (ROADMAP SC2) | PRESENT_BEHAVIOR_UNVERIFIED | Boot receivers and `RECEIVE_BOOT_COMPLETED` declared and pinned by `manifest_contract_test`; reconcile also runs on every start and resume (`startNotifications`, `NotificationLifecycleObserver`). No test can reboot a device. See behavior_unverified_items. |
| 3 | Quotes default OFF with configurable frequency and time; quiet hours default 22:00-07:00, configurable, respected by all kinds (ROADMAP SC3) | VERIFIED | Unchanged; `NotificationPrefs.defaults()`, planner and dispatcher both defer out of quiet hours (the dispatcher change in 04-21 kept the quiet-hours branch), settings UI present. Tests pass. |
| 4 | User can export all data as JSON and CSV containing every record (ROADMAP SC4) | VERIFIED | Unchanged; `BackupDao.readAll` uncapped, `exportJson`, `buildCsvExport`. CSV omits soft-deleted rows by design; JSON is complete. |
| 5 | Import shows a confirmation screen with record counts and date range, takes a safety backup first, and is atomic; a failed import leaves the database unchanged (ROADMAP SC5) | VERIFIED | `ImportSession.commit` exports and writes the safety backup before `BackupImporter.replace`; replace runs in one `writeTxn` with no inner catch, and now also aborts on a row-count shortfall. Atomicity, flow, store and cubit tests pass, including the new residual-duplicate abort test. |
| 6 | No data leaves the device: the safety backups this phase writes, and the Isar database, are excluded from OS cloud backup on Android and iOS (CLAUDE.md privacy constraint; D-13) | VERIFIED in code; OS effect on a device is in human_verification | Android: `allowBackup=false`, `backup_rules.xml`, `data_extraction_rules.xml`, contract-tested. iOS: launch-time `excludeUserDataFromBackup()` described in the table above, contract-tested. No `dio`/`http`/analytics added by the gap plans. |
| 7 | A CSV import restores every row of the file with a count that matches what is stored (DATA-04) | VERIFIED | Real-Isar regression test of the exact reproduced scenario passes; count verified inside the transaction. |

**Score:** 6/7 truths verified (1 present, behavior-unverified; 0 failed)

### Deferred Items

None.

### Advisory (New Scope, Unevidenced)

None. No new blocker-class finding was raised in this re-verification outside the carried-forward gaps, and the gap-closure files contain no unevidenced architectural or security concern.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ios/Runner/AppDelegate.swift` | Launch-time backup exclusion plus settings channel | VERIFIED | Both present, wired in `didFinishLaunchingWithOptions` and `didInitializeImplicitFlutterEngine` |
| `test/data/backup/ios_backup_exclusion_contract_test.dart` | iOS counterpart of manifest contract | VERIFIED | Six checks, passes |
| `lib/data/backup/import/snapshot_id_assigner.dart` | Deterministic ids for blank rows, all seven collections | VERIFIED | Substantive; called from `BackupImporter.replace` |
| `lib/data/backup/import/backup_importer.dart` | replace with id assignment and count check | VERIFIED | Wired from `ImportSession` |
| `lib/data/backup/import/snapshot_parser.dart` | Shared limits | VERIFIED | `importLimitViolation` used by parser and picker |
| `lib/data/backup/import/safety_backup_store.dart` | write/rotate tolerant, list/newest/deleteAll | VERIFIED | One instance shared by session and repository |
| `lib/application/backup/safety_backups_cubit.dart` + `lib/presentation/backup/widgets/safety_backups_section.dart` | Safety backup management UI | VERIFIED | DI-registered, mounted in `BackupScreen` |
| `lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart` | Non-prompting dispatch option | VERIFIED | Used by `GoalAlertEvaluator` |
| `lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart` + `MainActivity.kt` + `AppDelegate.swift` | Open settings channel | VERIFIED | Channel and method names match on all three sides |
| Rest of Phase 4 artifacts | Planners, gateway, sync, settings UI, export engines, manifest | VERIFIED | Unchanged since initial verification; regression sanity via the green suite |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AppDelegate.didFinishLaunchingWithOptions` | `excludeUserDataFromBackup()` | direct call before `super.application` | WIRED | Pinned by the contract test |
| `IsarService` / `SafetyBackupStore` | excluded Documents directory | `getApplicationDocumentsDirectory` | WIRED | Pinned by the contract test |
| `BackupImporter.replace` | `assignMissingIds` | call before `isar.writeTxn` | WIRED | |
| `FilePickerBackupFileGateway` | `importLimitViolation`, `clearTemporaryFiles` | before reading, in `finally` | WIRED | |
| `GoalAlertEvaluator` | `ImmediateAlertDispatcher.dispatch(promptIfNeeded: false)` | marker rollback on false | WIRED | |
| `NotificationSettingsCubit.requestPermission` | `NotificationPermissionService.openNotificationSettings` | `permissionRequested` flag | WIRED | |
| `NotificationPermissionServiceImpl` | `MainActivity.kt` / `AppDelegate.swift` | channel `agenda/system_settings` | WIRED | |
| `BackupScreen` | `SafetyBackupsSection` -> `SafetyBackupsCubit` -> `BackupRepositoryImpl` -> `SafetyBackupStore` | DI and direct | WIRED | Count refreshes on `BackupImportDone` and `BackupImportFailed` |
| Earlier links (`startNotifications`, reconciler, `runPostImportHooks`, tap routing) | | | WIRED | Unchanged |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Safety backups section | `state.count`, latest file | `SafetyBackupStore.list()` over real files | Yes | FLOWING |
| Import result counts | `counts` | `_put` after `putAll` and a stored-count check | Yes | FLOWING |
| Notification schedule, export files, import preview | | Isar DAOs / parsed snapshot | Yes | FLOWING (unchanged) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Whole suite (run once) | `flutter test` | 891 tests, all passed | PASS |
| Architecture guard | `dart run tool/check_architecture.dart` | PASS | PASS |
| Static analysis | `flutter analyze` | 64 issues, all info, 0 errors, 0 warnings | PASS |
| Mixed blank/explicit CSV ids with real Isar | `import_atomicity_test.dart` group `blank ids` (in the suite) | 3 stored for 3 reported, explicit id kept | PASS |
| iOS exclusion text and storage roots | `ios_backup_exclusion_contract_test.dart` (in the suite) | passes | PASS |
| Debt markers | grep `TBD|FIXME|XXX` in `lib`, `android/app/src`, `ios/Runner` (excluding generated) | none | PASS |

### Probe Execution

No probes declared by the phase plans; none found under `scripts/*/tests/`. Step 7c skipped.

### Requirements Coverage

All 14 requirement IDs (NOTF-01 to NOTF-11, DATA-02, DATA-03, DATA-04) appear in at least one PLAN `requirements:` frontmatter and in REQUIREMENTS.md (checked and marked Complete). No other ID in REQUIREMENTS.md maps to Phase 4, so there are no orphans. The gap plans claim DATA-04 (04-18, 04-19, 04-20) and NOTF-01, NOTF-06 (04-21).

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| NOTF-01 | 02, 03, 06, 09, 10, 12, 13, 21 | SATISFIED (delivery: human) | Task reminder planner; 04-21 keeps launch free of prompts |
| NOTF-02 | 02, 06, 09, 12, 13 | SATISFIED (delivery: human) | `BriefingPlanner` |
| NOTF-03 | 02, 09, 13, 14 | SATISFIED (delivery: human) | `BudgetAlertEvaluator` |
| NOTF-04 | 02, 06, 09, 12 | SATISFIED | Recurring task reminder kind |
| NOTF-05 | 02, 07, 12, 13 | SATISFIED (delivery: human) | `DebtReminderPlanner` |
| NOTF-06 | 02, 07, 12, 13, 14, 21 | SATISFIED | `GoalOffTrackPlanner`, `GoalAlertEvaluator`; WR-06 closed |
| NOTF-07 | 02, 07, 09, 13 | SATISFIED (delivery: human) | `PaymentReminderPlanner` |
| NOTF-08 | 02, 07, 12, 15 | SATISFIED | `QuotePlanner`, defaults OFF |
| NOTF-09 | 02, 03, 10, 15 | SATISFIED | One tile per kind |
| NOTF-10 | 02, 03, 10, 14, 15 | SATISFIED | Planner and dispatcher defer |
| NOTF-11 | 03, 05, 10, 12 | PRESENT_BEHAVIOR_UNVERIFIED | Needs a device reboot |
| DATA-02 | 02, 04, 16 | SATISFIED | JSON export |
| DATA-03 | 01, 02, 05, 08, 16 | SATISFIED | CSV export |
| DATA-04 | 01, 02, 05, 08, 11, 17, 18, 19, 20 | SATISFIED | Atomic import with safety backup; WR-01 and CR-01 closed |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/data/backup/import/csv_category_resolver.dart` | 55-57 | `category_id` trusted over `category_name` (WR-02) | Warning (open, out of scope of plans 18-21) | Silent mis-categorisation on a cross-device CSV; no roadmap criterion fails |
| `lib/data/backup/csv/csv_row_reader.dart` | 97-104 | `amount_cents` overrides an edited `amount` (WR-09) | Warning (open) | Surprising for spreadsheet editing |
| Info items IN-01 to IN-08 | various | See 04-REVIEW.md | Info | Not goal-blocking |
| Plaintext file protection | `ios/Runner/AppDelegate.swift` | No `NSFileProtectionComplete` on the safety backups | Info | Optional hardening listed in the old gap; not required by any criterion |

No former Blocker remains. No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers in modified files. WR-02 and WR-09 are carried forward as known warnings for the backlog; neither breaks a ROADMAP success criterion.

### Human Verification Required

See the `human_verification` list in the frontmatter. In short: confirm the iOS exclusion on a device, a real Android build, delivery of every notification kind, reboot and swipe-kill survival, quiet hours and time zone, permission flows including Open settings, file picker and picker cache, the safety backups section, Android Auto Backup state, and iOS 64-pending limit and tap routing.

### Gaps Summary

No code gaps remain. Both blockers from the first verification (iOS backup exclusion, CSV silent row loss) are closed with code that I read and tests that I ran, and the WR-03 to WR-08 ride-alongs are closed. The phase is `human_needed` only because the delivery, reboot, permission, picker and iOS exclusion behaviours can be proven only on a physical device. WR-02 and WR-09 remain open warnings.

---

_Verified: 2026-10-17_
_Verifier: Claude (gsd-verifier)_
