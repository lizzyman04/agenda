# application/backup

Owns the **state of the Backup screen**: the export flows and, after plan
04-17, the import flow (DATA-02, DATA-03).

## Responsibility

Turn a user action into repository and file-gateway calls and map every
outcome (saved, cancelled, failed) to a state the screen can show. The cubit
builds no file content and touches no file picker: the repository produces the
bytes and the gateway lets the user choose where each file lands (D-12).

## Files

| File | Lines | Role |
|------|------:|------|
| `backup_cubit.dart` | 88 | `BackupCubit` — `exportJson` runs repository `exportJson` then one gateway `saveFile`; `exportCsv` runs repository `exportCsv` then one `saveFile` per file in order, stopping at the first cancel; `acknowledge` returns to idle. Ignores a second request while an export is working |
| `backup_state.dart` | 51 | `BackupIdle`, `BackupWorking`, `BackupExportDone(fileCount, csv)`, `BackupExportCancelled(savedCount)`, `BackupFailed(failure)` |

## Conventions in this slice

- **Cancel is not an error.** A save dialog the user dismisses stops the
  export with `BackupExportCancelled` and the count already saved.
- **Failures are generic to the user.** The state carries the `Failure` for
  tests and logs, but the screen shows one localized message; raw messages are
  never displayed.
- **File content is never logged.**
- **One run at a time.** A request made while the state is `BackupWorking` is
  ignored, so a double tap cannot open two dialogs.

## Upstream dependencies

`domain/backup/` (`BackupRepository`, `BackupFileGateway`, `BackupFile`) ·
`core/failures/` · `flutter_bloc` · `injectable` · `equatable`.
