---
phase: 04-notifications-backup
plan: 12
subsystem: notifications-sync
tags: [reconcile, coordinator, debounce, single-flight, permission-gate, localisation, lifecycle, injectable]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-03/06/07 ReminderPlanner, six KindPlanners, diffSchedules, payload codec, goalScheduledKey, weekKey"
  - phase: 04-notifications-backup
    provides: "04-09 getRemindableItems / getItemsDueInWindow and watchChanges on budget and payment repositories"
  - phase: 04-notifications-backup
    provides: "04-10 LocalNotificationGateway, NotificationPrefsRepository, AlertStateStore, NotificationPermissionService, NotificationReconciler, notificationL10n, fakes, startNotifications()"
provides:
  - "SnapshotLoader.load: uncapped planner input, first repository Err short-circuits"
  - "NotificationContentBuilder.build: localised title/body for all eight kinds, no amounts, subjects clipped at 100"
  - "ReconcileRunner.run + ReconcileReport: load, plan, localise, diff, apply; idempotent and abort-safe"
  - "PermissionGate.ensureAsked: permission prompt at most once, only on data or preference change"
  - "NotificationSyncCoordinator implements NotificationReconciler: debounced, single-flight, started from main()"
  - "NotificationLifecycleObserver: timezone refresh and resume hooks"
  - "NotificationsModule.reminderPlanner DI composition"
affects: [04-13, 04-14, 04-15, 04-16, 04-17]

plan_head_before: 244eac54b1be944aff424534ee1569bf8bf6c59a
commits: 5
actuals:
  tokens: 14000
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Reconcile is a pure function of (planner output, pending list): owned pending entries are diffed, evaluator-owned ones are only cancelled when their kind is switched off"
    - "Single-flight via an active future plus one shared queued future (queued ??= active.then(start)), so any number of requests behind a running reconcile collapse into one extra run"
    - "Text is localised at schedule time and is part of the diff (title, body, payload), so a locale change or an exact-alarm grant reschedules without any extra trigger"
    - "Permission flag is persisted before the prompt is raised"

key-files:
  created:
    - lib/infrastructure/notifications/content/notification_content_builder.dart
    - lib/infrastructure/notifications/sync/snapshot_loader.dart
    - lib/infrastructure/notifications/sync/permission_gate.dart
    - lib/infrastructure/notifications/sync/reconcile_runner.dart
    - lib/infrastructure/notifications/sync/reconcile_apply.dart
    - lib/infrastructure/notifications/sync/reconcile_report.dart
    - lib/infrastructure/notifications/sync/notification_sync_coordinator.dart
    - lib/config/di/notifications_module.dart
    - lib/config/startup/notification_lifecycle_observer.dart
    - test/infrastructure/notifications/notification_content_builder_test.dart
    - test/infrastructure/notifications/snapshot_loader_test.dart
    - test/infrastructure/notifications/reconcile_runner_test.dart
    - test/infrastructure/notifications/notification_sync_coordinator_test.dart
  modified:
    - lib/config/startup/notification_startup.dart
    - lib/config/di/injection.config.dart

key-decisions:
  - "ReconcileRunner does not take NotificationPrefsRepository: the loader already puts the prefs into PlannerInput, and the runner reads them from there, so a second read could disagree with the one the plan was built from"
  - "The apply step and the disabled-alert filter live in reconcile_apply.dart as top-level functions, because the runner reached 170 lines with them inline (cap is 150)"
  - "An aborted run does not emit on truncatedCount, so a transient read error cannot flip a 'reminders left out' warning off"
  - "Non-owned pending entries are cancelled only when the id decodes as ours AND the payload decodes AND the kind is disabled; anything else is left alone"
  - "Resume hooks are plain callbacks and the timezone refresh is fire and forget, as planned; the 400 ms debounce gives it time to finish before the reconcile reads tz.local"

patterns-established:
  - "Coordinator tests drive a mocked ReconcileRunner and per-source StreamControllers, with NotificationSyncCoordinator.debounceDuration shortened in setUp and restored in tearDown"

requirements-completed: [NOTF-01, NOTF-02, NOTF-04, NOTF-05, NOTF-06, NOTF-07, NOTF-08, NOTF-11]

coverage:
  - id: D1
    description: "A due task becomes a scheduled, localised notification with the exact payload; a second run makes zero schedule or cancel calls; a changed title reschedules only that id; a removed task or disabled kind is cancelled"
    requirement: "NOTF-01"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#a due task is scheduled, localised, with the exact payload"
        status: pass
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#a second run schedules and cancels nothing"
        status: pass
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#changing a title reschedules only that id"
        status: pass
    human_judgment: false
  - id: D2
    description: "A load or pending-list failure aborts the reconcile without cancelling anything"
    requirement: "NOTF-11"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#an aborted load cancels nothing"
        status: pass
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#a failed pending read aborts without touching the schedule"
        status: pass
    human_judgment: false
  - id: D3
    description: "Notification text is localised in en and pt for all eight kinds, plural boundaries 1 and 4, subjects clipped to 100 characters, no amounts"
    requirement: "NOTF-05"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/notification_content_builder_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Snapshot loader sums tagged goal transactions with contributions, loads quotes only when enabled, maps locale, and short-circuits on the first Err"
    requirement: "NOTF-06"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/snapshot_loader_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "Budget alerts and non-decodable foreign entries survive the diff; budget alerts are cancelled only when their kind is switched off"
    requirement: "NOTF-04"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#evaluator-owned alerts"
        status: pass
    human_judgment: false
  - id: D6
    description: "Permission is requested once, only on dataChange or prefsChange that schedules something, never on start, resume or import"
    requirement: "NOTF-01"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#permission gate"
        status: pass
    human_judgment: false
  - id: D7
    description: "Inexact payloads are upgraded to exact once exact alarms are granted; goal one-shots record the gs: week marker; one failing id does not stop the rest"
    requirement: "NOTF-07"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#exact mode inexact payloads are upgraded once exact alarms are granted"
        status: pass
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#a scheduled goal alert records its week marker"
        status: pass
      - kind: unit
        ref: "test/infrastructure/notifications/reconcile_runner_test.dart#one failing id is counted and does not stop the others"
        status: pass
    human_judgment: false
  - id: D8
    description: "Coordinator debounces bursts into one run, queues exactly one run behind a running one, never throws, stops on dispose, emits truncated figures, and subscribes to all six sources on an idempotent start"
    requirement: "NOTF-08"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/notification_sync_coordinator_test.dart"
        status: pass
    human_judgment: false
  - id: D9
    description: "A reminder fires on the Android device 30 minutes before due, survives a reboot without opening the app and survives swiping the app from recents; a time zone change moves it to the new local wall-clock time"
    requirement: "NOTF-11"
    verification: []
    human_judgment: true
    rationale: "Real alarm delivery, boot receiver, OEM battery policy and zone changes cannot be observed on the host VM (assumption A3, Pitfall 1). The pipeline is proven against fakes; the platform plugin and lifecycle observer have no unit tests."

duration: 10 min
completed: 2026-10-16
---

# Phase 4 Plan 12: Notification coordinator and reconcile pipeline Summary

**A debounced, single-flight coordinator reconciles the OS notification schedule on every data, preference, start and resume event: load uncapped planner input, plan, localise, diff against owned pending entries, and apply only the difference, with the permission prompt raised once and only in context.**

## Performance

- **Duration:** 10 min (2026-10-16T07:34:27Z to about 07:45Z, before SUMMARY authoring)
- **Tasks:** 3 of 3 (Task 1 tracer, Tasks 2 and 3 TDD)
- **Files:** 15 (13 created, 2 modified), 5 commits

## Accomplishments

- Tracer: a due task flows through `SnapshotLoader`, `ReminderPlanner`, `NotificationContentBuilder`, `diffSchedules` and the fake gateway. The scheduled request carries the exact payload (`v1|tk|7|<epoch>|e`) and English text. The tracer gate (end-of-phase mode, automated-only `<verify>`) was re-run and passed before expansion.
- Idempotence is proven by counting `schedule` calls: a second run makes zero schedule and zero cancel calls, and a changed title reschedules exactly one id.
- Abort safety (T-04-12-01): a loader `Err` and a failing `pending()` both return `ReconcileReport.aborted()` with nothing cancelled or scheduled.
- Evaluator-owned alerts (budget, immediate goal) never enter the diff. They are cancelled only when the id decodes, the payload decodes and the kind is disabled. A pending entry with a foreign id and an undecodable payload is left untouched.
- `PermissionGate` persists the asked flag before prompting. The runner calls it only for `dataChange` or `prefsChange` reconciles with something to schedule; start, resume and import never ask.
- The exact-alarm mode is part of the payload, so granting exact alarms reschedules the same planned set from `i` to `e` with no extra trigger.
- Goal off-track one-shots record `gs:<goalId>:<weekKey>` after a successful schedule.
- `NotificationSyncCoordinator` subscribes to items, debts, goals, transactions, payments and prefs. Five requests in the window run once; any number of requests behind a running reconcile produce exactly one extra run; `dispose` stops everything; a throwing runner is contained.
- `startNotifications()` now starts the coordinator (fire and forget, errors swallowed) and registers `NotificationLifecycleObserver`, whose single hook requests an `appResume` reconcile. Plan 04-14 appends its evaluator hooks to that list.

## Task Commits

1. **Task 1 (tracer): reconcile pipeline from snapshot load to schedule diff** - `175cd93` (feat)
2. **Task 2 RED: failing tests for gate, protected alerts, exact upgrade** - `68e2858` (test)
3. **Task 2 GREEN: permission gate, alert protection, goal week markers** - `79bdf34` (feat)
4. **Task 3 RED: failing coordinator tests** - `a1e2f4d` (test)
5. **Task 3 GREEN: coordinator, lifecycle observer, startup wiring** - `9a519c0` (feat)

**Plan metadata:** committed separately as `docs(04-12): complete notification coordinator plan`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Apply step extracted to `reconcile_apply.dart`, report to `reconcile_report.dart`**
- **Found during:** Task 2
- **Issue:** With the gate, the disabled-alert filter and the goal-week marker inline, `reconcile_runner.dart` was 170 lines against the 150-line architecture cap.
- **Fix:** `applyDiff` and `disabledAlertIds` became top-level functions in `reconcile_apply.dart`; `ReconcileReport` has its own file. `sync/` holds 7 files (cap 10); the runner is 113 lines.
- **Commit:** 79bdf34

**2. [Rule 1 - Design] `ReconcileRunner` does not inject `NotificationPrefsRepository`**
- **Issue:** The plan lists it, but the runner never needs it: preferences arrive inside `PlannerInput`, and reading them a second time could differ from the set the plan was built from.
- **Fix:** Omitted the dependency. The runner is built from the loader, planner, content builder, gateway, permission service, gate and alert store.
- **Commit:** 175cd93, 79bdf34

**3. [Process] Task 1 (tracer) tests were written together with the implementation**
- Tasks 2 and 3 followed RED then GREEN with separate commits (`68e2858`, `a1e2f4d`; both RED states were compile failures). The tracer is `type="tracer"`, not `tdd="true"`, so this follows the plan.

**Total deviations:** 1 Rule 3, 1 design simplification, 1 process note. **Impact:** none on scope or behavior.

## Issues Encountered

- `flutter analyze` on the touched directories reports one `directives_ordering` info in `lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart:9`. It predates this plan (plan 04-10) and is out of scope; the project-wide count is 64, inside the budget of 65.
- The full suite takes longer than 120 s on this host and was run in the background.
- `rtk` condenses `ls`, `grep` and `cat` output; `rtk proxy` was used for exact reads.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub test/infrastructure/notifications test/config test/widget_test.dart` | 84/84 pass |
| `flutter test --no-pub` (full suite) | 664/664 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65) |
| `dart run tool/check_architecture.dart` | PASS |
| `dart run build_runner build --delete-conflicting-outputs` | exit 0, `injection.config.dart` registers `NotificationSyncCoordinator` |
| `grep diffSchedules reconcile_runner.dart` | match |
| `grep ensureAsked reconcile_runner.dart` | match |
| `grep "amountCents\|formatAmount" lib/infrastructure/notifications/content` | no match |
| `grep "start()" lib/config/startup/notification_startup.dart` | match |

## Human verification outstanding

Both checks need the Infinix X6831 (Android 13) and cannot run on the host VM:

1. Create a task due in 35 minutes, wait for the reminder (expect it 30 minutes before due in the Tasks channel), then create another due tomorrow, reboot without opening the app and confirm it still fires (boot receiver, NOTF-11). Swiping the app from recents must not cancel it.
2. Change the device time zone (for example to UTC-3) with a reminder pending, reopen the app and confirm the reminder fires at the new local wall-clock time (Pitfall 1). The observer refreshes `tz.local` on resume; the plugin gateway and the observer have no unit tests.

This also covers the plan 04-10 outstanding check (channel names in PT-BR, lock-screen privacy).

## Threat Flags

None beyond the plan's register. T-04-12-01 (aborted reports change nothing) and T-04-12-02 (evaluator alerts protected) are covered by tests; T-04-12-03 by the content builder (titles only, clipped to 100, no amount fields); T-04-12-04 by the debounce and single-flight tests.

## Known Stubs

None.

## Next Phase Readiness

Plans 04-13 to 04-17 can depend on `NotificationReconciler` from GetIt (`requestReconcile` for the settings cubit, `reconcileNow(afterImport)` for the backup flow, `truncatedCount` for the waiting-reminders banner). Plan 04-14 appends its on-open evaluator hooks to the resume hook list in `startNotifications()` and reads the `gs:` week markers this plan writes.

## Self-Check: PASSED

All 13 created files exist on disk; commits `175cd93`, `68e2858`, `79bdf34`, `a1e2f4d` and `9a519c0` are present in `git log`; `git rev-list --count 244eac5..HEAD` measured 5 before this SUMMARY commit.
