# application/notifications

Raises the **alerts that depend on an in-app event**, which a pre-scheduled
one-shot cannot represent (D-05, D-06).

## Responsibility

Watch the finance data for budget threshold crossings and hand each new
crossing to the immediate-alert dispatcher. Nothing here schedules the
time-based reminders: the planners in `domain/notifications/planner/` and the
reconcile runner own those.

## Files

| File | Lines | Role |
|------|------:|------|
| `budget_alert_evaluator.dart` | 128 | `BudgetAlertEvaluator` — on transaction and budget changes, finds categories that reached 80% or 100% of this month's limit and dispatches one alert per category per threshold per month |
| `budget_month.dart` | 50 | `loadBudgetMonth` — reads one month of spend, limits and category names; returns null if any read fails |
| `debounced_single_flight.dart` | 51 | `DebouncedSingleFlight` — 300 ms debounce plus at most one run in flight and one queued |

## Conventions in this slice

- **Evaluators mark state before dispatching and never write a marker while
  the kind is disabled.** A crash after the marker cannot repeat the alert,
  and switching the kind back on still yields the alert.
- **Alerts follow changes.** There is no scheduled job; the evaluator
  subscribes to `watchChanges()` and does not evaluate at start.
- **Highest threshold only.** A jump from below 80% to over 100% raises the
  100% alert and marks the 80% one, so no stale 80% alert follows.
- **Alert text is a name and a percentage, never an amount.**
- **Nothing throws.** A repository `Err` ends the pass quietly.

## Upstream dependencies

`domain/` (repository interfaces, `AlertStateStore`, budget threshold rules,
`PlannedNotification`) · `application/finance/budget/budget_aggregator.dart`
(`mergeBudgetData`) · `core/` · `shared_preferences` (stored locale only).
Exception to the layer rule: the evaluators call
`infrastructure/notifications/sync/immediate_alert_dispatcher.dart`, because
the dispatcher is the one place that applies the kind toggle, the permission
gate and quiet hours.
