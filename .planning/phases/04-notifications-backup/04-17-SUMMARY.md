---
phase: 04-notifications-backup
plan: 17
subsystem: backup-import-ui
tags: [flutter_bloc, cubit, backup, import, confirmation, l10n, post-import-hooks]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-11 BackupRepository.prepareImport / commitImport / discardImport / lastSafetyBackupPath, ImportPreview, ImportResult, ImportErrorCode, importErrorCodeOf"
  - phase: 04-notifications-backup
    provides: "04-12 NotificationReconciler.reconcileNow(ReconcileReason.afterImport)"
  - phase: 04-notifications-backup
    provides: "04-14 BudgetAlertEvaluator / GoalAlertEvaluator.reseedAfterImport"
  - phase: 04-notifications-backup
    provides: "04-16 BackupCubit, BackupState, BackupScreen, BackupActionCard, BackupFileGateway.pickFiles"
  - phase: 04-notifications-backup
    provides: "04-02 backup* strings"
provides:
  - "BackupCubit.pickAndPrepareImport / confirmImport / cancelImport and the states BackupImportPreviewReady, BackupImportDone, BackupImportFailed"
  - "runPostImportHooks: budget reseed, goal reseed, afterImport reconcile, each isolated by its own try/catch"
  - "ImportConfirmScreen, ImportSummaryCard, backupErrorMessage, backupOutcomeMessage"
  - "Import card on the Backup screen; DI regenerated for the three new cubit dependencies"
affects: [phase-05-settings, phase-04-verification]

plan_head_before: c5365a6b7f84ae71b12e448ee4384a3e09b618a9
commits: 3
actuals:
  tokens: 16000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Prepare / confirm / commit import: nothing is written until the confirmation screen's confirm button"
    - "Post-import hooks in a standalone function, each in its own try/catch, so a hook failure never masks a successful import"
    - "Confirmation screen closes via ModalRoute.isCurrent guard so the Idle that follows an acknowledge cannot pop a second route"
    - "Error text chosen by ImportErrorCode; raw Failure.message is never displayed"

key-files:
  created:
    - lib/application/backup/post_import_hooks.dart
    - lib/presentation/backup/screens/import_confirm_screen.dart
    - lib/presentation/backup/widgets/import_summary_card.dart
    - lib/presentation/backup/widgets/backup_error_text.dart
    - lib/presentation/backup/widgets/backup_outcome_message.dart
    - test/application/backup/backup_cubit_import_test.dart
    - test/presentation/backup/import_confirm_screen_test.dart
  modified:
    - lib/application/backup/backup_cubit.dart
    - lib/application/backup/backup_state.dart
    - lib/application/backup/README.md
    - lib/presentation/backup/README.md
    - lib/presentation/backup/screens/README.md
    - lib/presentation/backup/screens/backup_screen.dart
    - lib/presentation/backup/widgets/README.md
    - lib/config/di/injection.config.dart
    - test/application/backup/backup_cubit_test.dart
    - test/presentation/backup/backup_screen_test.dart

key-decisions:
  - "Post-import hooks live in post_import_hooks.dart as runPostImportHooks(), called by the cubit, to keep backup_cubit.dart at the 150-line cap; order is budget reseed, goal reseed, reconcileNow(afterImport)"
  - "Cancel is a single path: the Cancel button calls maybePop and a PopScope calls cancelImport() only while the state is BackupImportPreviewReady, so the system back button also discards the prepared import and cancel is never called twice"
  - "The confirm screen pops only when ModalRoute.isCurrent, because the Backup screen acknowledges Done/Failed with an Idle that would otherwise pop the Backup screen as well"
  - "The summary card lists every entity in preview.replaced (count defaults to 0), so a CSV that replaces an entity with an empty file shows 0 rather than hiding the wipe"
  - "The Backup screen does not acknowledge BackupImportPreviewReady: the confirmation screen needs the cubit to stay in that state"
  - "DI was regenerated in Task 1 (when the constructor changed) rather than Task 3, so every commit builds; the Task 3 run changed nothing"

requirements-completed: [DATA-04]

coverage:
  - id: D1
    description: "Picking a file prepares the import in memory and opens a confirmation screen with record counts per entity, date range, export date, soft-deleted count and dangling-link warnings; a cancelled picker returns to idle and a failed prepare shows the specific message"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/application/backup/backup_cubit_import_test.dart#BackupCubit.pickAndPrepareImport"
        status: pass
      - kind: unit
        ref: "test/presentation/backup/import_confirm_screen_test.dart#ImportConfirmScreen"
        status: pass
      - kind: unit
        ref: "test/presentation/backup/backup_screen_test.dart#a prepared import opens the confirmation screen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Confirming commits through the repository (safety backup then atomic replace); cancelling or going back discards the prepared import and writes nothing; confirm is ignored outside the preview state"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/application/backup/backup_cubit_import_test.dart#BackupCubit.confirmImport"
        status: pass
      - kind: unit
        ref: "test/presentation/backup/import_confirm_screen_test.dart#cancel discards the import once and pops"
        status: pass
    human_judgment: false
  - id: D3
    description: "A failed import reports that data is unchanged with the safety backup path; validation failures map to a distinct localized message per error code and never show raw failure text"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/presentation/backup/import_confirm_screen_test.dart#backupErrorMessage"
        status: pass
      - kind: unit
        ref: "test/presentation/backup/backup_screen_test.dart#ImportFailed shows the safety backup path, not the detail"
        status: pass
    human_judgment: false
  - id: D4
    description: "After a successful import the budget and goal alert state is reseeded and a reconcile runs in order; a throwing hook neither masks the import nor skips the later hooks"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/application/backup/backup_cubit_import_test.dart#commits, runs the hooks in order and emits Done"
        status: pass
      - kind: unit
        ref: "test/application/backup/backup_cubit_import_test.dart#a throwing hook still yields Done and later hooks still run"
        status: pass
    human_judgment: false
  - id: D5
    description: "CSV import states that only the supplied data types are replaced; JSON import does not show that note"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/presentation/backup/import_confirm_screen_test.dart#the partial note appears only for a CSV preview"
        status: pass
    human_judgment: false
  - id: D6
    description: "Real restore on a device: system file picker and scoped storage, safety backup file in the app documents folder, truncated file rejected with nothing changed, CSV replaces only transactions"
    verification: []
    human_judgment: true
    rationale: "The system file picker, scoped storage and the on-device safety backup folder cannot run on the host VM (assumptions A5 and A6)."
  - id: D7
    description: "No alert storm after a restore of a budget already over 100%, and reminders for restored tasks, debts and payments are scheduled and fire on time"
    requirement: "DATA-04"
    verification: []
    human_judgment: true
    rationale: "Requires real notification delivery after a restore."
  - id: D8
    description: "Android Auto Backup is off (allowBackup=false) and nothing is restored after reinstall (D-13); iOS parity for export, import, permission, reminders, budget alert, 64-pending case and notification tap"
    verification: []
    human_judgment: true
    rationale: "Backup eligibility is reported by the device's backup manager; there is no Xcode or iOS device on the build host."

duration: 9 min
completed: 2026-10-16
---

# Phase 4 Plan 17: Backup import UI Summary

**A prepare, confirm, commit import flow: the Backup screen picks a JSON or CSV backup, a confirmation screen shows counts per entity, date range and warnings before anything is written, and a confirmed import commits through the safety backup and then silently reseeds budget and goal alert state and reconciles notifications, with each post-import hook isolated so it can never mask a successful restore.**

## Performance

- **Duration:** 9 min (2026-10-16T08:34:26Z to 08:43:46Z, before SUMMARY authoring)
- **Tasks:** 3 of 3 (Task 1 tracer, Tasks 2 and 3 auto)
- **Files:** 17 (7 created, 10 modified), 3 commits

## Accomplishments

- `BackupCubit` gained `pickAndPrepareImport` (cancelled picker returns to idle, errors emit `BackupFailed`, success emits `BackupImportPreviewReady`), `confirmImport` (a no-op unless the state is the preview; emits `BackupImportDone`, or `BackupImportFailed` carrying `repository.lastSafetyBackupPath`) and `cancelImport` (discards the prepared import). Its constructor now takes `BudgetAlertEvaluator`, `GoalAlertEvaluator` and `NotificationReconciler`.
- `runPostImportHooks` runs `budgetAlerts.reseedAfterImport`, `goalAlerts.reseedAfterImport` and `reconcileNow(ReconcileReason.afterImport)` in that order, each in its own try/catch. A test makes the first two throw (one synchronously, one asynchronously) and still gets `Done` plus the reconcile call.
- `ImportConfirmScreen` shows the replace warning, the CSV-only partial note (D-14), an `ImportSummaryCard` and an error-coloured confirm button. Both buttons are disabled with a progress bar while `BackupWorking`. Back and Cancel discard the prepared import; the screen closes itself on a result.
- `ImportSummaryCard` lists a count per replaced entity, the date range (`DateFormat.yMd` in the app locale), the export date for JSON, the soft-deleted count and a warnings block when links dangle.
- `backupErrorMessage` maps `unsupported`, `invalid` and `empty` to the unsupported text, and `tooLarge`, `newerVersion`, `mixed` and `duplicate` to their own messages. `importFailed` with a safety path names the path, and anything else is generic. The test asserts seven distinct messages and that a detail string never leaks.
- `BackupScreen` has an import section, pushes the confirmation screen on a prepared import (sharing the cubit through `BlocProvider.value`), and raises hide-then-show SnackBars for ImportDone (`backupImportDone` plus the total) and for failures, then acknowledges.
- 809/809 tests pass; `flutter analyze --no-fatal-infos --fatal-warnings` reports 64 infos (budget 65, unchanged); architecture guard passes; DI registers `BackupCubit` with the evaluator and reconciler arguments.

## Task Commits

1. **Task 1 (tracer): cubit prepares, confirms and commits imports with post-import hooks** - `79f1120` (feat)
2. **Task 2: import confirmation screen, summary card and error text** - `05cda19` (feat)
3. **Task 3: import entry on the Backup screen with result handling** - `61627b3` (feat)

Tracer feedback gate: `workflow.auto_advance` is false, `human_verify_mode` is `end-of-phase` and the tracer's `<verify>` is automated-only, so its tests, analyzer and architecture guard were re-run on the committed state (plus a project-wide analyze, 64 issues) and passed before Task 2 ("Tracer verified end-to-end — expanding").

**Plan metadata:** committed with this SUMMARY (docs: complete plan).

## Decisions Made

See `key-decisions` in the frontmatter. The two that shape behavior most are the single-path cancel (button and back both go through `PopScope`, so `cancelImport` runs exactly once) and the `isCurrent` guard that stops the Idle emitted by the Backup screen's `acknowledge()` from popping the Backup screen after the confirmation screen has closed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] 150-line cap forced two extra files**
- **Found during:** Tasks 1 and 3
- **Issue:** `check_architecture.dart` rejects hand-written files over 150 lines. The cubit with the import flow and hooks reached 166 lines, and `backup_screen.dart` would have passed 150 with the import section.
- **Fix:** Moved the hooks to `lib/application/backup/post_import_hooks.dart` (`runPostImportHooks`, called from the cubit) and the SnackBar text mapping to `lib/presentation/backup/widgets/backup_outcome_message.dart`. The cubit ends at exactly 150 lines, `backup_screen.dart` at 129. The plan's note that `widgets/` would hold 3 files is now 5 (the guard allows 10); `screens/` holds 2 as planned.
- **Files modified:** the two new files, `backup_cubit.dart`, `backup_screen.dart`, the READMEs.
- **Commits:** `79f1120`, `61627b3`

**2. [Rule 1 - Bug] A second pop would have closed the Backup screen**
- **Found during:** Task 2 design
- **Issue:** The plan has the confirmation screen pop on Idle and the Backup screen call `acknowledge()` (which emits Idle) after a result. The confirmation screen is still mounted during its pop animation, so that Idle would have popped the Backup screen too. Likewise a Cancel button that pops and also calls `cancelImport()` (whose Idle triggers the listener) would pop twice.
- **Fix:** Cancel calls `maybePop`; a `PopScope` calls `cancelImport()` only from the preview state; the listener pops only while `ModalRoute.isCurrent`. A test emits ImportDone then Idle and asserts the base route is still on screen.
- **Files modified:** `lib/presentation/backup/screens/import_confirm_screen.dart`, `test/presentation/backup/import_confirm_screen_test.dart`
- **Commit:** `05cda19`

**3. [Rule 3 - Blocking] DI regenerated in Task 1, not Task 3**
- **Found during:** Task 1
- **Issue:** Changing the `BackupCubit` constructor makes `injection.config.dart` stale, so the app would not build at the Task 1 commit.
- **Fix:** Ran `dart run build_runner build --delete-conflicting-outputs` in Task 1 and committed the result; the Task 3 run changed nothing (`wrote 0 outputs`). The Task 3 acceptance grep for `BackupCubit` with the evaluator and reconciler arguments still holds.
- **Files modified:** `lib/config/di/injection.config.dart`
- **Commit:** `79f1120`

**4. [Rule 2 - Missing critical] Existing cubit test updated and extra tests added**
- `test/application/backup/backup_cubit_test.dart` built the cubit with two arguments, so it was updated for the new constructor. Extra cases beyond the plan list: a picker `Err` prepares nothing, a commit `Err` skips every hook, an async-throwing hook still lets the reconcile run, and the screen tests cover a validation-failure SnackBar and that a prepared import is not acknowledged.
- **Commit:** `79f1120`, `61627b3`

**Total deviations:** 2 Rule 3, 1 Rule 1, 1 Rule 2. **Impact:** none on scope or behavior; the cancel/pop design differs in mechanics from the plan text but meets its stated outcomes.

## Authentication Gates

None.

## Issues Encountered

- `flutter test` prints a Linux desktop toolchain warning (clang, cmake, GTK); it is unrelated to this plan.
- `pumpAndSettle` never settles while the confirmation screen shows its progress bar, so that test helper pumps a fixed duration instead.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub` (full suite) | 809/809 pass |
| `flutter test --no-pub test/application/backup` | 18/18 pass |
| `flutter test --no-pub test/presentation/backup` | 22/22 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65), none in files touched by this plan |
| `flutter analyze lib/application/backup test/application/backup lib/presentation/backup test/presentation/backup` | No issues found |
| `dart run build_runner build --delete-conflicting-outputs` | exit 0; `BackupCubit` in `injection.config.dart` with the three new arguments |
| `dart run tool/check_architecture.dart` | PASS |
| `grep -n "reseedAfterImport" lib/application/backup/backup_cubit.dart` | match (doc comment; the calls are in `post_import_hooks.dart`) |
| `grep -n "backupConfirmPartial" lib/presentation/backup/screens/import_confirm_screen.dart` | match |
| `grep -n "ImportConfirmScreen" lib/presentation/backup/screens/backup_screen.dart` | match |

## Human verification outstanding

These consolidate the device UAT for the phase and could not be run on the host VM.

1. **Android restore (A5, A6).** Export a JSON backup, add a few tasks and a transaction, then Import the JSON from the Backup screen and confirm. Then import a truncated copy, and a CSV transactions file on its own. Expect the confirmation screen to list counts and the date range before anything changes; after confirming, the data matches the export and a safety backup exists in the app documents backups folder; the truncated file is rejected with the unsupported message and nothing changes; the CSV import replaces only transactions and leaves tasks, goals and debts untouched.
2. **Alerts after a restore.** Import a backup that contains a budget already over 100%, then wait or add one more transaction, and check pending reminders. Expect no budget or goal alert storm, and reminders for restored tasks, debts and payments scheduled and firing at the right times.
3. **Auto Backup (D-13).** Run `adb shell dumpsys backup` (or `adb shell bmgr list transports`) for `com.omeu.space.agenda`, then reinstall and confirm the data is gone and restorable from the exported JSON. Expect the package not eligible (allowBackup=false) and no automatic restore.
4. **iOS (if a device is available).** Repeat export, import, notification permission, a reminder, a budget alert and the 64-pending case; tap a delivered notification to exercise the AppDelegate delegate. Expect Android-equivalent behavior, correct tap routing, no crash above 64 pending items, and the settings page showing the waiting count.
5. **Carried over from earlier plans (still on the phase UAT list):** the 04-16 export checks (save dialogs, valid JSON, CSV accents and decimal comma) and the 04-14 delivery check.

## Threat Flags

None beyond the plan's register. T-04-17-01 is covered by `backupErrorMessage` (code-mapped text, a test asserts a detail string never appears); T-04-17-02 by the confirmation screen and the safety path shown on failure; T-04-17-04 by `runPostImportHooks` (order and isolation tested). T-04-17-03 is accepted as planned.

## Known Stubs

None.

## Next Phase Readiness

This is the last plan of Phase 4. All 17 plans have summaries; the phase is ready for verification (`/gsd-verify-work 4`), with the device and iOS checks above as the manual part. Phase 5 can mount `BackupScreen` in Settings unchanged and replace the temporary task-list overflow menu.

## Self-Check: PASSED

All 7 created files verified on disk; commits `79f1120`, `05cda19` and `61627b3` present in `git log`; `git rev-list --count c5365a6..HEAD` measured 3 before this SUMMARY commit.
