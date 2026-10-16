# presentation/shell

The app's bottom-navigation frame.

## Responsibility

Hold the five top-level tabs and the shared state that lets code outside the
shell (a notification tap) change the selected tab.

## Files

| File | Lines | Role |
|------|------:|------|
| `shell_navigation.dart` | 13 | `appTabIndex` (selected tab, 0 Tasks .. 4 Finance) and `financeSubTabRequest` (one-shot Finance sub-tab request, reset by its consumer) |

## Conventions in this slice

- **Selection lives in a notifier, not in widget state**, so notification
  routing can switch tabs.
- A sub-tab request is consumed once and reset to null.

## Upstream dependencies

`flutter/foundation.dart`.
