# presentation/backup/widgets

Presentation-only widgets for the Backup page.

## Responsibility

Render one backup action. The widgets hold no state and call nothing but the
callback they are given.

## Files

| File | Lines | Role |
|------|------:|------|
| `backup_action_card.dart` | 33 | `BackupActionCard` — a `Card` with a `ListTile` (leading icon, title, description, trailing chevron); a null `onPressed` disables it |

## Conventions in this slice

- **Disabled means null callback.** The screen passes `null` while an export
  is running; the card needs no separate flag.

## Upstream dependencies

`flutter/material.dart` only.
