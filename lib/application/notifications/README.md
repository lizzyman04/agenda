# application/notifications

Raises the **alerts that depend on an in-app event**, which a pre-scheduled
one-shot cannot represent (D-05, D-06).

## Responsibility

Watch the finance data and raise the alerts a pre-scheduled one-shot cannot
represent: budget threshold crossings (on transaction and budget changes) and
an off-track goal (when the app opens). Both hand each new alert to the
immediate-alert dispatcher. Nothing here schedules the time-based reminders:
the planners in `domain/notifications/planner/` and the reconcile runner own
those.

## Files

| File | Lines | Role |
|------|------:|------|
| `budget_alert_evaluator.dart` | 149 | `BudgetAlertEvaluator` — `start` prunes stale markers, seeds the month silently and subscribes; `evaluate` dispatches one alert per category per threshold per month; `reseedAfterImport` rebuilds the markers after a restore |
| `budget_month.dart` | 80 | `loadBudgetMonth` (one month of spend, limits and names; null if any read fails), `crossedThresholds` and `crossedBudgetKeys` |
| `debounced_single_flight.dart` | 51 | `DebouncedSingleFlight` — 300 ms debounce, at most one run in flight and one queued |
| `goal_alert_evaluator.dart` | 122 | `GoalAlertEvaluator` — `evaluateOnOpen` raises at most one off-track alert per goal per week; `reseedAfterImport` marks current off-track goals silently |

## Conventions in this slice

- **Evaluators mark state before dispatching and never write a marker while
  the kind is disabled.** A crash after the marker cannot repeat the alert,
  and switching the kind back on still yields the alert.
- **Alerts follow changes.** There is no scheduled job; the evaluator
  subscribes to `watchChanges()` and does not evaluate at start.
- **Silent seeding.** The first start of a month, and a restore, mark the
  thresholds already crossed without alerting, so existing overspend never
  produces an alert storm. Seeding is skipped while the kind is off.
- **Highest threshold only.** A jump from below 80% to over 100% raises the
  100% alert and marks the 80% one, so no stale 80% alert follows.
- **Alert text is a name and a percentage, never an amount.**
- **Markers are pruned on start** (`isStaleAlertKey`): budget keys older than
  two months, seeded keys of past months, goal markers older than eight weeks.
- **Nothing throws.** A repository `Err` ends the pass quietly.

## Upstream dependencies

`domain/` (repository interfaces, `AlertStateStore`, budget threshold and goal
off-track rules, `PlannedNotification`) · `application/finance/budget/budget_aggregator.dart`
(`mergeBudgetData`) · `core/` · `shared_preferences` (stored locale only).
Exception to the layer rule: the evaluators call
`infrastructure/notifications/sync/immediate_alert_dispatcher.dart`, because
the dispatcher is the one place that applies the kind toggle, the permission
gate and quiet hours.
