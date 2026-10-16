# presentation/backup/widgets

Presentation-only widgets for the Backup page.

## Responsibility

Render one backup action, the import summary and the localized import errors.
The widgets hold no state and call nothing but the callback they are given.

## Files

| File | Lines | Role |
|------|------:|------|
| `backup_action_card.dart` | 33 | `BackupActionCard` — a `Card` with a `ListTile` (leading icon, title, description, trailing chevron); a null `onPressed` disables it |
| `import_summary_card.dart` | 74 | `ImportSummaryCard(preview)` — a `Card` with one count line per replaced entity (order: tasks, transactions, categories, budgets, goals, debts, payments), the date range, the export date (JSON), the soft-deleted count and a warnings block when links dangle. Dates use `DateFormat.yMd` in the app locale |
| `backup_error_text.dart` | 28 | `backupErrorMessage(l10n, failure, {safetyBackupPath})` — maps the import error code to localized text; `importFailed` with a path names the safety backup, anything unknown is generic. Raw `Failure.message` is never shown |

## Conventions in this slice

- **Disabled means null callback.** The screen passes `null` while an export
  is running; the card needs no separate flag.

## Upstream dependencies

`flutter/material.dart` only.
