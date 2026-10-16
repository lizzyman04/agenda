---
phase: 04-notifications-backup
plan: 16
subsystem: backup-export-ui
tags: [flutter_bloc, cubit, injectable, file_picker, backup, csv, json, l10n]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-04 and 04-08 BackupRepository.exportJson / exportCsv and BackupFile"
  - phase: 04-notifications-backup
    provides: "04-05 confirmed file_picker 11.0.2 API (static FilePicker.saveFile / pickFiles)"
  - phase: 04-notifications-backup
    provides: "04-11 maxImportFileBytes (25 MiB cap)"
  - phase: 04-notifications-backup
    provides: "04-15 TaskListSettingsMenu and TaskListSettingsDestination"
  - phase: 04-notifications-backup
    provides: "04-02 backup* strings"
provides:
  - "BackupFileGateway (domain interface: saveFile, pickFiles) and FilePickerBackupFileGateway (the only file_picker user)"
  - "BackupCubit.exportJson / exportCsv / acknowledge and BackupState (Idle, Working, ExportDone, ExportCancelled, Failed)"
  - "BackupScreen and BackupActionCard: standalone page with export actions and the privacy and reinstall notes"
  - "TaskListSettingsDestination.backup: second entry in the temporary overflow menu"
affects: [04-17, phase-05-settings]

plan_head_before: 67da7b58b83b9c5aaed018ae9071a40aae4abf0a
commits: 3
actuals:
  tokens: 10000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "File picker isolated behind a domain gateway; the cubit depends on the interface only"
    - "Export loop: one saveFile per file in order, stop at the first cancel and report the saved count"
    - "Page-local cubit via BlocProvider(create: getIt); outcome snackbar from a BlocConsumer listener, then acknowledge()"

key-files:
  created:
    - lib/domain/backup/backup_file_gateway.dart
    - lib/infrastructure/backup/file_picker_backup_file_gateway.dart
    - lib/application/backup/backup_state.dart
    - lib/application/backup/backup_cubit.dart
    - lib/application/backup/README.md
    - lib/presentation/backup/README.md
    - lib/presentation/backup/screens/README.md
    - lib/presentation/backup/screens/backup_screen.dart
    - lib/presentation/backup/widgets/README.md
    - lib/presentation/backup/widgets/backup_action_card.dart
    - test/application/backup/backup_cubit_test.dart
    - test/presentation/backup/backup_screen_test.dart
  modified:
    - lib/presentation/tasks/widgets/task_list_settings_menu.dart
    - lib/presentation/tasks/widgets/README.md
    - lib/config/di/injection.config.dart
    - test/presentation/tasks/task_list_settings_menu_test.dart

key-decisions:
  - "pickFiles reads each chosen file from the plugin cache path with dart:io after checking PlatformFile.size against maxImportFileBytes, and never loads data in the picker (withData stays at its false default)"
  - "saveFile always passes bytes plus fileName; a null path from the plugin means the user cancelled"
  - "Gateway failures carry only the exception type (saveFailed / pickFailed / tooLarge / readFailed), never a file name or content"
  - "The cubit ignores export requests while already Working, so a double tap cannot open two dialog sequences"

requirements-completed: [DATA-02, DATA-03]

coverage:
  - id: D1
    description: "JSON export runs repository -> one save dialog with saved, cancelled and failed outcomes mapped to states"
    requirement: "DATA-02"
    verification:
      - kind: unit
        ref: "test/application/backup/backup_cubit_test.dart#BackupCubit.exportJson"
        status: pass
    human_judgment: false
  - id: D2
    description: "CSV export saves the six files in order, stops at the first cancel with the saved count, and maps errors to Failed"
    requirement: "DATA-03"
    verification:
      - kind: unit
        ref: "test/application/backup/backup_cubit_test.dart#BackupCubit.exportCsv"
        status: pass
    human_judgment: false
  - id: D3
    description: "Backup screen: both cards in PT-BR, locale code passed to CSV, cards disabled while Working, snackbars for Done and Failed, privacy and reinstall notes visible"
    requirement: "DATA-02"
    verification:
      - kind: unit
        ref: "test/presentation/backup/backup_screen_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Backup reachable from the task list overflow menu"
    verification:
      - kind: unit
        ref: "test/presentation/tasks/task_list_settings_menu_test.dart#selecting Backup opens the backup page"
        status: pass
    human_judgment: false
  - id: D5
    description: "Real system save dialogs, scoped storage on Android, valid JSON content and spreadsheet rendering (accents, PT-BR decimal comma) of the saved files"
    verification: []
    human_judgment: true
    rationale: "System save dialogs and scoped storage cannot run on the host VM; the plugin and the spreadsheet rendering need a device (assumptions A5 and A8). The gateway has no unit test because FilePicker is a static plugin call."

duration: 14 min
completed: 2026-10-16
---

# Phase 4 Plan 16: Backup export UI Summary

**A file-picker gateway behind a domain interface, a `BackupCubit` that exports the full JSON backup (one save dialog) and the six CSV files (one dialog each, stopping cleanly on cancel), and a self-contained Backup screen with the unencrypted-file and reinstall notes, reachable from a second entry in the temporary task-list overflow menu.**

## Performance

- **Duration:** 14 min (2026-10-16T08:19:53Z to 08:33:05Z, before SUMMARY authoring)
- **Tasks:** 3 of 3
- **Files:** 16 (12 created, 4 modified)

## Accomplishments

- `BackupFileGateway` (domain) and `FilePickerBackupFileGateway` (infrastructure, `@LazySingleton`). `grep -rn "package:file_picker" lib` matches only `lib/infrastructure/backup`. `pickFiles` is ready for plan 04-17: it rejects any file above the 25 MiB cap from `PlatformFile.size` before reading, then reads from the plugin cache path.
- `BackupCubit` (injectable factory) with `exportJson`, `exportCsv` and `acknowledge`. Outcomes: `Done(fileCount, csv)`, `Cancelled(savedCount)`, `Failed(failure)`. A cancel at the third CSV dialog emits `Cancelled(2)` and does not offer files four to six.
- `BackupScreen` provides its own cubit and shows the JSON and CSV `BackupActionCard`s (disabled with a `LinearProgressIndicator` and `backupWorking` text while exporting), then `backupPrivacyNote` and `backupReinstallNote` (D-13). The CSV card passes the app language code, so the file dialect follows PT-BR or EN. Failures show only `backupErrorGeneric`.
- `TaskListSettingsMenu` gained the Backup entry (`Icons.backup_outlined`, `backupMenuLabel`); the notifications entry is unchanged.
- READMEs for `application/backup`, `presentation/backup`, `screens/` and `widgets/`; the tasks widgets README row is updated.
- 785/785 tests pass; `flutter analyze --no-fatal-infos --fatal-warnings` exits 0 with 64 issues (budget 65, one fewer than before); architecture guard passes; DI registers `BackupCubit` and the gateway.

## Task Commits

1. **Task 1 (tracer): cubit exports JSON through a file-picker gateway** - `1f3b95f` (feat)
2. **Task 2: CSV export flow and Backup screen** - `7632d21` (feat)
3. **Task 3: Backup entry in the overflow menu** - `230a7ab` (feat)

Tracer feedback gate: `workflow.auto_advance` is false, `human_verify_mode` is `end-of-phase` and the tracer's `<verify>` is automated-only, so its tests, analyzer and architecture guard were run on the committed state and passed before Task 2 ("Tracer verified end-to-end").

**Plan metadata:** committed with this SUMMARY (docs: complete plan).

## Decisions Made

- The gateway keeps `FilePicker.pickFiles` at its defaults for `type` (any) and `withData` (false) rather than passing them: the analyzer's `avoid_redundant_argument_values` flags explicit defaults, and the intent is recorded in a comment.
- `DI regeneration` ran after Task 1 (when the cubit and gateway first existed) and was committed there; the Task 3 run changed nothing further.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Menu row overflowed in PT-BR with the new Backup label**
- **Found during:** Task 3 (full test run)
- **Issue:** The popup `Row` overflowed by 62 px with the longer `backupMenuLabel`; the menu test failed with a RenderFlex overflow.
- **Fix:** Wrapped both menu labels in `Flexible`.
- **Files modified:** `lib/presentation/tasks/widgets/task_list_settings_menu.dart`
- **Verification:** `flutter test --no-pub` 785/785.
- **Commit:** `230a7ab`

**2. [Rule 3 - Blocking] Analyzer budget would have gone to 66**
- **Found during:** Task 3
- **Issue:** The second `Navigator.push` added a `discarded_futures` info on top of the 65-issue budget.
- **Fix:** Wrapped both pushes in `unawaited(...)`, which also removed the pre-existing one (64 issues).
- **Files modified:** `lib/presentation/tasks/widgets/task_list_settings_menu.dart`
- **Commit:** `230a7ab`

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). **Impact:** none on scope; the menu file is 69 lines.

## Authentication Gates

None.

## Issues Encountered

- `flutter test` prints a Linux desktop toolchain warning (clang, cmake, GTK); it is unrelated to this plan.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub` (full suite) | 785/785 pass |
| `flutter test --no-pub test/application/backup test/presentation/backup` | 16/16 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65) |
| `dart run build_runner build --delete-conflicting-outputs` | exit 0; `BackupCubit` in `injection.config.dart` |
| `dart run tool/check_architecture.dart` | PASS |
| `grep -rn "package:file_picker" lib` | only `lib/infrastructure/backup/file_picker_backup_file_gateway.dart` |
| READMEs exist for `application/backup`, `presentation/backup/screens`, `presentation/backup/widgets` | yes |

## Human verification outstanding

- Android device: Tasks > settings menu > Backup and restore. Export the full backup (JSON), save to Downloads; then export the spreadsheets (CSV) and save all six files. Open the JSON and a CSV in another app. Expect one save dialog for JSON and six for CSV, valid JSON containing every task and transaction, a CSV that opens with correct accents and the PT-BR decimal comma, and the cancelled message when a dialog is dismissed.

## Threat Flags

None beyond the plan's register. T-04-16-01 is accepted (the unencrypted note is on screen); T-04-16-02 (size checked before reading, no picker data loading) and T-04-16-03 (picked names only used as labels, paths come from the plugin cache path) are implemented in the gateway. The gateway has no unit test: `FilePicker` is a static plugin call, so those two mitigations are verified by code review and the device check.

## Known Stubs

None.

## Next Phase Readiness

Plan 04-17 can add import actions to `BackupCubit` and `BackupScreen`: `BackupFileGateway.pickFiles` already enforces the size cap and returns `List<BackupFile>?`. `lib/presentation/backup/screens/backup_screen.dart` is 106 lines, so the import controls will need a split to stay under the 150-line cap.

## Self-Check: PASSED

All 12 created files verified on disk; commits `1f3b95f`, `7632d21`, `230a7ab` present.
