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
| `time_setting_tile.dart` | 51 | `TimeSettingTile` — a labelled `HH:mm` row that opens `showTimePicker` and reports minutes since midnight; reports nothing on cancel; can be disabled |
| `permission_banner.dart` | 54 | `PermissionBanner` — non-blocking card with a title, body and one tonal action button; used for the denied-permission and exact-alarm cases |
| `quotes_section.dart` | 80 | `QuotesSection` — quotes heading; while off only the hint, while on a daily/weekly `SegmentedButton` and a `TimeSettingTile` (D-07) |
| `quiet_hours_section.dart` | 58 | `QuietHoursSection` — enable switch plus start and end `TimeSettingTile`s, enabled only while the switch is on (NOTF-10) |

## Conventions in this slice

- **Widgets own no preference logic.** The screen decides what a change
  means and which cubit method to call.
- **Strings come from the shared catalog.** The page reuses the Android
  channel names, so the page and the system settings never disagree.
