---
phase: 3
slug: finance-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test 10.0.0 + mocktail 1.0.5 |
| **Config file** | `pubspec.yaml` (flutter test) — no separate config |
| **Quick run command** | `flutter test test/domain/finance/ test/application/finance/ -x` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds (quick) / ~90 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/domain/finance/ test/application/finance/ -x`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | FIN-01 | — | N/A | unit | `flutter test test/domain/finance/transaction_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | FIN-05 | — | N/A | unit | `flutter test test/domain/finance/savings_goal_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | FIN-07 | — | N/A | unit | `flutter test test/domain/finance/ -x` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | FIN-01 | — | N/A | unit | `flutter test test/domain/finance/transaction_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 1 | FIN-04 | — | N/A | unit | `flutter test test/domain/finance/ -x` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | FIN-01,FIN-02,FIN-03 | — | N/A | unit | `flutter test test/application/finance/transaction_cubit_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | FIN-04 | — | N/A | unit | `flutter test test/application/finance/budget_cubit_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-03-03 | 03 | 2 | FIN-05,FIN-06 | — | N/A | unit | `flutter test test/domain/finance/savings_goal_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-03-04 | 03 | 2 | FIN-07,FIN-08 | — | N/A | unit | `flutter test test/application/finance/debt_cubit_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-03-05 | 03 | 2 | FIN-09,FIN-10 | — | N/A | unit | `flutter test test/application/finance/home_dashboard_cubit_test.dart -x` | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 3 | UX-04 | — | N/A | widget | `flutter test test/presentation/finance/ -x` | ❌ W0 | ⬜ pending |
| 03-05-01 | 05 | 3 | FIN-09,FIN-10 | — | N/A | unit | `flutter test test/application/finance/home_dashboard_cubit_test.dart -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/domain/finance/transaction_test.dart` — stubs for FIN-01, FIN-02, FIN-03
- [ ] `test/domain/finance/savings_goal_test.dart` — stubs for FIN-05, FIN-06
- [ ] `test/application/finance/transaction_cubit_test.dart` — stubs for FIN-01–FIN-03
- [ ] `test/application/finance/budget_cubit_test.dart` — stubs for FIN-04
- [ ] `test/application/finance/debt_cubit_test.dart` — stubs for FIN-07, FIN-08
- [ ] `test/application/finance/home_dashboard_cubit_test.dart` — stubs for FIN-09, FIN-10
- [ ] `test/presentation/finance/` directory — widget test stubs for UX-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pie + bar charts render correctly | FIN-10 | Visual rendering cannot be asserted in unit tests | Run app on device; add 3 transactions across 2 categories; verify chart shows correct proportions |
| Empty states show on all screens | UX-04 | Visual assertion requires running app | Launch app with no finance data; verify each screen shows an empty state with an action prompt |
| Dashboard balance updates immediately after add | FIN-01 | Requires live Isar + cubit integration on device | Add transaction; verify dashboard balance reflects new amount without manual refresh |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
