# presentation/backup/screens

Route-level widget for the Backup page.

## Responsibility

Provide the page-local `BackupCubit`, lay out the export actions and notes,
and turn each state into a snackbar. Nothing else.

## Files

| File | Lines | Role |
|------|------:|------|
| `backup_screen.dart` | 106 | `BackupScreen` — `BlocProvider(create: getIt)` around a view with the JSON and CSV `BackupActionCard`s (both disabled while `BackupWorking`, with a progress bar and working text), the privacy and reinstall captions, and a listener that raises the outcome snackbar then calls `acknowledge()`. The CSV card passes `Localizations.localeOf(context).languageCode` so the file dialect follows the app language |

## Conventions in this slice

- **An outcome SnackBar hides the current one before showing itself**, so the
  message the user sees always belongs to the latest run.
- **Strings come from `AppLocalizations.of(context)`**; the privacy note and
  the reinstall note (D-13) are always visible.

## Upstream dependencies

`application/backup/` (`BackupCubit`, `BackupState`) · `../widgets/` ·
`generated/l10n/` · `config/di/injection.dart`.
