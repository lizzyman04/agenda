# presentation/notifications/widgets

Presentation-only pieces of the notification settings page.

## Responsibility

Render what they are given and report user input through callbacks. Nothing
here reads a repository, a cubit or a platform service.

## Files

| File | Lines | Role |
|------|------:|------|
| `notification_type_labels.dart` | 30 | `notificationTypeLabel` and `notificationTypeDescription` — map each `NotificationKind` to its localized channel name and description |
| `notification_type_tile.dart` | 27 | `NotificationTypeTile` — one kind as a `SwitchListTile` |

## Conventions in this slice

- **Widgets own no preference logic.** The screen decides what a change
  means and which cubit method to call.
- **Strings come from the shared catalog.** The page reuses the Android
  channel names, so the page and the system settings never disagree.
