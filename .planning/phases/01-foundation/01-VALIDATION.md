---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — Wave 0 installs test stubs |
| **Quick run command** | `flutter analyze && flutter test --no-pub` |
| **Full suite command** | `flutter analyze && flutter test --no-pub --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze && flutter test --no-pub`
- **After every plan wave:** Run `flutter analyze && flutter test --no-pub --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01-01 | 1 | DATA-01 | — | N/A | static | `flutter analyze` | ✅ | ⬜ pending |
| 1-01-02 | 01-01 | 1 | DATA-01 | — | N/A | static | `flutter analyze` | ✅ | ⬜ pending |
| 1-02-01 | 01-02 | 2 | DATA-01 | — | N/A | unit | `flutter test test/core/isar_service_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-02 | 01-02 | 2 | DATA-01 | — | N/A | unit | `flutter test test/core/migration_runner_test.dart` | ❌ W0 | ⬜ pending |
| 1-03-01 | 01-03 | 3 | DATA-01 | — | N/A | unit | `flutter test test/core/di_test.dart` | ❌ W0 | ⬜ pending |
| 1-04-01 | 01-04 | 4 | UX-02 | — | N/A | unit | `flutter test test/l10n/l10n_test.dart` | ❌ W0 | ⬜ pending |
| 1-05-01 | 01-05 | 5 | DATA-01 | — | N/A | unit | `flutter test test/core/offline_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/isar_service_test.dart` — stubs for DATA-01 (IsarService opens DB)
- [ ] `test/core/migration_runner_test.dart` — stubs for DATA-01 (MigrationRunner no-ops when current)
- [ ] `test/core/di_test.dart` — stubs for DATA-01 (GetIt graph resolves)
- [ ] `test/l10n/l10n_test.dart` — stubs for UX-02 (ARB parity EN + PT-BR)
- [ ] `test/core/offline_test.dart` — stubs for DATA-01 (no network calls)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App launches on Android emulator without errors | DATA-01 | Requires emulator/device runtime | `flutter run -d <device>`, observe no exceptions on startup |
| App launches on iOS simulator without errors | DATA-01 | Requires macOS/Xcode | `flutter run -d <ios-device>`, observe no exceptions on startup |
| PT-BR strings render by default | UX-02 | Locale detection is device-level | Set device locale to pt_BR, observe UI text in Portuguese |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
