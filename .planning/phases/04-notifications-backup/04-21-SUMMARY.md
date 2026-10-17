---
phase: 04-notifications-backup
plan: 21
subsystem: notifications
tags: [permissions, platform-channel, android, ios, gap-closure]
requires: [04-18]
provides:
  - On-open goal alert that never raises the permission prompt and keeps its week marker on failure
  - agenda/system_settings platform channel (Dart, Kotlin, Swift) opening the app notification settings
  - Denied banner that flips to "Open settings" after a refused request
affects: []
tech-stack:
  added: []
  patterns: [three-language source-text contract test for a platform channel]
key-files:
  created:
    - test/infrastructure/notifications/system_settings_channel_test.dart
  modified:
    - lib/infrastructure/notifications/sync/immediate_alert_dispatcher.dart
    - lib/application/notifications/goal_alert_evaluator.dart
    - lib/application/notifications/notification_settings_cubit.dart
    - lib/application/notifications/notification_settings_state.dart
    - lib/application/notifications/README.md
    - lib/domain/notifications/notification_permission_service.dart
    - lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart
    - lib/presentation/notifications/screens/notification_settings_body.dart
    - android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt
    - ios/Runner/AppDelegate.swift
    - test/infrastructure/notifications/fake_notification_gateway.dart
    - test/infrastructure/notifications/immediate_alert_dispatcher_test.dart
    - test/application/notifications/goal_alert_evaluator_test.dart
    - test/application/notifications/notification_settings_cubit_test.dart
    - test/presentation/notifications/notification_settings_screen_test.dart
key-decisions:
  - "Dispatch keeps prompting by default; only the on-open goal path passes promptIfNeeded: false, so budget alerts are unchanged"
  - "The banner flips label after the first refused request instead of opening settings immediately, because the OS cannot tell a suppressed dialog from a refused one"
  - "Refresh/request state transitions live on NotificationSettingsLoaded (afterRequest, afterRefresh) to keep the cubit at the 150-line guard"
requirements-completed: [NOTF-01, NOTF-06]
status: complete
commits: 3
plan_head_before: 15f216dd323e6c89cd9f35720c32cb87d2dfe216
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
metrics:
  completed: 2026-10-17
---

# Phase 4 Plan 21: Permission flow fixes (WR-06, WR-07) Summary

Opening the app can no longer show the notification permission dialog, an unasked or refused permission no longer eats a goal's weekly alert, and a refused permission now has a route to the system notification settings through a small `agenda/system_settings` channel.

## Tasks

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: on-open goal alert never prompts and keeps its week marker | bf1ffed |
| 2 | Open-settings channel: service method, Android and iOS handlers, contract | c3c225c |
| 3 | Banner flips to "Open settings" after a refused request | 0fe657c |

### Task 1 (tracer)
`ImmediateAlertDispatcher.dispatch` gained `promptIfNeeded` (default true). When false it reads the permission and returns false unless granted, without touching the `PermissionGate`. `GoalAlertEvaluator.evaluateOnOpen` still writes the `gf:` marker first (crash safety) but now dispatches with `promptIfNeeded: false` and removes that one marker when dispatch returns false.

RED evidence: the dispatcher tests and the evaluator tests failed to compile before the change ("No named parameter with the name 'promptIfNeeded'"). After the change all of `test/infrastructure/notifications/immediate_alert_dispatcher_test.dart` and `test/application/notifications` pass, including the unchanged budget alert tests.

### Task 2
Domain `openNotificationSettings()`; impl wraps the `agenda/system_settings` MethodChannel (constants `systemSettingsChannelName`, `openNotificationSettingsMethod`), answers false off Android/iOS and maps every exception and a null reply to false. `MainActivity` keeps `class MainActivity : FlutterFragmentActivity()` and registers the channel in `configureFlutterEngine` after `super`; the handler launches `ACTION_APP_NOTIFICATION_SETTINGS` (API 26+) falling back to `ACTION_APPLICATION_DETAILS_SETTINGS`, replying false when both fail. `AppDelegate` registers the channel in `didInitializeImplicitFlutterEngine`, stores it in a property and opens `UIApplication.openSettingsURLString`. The new `system_settings_channel_test.dart` covers the Dart behaviour (7 cases) and pins names across Dart, Kotlin and Swift (4 cases). `manifest_contract_test` and the iOS exclusion contract still pass.

### Task 3
`NotificationSettingsLoaded.permissionRequested` is set when an OS request (banner or enabling a kind) ends denied and cleared when a refresh finds the permission granted. With the flag set, `requestPermission()` calls `openNotificationSettings()` and does not ask the OS again. The denied banner shows `notifSettingsOpenSettingsButton` once the flag is set, otherwise `notifSettingsAllowButton`. README rows and conventions updated.

RED evidence: the new cubit tests failed to compile (`permissionRequested` undefined) before the state change.

## Verification
- `flutter test --no-pub` (full suite): all 846 passed.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (limit 65), all pre-existing infos.
- `dart run tool/check_architecture.dart`: PASS.

## Deviations from Plan

**1. [Rule 3 - Blocking] Worktree base was stale.** HEAD predated the 04-18 merge; fast-forwarded to `main` with `git merge --ff-only` (no commits lost) and ran `flutter pub get --offline`.

**2. [Rule 3 - Blocking] 150-line architecture guard.** Adding the Open-settings flow pushed `notification_settings_cubit.dart` to 168 lines. Moved the permission state transitions to `NotificationSettingsLoaded.afterRequest` / `afterRefresh`, inlined the `1439` clamp constant and dropped two redundant null assignments in `_cancelSubscriptions` (the subscriptions are reassigned in `start`). Behaviour unchanged; the cubit is exactly 150 lines.

Otherwise the plan was executed as written.

## Not verified here
- Kotlin and Swift handlers were not compiled (no Xcode, Android licences not accepted on this host); they are pinned only by the source-text contract test.
- On a device: no prompt at launch on a fresh install with an off-track goal, and the banner opening the system settings after a refusal, remain in 04-VERIFICATION.md human_verification.

## Known Stubs
None.

## Threat Flags
None. The new channel accepts no arguments and launches fixed intents (T-04-21-01); missing activity falls back and replies false (T-04-21-02).

## Self-Check: PASSED
Created `system_settings_channel_test.dart` and all modified files exist; commits bf1ffed, c3c225c and 0fe657c present.
