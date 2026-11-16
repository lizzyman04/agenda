---
phase: "05"
slug: "app-lock-settings-polish"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-16"
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `05-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 |
| **Config file** | none (defaults); analysis via `analysis_options.yaml` (very_good_analysis 10.2.0) |
| **Quick run command** | `flutter test --no-pub test/application/lock test/infrastructure/lock test/presentation/lock test/presentation/settings test/presentation/onboarding test/domain/lock` |
| **Full suite command** | `flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` |
| **Estimated runtime** | ~90 seconds (full suite) |

Capture the test-count baseline at plan start (last recorded 306/306; re-measure). Hold analyzer budget at 65 infos.

---

## Sampling Rate

- **After every task commit:** Run the quick run command for the touched area + `flutter analyze --no-fatal-infos --fatal-warnings`
- **After every plan wave:** Run the full suite command
- **Before `/gsd-verify-work`:** Full suite green, `flutter build apk --release` succeeds, manual UAT list recorded
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

Task IDs are bound by the planner; rows below are keyed by requirement until plans exist.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | DATA-05 | — | PBKDF2-HMAC-SHA256 matches RFC 7914 vectors; constant-time compare | unit | `flutter test --no-pub test/infrastructure/lock/pbkdf2_pin_hasher_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 | — | Attempt ladder 1..4 remaining, 5th → 30 s, then 60/300/900 cap; reset on success | unit | `flutter test --no-pub test/domain/lock/lock_attempts_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 | — | `shouldLockOnResume` timeouts; negative elapsed locks; excursion cap | unit | `flutter test --no-pub test/domain/lock/lock_policy_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 | — | Attempts persisted before result; fresh-install wipe | unit | `flutter test --no-pub test/infrastructure/lock/secure_pin_store_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 | — | Cubit initial locked from prefs; verify ok/wrong/cooldown; single-emit resume | bloc_test | `flutter test --no-pub test/application/lock/app_lock_cubit_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 / SC-1 | — | First pump shows `LockScreen`, no `NavigationBar` | widget | `flutter test --no-pub test/presentation/lock/lock_gate_cold_start_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 | — | Keypad auto-submit, cooldown disables keys, tooltips render | widget | `flutter test --no-pub test/presentation/lock/lock_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-05 | — | PIN setup modes; cancel leaves state unchanged | bloc_test + widget | `flutter test --no-pub test/application/lock/pin_setup_cubit_test.dart test/presentation/lock/pin_setup_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-06 | — | Biometric auto-prompt only when resumed; cancel → keypad | bloc_test | `flutter test --no-pub test/application/lock/app_lock_biometric_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-06 / D-03 | — | Excursion guard does not lock within cap | unit | `flutter test --no-pub test/infrastructure/lock/excursion_guard_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-06 / D-04 | — | Overlay on `inactive` when PIN on; resume → lock same frame | widget | `flutter test --no-pub test/presentation/lock/lock_gate_lifecycle_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DATA-06 / D-04 | — | `setSecure` channel contract | unit | `flutter test --no-pub test/infrastructure/lock/secure_window_channel_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | UX-01 / SC-3 | — | Language switch; Security rows hidden when PIN off; rows push existing screens | widget | `flutter test --no-pub test/presentation/settings/settings_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | UX-01 | — | ARB parity en vs pt_BR | unit | `flutter test --no-pub test/l10n/l10n_test.dart` | ✅ | ⬜ pending |
| TBD | TBD | TBD | UX-03 | — | First launch privacy screen; flag persisted; skipped second launch; read-only mode | widget | `flutter test --no-pub test/presentation/onboarding/privacy_statement_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | UX-03 | — | Full-app smoke renders shell with flag seeded | widget | `flutter test --no-pub test/widget_test.dart` | ✅ (edit) | ⬜ pending |
| TBD | TBD | TBD | 05-04 | — | Empty states via `AppEmptyState` | widget | `flutter test --no-pub test/presentation/shared/app_empty_state_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | 05-04 | — | Release build compiles | build | `flutter build apk --release` | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/fake_clock.dart` — mutable `DateTime Function()` for cubit/policy tests
- [ ] `test/support/lock_fakes.dart` — mocktail mocks for `PinHasher`, `PinStore`, `DeviceAuthGateway`, `SecureWindowGateway`, `ExcursionGuard`; `MockAppLockCubit`
- [ ] `test/widget_test.dart` setUp — seed `privacy_statement_shown: true` and `FlutterSecureStorage.setMockInitialValues({})`
- [ ] Delete `test/presentation/tasks/task_list_settings_menu_test.dart` with the widget
- [ ] Update `test/infrastructure/notifications/system_settings_channel_test.dart` for the `ExcursionGuard` constructor param
- [ ] All ❌ W0 test files above

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Process kill → lock screen first | DATA-05 / SC-1 | Needs real OS process kill | Enable PIN, swipe-kill app, reopen: lock screen before any content |
| Fingerprint / Face ID unlock | DATA-06 / SC-2 | Biometric hardware | Enable biometrics, lock, unlock via sensor |
| FLAG_SECURE blank screenshot + Recents | DATA-06 / D-04 | Platform window flag | With PIN on, screenshot and open Recents: content hidden |
| File picker does not relock | D-03 | Real system picker | Backup import → pick file → return: no lock screen |
| iOS App Switcher cover | DATA-06 / SC-2 | No Mac/Xcode on this machine | On iOS device: PIN on, open App Switcher: cover shown |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
