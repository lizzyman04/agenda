# application/backup

Owns the **state of the Backup screen**: the export flows and the import flow
(DATA-02, DATA-03, DATA-04).

## Responsibility

Turn a user action into repository and file-gateway calls and map every
outcome (saved, cancelled, failed) to a state the screen can show. The cubit
builds no file content and touches no file picker: the repository produces the
bytes and the gateway lets the user choose where each file lands (D-12).
Imports run gateway (pick) -> repository (prepare, then commit once the user
confirms) -> post-import hooks.

## Files

| File | Lines | Role |
|------|------:|------|
| `backup_cubit.dart` | 150 | `BackupCubit` — `exportJson` / `exportCsv` as before; `pickAndPrepareImport` picks files and emits `BackupImportPreviewReady` (cancelled picker returns to idle); `confirmImport` (only from the preview state) commits, runs the hooks and emits `BackupImportDone`, or `BackupImportFailed` carrying the repository's safety backup path; `cancelImport` discards the prepared import; `acknowledge` returns to idle |
| `backup_state.dart` | 78 | `BackupIdle`, `BackupWorking`, `BackupExportDone(fileCount, csv)`, `BackupExportCancelled(savedCount)`, `BackupFailed(failure)`, `BackupImportPreviewReady(preview)`, `BackupImportDone(result)`, `BackupImportFailed(failure, safetyBackupPath)` |
| `post_import_hooks.dart` | 27 | `runPostImportHooks` — budget `reseedAfterImport`, goal `reseedAfterImport`, then `reconcileNow(ReconcileReason.afterImport)`, each in its own try/catch |

## Conventions in this slice

- **Cancel is not an error.** A save dialog the user dismisses stops the
  export with `BackupExportCancelled` and the count already saved.
- **Failures are generic to the user.** The state carries the `Failure` for
  tests and logs, but the screen shows one localized message; raw messages are
  never displayed.
- **File content is never logged.**
- **One run at a time.** A request made while the state is `BackupWorking` is
  ignored, so a double tap cannot open two dialogs.
- **A hook failure never masks a successful import.** The hooks run only after
  a successful commit, in a fixed order, each isolated; the state is then
  `BackupImportDone` regardless.
- **Nothing is written before confirmation.** `prepareImport` is in-memory;
  `confirmImport` is a no-op unless the state is `BackupImportPreviewReady`.

## Upstream dependencies

`domain/backup/` (`BackupRepository`, `BackupFileGateway`, `BackupFile`,
`ImportPreview`) · `application/notifications/` (`BudgetAlertEvaluator`,
`GoalAlertEvaluator`) · `domain/notifications/` (`NotificationReconciler`) ·
`core/failures/` · `flutter_bloc` · `injectable` · `equatable`.
