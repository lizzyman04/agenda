---
phase: "05"
slug: "app-lock-settings-polish"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-17"
---

# Phase 05 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| User ↔ lock screen | PIN keypad / biometric prompt gate the app UI | 4-digit PIN (secret), biometric result (OS) |
| App ↔ secure storage | PIN hash + attempt state in Keychain / EncryptedSharedPreferences | salted PBKDF2 hash, attempt ladder state |
| App ↔ OS window system | FLAG_SECURE / iOS cover over app snapshots | screen content (sensitive tasks, finances) |
| App ↔ system UIs (picker, permission, credential) | excursions out of the app and back | none persisted; lock state |
| App ↔ package ecosystem | pub dependencies | code (supply chain) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-05-01 | Info disclosure | New deps open a network path | high | mitigate | pubspec.yaml:13,23,31,33 pins exact versions; lock_platform_contract_test.dart:57 has the forbidden-package regex; .github/workflows/ci.yml:50-57 | closed |
| T-05-02 | DoS | BiometricPrompt theme crash | med | mitigate | res/values/styles.xml:4,15 and values-night/styles.xml:4,15 use Theme.AppCompat; contract test :78 | closed |
| T-05-03 | Repudiation | Copy over-promising encryption | med | mitigate | test/l10n/phase5_strings_test.dart:129-133; no ARB string claims encryption | closed |
| T-05-04 | Spoofing | Online PIN guessing ladder | high | mitigate | lib/domain/lock/lock_attempts.dart:22-30,42-57 (5 tries, then 30s/1m/5m/15m) | closed |
| T-05-05 | Tampering | Clock moved back | med | mitigate | lib/domain/lock/lock_policy.dart:41; lock_attempts.dart:70-71 clamp | closed |
| T-05-06 | EoP | Excursion abuse (policy) | med | mitigate | lock_policy.dart:42-45 max(timeout, 300) | closed |
| T-05-07 | Info disclosure | PIN in prefs or logs | high | mitigate | lib/infrastructure/lock/secure_pin_store.dart has no SharedPreferences; failures carry `runtimeType` only (:31,44,59,72); no print/log in lock dirs; pin_record.dart:61 sets `stringify false` | closed |
| T-05-08 | Info disclosure | Offline brute force | med | accept | Reason documented in 05-RESEARCH.md:307 (privacy gate, not encryption) | closed |
| T-05-09 | Tampering | Kill app to reset counter | high | mitigate | lib/application/lock/pin_verifier.dart:89-94 writes the count before returning; a failed write gives PinCheckFailed | closed |
| T-05-10 | Tampering | Stale Keychain after iOS reinstall | med | mitigate | lib/config/startup/app_lock_startup.dart:46-48 runs `deleteAll` when neither marker nor PIN is set | closed |
| T-05-11 | Info disclosure | Timing side channel | low | mitigate | lib/infrastructure/lock/pbkdf2_pin_hasher.dart:34-41 (`constantTimeEquals`), :82 (`Isolate.run`) | closed |
| T-05-12 | EoP | Corrupt or missing record fails open | high | mitigate | pin_verifier.dart:66,72-73,77-81 always give PinCheckFailed | closed |
| T-05-13 | Repudiation | Privacy statement over-promising | med | mitigate | lib/presentation/onboarding/screens/privacy_statement_screen.dart:70-73 shows the D-13 bullets only | closed |
| T-05-14 | DoS | Flag write failure | low | mitigate | lib/presentation/onboarding/widgets/onboarding_gate.dart:44-54 writes, then transitions; tests :174,181 | closed |
| T-05-15 | Tampering | Search query echoed | low | accept | lib/presentation/tasks/widgets/task_list_view.dart:32 renders it as plain text | closed |
| T-05-16 | Info disclosure | Content painted before lock on cold start | high | mitigate | lib/application/lock/app_lock_cubit.dart:32,44-54 sets the first state synchronously and locks if the value is unreadable; lock_gate.dart:59-61 Offstage; widget_test.dart:376,443 | closed |
| T-05-17 | Info disclosure | Semantics tree leak | med | mitigate | Offstage at lock_gate.dart:59; lock_gate_cover_test.dart:52-63 | closed |
| T-05-18 | EoP | Android back while locked | med | accept | lock_gate.dart:21-22; reason holds, tested in lock_gate_cover_test.dart:66,75 | closed |
| T-05-19 | EoP | Routes drawn over the lock | high | mitigate | lib/app.dart:79 mounts the lock in `MaterialApp.builder`; lock_gate.dart:133-148 gives it its own Navigator | closed |
| T-05-20 | EoP | Verifier error unlocks | high | mitigate | lib/application/lock/lock_screen_cubit.dart:114-128; any thrown error is treated as PinCheckFailed | closed |
| T-05-21 | Tampering | Stored locale value | low | accept | lib/application/shared/locale/locale_cubit.dart:39,46; reason holds | closed |
| T-05-22 | Info disclosure | App-switcher snapshot | high | mitigate | app_lock_cubit.dart:71-74; lock_gate.dart:40,64; privacy_overlay.dart | closed |
| T-05-23 | DoS | Relock loop after excursions | med | mitigate | lock_policy.dart:39 (locks only after `hidden`); ExcursionGuard wraps file_picker_backup_file_gateway.dart:36,58, notification_permission_service_impl.dart:72,78,104,117, local_auth_gateway.dart:56 | closed |
| T-05-24 | EoP | Excursion keeps app unlocked | med | mitigate | app_lock_cubit.dart:82,96; lock_policy.dart:42-45 | closed |
| T-05-25 | Info disclosure | Content frame between overlay and lock | high | mitigate | app_lock_cubit.dart:100-101 sends one combined state change | closed |
| T-05-26 | Tampering | Restart to skip cooldown | high | mitigate | lock_screen_cubit.dart:46-52; pin_verifier.dart:75 checks again | closed |
| T-05-27 | Tampering | Clock moved forward | low | accept | Reason documented in the 05-09 register | closed |
| T-05-28 | Info disclosure | Status messages | low | accept | lib/application/lock/lock_screen_state.dart:31-56 shows only the remaining count and wait time | closed |
| T-05-29 | Info disclosure | Android screenshots and Recents | high | mitigate | android/.../MainActivity.kt:41-50 FLAG_SECURE; app_lock_startup.dart:32-34 at boot; lib/application/lock/setup/pin_lifecycle.dart:41,44,62; device UAT item 5 | closed |
| T-05-30 | Tampering | Malformed channel arguments | low | mitigate | MainActivity.kt:41-43 (`as? Boolean`); ios/Runner/AppDelegate.swift:67-69 (`as? Bool`) | closed |
| T-05-31 | Info disclosure | iOS App Switcher snapshot | high | mitigate | ios/Runner/SceneDelegate.swift:19-27,35-42; Info.plist:44-45; Mac UAT still human_needed | closed |
| T-05-32 | Spoofing | Biometric spoofing | med | transfer | Matching is done by the OS; lib/application/lock/lock_device_auth.dart:38 `biometricOnly: true`; PIN keypad stays available | closed |
| T-05-33 | EoP | Biometric error unlocks | high | mitigate | lib/infrastructure/lock/local_auth_gateway.dart:70-75,82-92; lock_device_auth.dart:37-40; lock_screen_cubit.dart:93 | closed |
| T-05-34 | DoS | Prompt relock loop | med | mitigate | local_auth_gateway.dart:56; lock_screen_cubit.dart:103-107 auto-prompts once | closed |
| T-05-35 | Info disclosure | Prompt text leak | low | accept | lib/presentation/lock/screens/forgot_pin_button.dart:11-17 uses fixed strings only | closed |
| T-05-36 | EoP | Forgot-PIN without identity | high | mitigate | forgot_pin_button.dart:64-76 (`success` is the only push); lock_device_auth.dart:51,58-63 `biometricOnly: false`; lock_screen.dart:136-137 is the only reset entry point | closed |
| T-05-37 | EoP | Change or disable without current PIN | high | mitigate | pin_setup_state.dart:59-60; lib/application/lock/setup/pin_setup_cubit.dart:90-108 | closed |
| T-05-38 | Tampering | Half-enabled lock | med | mitigate | pin_lifecycle.dart:39-49 (flag set last, with rollback), :60-61 (flag cleared first) | closed |
| T-05-39 | DoS | New PIN starts in old cooldown | low | mitigate | pin_lifecycle.dart:82-86 writes `LockAttempts.none` | closed |
| T-05-40 | Repudiation | Switch shows ON while lock is off | med | mitigate | lib/application/settings/security_settings_cubit.dart:26,59-67 follows AppLockCubit; security_section.dart:41 | closed |
| T-05-41 | EoP | Disable without PIN | high | mitigate | lib/presentation/settings/security/security_section.dart:95-103; pin_setup_cubit.dart:98-100 | closed |
| T-05-42 | Tampering | Stored timeout or biometrics pref edited | low | accept | lock_policy.dart:22-23; security_settings_cubit.dart:99; reason holds | closed |
| T-05-43 | DoS | R8 strips plugins | high | mitigate | build/app/outputs/flutter-apk/app-release.apk (64,909,801 B); 05-14-SUMMARY device UAT items 4, 8, 9 on the release build | closed |
| T-05-44 | Info disclosure | Network package slips in | high | mitigate | ci.yml:50-57; contract test :55-64 | closed |
| T-05-SC | Tampering | Supply chain | high | mitigate (05-01) / accept (05-02 to 05-14) | Exact pins at pubspec.yaml:13,23,31,33, enforced by contract test :39-48; 05-RESEARCH.md:159 Package Legitimacy Audit; later plans add no packages | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

Notes:
- T-05-31 (iOS App Switcher cover) is closed in code; on-device verification is human_needed (no Mac).
- Out of phase scope: `http` is a transitive dependency of `timezone` 0.11.0 (pre-Phase-5); nothing in lib/ imports it. The CI/contract check covers direct dependencies only.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-05-08 | Offline brute force of 4-digit PBKDF2 hash accepted: lock is a privacy gate, not encryption (05-RESEARCH.md:307) | user (plan-phase approval) | 2026-11-17 |
| AR-02 | T-05-15 | Search query echoed only as plain Text in empty state | user (plan-phase approval) | 2026-11-17 |
| AR-03 | T-05-18 | Android Back while locked pops a hidden route; lock stays on top (tested lock_gate_cover_test) | user (plan-phase approval) | 2026-11-17 |
| AR-04 | T-05-21 | Stored locale pref tampering only changes UI language | user (plan-phase approval) | 2026-11-17 |
| AR-05 | T-05-27 | Clock moved forward shortens cooldown; needs device access + is bounded by ladder | user (plan-phase approval) | 2026-11-17 |
| AR-06 | T-05-28 | Lock status messages reveal only remaining count and wait time | user (plan-phase approval) | 2026-11-17 |
| AR-07 | T-05-35 | Biometric/credential prompt uses fixed strings only | user (plan-phase approval) | 2026-11-17 |
| AR-08 | T-05-42 | Edited timeout/biometric prefs are clamped/validated; worst case is a shorter/longer timeout | user (plan-phase approval) | 2026-11-17 |
| AR-09 | T-05-SC | Plans 05-02..05-14 add no packages; supply chain mitigated at 05-01 via exact pins | user (plan-phase approval) | 2026-11-17 |
| TR-01 | T-05-32 | Biometric matching transferred to the OS (biometricOnly: true); PIN keypad remains | user (plan-phase approval) | 2026-11-17 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-17 | 45 | 45 | 0 | gsd-security-auditor (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
