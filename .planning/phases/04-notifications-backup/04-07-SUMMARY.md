---
phase: 04-notifications-backup
plan: 07
subsystem: notifications-domain
tags: [notifications, planner, debt, recurring-payment, goal, quotes, pure-dart]

requires:
  - phase: 04-notifications-backup
    provides: "04-03 KindPlanner, ReminderPlanner, PlannerInput, day_math, notificationId, AppConstants"
provides:
  - "paymentOccurrence, dayBeforeAt9, nextPaymentReminderDue: anchor-stepped, month-end-clamped, in-memory due dates"
  - "DebtReminderPlanner and PaymentReminderPlanner: once-only 09:00 day-before reminders"
  - "isGoalOffTrack, goalFiredKey, goalScheduledKey and GoalOffTrackPlanner: at most one Monday 09:00 alert per goal per week"
  - "seededPermutation, pickQuote, quotesFor, quotesEn, quotesPt and QuotePlanner: deterministic non-repeating quote slots"
affects: [04-10, 04-12, 04-14]

status: complete
plan_head_before: 5c891a0b2e1a826bae5300d984661df34152a2fc
commits: 4
actuals:
  tokens: 10300
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Recurring dates are always stepped from the original anchor, never chained, so Jan 31 returns to Mar 31 after Feb 28"
    - "The stored nextDueDate is never advanced in the database (D-15); advancement is an in-memory read"
    - "Quote order comes from a private LCG Fisher-Yates, not dart:math Random, so it survives SDK upgrades"

key-files:
  created:
    - lib/domain/notifications/planning/effective_due_date.dart
    - lib/domain/notifications/planning/goal_off_track.dart
    - lib/domain/notifications/planning/goal_alert_keys.dart
    - lib/domain/notifications/planning/quote_picker.dart
    - lib/domain/notifications/planner/debt_reminder_planner.dart
    - lib/domain/notifications/planner/payment_reminder_planner.dart
    - lib/domain/notifications/planner/goal_off_track_planner.dart
    - lib/domain/notifications/planner/quote_planner.dart
    - lib/domain/notifications/quotes/quotes_en.dart
    - lib/domain/notifications/quotes/quotes_pt.dart
    - lib/domain/notifications/quotes/quotes_catalog.dart
    - test/domain/notifications/effective_due_date_test.dart
    - test/domain/notifications/finance_reminder_planners_test.dart
    - test/domain/notifications/goal_off_track_test.dart
    - test/domain/notifications/quote_planner_test.dart
  modified: []

key-decisions:
  - "Off-track comparison carries a 1e-9 epsilon so exactly ten percentage points below is robustly on track despite floating point"
  - "QuotePlanner keeps stepping until the full quoteSlotsAhead entries are planned, so a passed slot today is replaced by a later one instead of leaving 6"
  - "Weekly quotes use Mondays (D-07 gives no weekday); slot index is epochDay ~/ 7"
  - "Bundled quotes stay within 80 columns per line so lines_longer_than_80_chars needs no exemption"

requirements-completed: [NOTF-05, NOTF-06, NOTF-07, NOTF-08]

coverage:
  - id: D1
    description: "Unpaid, non-deleted debts get one reminder at 09:00 the day before due; due-today, overdue, paid and deleted get none; toPay and toReceive differ by variant"
    requirement: "NOTF-05"
    verification:
      - kind: unit
        ref: "test/domain/notifications/finance_reminder_planners_test.dart#DebtReminderPlanner"
        status: pass
    human_judgment: false
  - id: D2
    description: "Recurring payment due dates step from the original anchor with month-end clamping and never write the database"
    requirement: "NOTF-07"
    verification:
      - kind: unit
        ref: "test/domain/notifications/effective_due_date_test.dart#paymentOccurrence"
        status: pass
      - kind: unit
        ref: "test/domain/notifications/finance_reminder_planners_test.dart#a past stored due date advances in memory only"
        status: pass
    human_judgment: false
  - id: D3
    description: "Active payments always have a next reminder; paused and deleted have none"
    requirement: "NOTF-07"
    verification:
      - kind: unit
        ref: "test/domain/notifications/finance_reminder_planners_test.dart#PaymentReminderPlanner"
        status: pass
    human_judgment: false
  - id: D4
    description: "Goal off-track rule (ten percentage points, strict) and one weekly Monday alert per goal honoring fired markers"
    requirement: "NOTF-06"
    verification:
      - kind: unit
        ref: "test/domain/notifications/goal_off_track_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "Deterministic non-repeating quote slots, off by default, deferred by quiet hours; two bundled lists of 50+ unique quotes"
    requirement: "NOTF-08"
    verification:
      - kind: unit
        ref: "test/domain/notifications/quote_planner_test.dart"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-10-16
---

# Phase 4 Plan 07: Finance and quote planners Summary

**Pure debt, recurring-payment, weekly goal off-track and motivational quote planners, with anchor-stepped month-end-clamped due dates computed in memory and two bundled 50+ entry quote lists (EN and PT-BR).**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-16T06:43:26Z
- **Completed:** 2026-10-16
- **Tasks:** 3 (Task 1 tracer, Tasks 2 and 3 TDD)
- **Files:** 15 created, 0 modified

## Accomplishments

- `paymentOccurrence` steps from the original anchor: Jan 31 monthly gives Jan 31, Feb 28, Mar 31 (Feb 29 in a leap year); yearly Feb 29 2028 gives Feb 28 2029. `nextPaymentReminderDue` is bounded at 5000 steps (T-04-07-02) and never mutates the payment.
- `DebtReminderPlanner` fires once at 09:00 the day before due; a debt due today or overdue gets nothing. `PaymentReminderPlanner` always plans the next reminder of an active payment, even when its stored date is long past.
- `isGoalOffTrack` uses `AppConstants.goalOffTrackTolerance` as ten percentage points of the target with a strict comparison; expected progress is clamped to 0..1. `GoalOffTrackPlanner` plans the next Monday 09:00, skipping a week with a `gf:` fired marker, at most one entry per goal.
- `QuotePlanner` is silent unless the quote kind is enabled and the list is non-empty; daily or Monday slots; the picker is a seeded LCG permutation so no quote repeats within one cycle. Verified through `ReminderPlanner` that a 23:00 quote is deferred to 07:00.

## Task Commits

1. **Task 1: Tracer - debt and recurring-payment reminders** - `390d601` (feat)
2. **Task 2 RED: failing goal off-track tests** - `52403b3` (test)
3. **Task 2 GREEN: off-track rule, markers, planner** - `1b12c97` (feat)
4. **Task 3: quotes, picker, QuotePlanner** - `00f05f7` (feat)

**Plan metadata:** committed separately as `docs(04-07)`.

## Tracer feedback gate

Tracer `<verify>` is automated-only and `human_verify_mode` is `end-of-phase`, so it was re-run before expansion (20/20 tests pass, analyze clean). Tracer verified, expansion proceeded.

## Decisions Made

See `key-decisions`. The goal-alert key families are documented in `goal_alert_keys.dart`: the planner reads only `gf:`, plan 04-14's evaluator reads both `gf:` and `gs:`.

## Deviations from Plan

**1. [Rule 1 - Bug] QuotePlanner slot count when today's time has passed**
- **Found during:** Task 3
- **Issue:** The action text loops offsets `0..quoteSlotsAhead-1` and skips past times, which yields 6 slots when today's slot has passed. The behavior list requires 7 slots starting tomorrow.
- **Fix:** Keep stepping until `quoteSlotsAhead` entries are planned. The behavior contract wins over the loop sketch.
- **Files modified:** `lib/domain/notifications/planner/quote_planner.dart`
- **Commit:** `00f05f7`

**2. [Process] Task 3 was not RED-first**
- Task 3 is marked `tdd="true"`, but the implementation and tests were written together and committed as one `feat` commit. All behavior-list cases are covered by passing tests; the RED gate was not separately evidenced for this task. Task 2 followed RED then GREEN (`52403b3`, `1b12c97`).

**Total deviations:** 1 auto-fixed (Rule 1), 1 process note. **Impact:** none on behavior.

## Issues Encountered

None.

## Verification

- `flutter test --no-pub test/domain/notifications`: 123/123 pass.
- `flutter test --no-pub` (full suite): 496/496 pass.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 63 issues (budget 65); none in `lib/domain/notifications` or `test/domain/notifications`.
- `dart run tool/check_architecture.dart`: PASS (`planning/` 5 files, `planner/` 8, `quotes/` 3; all files under 150 lines).
- `grep "package:flutter\|isar_community"` over `planning/` and `planner/`: no match.
- `grep goalOffTrackTolerance` in `goal_off_track.dart`: match (constant, not a literal).

## Threat Flags

None. T-04-07-01 applied: finance planners carry only titles, no amounts or counterparties. T-04-07-02 applied: `maxPaymentSteps = 5000`, returns null past it (tested).

## Known Stubs

None.

## Next Phase Readiness

Plan 04-12 wires these planners into the coordinator and plan 04-14 adds the immediate budget/goal alerts using the `gf:`/`gs:` markers. No blockers.

## Self-Check: PASSED

All 15 files exist; commits `390d601`, `52403b3`, `1b12c97`, `00f05f7` present; `git rev-list --count` from `plan_head_before` is 4.
