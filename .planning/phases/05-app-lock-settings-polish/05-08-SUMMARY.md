---
phase: 05-app-lock-settings-polish
plan: 08
subsystem: app-lock
tags: [flutter, bloc, app-lifecycle, privacy-overlay, excursion-guard, injectable]

requires:
  - phase: 05-02
    provides: LockPolicy.effectiveTimeoutSeconds, excursionCapSeconds, shouldLockOnResume
  - phase: 05-06
    provides: AppLockCubit (cold-start seed), LockGate builder Stack with lock layer
provides:
  - AppLockCubit.onInactive / onHidden / onResumed (resume relock with one state change)
  - LockGate as a StatefulWidget owning an AppLifecycleListener, with the PrivacyOverlay layer on top
  - PrivacyOverlay widget (D-04 Flutter half)
  - ExcursionGuard interface (domain) and ExcursionGuardImpl (2 s grace, lazy singleton)
  - FilePickerBackupFileGateway(ExcursionGuard), NotificationPermissionServiceImpl(plugin, ExcursionGuard)
  - MockExcursionGuard in test/support/lock_fakes.dart
affects: [05-09, 05-10, 05-11, 05-14, local_auth gateway, app-lock settings]

actuals:
  tokens: 17022
  tasks: 2
  commits: 2
plan_head_before: 421d8a355b3392e556e4608c99f1bad8f68678cd
plan_head_after: b459080ae48f523796bfad8c25c9c4b14e6dd82f

tech-stack:
  added: []
  patterns:
    - "AppLifecycleListener owned by LockGate state, forwarding onInactive/onHide/onResume to the app-wide cubit"
    - "Resume emits ONE copyWith(obscured: false, locked: ...) so no content frame paints between overlay and lock"
    - "External-UI plugin calls wrapped in ExcursionGuard.run; the cubit samples guard.isActive at hidden time"

key-files:
  created:
    - lib/presentation/lock/widgets/privacy_overlay.dart
    - lib/domain/lock/excursion_guard.dart
    - lib/infrastructure/lock/excursion_guard_impl.dart
    - test/application/lock/app_lock_lifecycle_test.dart
    - test/presentation/lock/lock_gate_lifecycle_test.dart
    - test/infrastructure/lock/excursion_guard_test.dart
  modified:
    - lib/application/lock/app_lock_cubit.dart
    - lib/presentation/lock/widgets/lock_gate.dart
    - lib/infrastructure/backup/file_picker_backup_file_gateway.dart
    - lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart
    - lib/config/di/injection.config.dart
    - lib/application/lock/README.md
    - lib/presentation/lock/widgets/README.md
    - test/support/lock_fakes.dart
    - test/config/di/lock_di_test.dart
    - test/infrastructure/notifications/system_settings_channel_test.dart
    - test/application/lock/app_lock_cubit_test.dart
    - test/presentation/lock/lock_gate_cover_test.dart
    - test/presentation/lock/lock_screen_test.dart

key-decisions:
  - "onHidden keeps the FIRST hidden time of a trip (hidden -> paused -> hidden does not reset it) and samples ExcursionGuard.isActive at that instant"
  - "ExcursionGuardImpl.isActive is true while any run is in flight or when now <= lastEndedAt + 2 s (inclusive bound)"
  - "Keyboard dismissal on lock stays in _LockLayer.didUpdateWidget (05-06) instead of a second BlocListener; same trigger (locked false -> true)"
  - "PrivacyOverlay wraps its content in a transparent Material so the text gets the theme style above the app Navigator"

patterns-established:
  - "Wrap every call that launches UI outside the app in ExcursionGuard.run (05-11 local_auth must follow this)"
  - "Widget lifecycle tests pump twice after a lifecycle change: cubit emissions reach BlocBuilder in a microtask"

requirements-completed: [DATA-05, DATA-06]

coverage:
  - id: D1
    description: "Returning from the background past the timeout shows the lock screen; a shorter trip continues in place on the pushed route"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/app_lock_lifecycle_test.dart#resume after the background"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_lifecycle_test.dart#past the timeout: overlay -> lock screen, then PIN resumes DETAIL"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_lifecycle_test.dart#short trip (30 s, timeout 60): no lock, DETAIL stays"
        status: pass
    human_judgment: false
  - id: D2
    description: "Resume replaces the privacy overlay with the lock screen in one state change (no content frame); clock moved back locks"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/app_lock_lifecycle_test.dart#hidden 60 s with timeout 60 -> locked in ONE emission on resume"
        status: pass
      - kind: unit
        ref: "test/application/lock/app_lock_lifecycle_test.dart#clock moved back while hidden -> locked (fail closed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Privacy overlay painted on inactive with a PIN; never with the PIN off"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_lifecycle_test.dart#PIN off: inactive never shows the overlay"
        status: pass
    human_judgment: true
    rationale: "Whether the OS app-switcher snapshot actually captures the overlay depends on device frame timing; native backstops land in 05-10 and the device UAT is 05-14."
  - id: D4
    description: "File picker and notification permission/settings trips never relock within max(timeout, 5 min); longer excursions lock"
    requirement: DATA-06
    verification:
      - kind: unit
        ref: "test/infrastructure/lock/excursion_guard_test.dart"
        status: pass
      - kind: unit
        ref: "test/application/lock/app_lock_lifecycle_test.dart#app-initiated excursions (D-03)"
        status: pass
      - kind: integration
        ref: "test/infrastructure/notifications/system_settings_channel_test.dart#the excursion guard is active while the page opens (D-03)"
        status: pass
      - kind: unit
        ref: "test/config/di/lock_di_test.dart#ExcursionGuard resolves as a single ExcursionGuardImpl"
        status: pass
    human_judgment: true
    rationale: "The 5-minute cap and 2-second grace (RESEARCH A3) must be confirmed on a real picker/permission trip in the 05-14 device UAT."

duration: 31min
completed: 2026-11-16
status: complete
---

# Phase 05 Plan 08: Resume Lock, Privacy Overlay and Excursion Guard Summary

**AppLockCubit now relocks after a background trip past the stored timeout, removing the privacy overlay in the same state change. LockGate forwards app-lifecycle events and paints a PrivacyOverlay on `inactive`. An ExcursionGuard (2 s grace, 5 min cap) keeps the file picker and the OS permission/settings screens from relocking the app.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-11-16T20:09:26Z
- **Completed:** 2026-11-16T20:40:27Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments
- Lock on resume: a trip through `hidden` that reaches `StorageKeys.lockTimeoutSeconds` (read at each resume, default 60) locks. `inactive` on its own never locks. A clock moved back locks (fail closed). Resume emits exactly one state.
- `LockGate` is stateful and owns an `AppLifecycleListener`. Stack order from bottom to top: app (Offstage while locked), lock layer, `PrivacyOverlay`. The pushed route and its state survive the lock, and the correct PIN brings back the same DETAIL route.
- `PrivacyOverlay`: a full-bleed `cs.surface` with a 64 px `lock_outline` icon and the app name in `titleMedium`. It is shown only when a PIN is enabled.
- `ExcursionGuard` / `ExcursionGuardImpl`: a counter of in-flight runs (safe for nested and concurrent runs) plus a 2 s grace after the last run ends. It wraps `FilePicker.saveFile`, `FilePicker.pickFiles`, the notification and exact-alarm permission requests, and the settings channel call.

## Task Commits

1. **Task 1: Tracer, resume relock with the privacy overlay** - `095aae0` (feat)
2. **Task 2: ExcursionGuard around the picker and OS permission/settings calls** - `b459080` (feat)

Tracer gate (end-of-phase, automated-only verify): re-ran `flutter test --no-pub test/application/lock test/presentation/lock` (62 passed) and `flutter analyze` (64 issues, exit 0) before expanding.

## Files Created/Modified
- `lib/application/lock/app_lock_cubit.dart`: adds `onInactive`/`onHidden`/`onResumed`, the `ExcursionGuard` parameter and an injected clock (113 lines)
- `lib/presentation/lock/widgets/lock_gate.dart`: now a StatefulWidget with an `AppLifecycleListener` and the overlay layer (149 lines)
- `lib/presentation/lock/widgets/privacy_overlay.dart`: `PrivacyOverlay`
- `lib/domain/lock/excursion_guard.dart`: the `ExcursionGuard` interface
- `lib/infrastructure/lock/excursion_guard_impl.dart`: `ExcursionGuardImpl` (`grace` = 2 s, `@LazySingleton(as: ExcursionGuard)`)
- `lib/infrastructure/backup/file_picker_backup_file_gateway.dart`: new constructor taking the guard; both picker calls are wrapped
- `lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart`: guard added as the second constructor parameter; three methods wrapped; still 130 lines
- `lib/config/di/injection.config.dart`: regenerated
- Tests: `app_lock_lifecycle_test.dart` (16), `lock_gate_lifecycle_test.dart` (3), `excursion_guard_test.dart` (6), plus updates to `system_settings_channel_test.dart`, `lock_di_test.dart`, `lock_fakes.dart` and the existing `AppLockCubit(` call sites

## Decisions Made
- `onHidden` keeps the first hidden time of a trip and samples the guard at that moment, using the same clock value.
- The guard's grace bound is inclusive: it is active at end + 2 s and inactive at end + 2.1 s.
- Keyboard dismissal on lock stays in `_LockLayer.didUpdateWidget`, which 05-06 already uses for the false -> true transition. No second BlocListener was added.
- `PrivacyOverlay` puts a transparent `Material` inside the `ColoredBox`. Above the app Navigator there is no Material ancestor, so the text would otherwise get the debug fallback style.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the existing `AppLockCubit(` call sites for the new required `ExcursionGuard` parameter**
- **Found during:** Task 2
- **Issue:** `app_lock_cubit_test.dart`, `lock_screen_test.dart` and `lock_gate_cover_test.dart` construct `AppLockCubit` directly. They would not have compiled after the guard became the second positional parameter, and none of them is listed in the plan's files.
- **Fix:** Pass `ExcursionGuardImpl()` as the second argument.
- **Files modified:** the three tests above
- **Verification:** Full suite passes (1067 tests).
- **Committed in:** b459080

**2. [Rule 1 - Bug] Explicit `run<bool?>` on the settings channel call**
- **Found during:** Task 2
- **Issue:** With `await _guard.run(...) ?? false`, the context type made Dart infer `T = bool`. The `invokeMethod<bool>` closure returns `Future<bool?>`, so compilation failed.
- **Fix:** `_guard.run<bool?>(...)`
- **Files modified:** `notification_permission_service_impl.dart`
- **Committed in:** b459080

**3. [Plan variance] The keyboard is dismissed through the existing lock-layer hook, not a new BlocListener**
- **Found during:** Task 1
- **Issue:** The plan asked for a BlocListener that unfocuses when `locked` turns true. 05-06 already does exactly this in `_LockLayer.didUpdateWidget`, and `lock_gate.dart` had no room left under the 150-line cap.
- **Fix:** Kept the existing hook. The new widget test checks that the DETAIL text field loses focus on lock.
- **Committed in:** 095aae0

---

**Total deviations:** 3 (1 blocking, 1 bug, 1 plan variance)
**Impact on plan:** None on scope. All plan truths are covered by tests.

## Issues Encountered
- In widget tests, a cubit emission reaches `BlocBuilder` in a microtask, so the first `tester.pump()` after a lifecycle change has no frame scheduled yet. The lifecycle test's `frame()` helper therefore pumps twice. On a real engine the microtask runs before the next vsync, so the overlay is still painted in the next frame while frames are produced.
- A broad `dart format test/infrastructure` call briefly reformatted five unrelated test files. Those files were restored before committing, and analyze is back at the 64-issue baseline.

## User Setup Required

None. No external service configuration is required.

## Next Phase Readiness
- 05-09 (lock-screen status line and cooldown) and 05-11 (biometrics) can build on the lifecycle cubit. The `local_auth` gateway in 05-11 must wrap `authenticate` in `ExcursionGuard.run` (RESEARCH Pitfall 3).
- 05-10 adds the native app-switcher backstops (FLAG_SECURE, iOS SceneDelegate cover).
- DATA-05 and DATA-06 stay open in REQUIREMENTS.md because sibling plans also declare them (`requirements.ready-ids` reports them as blocked).

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*

## Self-Check: PASSED
- Files: privacy_overlay.dart, excursion_guard.dart, excursion_guard_impl.dart, app_lock_lifecycle_test.dart, lock_gate_lifecycle_test.dart and excursion_guard_test.dart all exist.
- Commits 095aae0 and b459080 are ancestors of HEAD.
- Acceptance: AppLifecycleListener appears in lock_gate.dart (2 matches). shouldLockOnResume appears in app_lock_cubit.dart (1). app_lock_cubit.dart has 113 lines (cap 150). `_guard.run` appears 2 times in the gateway and 4 in the service. ExcursionGuardImpl appears in injection.config.dart (1). The full `flutter test --no-pub` passes. `check_architecture` reports PASS. `flutter analyze` reports 64 issues, exit 0.
