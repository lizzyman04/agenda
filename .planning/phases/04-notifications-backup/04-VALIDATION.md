---
phase: "4"
slug: "notifications-backup"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-12"
---

# Phase 4 - Validation Strategy

> Per-phase validation contract. Full requirement-to-test map lives in `04-RESEARCH.md` section "Validation Architecture".

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test 10.0.0 + mocktail 1.0.5; real Isar via `test/support/isar_test_harness.dart` |
| **Config file** | none (`analysis_options.yaml`, `l10n.yaml`) |
| **Quick run command** | `flutter test --no-pub test/domain/notifications test/data/backup` |
| **Full suite command** | `flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` |
| **Estimated runtime** | ~30 s quick, several minutes full |

## Sampling Rate

- **After every task commit:** quick command for the area touched + `dart run tool/check_architecture.dart`
- **After every plan wave:** full suite command
- **Before `/gsd-verify-work`:** full suite green
- **Max feedback latency:** 30 seconds

## Per-Task Verification Map

Populated by the planner from `04-RESEARCH.md` (NOTF-01..11, DATA-02..04 each map to a Wave 0 test file).

## Wave 0 Requirements

- [ ] `test/domain/notifications/*_test.dart` - pure rule tests (inject `now`, assert date components)
- [ ] `test/infrastructure/notifications/fake_notification_gateway.dart`
- [ ] `test/data/backup/` - real-Isar round-trip, atomicity, 600-row seeds
- [ ] `test/infrastructure/notifications/manifest_contract_test.dart`
- [ ] Update `test/widget_test.dart` stubs when `watchChanges()` is added to Budget and RecurringPayment repositories

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reminders survive reboot | NOTF-11 | Needs physical device | Schedule, reboot, confirm fire |
| Quiet-hours deferral lands at window end | NOTF-10 | Real clock | Schedule inside window, observe |
| Permission deny/grant flows | NOTF-01 | OS dialogs | Deny then grant POST_NOTIFICATIONS / exact alarm |
| iOS >64 pending items | NOTF-09 | No Xcode on host | Human UAT on iOS device |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
