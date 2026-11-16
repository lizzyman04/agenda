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

Task IDs bound by the planner on 2026-11-16 (14 plans, 9 waves). "W0" = the test file is created by that task itself.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-T1 | 01 | 1 | DATA-05, DATA-06 | T-05-01, T-05-02, T-05-SC | exact pins resolve; AppCompat theme; USE_BIOMETRIC; Face ID string; real plugin APIs compile; no network package | contract + smoke | `flutter pub get && flutter test --no-pub test/infrastructure/lock/lock_platform_contract_test.dart` | ❌ W0 | ⬜ pending |
| 05-01-T2 | 01 | 1 | UX-01, UX-03 | T-05-03 | ARB parity; lockWrongPin plural; D-12 headline; no encryption claim | unit | `flutter gen-l10n && flutter test --no-pub test/l10n && flutter analyze --no-fatal-infos --fatal-warnings` | ✅ l10n_test / ❌ W0 phase5_strings_test | ⬜ pending |
| 05-02-T1 | 02 | 1 | DATA-05 | T-05-04 | ladder 1..4 remaining, 5th -> 30 s, then 60/300/900 cap; reset; no backwards-clock extension | unit (tdd) | `flutter test --no-pub test/domain/lock/lock_attempts_test.dart` | ❌ W0 | ⬜ pending |
| 05-02-T2 | 02 | 1 | DATA-05 | T-05-05, T-05-06 | elapsed >= timeout locks; negative elapsed locks; excursion cap | unit (tdd) | `flutter test --no-pub test/domain/lock` | ❌ W0 | ⬜ pending |
| 05-03-T1 | 03 | 2 | DATA-05 | T-05-07, T-05-11 | PBKDF2 RFC vectors; constant-time compare; secure-store round trip | unit | `flutter test --no-pub test/infrastructure/lock/pbkdf2_pin_hasher_test.dart test/infrastructure/lock/secure_pin_store_test.dart` | ❌ W0 | ⬜ pending |
| 05-03-T2 | 03 | 2 | DATA-05 | T-05-09, T-05-12 | attempts persisted before the result; fail closed on missing record | unit | `flutter test --no-pub test/application/lock/pin_verifier_test.dart test/config/di/lock_di_test.dart` | ❌ W0 | ⬜ pending |
| 05-03-T3 | 03 | 2 | DATA-05 | T-05-10 | fresh-install wipe, never wipes a configured PIN | unit | `flutter test --no-pub test/config/startup/app_lock_startup_test.dart` | ❌ W0 | ⬜ pending |
| 05-04-T1 | 04 | 2 | UX-03 | T-05-13 | first launch -> statement -> Começar persists -> shell; second launch skips | widget | `flutter test --no-pub test/presentation/onboarding test/widget_test.dart` | ✅ (edit) widget_test / ❌ W0 | ⬜ pending |
| 05-04-T2 | 04 | 2 | UX-03 | T-05-14 | language switch; read-only mode; persist failure; 200% overflow | widget | `flutter test --no-pub test/presentation/onboarding/privacy_statement_test.dart` | ❌ W0 | ⬜ pending |
| 05-05-T1 | 05 | 2 | UX-04 (05-04 polish) | T-05-15 | empty task list CTA via AppEmptyState | widget | `flutter test --no-pub test/presentation/shared/app_empty_state_test.dart test/presentation/tasks/task_list_screen_test.dart` | ❌ W0 / ✅ (edit) | ⬜ pending |
| 05-05-T2 | 05 | 2 | UX-04 (05-04 polish) | — | search-no-match and GTD empty; finance empty unchanged | widget | `flutter test --no-pub test/presentation/tasks test/presentation/finance` | ✅ (edit) | ⬜ pending |
| 05-06-T1 | 06 | 3 | DATA-05 / SC-1 | T-05-16, T-05-20 | first pump shows LockScreen, no NavigationBar; correct PIN unlocks; only PinVerified unlocks | widget + bloc_test | `flutter test --no-pub test/presentation/lock/lock_gate_cold_start_test.dart test/application/lock/app_lock_cubit_test.dart test/application/lock/lock_screen_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 05-06-T2 | 06 | 3 | DATA-05 | — | keypad empty/partial states, semantics, tooltips render (Overlay present) | widget | `flutter test --no-pub test/presentation/lock/lock_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-06-T3 | 06 | 3 | DATA-05 | T-05-17, T-05-18, T-05-19 | hidden semantics; back keeps the lock; fade; full-app cold start | widget | `flutter test --no-pub test/presentation/lock/lock_gate_cover_test.dart test/widget_test.dart` | ❌ W0 / ✅ (edit) | ⬜ pending |
| 05-07-T1 | 07 | 3 | UX-01 / SC-3 | T-05-21 | gear replaces menu; two-language dialog re-renders app | widget | `flutter test --no-pub test/presentation/settings/settings_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-07-T2 | 07 | 3 | UX-01 / SC-3 | — | Notifications/Data/About rows push existing screens; D-10 order; 200% scroll | widget | `flutter test --no-pub test/presentation/settings` | ❌ W0 | ⬜ pending |
| 05-08-T1 | 08 | 4 | DATA-05 / DATA-06 / D-04 | T-05-22, T-05-25 | overlay on inactive (PIN on), never when off; resume -> lock in one emission | widget + bloc_test | `flutter test --no-pub test/presentation/lock/lock_gate_lifecycle_test.dart test/application/lock/app_lock_lifecycle_test.dart` | ❌ W0 | ⬜ pending |
| 05-08-T2 | 08 | 4 | DATA-06 / D-03 | T-05-23, T-05-24 | excursion guard active during call + grace; no lock within cap | unit | `flutter test --no-pub test/infrastructure/lock/excursion_guard_test.dart test/infrastructure/notifications/system_settings_channel_test.dart` | ❌ W0 / ✅ (edit) | ⬜ pending |
| 05-09-T1 | 09 | 5 | DATA-05 | T-05-28 | lockWrongPin(remaining) + shake, reduced motion honoured | widget + bloc_test | `flutter test --no-pub test/presentation/lock/lock_screen_test.dart test/application/lock/lock_screen_cubit_test.dart` | ✅ (edit) | ⬜ pending |
| 05-09-T2 | 09 | 5 | DATA-05 | T-05-26, T-05-27 | cooldown disables keys, countdown survives a kill; storage error retryable | widget | `flutter test --no-pub test/application/lock/lock_screen_cooldown_test.dart` | ❌ W0 | ⬜ pending |
| 05-10-T1 | 10 | 5 | DATA-06 / D-04 | T-05-29, T-05-30 | setSecure channel contract; boot apply only with a PIN | unit | `flutter test --no-pub test/infrastructure/lock/secure_window_channel_test.dart test/config/startup` | ❌ W0 / ✅ (edit) | ⬜ pending |
| 05-10-T2 | 10 | 5 | DATA-06 / SC-2 | T-05-31 | iOS shield + SceneDelegate cover source contract | contract | `flutter test --no-pub test/infrastructure/lock/lock_platform_contract_test.dart` | ✅ (edit) | ⬜ pending |
| 05-11-T1 | 11 | 6 | DATA-06 | T-05-33, T-05-34 | auto-prompt only when resumed, once; success unlocks + resets; exception mapping | bloc_test + unit | `flutter test --no-pub test/infrastructure/lock/local_auth_gateway_test.dart test/application/lock/app_lock_biometric_test.dart` | ❌ W0 | ⬜ pending |
| 05-11-T2 | 11 | 6 | DATA-06 | T-05-32 | biometric key visibility and platform icon; cancel -> keypad | widget | `flutter test --no-pub test/presentation/lock/lock_screen_biometric_test.dart` | ❌ W0 | ⬜ pending |
| 05-12-T1 | 12 | 7 | DATA-05 | T-05-38, T-05-39 | create + confirm; enable write order and rollback | bloc_test + widget | `flutter test --no-pub test/application/lock/pin_lifecycle_test.dart test/application/lock/pin_setup_cubit_test.dart test/presentation/lock/pin_setup_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-12-T2 | 12 | 7 | DATA-05 | T-05-37 | change / verify / reset modes; shared counter; cancel leaves state unchanged | bloc_test + widget | `flutter test --no-pub test/application/lock/pin_setup_cubit_test.dart test/application/lock/lock_screen_cooldown_test.dart` | ✅ (edit) | ⬜ pending |
| 05-12-T3 | 12 | 7 | DATA-06 / D-06 | T-05-36 | forgot PIN via device credential; unavailable dialog; fail closed | widget | `flutter test --no-pub test/presentation/lock/forgot_pin_test.dart` | ❌ W0 | ⬜ pending |
| 05-13-T1 | 13 | 8 | DATA-05 / SC-3 | T-05-40, T-05-41 | PIN switch never optimistic; off requires confirm + verify | widget + bloc_test | `flutter test --no-pub test/application/settings test/presentation/settings` | ❌ W0 | ⬜ pending |
| 05-13-T2 | 13 | 8 | DATA-06 / UX-01 / SC-3 | T-05-42 | Security rows hidden when PIN off; biometric availability states; five timeouts; no-device-lock warning | widget | `flutter test --no-pub test/presentation/settings/security_section_test.dart` | ✅ (edit) | ⬜ pending |
| 05-14-T1 | 14 | 9 | DATA-05, DATA-06, UX-01, UX-03 | T-05-43, T-05-44 | full-app smoke (first launch, PIN cold start); release build | widget + build | `flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart && flutter build apk --release` | ✅ (edit) | ⬜ pending |
| 05-14-T2 | 14 | 9 | DATA-05, DATA-06, UX-01, UX-03 | — | device UAT (see Manual-Only) | manual | checkpoint:human-verify | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/fake_clock.dart` — mutable `DateTime Function()` for cubit/policy tests (05-03-T2)
- [ ] `test/support/lock_fakes.dart` — mocktail mocks for `PinHasher`, `PinStore`, `DeviceAuthGateway`, `SecureWindowGateway`, `ExcursionGuard`; `MockAppLockCubit` (created 05-03-T2, appended by 05-06, 05-08, 05-10, 05-11, 05-12)
- [ ] `test/widget_test.dart` setUp — seed `privacy_statement_shown: true` (05-04-T1) and `FlutterSecureStorage.setMockInitialValues({})` (05-06-T3)
- [ ] Delete `test/presentation/tasks/task_list_settings_menu_test.dart` with the widget (05-07-T1)
- [ ] Update `test/infrastructure/notifications/system_settings_channel_test.dart` for the `ExcursionGuard` constructor param (05-08-T2)
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
