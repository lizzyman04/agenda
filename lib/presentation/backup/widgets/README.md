# presentation/backup/widgets

Presentation-only widgets for the Backup page.

## Responsibility

Render one backup action, the import summary and the localized import errors.
The widgets hold no state and call nothing but the callback they are given.

## Files

| File | Lines | Role |
|------|------:|------|
| `backup_action_card.dart` | 33 | `BackupActionCard` — a `Card` with a `ListTile` (leading icon, title, description, trailing chevron); a null `onPressed` disables it |
| `backup_outcome_message.dart` | 21 | `backupOutcomeMessage(l10n, state)` — the SnackBar text for Done, Cancelled, ImportDone (`backupImportDone` plus the total count), ImportFailed (with the safety path) and Failed; null for idle, working and the preview |
| `import_summary_card.dart` | 74 | `ImportSummaryCard(preview)` — a `Card` with one count line per replaced entity (order: tasks, transactions, categories, budgets, goals, debts, payments), the date range, the export date (JSON), the soft-deleted count and a warnings block when links dangle. Dates use `DateFormat.yMd` in the app locale |
| `backup_error_text.dart` | 28 | `backupErrorMessage(l10n, failure, {safetyBackupPath})` — maps the import error code to localized text; `importFailed` with a path names the safety backup, anything unknown is generic. Raw `Failure.message` is never shown |
| `safety_backups_section.dart` | 131 | `SafetyBackupsSection` — owns a `SafetyBackupsCubit` (`getIt`, `load()` on create): header, description, localized count, and a "save latest copy" `OutlinedButton` (key `safetySave`) and a "delete all" `TextButton` (key `safetyDelete`), both disabled while busy or at count 0. Reloads the count when the surrounding `BackupCubit` reports `BackupImportDone` or `BackupImportFailed`; announces saved / none / deleted / failed as a SnackBar (cancelled shows nothing) then acknowledges. Never shows a path or file name |
| `delete_safety_backups_dialog.dart` | 32 | `confirmDeleteSafetyBackups(context)` — confirmation `AlertDialog` (cancel `TextButton`, error-coloured `FilledButton`); returns `true` only on confirm |

## Conventions in this slice

- **Disabled means null callback.** The screen passes `null` while an export
  is running; the card needs no separate flag.

## Upstream dependencies

`flutter/material.dart` only.
