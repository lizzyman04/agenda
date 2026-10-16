---
phase: 04-notifications-backup
plan: 13
subsystem: notifications-navigation
tags: [tap-routing, payload-validation, app-shell, notifiers, locale-reconcile, cold-start]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-03 decodePayload / NotificationKind"
  - phase: 04-notifications-backup
    provides: "04-10 LocalNotificationGateway (tapPayloads, launchPayload), NotificationReconciler, FakeNotificationGateway"
  - phase: 04-notifications-backup
    provides: "04-12 NotificationSyncCoordinator registered as NotificationReconciler"
provides:
  - "TapTarget (sealed) and resolveTapTarget(payload): pure, never throws, unknown input -> AppOnly"
  - "NotificationTapListener: live taps via tapPayloads, cold-start tap once after the first frame"
  - "openTapTarget: tab/sub-tab navigation and task/goal detail push after an existence and deletedAt re-check"
  - "appTabIndex and financeSubTabRequest notifiers (presentation/shell)"
  - "AppShell extracted from app.dart; app.dart down from 145 to 87 lines"
  - "Locale change requests a ReconcileReason.localeChange reconcile"
affects: [04-14, 04-15, 04-16, 04-17]

plan_head_before: 7e24bf35160d34766ab03b7e07544087093dc8d4
commits: 2
actuals:
  tokens: 9000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Shared ValueNotifiers for tab selection and a one-shot sub-tab request, so code outside the shell can navigate"
    - "Untrusted payload -> strict decode -> sealed target -> entity re-load and deletedAt check -> navigate; every failure degrades to a tab"
    - "Cold-start payload read in a post-frame callback; every use guarded by mounted"

key-files:
  created:
    - lib/domain/notifications/rules/tap_target.dart
    - lib/presentation/shell/shell_navigation.dart
    - lib/presentation/shell/app_shell.dart
    - lib/presentation/shell/README.md
    - lib/presentation/notifications/README.md
    - lib/presentation/notifications/routing/README.md
    - lib/presentation/notifications/routing/tap_navigator.dart
    - lib/presentation/notifications/routing/notification_tap_listener.dart
    - test/domain/notifications/tap_target_test.dart
    - test/presentation/notifications/notification_tap_listener_test.dart
  modified:
    - lib/app.dart
    - lib/presentation/finance/screens/finance_dashboard_screen.dart
    - lib/presentation/finance/screens/README.md
    - test/widget_test.dart

key-decisions:
  - "The Finance sub-tab hook also runs once in a post-frame callback, so a request set before the screen mounts is not lost"
  - "Detail routes are pushed with unawaited(push) so the tap handler's future completes instead of waiting for the user to pop the route"
  - "Sub-tab request is cleared (set to null) on every tab navigation that is not a Finance sub-tab, so a stale request never fires later"

requirements-completed: [NOTF-01, NOTF-02, NOTF-03, NOTF-05, NOTF-06, NOTF-07]

coverage:
  - id: D1
    description: "Every notification kind maps to a defined target; null, malformed, wrong-version and unknown-kind payloads resolve to AppOnly"
    requirement: "NOTF-01"
    verification:
      - kind: unit
        ref: "test/domain/notifications/tap_target_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "A task tap opens its detail screen; a missing or soft-deleted task stays on the Tasks tab; invalid payloads change nothing and throw nothing; a launch payload is handled once"
    requirement: "NOTF-02"
    verification:
      - kind: widget
        ref: "test/presentation/notifications/notification_tap_listener_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "A debt payload selects the Finance tab with the Debts sub-tab requested; the Finance screen applies the request and resets it"
    requirement: "NOTF-05"
    verification:
      - kind: widget
        ref: "test/presentation/notifications/notification_tap_listener_test.dart#a debt payload selects Finance on the Debts sub-tab"
        status: pass
      - kind: widget
        ref: "test/widget_test.dart#A Finance sub-tab request moves the tab bar and resets"
        status: pass
    human_judgment: false
  - id: D4
    description: "The app shell test still passes with the fake gateway; app.dart stays well under the 150-line cap"
    requirement: "NOTF-06"
    verification:
      - kind: widget
        ref: "test/widget_test.dart#App renders bottom navigation shell"
        status: pass
      - kind: command
        ref: "dart run tool/check_architecture.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "A language change triggers a reconcile so scheduled notification text is refreshed"
    requirement: "NOTF-07"
    verification: []
    human_judgment: true
    rationale: "The BlocListener in app.dart has no dedicated test (the coordinator and the localeChange reason are tested in 04-12). Needs a device check: switch language, then read a pending notification."
  - id: D6
    description: "Tapping a real delivered notification (app in background and fully closed) lands on the right screen, including a deleted task"
    requirement: "NOTF-03"
    verification: []
    human_judgment: true
    rationale: "Cold-start launch details and notification taps need a real notification on a device; the tap path is proven against the fake gateway only."

duration: 8 min
completed: 2026-10-16
---

# Phase 4 Plan 13: Notification tap routing and app shell extraction Summary

**A tapped notification now resolves through a pure, strictly validated `TapTarget` and lands on the task detail, a Finance sub-tab or a goal detail, with every malformed or stale case degrading to the Tasks tab; the bottom-nav shell moved out of `app.dart` and is driven by shared notifiers.**

## Performance

- **Duration:** 8 min (2026-10-16T07:46Z to 07:53Z, before SUMMARY authoring)
- **Tasks:** 2 of 2 (Task 1 tracer, Task 2 auto)
- **Files:** 14 (10 created, 4 modified), 2 commits

## Accomplishments

- Tracer: `resolveTapTarget` -> `NotificationTapListener` -> `openTapTarget` -> `TaskDetailScreen`, proven end to end against `FakeNotificationGateway`. The tracer gate (end-of-phase mode, automated-only `<verify>`) was re-run (tests and analyze) and passed before expansion.
- Mapping: task and recurring-task -> task detail; briefing -> Tasks tab; budget -> Finance/Budgets (2); debt -> Finance/Debts (4); recurring payment -> Finance/Recurring (5); goal -> Finance/Goals (3) then goal detail; quote -> app only.
- Spoofing mitigation (T-04-13-01): strict `decodePayload`, then the id is only used to load the entity and `deletedAt` is checked before a detail route is pushed. Repository errors and exceptions are swallowed in the listener.
- Cold start: `launchPayload()` is read once in a post-frame callback; live taps use the broadcast stream; the subscription is cancelled on dispose and `mounted` guards every use.
- `AppShell` (73 lines) replaces the private shell; `app.dart` is 87 lines. Tab selection is `appTabIndex`; `FinanceDashboardScreen` consumes `financeSubTabRequest` through a private listener and resets it.
- `BlocListener<LocaleCubit>` with a locale-compare `listenWhen` requests `ReconcileReason.localeChange` (Pitfall 9).

## Task Commits

1. **Task 1 (tracer): tap target resolver, listener, navigator, notifiers, READMEs, tests** - `3fcca70` (feat)
2. **Task 2: shell extraction, finance sub-tab hook, locale reconcile, widget test** - `59f0973` (feat)

**Plan metadata:** committed separately as `docs(04-13): complete tap routing plan`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `presentation/shell/README.md` and `shell_navigation.dart` created in Task 1**
- **Found during:** Task 1
- **Issue:** Task 1's acceptance runs the architecture guard, which requires a README in every `presentation/` directory. `shell_navigation.dart` (Task 1) creates `presentation/shell/`, but the plan assigns the README to Task 2.
- **Fix:** Created the shell README in Task 1 with the single file, extended it with `app_shell.dart` in Task 2.
- **Commits:** 3fcca70, 59f0973

**2. [Rule 2 - Missing critical] Extra tests beyond the plan list**
- Added a soft-deleted-task case and a debt sub-tab case to the listener tests, and a Finance sub-tab hook test to `test/widget_test.dart` (the plan keeps the existing test intact; it is untouched, one test was added).
- **Commits:** 3fcca70, 59f0973

**3. [Process] `dart format` on touched files re-wrapped `app.dart`, `finance_dashboard_screen.dart` and `test/widget_test.dart`**
- The project formatter style differs from the older hand formatting, so those diffs are larger than the logical change. Only touched files were formatted.

**Total deviations:** 1 Rule 3, 1 Rule 2, 1 process note. **Impact:** none on scope or behavior.

## Issues Encountered

- `flutter analyze --no-fatal-infos --fatal-warnings`: 64 infos project-wide (budget 65), none in files touched by this plan.
- The full suite takes about two minutes on this host.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub test/domain/notifications/tap_target_test.dart test/presentation/notifications/notification_tap_listener_test.dart` | 12/12 pass |
| `flutter test --no-pub test/widget_test.dart test/presentation` | 86/86 pass |
| `flutter test --no-pub` (full suite) | 677/677 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65) |
| `flutter analyze` on touched notification/shell dirs and tests | No issues found |
| `dart run tool/check_architecture.dart` | PASS |
| `wc -l lib/app.dart` | 87 (< 150); `grep AppShell lib/app.dart` matches |

## Human verification outstanding

On the Infinix X6831 (Android 13), with a pending reminder:

1. Tap the delivered notification with the app in the background and fully closed. A task notification opens that task's detail; a briefing opens the Tasks tab; a debt notification opens Finance on Debts; a deleted task opens the Tasks tab without crashing. Repeat for a budget alert once plan 04-14 exists.
2. Switch the app language, then inspect a pending notification: its text should be in the new language (the locale `BlocListener` has no unit test of its own).

## Threat Flags

None beyond the plan's register. T-04-13-01 is covered by the resolver and listener tests (malformed, wrong version, missing and soft-deleted entities). T-04-13-03 relies on `exported=false` receivers from plan 04-05, unchanged here.

## Known Stubs

None.

## Next Phase Readiness

Plan 04-14 can append its on-open evaluator hooks to the resume hook list in `startNotifications()`. Plan 04-15 adds `screens/` and `widgets/` under `presentation/notifications/` (the umbrella README already describes them) and can reuse `appTabIndex` for any in-app deep link.

## Self-Check: PASSED

All 10 created files exist on disk; commits `3fcca70` and `59f0973` are present in `git log`; `git rev-list --count 7e24bf3..HEAD` measured 2 before this SUMMARY commit.
