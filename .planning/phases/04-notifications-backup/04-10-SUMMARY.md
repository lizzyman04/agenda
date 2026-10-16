---
phase: 04-notifications-backup
plan: 10
subsystem: notifications-platform-seam
tags: [flutter_local_notifications, timezone, shared_preferences, injectable, android-channels, permissions]

requires:
  - phase: 04-notifications-backup
    provides: "04-03 notification domain model (NotificationKind, NotificationPrefs, ScheduleRequest)"
  - phase: 04-notifications-backup
    provides: "04-05 pinned dependencies, manifest, Confirmed API names table"
provides:
  - "Domain interfaces: LocalNotificationGateway, NotificationPrefsRepository, AlertStateStore, NotificationPermissionService, NotificationReconciler"
  - "SharedPreferences prefs and alert-state implementations behind StorageKeys"
  - "FlutterLocalNotificationsGateway with eight versioned private channels"
  - "NotificationPermissionServiceImpl, bootstrapTimezone, startNotifications() hook in main()"
  - "FakeNotificationGateway and FakeNotificationPermissionService for 04-12, 04-14, 04-15"
affects: [04-12, 04-13, 04-14, 04-15, 04-16]

plan_head_before: c8eaba8546fc6ed82c9d028bc8e7dc05d9dc60b2
commits: 3
actuals:
  tokens: 13000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Plugin and timezone packages are imported only under lib/infrastructure/notifications/gateway; domain sees interfaces only"
    - "Every plugin call goes through one _run guard that returns Err(NotificationFailure) carrying only the exception type"
    - "Persist-then-emit prefs repository with a broadcast watch() stream"

key-files:
  created:
    - lib/domain/notifications/local_notification_gateway.dart
    - lib/domain/notifications/notification_prefs_repository.dart
    - lib/domain/notifications/alert_state_store.dart
    - lib/domain/notifications/notification_permission_service.dart
    - lib/domain/notifications/notification_reconciler.dart
    - lib/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart
    - lib/infrastructure/notifications/prefs/alert_state_store_impl.dart
    - lib/infrastructure/notifications/gateway/notification_channels.dart
    - lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart
    - lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart
    - lib/infrastructure/notifications/gateway/timezone_bootstrap.dart
    - lib/config/startup/notification_startup.dart
    - test/infrastructure/notifications/fake_notification_gateway.dart
    - test/infrastructure/notifications/notification_prefs_repository_test.dart
    - test/infrastructure/notifications/alert_state_store_test.dart
    - test/infrastructure/notifications/notification_channels_test.dart
  modified:
    - lib/core/constants/storage_keys.dart
    - lib/config/di/infrastructure_module.dart
    - lib/config/di/injection.config.dart
    - lib/main.dart

key-decisions:
  - "Channel ids are agenda_<name>_v1, one per NotificationKind; quotes use default importance, all others high"
  - "All Android notifications use NotificationVisibility.private; Darwin initialization sets all three request flags false"
  - "Quote seed is created on first read and written with an unawaited setInt; stable because SharedPreferences updates its in-memory cache synchronously"
  - "startNotifications() swallows every failure; bootstrapTimezone falls back to UTC and returns Err instead of throwing"

requirements-completed: [NOTF-01, NOTF-09, NOTF-10, NOTF-11]

coverage:
  - id: D1
    description: "Notification prefs persist, clamp, default quotes off, and emit on watch after save"
    requirement: "NOTF-09"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/notification_prefs_repository_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Alert-state store is idempotent, supports prefix removal, clear and persists across instances"
    requirement: "NOTF-10"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/alert_state_store_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "Eight distinct _v1 channels, both locales named, private visibility, iOS thread identifier"
    requirement: "NOTF-01"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/notification_channels_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "DI graph resolves with the new registrations and the app shell still renders"
    requirement: "NOTF-11"
    verification:
      - kind: unit
        ref: "test/config/di/di_test.dart"
        status: pass
      - kind: unit
        ref: "test/widget_test.dart#App renders bottom navigation shell"
        status: pass
    human_judgment: false
  - id: D5
    description: "Plugin delivery, channel creation, permission prompts, exact-alarm screen and lock-screen privacy on a real device"
    verification: []
    human_judgment: true
    rationale: "Plugin calls (zonedSchedule, createNotificationChannel, permission requests) need a platform channel and cannot run on the host VM; the gateway and permission service have no unit tests, only compile-time and DI coverage"

duration: 9 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 10: Notification platform seam Summary

**Gateway, permission service, timezone bootstrap and prefs/alert-state stores behind five domain interfaces, with eight versioned private Android channels, no permission prompt at init, and a failure-proof `startNotifications()` hook in `main()`.**

## Performance

- **Duration:** 9 min (2026-10-16T07:04:37Z to 07:13:41Z, before SUMMARY authoring)
- **Tasks:** 3 of 3
- **Files:** 20 (16 created, 4 modified)

## Accomplishments

- Domain interfaces for the gateway, prefs, alert state, permission and reconciler. `NotificationReconciler` and `ReconcileReason` are contract-only here; plan 04-12 implements them.
- `NotificationPrefsRepositoryImpl`: reads every key with `NotificationPrefs.defaults()` fallbacks, clamps minutes to 0..1439, treats an unknown frequency as daily, creates a positive quote seed on first read, and emits on `watch()` only after the writes complete.
- `AlertStateStoreImpl`: de-duplicated sorted string list under `StorageKeys.notifAlertState`; writes are skipped when nothing changes.
- `notification_channels.dart`: `channelIdFor`, `notificationL10n`, `androidChannels`, `detailsFor`. Eight channels, `NotificationVisibility.private`, `groupKey: agenda_<code>`, iOS `threadIdentifier` = kind code.
- `FlutterLocalNotificationsGateway`: `initialize()` is guarded and never prompts (all three Darwin request flags false); `schedule` converts to `TZDateTime` in `tz.local` and picks exact or inexact `AndroidScheduleMode` per request; `showNow`, `cancel`, `pending`, `launchPayload` follow. Tap payloads forward as raw strings only.
- `NotificationPermissionServiceImpl`: Android enabled/request/exact checks, iOS alert+sound only (no badge), all guarded to a safe default.
- `bootstrapTimezone()` and `startNotifications()` wired into `main()` between Isar open and `runApp`.
- `StorageKeys`: seven new `notif*` constants; the three quiet-hours docs now say minutes since midnight.

## Task Commits

1. **Task 1 (tracer): prefs repository and gateway contract with fake** - `cc201cd` (feat)
2. **Task 2: alert-state store, permission and reconciler contracts, versioned channels** - `41be9b1` (feat)
3. **Task 3: plugin gateway, permission service, timezone bootstrap, DI and startup hook** - `527234d` (feat)

Tracer feedback gate: `workflow.human_verify_mode` is `end-of-phase` and the tracer's `<verify>` is automated-only, so its test and analyze were re-run before Task 2 and passed ("Tracer verified end-to-end").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Architecture guard: gateway file was 159 lines**
- **Found during:** Task 3 verification (`dart run tool/check_architecture.dart` reported `LINES ... 159 > 150`)
- **Issue:** Three near-identical try/catch blocks pushed the file over the 150-line house rule.
- **Fix:** Extracted a private `_run(what, body)` guard used by `schedule`, `showNow` and `cancel`. The file is now 148 lines, and the Err message keeps only the exception type.
- **Files modified:** `lib/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart`
- **Commit:** `527234d` (fixed before the task commit)

**2. [Rule 3 - Blocking] `dart format` reformatted six unrelated files**
- **Found during:** Task 1 (formatting `lib/domain/notifications` and `test/infrastructure/notifications` as a directory)
- **Issue:** Pre-existing planner, rules and 04-05 test files are not `dart format` clean; formatting the directory rewrote them.
- **Fix:** Restored those six files with a path-by-path `git checkout --`; afterwards only explicitly named files were formatted.
- **Commit:** none (no change reached a commit)

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). **Impact:** none on scope or behavior.

## Issues Encountered

- The first `Write` of the gateway used a placeholder type name (`AppLocalizationsHolder`); caught immediately and replaced with `AppLocalizations` before any analyze or commit.
- A stash entry `stash@{0}: rewrite` exists in the repository. It predates this plan and was not touched.

## Verification

| Check | Result |
|-------|--------|
| `dart run build_runner build --delete-conflicting-outputs` | exit 0, injection.config.dart regenerated (registers prefs, alert store, gateway, permission service, plugin) |
| `flutter test --no-pub` (full suite) | 568/568 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65) |
| `dart run tool/check_architecture.dart` | PASS |
| `grep package:flutter_local_notifications\|package:timezone lib/domain` | no match |
| `requestAlertPermission/Sound/Badge: false` in gateway | 3 matches |
| `startNotifications` in `lib/main.dart` | present |

## Human verification outstanding

Plugin delivery, channel names in PT-BR, the notification and exact-alarm permission flows and lock-screen privacy cannot run on the host VM. Not testable until plan 04-12 supplies a trigger: after 04-12, create a task due in 35 minutes on the Android device and wait for the T-30 reminder. Expect it in the Tasks channel, channel names in PT-BR under long-press, and hidden content on a secure lock screen (assumption A17, OEM behavior varies).

## Threat Flags

None beyond the plan's register. T-04-10-01 (private visibility), T-04-10-02 (raw payload forwarded, parsing deferred to 04-13), T-04-10-03 (per-call Err wrapping) and T-04-10-04 (no prompt at init) are implemented as planned.

## Known Stubs

None.

## Next Phase Readiness

04-12 (coordinator) can depend on `LocalNotificationGateway`, `NotificationPermissionService`, `NotificationPrefsRepository`, `AlertStateStore` and `NotificationReconciler`, and test against `FakeNotificationGateway` and `FakeNotificationPermissionService`. `startNotifications()` has a documented spot for the coordinator start and lifecycle observer.

## Self-Check: PASSED

All 20 files verified on disk; commits `cc201cd`, `41be9b1`, `527234d` present.
