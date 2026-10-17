# presentation/backup

Presentation slice for **backup and restore**: the page where the user exports
and imports their data, and the confirmation step before an import replaces
anything (DATA-02, DATA-03, DATA-04).

## Responsibility

Show the export and import actions, the unencrypted-file and reinstall notes,
the review screen for a prepared import, and the outcome of each run. File content, file picking and repository calls never
live here: the cubit in `application/backup/` drives them.

## Layout

```
backup/
├── screens/   BackupScreen (standalone page, owns its cubit), ImportConfirmScreen
└── widgets/   BackupActionCard, ImportSummaryCard, backupErrorMessage,
               backupOutcomeMessage, SafetyBackupsSection,
               confirmDeleteSafetyBackups
```

## Conventions in this slice

- **The screen is a self-contained route.** It provides its own `BackupCubit`
  from `getIt`, so Phase 5 can mount it in Settings unchanged.
- **Outcomes are snackbars from a `BlocListener`**, hide-current-then-show,
  followed by `acknowledge()`.
- **Failures show a localized message chosen by import error code**
  (`backupErrorMessage`), never `Failure.message`. A failed commit also names
  the safety backup path (D-12).
- **Nothing is replaced before the confirmation screen.** The Backup screen
  only prepares; `ImportConfirmScreen` confirms or cancels, and closes itself
  once on a result (guarded so it cannot also pop the Backup screen).
- **The safety-backups section owns its cubit and never shows a path;** the
  import-failed text keeps the path per D-12. Restoring a saved copy is the
  existing Import action.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`application/backup/` · `generated/l10n/` · `config/di/injection.dart`.
