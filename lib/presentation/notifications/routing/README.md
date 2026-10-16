# presentation/notifications/routing

Sends a notification tap to the screen it points at.

## Responsibility

Listen for taps (while the app runs and the one that cold-started it),
resolve each payload to a `TapTarget`, and navigate: select a bottom-nav tab,
request a Finance sub-tab, and push a task or goal detail route.

## Files

| File | Lines | Role |
|------|------:|------|
| `notification_tap_listener.dart` | 86 | `NotificationTapListener` — subscribes to `tapPayloads`, reads `launchPayload()` once after the first frame, never throws, cancels on dispose |
| `tap_navigator.dart` | 82 | `openTapTarget` — pops to the first route, drives `appTabIndex` / `financeSubTabRequest`, and pushes `TaskDetailScreen` or `GoalDetailScreen` only when the entity exists and is not soft-deleted |

## Conventions in this slice

- **The id is only a lookup key.** A task or goal is re-loaded and checked
  for existence and `deletedAt` before a detail route is pushed (T-04-13-01).
- **Capture before awaiting.** `TaskListCubit` is read from the context before
  the first `await`, and `context.mounted` is checked after it.
- **Tabs move through notifiers**, not through the shell's state, so routing
  works from outside the widget that owns the `NavigationBar`.

## Upstream dependencies

`domain/notifications/` (`LocalNotificationGateway`, `resolveTapTarget`) ·
`domain/tasks/item_repository.dart` · `domain/finance/goal/goal_repository.dart` ·
`application/tasks/task_list/` · `presentation/shell/shell_navigation.dart` ·
`presentation/tasks/screens/` · `presentation/finance/goals/screens/` ·
`config/di/injection.dart`.
