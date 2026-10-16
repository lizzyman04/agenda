---
phase: 04-notifications-backup
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 144
files_reviewed_list:
  - android/app/build.gradle.kts
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/xml/backup_rules.xml
  - android/app/src/main/res/xml/data_extraction_rules.xml
  - ios/Runner/AppDelegate.swift
  - lib/app.dart
  - lib/main.dart
  - pubspec.yaml
  - lib/application/backup/backup_cubit.dart
  - lib/application/backup/backup_state.dart
  - lib/application/backup/post_import_hooks.dart
  - lib/application/notifications/budget_alert_evaluator.dart
  - lib/application/notifications/budget_month.dart
  - lib/application/notifications/debounced_single_flight.dart
  - lib/application/notifications/goal_alert_evaluator.dart
  - lib/application/notifications/notification_settings_cubit.dart
  - lib/application/notifications/notification_settings_state.dart
  - lib/config/di/backup_module.dart
  - lib/config/di/infrastructure_module.dart
  - lib/config/di/notifications_module.dart
  - lib/config/startup/notification_lifecycle_observer.dart
  - lib/config/startup/notification_startup.dart
  - lib/core/constants/app_constants.dart
  - lib/core/constants/storage_keys.dart
  - lib/data/backup/csv/csv_amount.dart
  - lib/data/backup/csv/csv_format.dart
  - lib/data/backup/csv/csv_row_reader.dart
  - lib/data/backup/csv/csv_snapshot_reader.dart
  - lib/data/backup/csv/csv_table_codec.dart
  - lib/data/backup/csv/csv_text_guard.dart
  - lib/data/backup/csv/mappers/budget_csv_mapper.dart
  - lib/data/backup/csv/mappers/debt_csv_mapper.dart
  - lib/data/backup/csv/mappers/goal_csv_mapper.dart
  - lib/data/backup/csv/mappers/payment_csv_mapper.dart
  - lib/data/backup/csv/mappers/task_csv_mapper.dart
  - lib/data/backup/csv/mappers/transaction_csv_mapper.dart
  - lib/data/backup/dao/backup_dao.dart
  - lib/data/backup/import/backup_importer.dart
  - lib/data/backup/import/backup_snapshot.dart
  - lib/data/backup/import/csv_category_resolver.dart
  - lib/data/backup/import/import_preview_builder.dart
  - lib/data/backup/import/safety_backup_store.dart
  - lib/data/backup/import/snapshot_parser.dart
  - lib/data/backup/import/snapshot_validator.dart
  - lib/data/backup/json/backup_envelope.dart
  - lib/data/backup/json/budget_json_codec.dart
  - lib/data/backup/json/category_json_codec.dart
  - lib/data/backup/json/debt_json_codec.dart
  - lib/data/backup/json/goal_json_codec.dart
  - lib/data/backup/json/item_json_codec.dart
  - lib/data/backup/json/json_fields.dart
  - lib/data/backup/json/payment_json_codec.dart
  - lib/data/backup/json/transaction_json_codec.dart
  - lib/data/finance/budget/budget_dao.dart
  - lib/data/finance/recurring/recurring_payment_dao.dart
  - lib/data/finance/recurring/recurring_payment_model.dart
  - lib/data/tasks/item_dao.dart
  - lib/data/tasks/item_reminder_queries.dart
  - lib/domain/backup/backup_entity.dart
  - lib/domain/backup/backup_file.dart
  - lib/domain/backup/backup_file_gateway.dart
  - lib/domain/backup/backup_repository.dart
  - lib/domain/backup/import_preview.dart
  - lib/domain/finance/budget/budget_repository.dart
  - lib/domain/finance/recurring/recurring_payment_repository.dart
  - lib/domain/notifications/alert_state_store.dart
  - lib/domain/notifications/local_notification_gateway.dart
  - lib/domain/notifications/model/notification_kind.dart
  - lib/domain/notifications/model/notification_prefs.dart
  - lib/domain/notifications/model/planned_notification.dart
  - lib/domain/notifications/model/planner_input.dart
  - lib/domain/notifications/model/quote_frequency.dart
  - lib/domain/notifications/model/schedule_request.dart
  - lib/domain/notifications/notification_permission_service.dart
  - lib/domain/notifications/notification_prefs_repository.dart
  - lib/domain/notifications/notification_reconciler.dart
  - lib/domain/notifications/planner/briefing_planner.dart
  - lib/domain/notifications/planner/debt_reminder_planner.dart
  - lib/domain/notifications/planner/goal_off_track_planner.dart
  - lib/domain/notifications/planner/kind_planner.dart
  - lib/domain/notifications/planner/payment_reminder_planner.dart
  - lib/domain/notifications/planner/quote_planner.dart
  - lib/domain/notifications/planner/reminder_planner.dart
  - lib/domain/notifications/planner/task_reminder_planner.dart
  - lib/domain/notifications/planning/budget_threshold.dart
  - lib/domain/notifications/planning/effective_due_date.dart
  - lib/domain/notifications/planning/goal_alert_keys.dart
  - lib/domain/notifications/planning/goal_off_track.dart
  - lib/domain/notifications/planning/quote_picker.dart
  - lib/domain/notifications/planning/stale_alert_keys.dart
  - lib/domain/notifications/planning/task_fire_time.dart
  - lib/domain/notifications/quotes/quotes_catalog.dart
  - lib/domain/notifications/quotes/quotes_en.dart
  - lib/domain/notifications/quotes/quotes_pt.dart
  - lib/domain/notifications/rules/day_math.dart
  - lib/domain/notifications/rules/notification_id.dart
  - lib/domain/notifications/rules/payload_codec.dart
  - lib/domain/notifications/rules/quiet_hours.dart
  - lib/domain/notifications/rules/schedule_diff.dart
  - lib/domain/notifications/rules/slot_budget.dart
  - lib/domain/notifications/rules/tap_target.dart
  - lib/domain/tasks/item_repository.dart
  - lib/infrastructure/backup/backup_repository_impl.dart
  - lib/infrastructure/backup/csv_export_builder.dart
  - lib/infrastructure/backup/file_picker_backup_file_gateway.dart
  - lib/infrastructure/backup/import_session.dart
  - lib/infrastructure/finance/budget_repository_impl.dart
  - lib/infrastructure/finance/recurring_payment_repository_impl.dart
  - lib/infrastructure/notifications/content/notification_content_builder.dart
  - lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart
  - lib/infrastructure/notifications/gateway/notification_channels.dart
  - lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart
  - lib/infrastructure/notifications/gateway/timezone_bootstrap.dart
  - lib/infrastructure/notifications/prefs/alert_state_store_impl.dart
  - lib/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart
  - lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart
  - lib/infrastructure/notifications/sync/notification_sync_coordinator.dart
  - lib/infrastructure/notifications/sync/permission_gate.dart
  - lib/infrastructure/notifications/sync/reconcile_apply.dart
  - lib/infrastructure/notifications/sync/reconcile_report.dart
  - lib/infrastructure/notifications/sync/reconcile_runner.dart
  - lib/infrastructure/notifications/sync/snapshot_loader.dart
  - lib/infrastructure/tasks/item_repository_impl_queries.dart
  - lib/presentation/backup/screens/backup_screen.dart
  - lib/presentation/backup/screens/import_confirm_screen.dart
  - lib/presentation/backup/widgets/backup_action_card.dart
  - lib/presentation/backup/widgets/backup_error_text.dart
  - lib/presentation/backup/widgets/backup_outcome_message.dart
  - lib/presentation/backup/widgets/import_summary_card.dart
  - lib/presentation/finance/screens/finance_dashboard_screen.dart
  - lib/presentation/notifications/routing/notification_tap_listener.dart
  - lib/presentation/notifications/routing/tap_navigator.dart
  - lib/presentation/notifications/screens/notification_settings_body.dart
  - lib/presentation/notifications/screens/notification_settings_screen.dart
  - lib/presentation/notifications/widgets/notification_type_labels.dart
  - lib/presentation/notifications/widgets/notification_type_tile.dart
  - lib/presentation/notifications/widgets/permission_banner.dart
  - lib/presentation/notifications/widgets/quiet_hours_section.dart
  - lib/presentation/notifications/widgets/quotes_section.dart
  - lib/presentation/notifications/widgets/time_setting_tile.dart
  - lib/presentation/shell/app_shell.dart
  - lib/presentation/shell/shell_navigation.dart
  - lib/presentation/tasks/screens/task_list_screen.dart
  - lib/presentation/tasks/widgets/task_list_settings_menu.dart
findings:
  critical: 1
  warning: 9
  info: 8
  total: 18
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 144 (generated `*.g.dart`, `injection.config.dart`, `lib/generated/**`, ARB files and README files excluded; ARB key parity across en/pt/pt_BR was checked and matches at 659 keys; `tool/check_architecture.dart` passes)

## Summary

The core import path is sound. Parsing and validation run before anything is written. The replace runs in one Isar write transaction, and any exception inside it aborts the whole transaction. The safety backup is written before the replace. File content is kept out of error messages. CSV export guards formula-leading text on every free-text column I checked. The notification planners, ID scheme, payload decoder and diff logic are consistent and well bounded.

The defects below are mostly at the edges.

- **Privacy:** the safety backups are an iOS privacy hole. D-13 excludes them from backup on Android only.
- **Data integrity:** CSV import has two paths that can silently misplace or lose data.
- **Safety-backup UX:** the stale path and the unreachable file undermine the stated recovery story.
- **Launch behaviour:** a permission prompt can fire at launch, which contradicts the stated design.

## Structural Findings (fallow)

None provided for this review.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Safety backups (full plaintext financial data) are included in iOS iCloud/iTunes backup, violating the privacy constraint and D-13

**File:** `lib/data/backup/import/safety_backup_store.dart:39-42` (also `ios/Runner/AppDelegate.swift:1-20`)
**Issue:** `SafetyBackupStore.write` puts up to three complete JSON dumps of the user's tasks, transactions, debts, goals and budgets in `<Application Documents>/backups`. The class comment says the directory is "excluded from Android Auto Backup (D-13)". That is true only on Android (`allowBackup=false`, `backup_rules.xml`, `data_extraction_rules.xml`). On iOS, `Documents/` is included in iCloud and iTunes backups by default, and nothing marks the directory or files with `NSURLIsExcludedFromBackupKey`. A grep for `isExcludedFromBackup` and `NSURLIsExcluded` across `lib`, `ios` and `android` finds no match.

Every import therefore creates unencrypted copies of the user's finances that iOS uploads to iCloud. This breaks the project's core constraint: "No data may leave the device". The Isar database itself also lives in the documents directory (`IsarService`), so the same exposure applies there. The new safety backups add multiple extra plaintext copies on top.

**Fix:** Exclude the backup directory from iOS backup, or store it in a location that is never backed up. Add a small method channel, or a plugin such as `flutter_file_exclude`-style code, that sets the resource value `isExcludedFromBackup = true` on the `backups` directory and on the DB directory. For example, in `AppDelegate.swift`:
```swift
func excludeFromBackup(_ url: URL) {
  var u = url; var v = URLResourceValues(); v.isExcludedFromBackup = true
  try? u.setResourceValues(v)
}
```
Call it for the `backups` dir after `dir.create`, via a channel. Alternatively, write the safety backup to `getApplicationSupportDirectory()` and exclude that directory. On iOS, also consider `NSFileProtectionComplete` for these files.

## Warnings

### WR-01: CSV import can silently overwrite rows when blank-id rows precede explicit-id rows

**File:** `lib/data/backup/import/snapshot_validator.dart:39-48`, `lib/data/backup/import/backup_importer.dart:53-80`, `lib/data/backup/csv/mappers/task_csv_mapper.dart:85` (same pattern in every CSV mapper)
**Issue:** Every CSV mapper uses `r.optInt('id') ?? Isar.autoIncrement`. The validator comment says rows without an id "are never duplicates of each other", and it only checks explicit ids against each other. `putAll` assigns auto ids in list order. If a spreadsheet user adds new rows with a blank `id` above existing rows, an auto-assigned id can equal an explicit id that appears later in the same file. The later put then overwrites the earlier row. No error is raised, the row count in the result is still reported correctly, and the safety backup is the only recovery. Whether the collision occurs depends on Isar's per-collection auto-increment counter after `clear()`. I could not confirm that behaviour from the code, so test it.

**Fix:** In the importer, assign ids deterministically before `putAll`. For example, compute `maxId` over the explicit ids and give each `autoIncrement` row `++maxId`, which also makes `parentId` and `linkedGoalId` remapping possible. Alternatively, put explicit-id rows first and auto-id rows last:
```dart
final ordered = [...rows.where((m) => m.id != Isar.autoIncrement),
                 ...rows.where((m) => m.id == Isar.autoIncrement)];
```

### WR-02: CSV category resolution trusts `category_id` over `category_name`, so cross-device or cross-install imports silently mis-categorise

**File:** `lib/data/backup/import/csv_category_resolver.dart:55-57`
**Issue:** `if (categoryId > 0 && known.contains(categoryId)) return existing`. The export writes both `category_id` and `category_name`. When a CSV from another install or device is imported, custom category ids differ. Any numeric id that happens to exist locally wins, even if that local category has a different name or a different `TransactionType`. An expense row can end up in an income category, or "Rent" in "Groceries", with no warning in the preview. Names are only consulted when the id is unknown.

**Fix:** When both id and name are present, prefer the name match. Use the id only when the name is blank, or when the id's category name equals the given name. Also verify `type` compatibility for the id path:
```dart
if (categoryId > 0 && known.contains(categoryId) && (name.isEmpty || nameMatches(categoryId, name)) && typeMatches) { ... }
```

### WR-03: A stale `lastSafetyBackupPath` is reported as the recovery location for a failed import

**File:** `lib/infrastructure/backup/import_session.dart:41,80-96`; consumed at `lib/application/backup/backup_cubit.dart:106` and `lib/presentation/backup/widgets/backup_error_text.dart:24-25`
**Issue:** `lastSafetyBackupPath` is never reset at the start of `commit()`. If the export step fails (`backup is! Success`) or `_store.write` throws (disk full), the field still holds the path from a previous import. The UI then shows "Your data is unchanged. Safety backup: <old path>" for a backup that was not made for this import. Rotation may also have deleted that file.

**Fix:** Set `lastSafetyBackupPath = null;` right after `_committing = true;` in `commit()`, and only assign it after `_store.write` returns. The UI then falls back to the generic message when no new backup exists.

### WR-04: Safety backups are unreachable and unmanageable by the user

**File:** `lib/presentation/backup/widgets/backup_error_text.dart:24-25`, `lib/data/backup/import/safety_backup_store.dart:12-17`
**Issue:** The safety backup lives in the private app documents directory (`/data/user/0/<pkg>/app_flutter/backups` on Android). The only user-facing mention is a printed path in an error snackbar. There is no "export safety backup", "restore", or "delete" action. On a non-rooted device the user cannot open that path, so the D-12 recovery story is not usable. The same files also persist as unmanaged plaintext copies of the user's data, up to three of them, with no way to delete them.

**Fix:** Add a Backup-screen action that lists the safety backups and lets the user share or save one with the existing `saveFile` gateway, and a way to delete them. At minimum, do not present the raw path as actionable guidance.

### WR-05: Safety-backup rotation failure aborts the import after the backup was already written

**File:** `lib/data/backup/import/safety_backup_store.dart:55-56,75-78`; `lib/infrastructure/backup/import_session.dart:92-96`
**Issue:** `write` awaits `_rotate`, which deletes old files. A `FileSystemException` there (a file locked or removed concurrently) propagates out of `write`. `commit()` catches it and returns `importFailed` without ever running `replace`. The new backup file exists, but the import is refused over housekeeping. Rotation is best-effort cleanup and must not fail the import.

**Fix:** Wrap the rotation in `try { await _rotate(dir, file); } on FileSystemException { /* keep extra files */ }` inside `write`, or in the `_rotate` delete loop.

### WR-06: The goal on-open evaluator can raise the notification permission prompt at app launch, contradicting the stated "never at launch" design

**File:** `lib/config/startup/notification_startup.dart:32`, `lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart:46`, `lib/application/notifications/goal_alert_evaluator.dart:57-58`
**Issue:** `startNotifications()` documents that it never prompts (Pitfall 10), but it runs `GoalAlertEvaluator.evaluateOnOpen()` on cold start. When any goal is off track (the kind is on by default), `dispatch` calls `_gate.ensureAsked()`. That raises the system permission dialog over the first frame, with no user context. The marker `gf:<goal>:<week>` is written before dispatch (line 57). If the user denies the prompt or the gateway call fails, that goal's alert is suppressed for the whole week.

**Fix:** Do not call `ensureAsked()` from the on-open path. Dispatch only if `notificationPermission() == granted`, and leave the prompt to the reconcile path or the settings screen. Write the week marker only after `dispatch` returns true.

### WR-07: The "Allow" banner button is a no-op once the OS permission is permanently denied

**File:** `lib/application/notifications/notification_settings_cubit.dart:102-106`, `lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart:56`
**Issue:** `requestPermission()` calls `requestNotificationsPermission()`. On Android 13+ after the second denial, and always on iOS after the first denial, the OS shows no dialog and returns false. The banner stays and the button silently does nothing. The settings screen offers no route to the system settings. Users who denied once cannot recover from inside the app.

**Fix:** If the permission is still denied after the request, open the app notification settings. `flutter_local_notifications` has no API for this, so use a small platform channel or a `permission_handler`-free intent, and change the banner label to "Open settings".

### WR-08: Picked files are never cleaned from the plugin cache, and the size cap is per file only

**File:** `lib/infrastructure/backup/file_picker_backup_file_gateway.dart:46-66`, `lib/data/backup/import/snapshot_parser.dart:36-40`
**Issue:** `FilePicker.pickFiles` copies every picked file into the app cache directory. Nothing calls `FilePicker.clearTemporaryFiles()`. A user's complete financial CSV or JSON stays on disk indefinitely. The limit of 25 MiB is applied per file, but `allowMultiple: true` has no count limit and no aggregate limit. Six or more large CSVs are read fully into memory as bytes and then again as UTF-16 strings, which risks an out-of-memory crash on low-end devices.

**Fix:** After reading the bytes (in a `finally`), call `await FilePicker.clearTemporaryFiles()`. Cap the file count (for example 6, one per entity) and the total size, and reject with `tooLarge` before reading.

### WR-09: CSV `amount_cents` silently overrides an edited `amount` column

**File:** `lib/data/backup/csv/csv_row_reader.dart:97-104`
**Issue:** CSV exists so users can edit it in a spreadsheet. When both `amount` and `amount_cents` are present, the integer cents cell is authoritative and `amount` is ignored without any warning. A user who corrects the human-readable amount, which is the column they see, imports the old value and nothing in the preview reveals it. The preview shows only counts.

**Fix:** When both are present and disagree, fail the row with a clear message (`amount and amount_cents disagree`), or prefer `amount` when it differs. At minimum, count disagreements and surface them in the preview.

## Info

### IN-01: Invisible U+FEFF literals in source

**File:** `lib/data/backup/import/snapshot_parser.dart:45`, `lib/data/backup/csv/csv_format.dart:3`
**Issue:** The BOM is written as a raw invisible character inside a string literal. It is easy to lose through an editor or formatter, and prompt-injection scanners flag it.
**Fix:** Use the escape sequence `'\uFEFF'`.

### IN-02: `_clip` can split a UTF-16 surrogate pair

**File:** `lib/infrastructure/notifications/content/notification_content_builder.dart:9-12`, `lib/domain/notifications/planner/briefing_planner.dart:83-86`
**Issue:** `substring(0, n)` on user titles can cut an emoji in half. The result is a lone surrogate, which the platform channel renders as U+FFFD.
**Fix:** Clip on `text.runes` or `characters` (`package:characters`).

### IN-03: `NotificationPrefsRepositoryImpl.load()` has a write side effect and a race on the seed

**File:** `lib/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart:108-114`
**Issue:** `load()` creates a random seed and persists it with `unawaited(setInt)`. Two `load()` calls before the first write lands (for example the reconciler and the budget evaluator at startup) produce different seeds. Quote text can differ between runs and cause one spurious reschedule.
**Fix:** Generate and `await` the seed in an explicit init step, or cache the generated value in memory.

### IN-04: `NotificationSyncCoordinator._enqueue` single-flight has a narrow window

**File:** `lib/infrastructure/notifications/sync/notification_sync_coordinator.dart:96-113`
**Issue:** `_active` is cleared in `whenComplete`, which is registered before the queued `then`. In the gap, a new `_enqueue` that sees `_active == null` starts a run while `_queued` is still set. Two runs can then execute at the same time. The idempotent diff makes this benign, but the stated single-flight guarantee (T-04-12-04) does not hold exactly.
**Fix:** Chain on a single tail future, for example `_tail = _tail.then((_) => _execute())`, and drop the `_active` and `_queued` pair.

### IN-05: Reseed after import clears markers even when the kind is off

**File:** `lib/application/notifications/goal_alert_evaluator.dart:65-69`, `lib/application/notifications/budget_alert_evaluator.dart:82-87`
**Issue:** Both `reseedAfterImport` methods delete the markers and return early without seeding while the kind is disabled. If the user later enables the kind, every already-crossed budget and every off-track goal alerts at once, which is the "alert storm" the reseed was meant to prevent.
**Fix:** Seed the markers regardless of the toggle, or keep the seeded flag when the kind is off.

### IN-06: Notification text is shown in full on the iOS lock screen

**File:** `lib/infrastructure/notifications/gateway/notification_channels.dart:99-106`
**Issue:** The Android channel sets `NotificationVisibility.private`, but iOS has no equivalent in these details. Task titles, debt titles, goal names and budget category names appear on the lock screen according to the user's global iOS setting. No amounts are included, which is good.
**Fix:** Document this in the privacy note, or offer a "hide content" option that sends generic text on iOS.

### IN-07: `bootstrapTimezone()` re-parses the full tz database on every resume

**File:** `lib/infrastructure/notifications/gateway/timezone_bootstrap.dart:19`
**Issue:** `tzdata.initializeTimeZones()` runs on every `resumed` event, together with a reconcile request. Initialization only needs to happen once.
**Fix:** Guard with a static `_initialized` flag and only refresh `setLocalLocation` on resume.

### IN-08: The snapshot validator accepts out-of-scheme ids and unbounded dates

**File:** `lib/data/backup/import/snapshot_validator.dart:39-48,64-91`
**Issue:** Negative, zero or very large explicit ids are accepted, and so are dates such as year 0001 or 9999. Ids above `maxNotificationEntityId` (999,999) silently get no reminders, because every planner skips them. A task due in year 9999 is still processed by the planners.
**Fix:** Reject ids outside `0..maxNotificationEntityId`, or warn in the preview, and bound the accepted year range (for example 1970 to 2200).

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
