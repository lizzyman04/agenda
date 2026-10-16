---
phase: 04-notifications-backup
plan: 06
subsystem: notifications-domain
tags: [notifications, planner, task-reminders, morning-briefing, pure-dart]

requires:
  - phase: 04-notifications-backup
    provides: "04-03 KindPlanner, ReminderPlanner, PlannerInput, day_math, notificationId"
provides:
  - "taskFireAt and formatHhmm: D-01 fire-time rule built from calendar components"
  - "TaskReminderPlanner: taskReminder and recurringTaskReminder entries (own kind per series, NOTF-04)"
  - "BriefingPlanner: one morningBriefing per day over the 7-day horizon with count and top 3 titles"
affects: [04-09, 04-10, 04-12]

status: complete
plan_head_before: c9e89673b3af97e1af477fddcef76580de7e14b7
actuals:
  tokens: 5500
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Kind planners are pure functions of PlannerInput with an injected now; toggles, quiet hours, de-dup and budget stay in ReminderPlanner"
    - "Fire times are built with DateTime component arithmetic (atMinutes) so DST cannot shift a reminder"
    - "Briefing text is precomputed at schedule time because a delivered notification cannot run code"

key-files:
  created:
    - lib/domain/notifications/planning/task_fire_time.dart
    - lib/domain/notifications/planner/task_reminder_planner.dart
    - lib/domain/notifications/planner/briefing_planner.dart
    - test/domain/notifications/task_reminder_planner_test.dart
    - test/domain/notifications/briefing_planner_test.dart
  modified: []

key-decisions:
  - "D-04 is structural: the repository materialises only the next occurrence of a recurring item, so TaskReminderPlanner never expands recurrences"
  - "A due time of 00:10-00:29 fires the previous evening (23:40-23:59), which quiet hours then defer to 07:00 of the due day, after the due time; consequence of D-01 plus D-08, recorded rather than special-cased"
  - "Briefing ordering: timed tasks by due time, then date-only, ties by case-insensitive title then id"

requirements-completed: [NOTF-01, NOTF-02, NOTF-04]

coverage:
  - id: D1
    description: "Timed task reminds 30 minutes before; date-only task reminds at briefing time on its due day"
    requirement: "NOTF-01"
    verification:
      - kind: unit
        ref: "test/domain/notifications/task_reminder_planner_test.dart#TaskReminderPlanner"
        status: pass
    human_judgment: false
  - id: D2
    description: "Recurring tasks use their own kind and can be disabled independently"
    requirement: "NOTF-04"
    verification:
      - kind: unit
        ref: "test/domain/notifications/task_reminder_planner_test.dart#disabling the recurring kind drops only recurring reminders"
        status: pass
    human_judgment: false
  - id: D3
    description: "Morning briefing per day with count, top 3 titles, empty-day and past-time skip, quiet-hours deferral"
    requirement: "NOTF-02"
    verification:
      - kind: unit
        ref: "test/domain/notifications/briefing_planner_test.dart#BriefingPlanner"
        status: pass
    human_judgment: false
  - id: D4
    description: "Completed, deleted, project and undated items never produce reminders or count toward a briefing"
    requirement: "NOTF-01"
    verification:
      - kind: unit
        ref: "test/domain/notifications/task_reminder_planner_test.dart#completed, deleted, project and undated items are skipped"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-10-16
---

# Phase 4 Plan 06: Task reminder and briefing planners Summary

**Pure task-side kind planners: D-01 reminders (30 minutes before a due time, briefing time for date-only tasks), a separate recurring kind, and a per-day morning briefing with count and top 3 titles, all plugged into ReminderPlanner without editing it.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-10-16T06:37:48Z
- **Completed:** 2026-10-16
- **Tasks:** 2 (Task 1 tracer, Task 2 TDD)
- **Files:** 5 created, 0 modified

## Accomplishments

- `taskFireAt` returns the D-01 fire time or null (no due date, or not strictly after `now`); `formatHhmm` zero-pads without intl.
- `TaskReminderPlanner` emits one entry per eligible item with id `notificationId(kind.idBase, item.id, kind.idType)`, variant 0 (timed, extras `['HH:mm']`) or 1 (date-only), and skips ids above `maxNotificationEntityId` instead of throwing.
- `BriefingPlanner` emits one `morningBriefing` per day for 7 calendar days starting today, id keyed by `epochDay`, titles clipped to 60 characters plus an ellipsis.
- The tracer was proven through a real `ReminderPlanner` (quiet-hours deferral and per-kind toggle), and the 00:20 edge case is pinned: fire 23:50 the previous evening, deferred to 07:00 of the due day.

## Task Commits

1. **Task 1: Tracer - due task to quiet-hours-aware reminder** - `fb41b01` (feat)
2. **Task 2 RED: failing briefing tests** - `364ed87` (test)
3. **Task 2 GREEN: BriefingPlanner** - `402380d` (feat)

**Plan metadata:** committed separately as `docs(04-06)`.

## Tracer feedback gate

The tracer `<verify>` is automated-only and `human_verify_mode` is `end-of-phase`, so it was re-run end to end before expansion: `task_reminder_planner_test.dart` 15/15 pass, `flutter analyze lib/domain/notifications test/domain/notifications` clean. Tracer verified, expansion proceeded.

## Files Created

- `lib/domain/notifications/planning/task_fire_time.dart` - `taskFireAt`, `formatHhmm`
- `lib/domain/notifications/planner/task_reminder_planner.dart` - `TaskReminderPlanner`
- `lib/domain/notifications/planner/briefing_planner.dart` - `BriefingPlanner`
- `test/domain/notifications/task_reminder_planner_test.dart`, `test/domain/notifications/briefing_planner_test.dart`

## Decisions Made

See `key-decisions` above. The 00:10 edge case (reminder deferred to after the due time) is a direct consequence of D-01 plus D-08 and is documented, not hidden.

## Deviations from Plan

None - plan executed exactly as written. Two cosmetic follow-ups inside Task 1 and Task 2 (removing redundant default arguments flagged by `avoid_redundant_argument_values`, and a cascade in the briefing sort) were made before committing to keep the analyzer clean; they changed no behavior.

## Issues Encountered

None.

## Verification

- `flutter test --no-pub test/domain/notifications`: 81/81 pass.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 63 issues (budget 65).
- `dart run tool/check_architecture.dart`: PASS; `planner/` holds 3 files (cap 10).
- `grep "package:flutter\|isar_community"` over `planning/` and `planner/`: no match.

## Threat Flags

None. T-04-06-01 mitigation applied: titles are clipped to 60 characters in `extras`; no amounts or descriptions are carried. Lock-screen visibility is plan 04-10's job.

## Known Stubs

None.

## Next Phase Readiness

Plan 04-09 supplies the uncapped sorted reads that feed `items` and `windowItems`; plan 04-12 wires these planners into the coordinator. No blockers.

## Self-Check: PASSED

All five files exist; commits `fb41b01`, `364ed87`, `402380d` present; `git rev-list --count` from `plan_head_before` is 3.
