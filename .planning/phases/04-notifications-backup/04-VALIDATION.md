---
phase: "4"
slug: "notifications-backup"
status: planned
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-12"
updated: "2026-10-12"
---

# Phase 4 - Validation Strategy

> Per-phase validation contract. Full requirement-to-test map also lives in `04-RESEARCH.md` section "Validation Architecture"; this file maps every PLAN task to its automated command.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test 10.0.0 + mocktail 1.0.5; real Isar via `test/support/isar_test_harness.dart` |
| **Config file** | none (`analysis_options.yaml`, `l10n.yaml`) |
| **Quick run command** | `flutter test --no-pub test/domain/notifications test/data/backup` |
| **Full suite command** | `flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` |
| **Real-Isar tests** | add `-j 1` (isar core download race, see harness header); CI pre-warms the binary |
| **Analyzer budget** | no more than 65 issues (baseline measured 2026-10-12: 65 infos, guard PASS); new code adds zero |
| **Estimated runtime** | ~30 s quick, several minutes full |

## Sampling Rate

- **After every task commit:** the task's own command below + `dart run tool/check_architecture.dart`
- **After every plan wave:** full suite command
- **Before `/gsd-verify-work`:** full suite green
- **Max feedback latency:** 30 seconds for pure-rule tasks; real-Isar and build_runner tasks run longer (accepted, same as Phase 03 plans)

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Behavior verified | Test type | Automated command | File |
|---------|------|------|-------------|-------------------|-----------|-------------------|------|
| 04-01-T1 | 01 | 1 | DATA-03, DATA-04 | csv 8.0.0 identity confirmed by a human before pub get (blocking-human checkpoint, never auto-approved) | checkpoint | n/a (human reply recorded in SUMMARY) | - |
| 04-02-T1 | 02 | 1 | NOTF-01..08 | channel + notification-content strings resolve in PT-BR and EN, plurals, no amounts | unit | `flutter gen-l10n && flutter test --no-pub test/l10n` | test/l10n/phase4_strings_test.dart |
| 04-02-T2 | 02 | 1 | NOTF-09, NOTF-10, DATA-02..04 | settings + backup/import strings, ARB parity, analyzer budget | unit | `flutter gen-l10n && flutter test --no-pub test/l10n && flutter analyze --no-fatal-infos --fatal-warnings` | test/l10n/phase4_strings_test.dart |
| 04-03-T1 | 03 | 1 | NOTF-10, NOTF-11 | quiet-hours boundaries (22:00 in, 07:00 out, overnight wrap), id grid uniqueness, ScheduleDiff add/cancel/replace/idempotent | unit | `flutter test --no-pub test/domain/notifications/scheduling_pipeline_test.dart && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/scheduling_pipeline_test.dart |
| 04-03-T2 | 03 | 1 | NOTF-01, NOTF-11 | day math, payload grammar round trip + malformed -> null, slot budget caps and truncation | unit | `flutter test --no-pub test/domain/notifications/day_math_test.dart test/domain/notifications/payload_codec_test.dart test/domain/notifications/slot_budget_test.dart && flutter analyze lib/domain/notifications lib/core/constants test/domain/notifications` | test/domain/notifications/{day_math,payload_codec,slot_budget}_test.dart |
| 04-03-T3 | 03 | 1 | NOTF-09, NOTF-10 | disabled kind never planned, past dropped, quiet-hours deferral, de-dup, budget | unit | `flutter test --no-pub test/domain/notifications && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/reminder_planner_test.dart |
| 04-04-T1 | 04 | 1 | DATA-02 | items export through DAO -> codec -> envelope on 600 real rows incl. soft-deleted; strict reader errors | unit + real-Isar | `flutter test --no-pub -j 1 test/data/backup/json_fields_test.dart test/data/backup/export_items_test.dart` | test/data/backup/{json_fields,export_items}_test.dart |
| 04-04-T2 | 04 | 1 | DATA-02 | transaction/category/budget/goal codecs round trip; growable contributions; readAll one txn | real-Isar | `flutter test --no-pub -j 1 test/data/backup && flutter analyze lib/data/backup lib/infrastructure/backup test/data/backup` | test/data/backup/json_roundtrip_test.dart |
| 04-04-T3 | 04 | 1 | DATA-02 | all seven collections exported uncapped incl. soft-deleted; DI resolves repository | real-Isar + DI | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub -j 1 test/data/backup test/config/di && flutter analyze --no-fatal-infos --fatal-warnings` | test/data/backup/export_completeness_test.dart |
| 04-05-T1 | 05 | 2 | NOTF-11, DATA-03, DATA-04 | five pins resolve; manifest permissions/receivers/allowBackup=false/rules XML/desugaring contract | static contract | `flutter pub get && flutter test --no-pub test/infrastructure/notifications/manifest_contract_test.dart` | test/infrastructure/notifications/manifest_contract_test.dart |
| 04-05-T2 | 05 | 2 | NOTF-11 | AppDelegate delegate line; packages compile at real API names; offline timezone data | static + smoke | `flutter test --no-pub test/infrastructure/notifications && flutter analyze --no-fatal-infos --fatal-warnings` | test/infrastructure/notifications/dependency_smoke_test.dart |
| 04-06-T1 | 06 | 2 | NOTF-01, NOTF-04 | due-30min, date-only at briefing hour, past dropped, recurring kind, toggle, DST-safe | unit | `flutter test --no-pub test/domain/notifications/task_reminder_planner_test.dart && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/task_reminder_planner_test.dart |
| 04-06-T2 | 06 | 2 | NOTF-02 | briefing count + top 3, skip empty/past days, horizon 7, quiet-hours shift | unit | `flutter test --no-pub test/domain/notifications && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/briefing_planner_test.dart |
| 04-07-T1 | 07 | 2 | NOTF-05, NOTF-07 | debt day-before 09:00 once, skip past/paid/deleted; Jan-31 clamp; stale nextDueDate stepping | unit | `flutter test --no-pub test/domain/notifications/effective_due_date_test.dart test/domain/notifications/finance_reminder_planners_test.dart && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/{effective_due_date,finance_reminder_planners}_test.dart |
| 04-07-T2 | 07 | 2 | NOTF-06 | off-track boundary (exactly 10 points is on track), no deadline never, one per week, fired marker skip | unit | `flutter test --no-pub test/domain/notifications/goal_off_track_test.dart && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/goal_off_track_test.dart |
| 04-07-T3 | 07 | 2 | NOTF-08 | default OFF, deterministic non-repeating slots, daily/weekly, 50+ unique quotes per language | unit | `flutter test --no-pub test/domain/notifications && flutter analyze lib/domain/notifications test/domain/notifications` | test/domain/notifications/quote_planner_test.dart |
| 04-08-T1 | 08 | 3 | DATA-03 | transactions CSV dialects (PT `;`/`,`, EN `,`/`.`), BOM, CRLF, lossless injection guard | unit | `flutter test --no-pub test/data/backup/csv_primitives_test.dart && flutter analyze lib/data/backup lib/domain/backup lib/infrastructure/backup test/data/backup` | test/data/backup/csv_primitives_test.dart |
| 04-08-T2 | 08 | 3 | DATA-04 | strict amount parser (no sign flip, rejects 1.250), date parse, delimiter sniff, row reader, 3 mappers | unit | `flutter test --no-pub test/data/backup/csv_decode_test.dart test/data/backup/csv_primitives_test.dart && flutter analyze lib/data/backup test/data/backup` | test/data/backup/csv_decode_test.dart |
| 04-08-T3 | 08 | 3 | DATA-03, DATA-04 | six mappers round trip both dialects; six files, 600 active rows each, soft-deleted excluded | unit + real-Isar | `flutter test --no-pub -j 1 test/data/backup && flutter analyze --no-fatal-infos --fatal-warnings` | test/data/backup/{csv_roundtrip,csv_export}_test.dart |
| 04-09-T1 | 09 | 1 | NOTF-01, NOTF-02, NOTF-04 | soonest-N sorted before limit on 700 rows; window read uncapped (650); exclusions | real-Isar | `flutter test --no-pub -j 1 test/data/tasks/item_reminder_queries_test.dart test/widget_test.dart && flutter analyze lib/data/tasks lib/domain/tasks lib/infrastructure/tasks test/data/tasks` | test/data/tasks/item_reminder_queries_test.dart |
| 04-09-T2 | 09 | 1 | NOTF-03 | BudgetRepository.watchChanges emits after a write; shell test compiles | real-Isar + widget | `flutter test --no-pub -j 1 test/data/finance/reactive_watch_test.dart test/application/finance/budget_cubit_test.dart test/widget_test.dart` | test/data/finance/reactive_watch_test.dart |
| 04-09-T3 | 09 | 1 | NOTF-07 | RecurringPaymentRepository.watchChanges; full suite green | real-Isar + suite | `flutter test --no-pub -j 1 test/data/finance test/widget_test.dart && flutter analyze --no-fatal-infos --fatal-warnings` | test/data/finance/reactive_watch_test.dart |
| 04-10-T1 | 10 | 3 | NOTF-09, NOTF-10 | prefs defaults (quotes OFF), persistence across instances, watch, clamp, stable seed | unit | `flutter test --no-pub test/infrastructure/notifications/notification_prefs_repository_test.dart && flutter analyze lib/domain/notifications lib/infrastructure/notifications lib/core/constants test/infrastructure/notifications` | test/infrastructure/notifications/notification_prefs_repository_test.dart |
| 04-10-T2 | 10 | 3 | NOTF-11 | alert-state store idempotence; channel ids `_v1`, one per kind, private visibility | unit | `flutter test --no-pub test/infrastructure/notifications && flutter analyze lib/domain/notifications lib/infrastructure/notifications test/infrastructure/notifications` | test/infrastructure/notifications/{alert_state_store,notification_channels}_test.dart |
| 04-10-T3 | 10 | 3 | NOTF-01, NOTF-11 | gateway/permission/tz compile and register; startup hook; no permission prompt at init | DI + suite | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub test/config test/infrastructure/notifications test/widget_test.dart && flutter analyze --no-fatal-infos --fatal-warnings` | test/config/di/di_test.dart |
| 04-11-T1 | 11 | 4 | DATA-04 | single-transaction replace, rollback on unique-key failure, auto-increment after explicit ids (A4), partial CSV mode | real-Isar | `flutter test --no-pub -j 1 test/data/backup/import_atomicity_test.dart && flutter analyze lib/data/backup lib/domain/backup test/data/backup` | test/data/backup/import_atomicity_test.dart |
| 04-11-T2 | 11 | 4 | DATA-04 | parser gating (app, version, size, mixed, duplicate), validator rules, preview counts/date range | unit | `flutter test --no-pub test/data/backup/snapshot_parser_test.dart test/data/backup/snapshot_validator_test.dart && flutter analyze lib/data/backup lib/domain/backup test/data/backup` | test/data/backup/{snapshot_parser,snapshot_validator}_test.dart |
| 04-11-T3 | 11 | 4 | DATA-04 | safety backup rotation (keep 3), CSV category resolution, prepare/commit flow, failed import unchanged | real-Isar | `flutter test --no-pub -j 1 test/data/backup && flutter analyze --no-fatal-infos --fatal-warnings` | test/data/backup/{safety_backup_store,import_flow}_test.dart |
| 04-12-T1 | 12 | 4 | NOTF-01, NOTF-02, NOTF-05, NOTF-07 | load -> plan -> localise -> diff -> apply; idempotent second run; aborted load cancels nothing | unit (fakes) | `flutter test --no-pub test/infrastructure/notifications && flutter analyze lib/infrastructure/notifications lib/config test/infrastructure/notifications` | test/infrastructure/notifications/{notification_content_builder,snapshot_loader,reconcile_runner}_test.dart |
| 04-12-T2 | 12 | 4 | NOTF-11, NOTF-06 | permission asked once in context; non-owned alerts preserved; exact-mode upgrade; goal week markers | unit (fakes) | `flutter test --no-pub test/infrastructure/notifications/reconcile_runner_test.dart && flutter analyze lib/infrastructure/notifications test/infrastructure/notifications` | test/infrastructure/notifications/reconcile_runner_test.dart |
| 04-12-T3 | 12 | 4 | NOTF-11 | debounce + single-flight coordinator, start subscribes, dispose; startup + lifecycle | unit + DI | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub test/infrastructure/notifications test/config test/widget_test.dart && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` | test/infrastructure/notifications/notification_sync_coordinator_test.dart |
| 04-13-T1 | 13 | 4 | NOTF-01, NOTF-02 | tap target mapping; listener navigation incl. missing entity and cold-start payload | unit + widget | `flutter test --no-pub test/domain/notifications/tap_target_test.dart test/presentation/notifications/notification_tap_listener_test.dart && flutter analyze lib/domain/notifications lib/presentation/notifications lib/presentation/shell test/presentation/notifications` | test/presentation/notifications/notification_tap_listener_test.dart |
| 04-13-T2 | 13 | 4 | NOTF-03, NOTF-05, NOTF-06 | shell extraction keeps NavigationBar test green; app.dart under cap; locale reconcile hook | widget | `flutter test --no-pub test/widget_test.dart test/presentation && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` | test/widget_test.dart |
| 04-14-T1 | 14 | 5 | NOTF-03, NOTF-10 | thresholds 79/80/99/100/101; dispatcher quiet-hours defer vs show; evaluator once-per-month | unit (fakes) | `flutter test --no-pub test/domain/notifications/budget_threshold_test.dart test/infrastructure/notifications/immediate_alert_dispatcher_test.dart test/application/notifications/budget_alert_evaluator_test.dart && flutter analyze lib/application/notifications lib/domain/notifications lib/infrastructure/notifications test/application/notifications` | test/application/notifications/budget_alert_evaluator_test.dart |
| 04-14-T2 | 14 | 5 | NOTF-03, NOTF-06 | silent seeding, key pruning, goal on-open once per week, post-import reseed | unit (fakes) | `flutter test --no-pub test/application/notifications && flutter analyze lib/application/notifications test/application/notifications` | test/application/notifications/{budget,goal}_alert_evaluator_test.dart |
| 04-14-T3 | 14 | 5 | NOTF-03, NOTF-06 | startup wiring, DI regenerated, whole suite | DI + suite | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` | test/config/di/di_test.dart |
| 04-15-T1 | 15 | 6 | NOTF-09 | per-kind switch persists (save before emit), permission requested when enabling, waiting count | bloc + widget | `flutter test --no-pub test/application/notifications/notification_settings_cubit_test.dart test/presentation/notifications/notification_settings_screen_test.dart && flutter analyze lib/application/notifications lib/presentation/notifications test/application/notifications test/presentation/notifications` | test/application/notifications/notification_settings_cubit_test.dart |
| 04-15-T2 | 15 | 6 | NOTF-08, NOTF-10 | briefing/quote/quiet controls, banners (denied, exact on Android), waiting text | widget | `flutter test --no-pub test/presentation/notifications && flutter analyze lib/presentation/notifications test/presentation/notifications && dart run tool/check_architecture.dart` | test/presentation/notifications/notification_settings_screen_test.dart |
| 04-15-T3 | 15 | 6 | NOTF-09 | overflow menu entry, task_list_screen under cap, DI regenerated, suite | widget + suite | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` | test/presentation/tasks/task_list_settings_menu_test.dart |
| 04-16-T1 | 16 | 7 | DATA-02 | JSON export flow states (done, cancelled, failed) via gateway interface | bloc | `flutter test --no-pub test/application/backup/backup_cubit_test.dart && flutter analyze lib/domain/backup lib/infrastructure/backup lib/application/backup test/application/backup` | test/application/backup/backup_cubit_test.dart |
| 04-16-T2 | 16 | 7 | DATA-02, DATA-03 | CSV six-save flow with cancel at third dialog; Backup screen buttons, disabled while working | bloc + widget | `flutter test --no-pub test/application/backup test/presentation/backup && flutter analyze lib/application/backup lib/presentation/backup test/application/backup test/presentation/backup && dart run tool/check_architecture.dart` | test/presentation/backup/backup_screen_test.dart |
| 04-16-T3 | 16 | 7 | DATA-02, DATA-03 | menu entry to Backup, DI regenerated, suite | widget + suite | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` | test/presentation/tasks/task_list_settings_menu_test.dart |
| 04-17-T1 | 17 | 8 | DATA-04 | prepare/confirm/commit states; post-import hook order and isolation; safety path on failure | bloc | `flutter test --no-pub test/application/backup && flutter analyze lib/application/backup test/application/backup` | test/application/backup/backup_cubit_import_test.dart |
| 04-17-T2 | 17 | 8 | DATA-04 | confirmation screen counts/date range/warnings/partial note; error text per code | widget | `flutter test --no-pub test/presentation/backup && flutter analyze lib/presentation/backup test/presentation/backup && dart run tool/check_architecture.dart` | test/presentation/backup/import_confirm_screen_test.dart |
| 04-17-T3 | 17 | 8 | DATA-04 | import entry + result snackbars; DI regenerated; full suite | widget + suite | `dart run build_runner build --delete-conflicting-outputs && flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` | test/presentation/backup/backup_screen_test.dart |

## Wave 0 Requirements

Test scaffolds are created inside the plan tasks that need them (no separate Wave 0 plan):

- [ ] `test/domain/notifications/*_test.dart` - pure rule tests (plans 03, 06, 07, 13, 14)
- [ ] `test/infrastructure/notifications/fake_notification_gateway.dart` - in-memory gateway + permission fake (plan 10)
- [ ] `test/data/backup/` - real-Isar round-trip, atomicity, 600-row seeds (plans 04, 08, 11)
- [ ] `test/infrastructure/notifications/manifest_contract_test.dart` (plan 05)
- [ ] `test/widget_test.dart` stub updates for the new repository members (plans 09, 13)
- [ ] Spike (compile-only): confirmed plugin / file_picker / csv / TimezoneInfo API names (plan 05 smoke test + SUMMARY table); Isar auto-increment after explicit-id `putAll` (A4, plan 11 Task 1)

## Manual-Only Verifications

All of these are carried as `<verify><human-check>` blocks in the plans and harvested into the end-of-phase UAT.

| Behavior | Requirement | Plan | Why Manual | Test Instructions |
|----------|-------------|------|------------|-------------------|
| Debug APK builds and launches (manifest merge, desugaring) | NOTF-11 | 05 | Android SDK licences + device | `flutter build apk --debug`, install, launch |
| iOS project compiles with the delegate edit | NOTF-11 | 05 | No Xcode on Linux host | Build in Xcode |
| Reminder fires 30 min before due; survives reboot and swipe-kill | NOTF-01, NOTF-11 | 12 | Physical device | Task due in 35 min; reboot; confirm fire |
| Time zone change re-times reminders | NOTF-01 | 12 | Device clock | Change zone, reopen |
| Tap opens the right screen (warm and cold start) | NOTF-01..07 | 13 | Real notification | Tap task/briefing/debt notifications |
| Budget alerts 80/100, once per month, deferred in quiet hours | NOTF-03, NOTF-10 | 14 | Real clock + delivery | Add transactions to cross thresholds |
| Permission deny/grant, exact alarm, quiet hours, quotes | NOTF-08..10 | 15 | OS dialogs | Walk the settings page |
| iOS more than 64 pending items | NOTF-09 | 15, 17 | No Xcode on host | Human UAT on an iOS device |
| JSON/CSV export saved via system dialog, opens in other apps | DATA-02, DATA-03 | 16 | Scoped storage, spreadsheet apps | Export to Downloads and open |
| Import confirm, restore, corrupted file, CSV partial, safety backup folder | DATA-04 | 17 | File picker + app-private dir | Walk the import flow |
| Auto Backup is off; reinstall needs the JSON | DATA-04 (D-13) | 17 | Device backup manager | `adb shell dumpsys backup` |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or an explicit blocking-human checkpoint (04-01-T1)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (created inside plan tasks, listed above)
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending plan-checker
