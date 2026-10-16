# presentation/backup

Presentation slice for **backup and restore**: the page where the user exports
their data (DATA-02, DATA-03). Plan 04-17 adds the import controls to it.

## Responsibility

Show the export actions, the unencrypted-file and reinstall notes, and the
outcome of each run. File content, file picking and repository calls never
live here: the cubit in `application/backup/` drives them.

## Layout

```
backup/
├── screens/   BackupScreen (standalone page, owns its cubit)
└── widgets/   BackupActionCard
```

## Conventions in this slice

- **The screen is a self-contained route.** It provides its own `BackupCubit`
  from `getIt`, so Phase 5 can mount it in Settings unchanged.
- **Outcomes are snackbars from a `BlocListener`**, hide-current-then-show,
  followed by `acknowledge()`.
- **Failures show one generic localized message**, never `Failure.message`.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`application/backup/` · `generated/l10n/` · `config/di/injection.dart`.
