---
phase: 04-notifications-backup
plan: 14
subsystem: notifications-alerts
tags: [budget-alerts, goal-alerts, immediate-dispatch, quiet-hours, seeding, alert-state]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-03 NotificationKind, PlannedNotification, notificationId, deferOutOfQuietHours, encodePayload, weekKey"
  - phase: 04-notifications-backup
    provides: "04-07 isGoalOffTrack, goalFiredKey, goalScheduledKey"
  - phase: 04-notifications-backup
    provides: "04-10 / 04-12 AlertStateStore, LocalNotificationGateway, PermissionGate, NotificationContentBuilder, startNotifications()"
provides:
  - "crossedBudgetThreshold, budgetAlertKey, budgetSeededKey, plannedBudgetAlert, newBudgetKeys (pure domain rules)"
  - "isStaleAlertKey: retention rule for persisted alert markers"
  - "ImmediateAlertDispatcher.dispatch: toggle, permission gate, quiet-hours defer, show or schedule"
  - "BudgetAlertEvaluator: start, evaluate, reseedAfterImport, dispose"
  - "GoalAlertEvaluator: evaluateOnOpen, reseedAfterImport"
  - "Evaluators started from startNotifications(); goal evaluator also on each resume"
affects: [04-15, 04-16, 04-17]

plan_head_before: 4e16405ebcf16e8def7a98c5d659104fe0e83bbb
commits: 3
actuals:
  tokens: 14500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Evaluate-on-write: watchChanges -> 300 ms debounce -> single-flight -> evaluate, with no initial evaluation"
    - "Mark before dispatch; never mark while the kind is off"
    - "Silent seeding of already-crossed thresholds once per month and after a restore"
    - "Decision logic kept in pure domain functions so the application files stay under the 150-line cap"

key-files:
  created:
    - lib/domain/notifications/planning/budget_threshold.dart
    - lib/domain/notifications/planning/stale_alert_keys.dart
    - lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart
    - lib/application/notifications/budget_alert_evaluator.dart
    - lib/application/notifications/budget_month.dart
    - lib/application/notifications/debounced_single_flight.dart
    - lib/application/notifications/goal_alert_evaluator.dart
    - lib/application/notifications/README.md
    - test/domain/notifications/budget_threshold_test.dart
    - test/domain/notifications/stale_alert_keys_test.dart
    - test/infrastructure/notifications/immediate_alert_dispatcher_test.dart
    - test/application/notifications/budget_alert_evaluator_test.dart
    - test/application/notifications/goal_alert_evaluator_test.dart
  modified:
    - lib/config/startup/notification_startup.dart
    - lib/config/di/injection.config.dart

key-decisions:
  - "Seeding (at start and after an import) is skipped while the kind is disabled, so T-04-14-03 holds literally; the next start seeds silently once the kind is on."
  - "A category with no stored name, or an id outside 0..maxNotificationEntityId, is skipped without writing a marker."
  - "The application evaluators call the infrastructure ImmediateAlertDispatcher as the plan specifies; the exception to the layer rule is documented in the application README."
  - "Goal reseedAfterImport clears gf:/gs: markers even when the kind is off, but writes fired markers only when it is on."

requirements-completed: [NOTF-03, NOTF-06, NOTF-10]

coverage:
  - id: D1
    description: "A budget crossing 80% fires one alert and crossing 100% one more, each once per category per month and persisted; a jump past 100% fires only the 100% alert and marks 80%"
    requirement: "NOTF-03"
    verification:
      - kind: unit
        ref: "test/application/notifications/budget_alert_evaluator_test.dart"
        status: pass
      - kind: unit
        ref: "test/domain/notifications/budget_threshold_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Only the current month is evaluated; a zero or absent limit is ignored; alerts follow transaction and budget changes through a debounced single-flight, never a scheduled job"
    requirement: "NOTF-03"
    verification:
      - kind: unit
        ref: "test/application/notifications/budget_alert_evaluator_test.dart#a change burst evaluates once after the debounce"
        status: pass
    human_judgment: false
  - id: D3
    description: "First start of a month and a restore seed crossed thresholds silently; stale markers are pruned"
    requirement: "NOTF-10"
    verification:
      - kind: unit
        ref: "test/application/notifications/budget_alert_evaluator_test.dart#seeding and pruning"
        status: pass
      - kind: unit
        ref: "test/domain/notifications/stale_alert_keys_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "An immediate alert inside quiet hours is scheduled for the window end; outside it is shown now; a disabled kind does nothing; the permission is asked once"
    requirement: "NOTF-10"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/immediate_alert_dispatcher_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "On open an off-track goal raises at most one immediate alert per goal per week and never in a week with a fired or scheduled marker; disabled kind writes nothing"
    requirement: "NOTF-06"
    verification:
      - kind: unit
        ref: "test/application/notifications/goal_alert_evaluator_test.dart"
        status: pass
    human_judgment: false
  - id: D6
    description: "Alert text carries a name and a percentage only, never an amount"
    requirement: "NOTF-10"
    verification:
      - kind: unit
        ref: "test/application/notifications/budget_alert_evaluator_test.dart#the notification carries the name and percent, no amount"
        status: pass
    human_judgment: false
  - id: D7
    description: "Real delivery on a device: one alert at 80% and one at 100% with category name and percentage, none repeated in the month, deferred to the end of quiet hours when inside them"
    requirement: "NOTF-10"
    verification: []
    human_judgment: true
    rationale: "Real notification delivery and quiet-hours timing need a device and a real clock (NOTF-10 manual-only row in the plan)."

duration: 11 min
completed: 2026-10-16
---

# Phase 4 Plan 14: Budget and goal alert evaluators Summary

**Budget alerts at 80% and 100% (once per category per month, persisted, silently seeded) and an on-open goal off-track alert, both dispatched through a shared dispatcher that applies the kind toggle, the permission prompt and quiet-hours deferral.**

## Performance

- **Duration:** 11 min
- **Tasks:** 3 of 3 (Task 1 tracer, Task 2 auto/tdd, Task 3 auto)
- **Files:** 15 (13 created, 2 modified), 3 commits

## Accomplishments

- Tracer: a transaction pushing a category over 80% now flows `watchChanges` -> debounce -> `BudgetAlertEvaluator.evaluate` -> marker written -> `ImmediateAlertDispatcher` -> gateway, proven against `FakeNotificationGateway` and mocked repositories. The tracer gate (end-of-phase mode, automated-only `<verify>`) was re-run (tests, analyze, architecture guard) and passed before expansion.
- `crossedBudgetThreshold` uses integer cents only. `newBudgetKeys` encodes the highest-threshold-only rule (100 also marks 80). `plannedBudgetAlert` builds the notification in the evaluator id namespace with name and percentage only.
- `ImmediateAlertDispatcher` honours the kind toggle, asks for permission once, defers inside quiet hours with `deferOutOfQuietHours` (23:00 -> 07:00 next day) and chooses `showNow` or `schedule` on whether the fire time is after now.
- `BudgetAlertEvaluator.start` prunes stale markers (`isStaleAlertKey`), seeds the month silently, then subscribes with no initial evaluation. `reseedAfterImport` rebuilds budget markers.
- `GoalAlertEvaluator.evaluateOnOpen` writes `gf:<id>:<weekKey>` before dispatching and skips weeks with a fired or scheduled marker; `reseedAfterImport` clears `gf:`/`gs:` and marks currently off-track goals silently.
- `startNotifications()` starts the budget evaluator and runs the goal evaluator once; the lifecycle observer re-runs the goal evaluator on every resume. Each call is isolated by `_fireAndForget`.

## Task Commits

1. **Task 1 (tracer): threshold rule, dispatcher, budget evaluator, README, tests** - `c653f1f` (feat)
2. **Task 2: goal evaluator, seeding, pruning, reseed** - `633fd8d` (feat)
3. **Task 3: startup and resume wiring, DI regenerated, README** - `5764be7` (feat)

**Plan metadata:** committed separately as `docs(04-14): complete budget and goal alert evaluators plan`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extra files to respect the 150-line architecture cap**
- **Found during:** Tasks 1 and 2
- **Issue:** `check_architecture.dart` rejects hand-written files over 150 lines; the evaluator with seeding, pruning and reseed reached 163 lines.
- **Fix:** Extracted `budget_month.dart` (month loader, `crossedThresholds`, `crossedBudgetKeys`), `debounced_single_flight.dart`, and the pure domain helpers `newBudgetKeys`, `plannedBudgetAlert` and `stale_alert_keys.dart`. `budget_alert_evaluator.dart` ends at 149 lines.
- **Files modified:** the files above, plus the matching `stale_alert_keys_test.dart`.
- **Commits:** c653f1f, 633fd8d

**2. [Rule 2 - Missing critical] Extra tests beyond the plan list**
- Added `stale_alert_keys_test.dart`, a debounce-burst test, a repository-error test, a locale-name test, and goal cases for deleted goals, tagged transactions, a new week and a repository error.
- **Commits:** c653f1f, 633fd8d

**3. [Process] Task 2 (`tdd="true"`) was committed as one `feat` commit**
- Implementation and tests were written together and committed once, not as separate RED/GREEN commits. All behavior-list cases are covered by passing tests.

**Total deviations:** 1 Rule 3, 1 Rule 2, 1 process note. **Impact:** none on scope or behavior.

## Issues Encountered

- `flutter analyze` on the touched directories prints one info, `directives_ordering` in `lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart` (plan 04-10, not touched here). It is counted in the project-wide total, so the Task 1 literal "analyze prints any issue" was satisfied for every file this plan touched but not for the directory as a whole. Left alone per the scope boundary.
- `flutter analyze --no-fatal-infos --fatal-warnings`: 64 infos project-wide (budget 65), none in files touched by this plan.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub` (budget_threshold, immediate_alert_dispatcher, budget_alert_evaluator) | 32/32 pass |
| `flutter test --no-pub test/application/notifications test/domain/notifications` | 176/176 pass |
| `flutter test --no-pub` (full suite) | 731/731 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65) |
| `dart run build_runner build --delete-conflicting-outputs` | success, 4 outputs |
| `dart run tool/check_architecture.dart` | PASS |
| `grep -n goalImmediate lib/application/notifications/goal_alert_evaluator.dart` | match (`NotificationIdTypes.goalImmediate`) |
| `grep -n BudgetAlertEvaluator lib/config/startup/notification_startup.dart` | match |

## Human verification outstanding

On the Infinix X6831 (Android 13): set a monthly budget for a category, add transactions to about 80% then 100%, then edit a transaction and repeat the 100% add. Expect one alert at 80% and one at 100% with the category name and percentage only, none repeated in the month, and, inside quiet hours, delivery when quiet hours end. Also check the goal alert after leaving a goal behind schedule and reopening the app.

## Threat Flags

None beyond the plan's register. T-04-14-01 (text is a name and percentage), T-04-14-02 (silent seeding at start and after import), T-04-14-03 (no marker while the kind is off) and T-04-14-04 (300 ms debounce, single-flight) each have a covering test.

## Known Stubs

None.

## Next Phase Readiness

`BudgetAlertEvaluator.reseedAfterImport` and `GoalAlertEvaluator.reseedAfterImport` exist but nothing calls them yet: the backup import flow (a later plan in this phase) must call both after a restore, then request a reconcile.

## Self-Check: PASSED

All 13 created files exist on disk; commits `c653f1f`, `633fd8d` and `5764be7` are present in `git log`; `git rev-list --count 4e16405..HEAD` measured 3 before this SUMMARY commit.
