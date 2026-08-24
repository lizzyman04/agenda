---
phase: 03-finance-core
verified: 2026-08-15T06:54:25Z
status: gaps_found
score: 4/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "User can set a monthly budget limit per expense category; a progress indicator shows current spend vs. limit in real time as transactions are added"
    status: partial
    reason: "BudgetCubit._reload folds TransactionRepository.getByMonth into per-category spend and the over-limit warning. getByMonth is implemented by TransactionDao.findByMonth (lib/data/finance/transaction/transaction_dao.dart:51-63), which applies .limit(500) with NO .sortBy — confirmed by direct source read. Isar returns unsorted rows in id (insertion) order, so past 500 expense transactions in a single category-month the cap silently retains the OLDEST 500 and drops the most recent ones, understating spend and potentially hiding an over-limit state. This is the same failure class already rated Critical once in this phase (CR-04) and explicitly left half-fixed by plan 03-09/03-REVIEW.md's BL-01 finding, which the code confirms is still live at HEAD."
    artifacts:
      - path: "lib/data/finance/transaction/transaction_dao.dart"
        issue: "findByMonth (lines 51-63) is a .limit(500) list read with no sortBy, feeding an aggregate (BudgetCubit per-category spend) rather than a display list. The file's own class doc (lines 5-11) claims findAllForAggregates is 'the single, deliberate exception' to the cap — false; findByMonth is capped and feeds an aggregate too."
      - path: "lib/application/finance/budget/budget_cubit.dart"
        issue: "_reload (lines ~78-88) folds the capped, unsorted getByMonth result directly into per-category spend totals and the over-limit warning with no compensating logic."
    missing:
      - "Uncap findByMonth (make it an unbounded aggregate read like findAllForAggregates) since budget spend is a total, not a page — per 03-REVIEW.md BL-01's proposed fix."
      - "Correct the transaction_dao.dart class doc, which currently misdescribes findAllForAggregates as the sole uncapped exception."
      - "Add a behavioral (not source-text) regression test — the existing transaction_dao_ordering_test.dart tests findAll/findAllForAggregates only; it does not reference findByMonth or findByLinkedGoal at all (confirmed by grep — zero hits), so this defect class has zero test coverage."
  - truth: "User can create a savings goal with a target amount and optional deadline, contribute to it, and see the percentage progress update with each contribution"
    status: partial
    reason: "GoalCubit._refreshGoal folds TransactionRepository.getByLinkedGoal into taggedTransactionsCents, which SavingsGoal.amountSavedCents/progressPercent (lib/domain/finance/goal/savings_goal.dart:64-80) use directly to compute displayed progress. getByLinkedGoal is implemented by TransactionDao.findByLinkedGoal (transaction_dao.dart:68-75), which also applies .limit(500) with no sortBy — same defect class as findByMonth above, confirmed by direct source read. Manual contributions (goal.contributions) are unaffected, but the tagged-transaction half of progress can silently understate once a single long-lived goal accumulates 500+ tagged transactions, which is plausible for a goal used across multiple years of daily logging (the intended use pattern for this app per CLAUDE.md's 'open AGENDA at any moment... morning, midday, or night' framing)."
    artifacts:
      - path: "lib/data/finance/transaction/transaction_dao.dart"
        issue: "findByLinkedGoal (lines 68-75) is a .limit(500) list read with no sortBy, feeding GoalCubit's taggedTransactionsCents aggregate."
      - path: "lib/application/finance/goal/goal_cubit.dart"
        issue: "_refreshGoal (lines ~94-103) folds the capped, unsorted getByLinkedGoal result directly into taggedCents with no compensating logic."
    missing:
      - "Uncap findByLinkedGoal since goal progress is a total, not a page — per 03-REVIEW.md BL-01's proposed fix."
      - "Add a behavioral regression test covering the >500-tagged-transaction case; none exists today."
deferred: []
human_verification:
  - test: "Full 10-step UAT device pass on current HEAD (transaction add/edit/delete, swipe-undo x2 in sequence, budget limit set, goal contribution, debt toggle, recurring payment add, dashboard+charts+month nav, task-finance link chip)"
    expected: "All 10 flows behave as documented in 03-UAT.md, including the three flows (tests 2, 3, 9) whose fixes (plans 03-06/03-07/03-08) have only ever been verified by widget test, never re-run on the Infinix X6831 or any device"
    why_human: "03-UAT.md's own device session (2026-08-11) already demonstrated that host-side/widget-test pass does not guarantee device-observed correctness — test 2 was recorded as 'pass' in an earlier (host or lightly-tested) pass and then failed on the first real device retest, revealing the category-id stub bug. The current HEAD (through plan 03-12 and the 03-REVIEW.md delta review) has never been executed on physical hardware; all fix verification since 2026-08-11 is host-side (flutter test / mutation testing) only."
---

# Phase 3: Finance Core Verification Report

**Phase Goal:** Users can log income and expenses, track budgets per category, manage savings goals, monitor debts, and view their financial picture on a dashboard with spending charts — all stored locally
**Verified:** 2026-08-15T06:54:25Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can log an income/expense transaction (amount, category, date, note); edit; delete; dashboard balance updates immediately | ✓ VERIFIED | `Transaction` domain entity + `TransactionCubit` (add/update/softDelete/restoreTransaction) present and wired to `transaction_form_screen.dart` / `transaction_list_screen.dart`. `HomeDashboardCubit.start()` subscribes to `TransactionRepository.watchChanges()` and recomputes balance from `findAllForAggregates()` (uncapped — CR-04 dashboard fix confirmed in source). UAT tests 1, 2, 3, 10 confirmed working on-device (2026-08-11), with tests 2 and 3's defects since closed by plans 03-06/03-07 (host-verified with mutation-checked regression tests, not yet device-retested — see Human Verification). |
| 2 | User can set a monthly budget limit per expense category; a progress indicator shows current spend vs. limit in real time as transactions are added | ✗ FAILED | `BudgetCubit` and `budget_overview_screen.dart`/`BudgetProgressBar` exist and are wired, and the budget-*limit-setting* UAT flow (test 4) passed on-device. But the *spend total* the progress bar renders is computed from `TransactionDao.findByMonth`, which is capped at 500 with no sort (confirmed by direct source read of `transaction_dao.dart:51-63`) — see Gaps. |
| 3 | User can create a savings goal with target amount/optional deadline, contribute to it, and see percentage progress update with each contribution | ✗ FAILED | Goal domain entity, `GoalCubit`, `goal_form_screen.dart`, `goal_detail_screen.dart`, contribution sheet all exist and are wired; UAT test 5 (crash + persistence bug) confirmed fixed and device-reverified (2026-08-11, quick task 260811-97x). But `progressPercent`'s tagged-transaction half is computed from `TransactionDao.findByLinkedGoal`, which is also capped at 500 with no sort (confirmed by direct source read of `transaction_dao.dart:68-75`) — see Gaps. |
| 4 | User can log a debt (to pay/receive) with amount and due date, and a recurring payment (subscription/bill) with amount and billing cycle | ✓ VERIFIED | `Debt`/`RecurringPayment` domain entities present with `direction`/`dueDate` and `amountCents`/`cycle` fields respectively. `DebtCubit`, `RecurringPaymentCubit`, `debt_form_screen.dart`, `recurring_payment_form_screen.dart` wired. UAT tests 6 and 7 both passed on-device (2026-08-11). Debt swipe-delete recoverability (CR-01) closed and verified in 03-REVIEW.md by tracing every layer link, not just shape. |
| 5 | All screens (transaction list, budget overview, goals list, debt list) show meaningful empty states; dashboard shows balance + net worth; spending chart renders monthly category breakdown as pie and bar | ✓ VERIFIED | `FinanceEmptyState` used in `transaction_list_screen.dart`, `budget_overview_screen.dart`, `debt_list_screen.dart`, `recurring_payment_screen.dart`, and `goal_list_screen.dart` (5/5 finance list screens). `DashboardSummaryCard` renders `balanceCents` (displaySmall) and `netWorthCents`. `dashboard_tab.dart` wires `SpendingPieChart`/`SpendingBarChart` to `state.categorySpend`, with `EmptyChartMessage` when a month has transactions but zero expense categories, and `FinanceEmptyState` when there are no transactions at all. UAT test 8 (dashboard, charts, empty states) passed on-device 2026-08-11. |

**Score:** 3/5 truths fully verified, 2/5 FAILED (partial implementation — mechanism exists and is UI-wired, but the underlying aggregate is silently incorrect past a data-volume threshold)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/domain/finance/transaction/transaction.dart` + repo | Transaction entity, income/expense, edit/delete | ✓ VERIFIED | Present, exercised by 297 passing tests |
| `lib/data/finance/transaction/transaction_dao.dart` | `findAllForAggregates` uncapped; `findAll` sorted+capped; `findByMonth`/`findByLinkedGoal` correct | ⚠️ PARTIAL | `findAllForAggregates` and `findAll` are correct (CR-04 dashboard fix holds). `findByMonth` and `findByLinkedGoal` are still `.limit(500)` with no sort — confirmed live at HEAD by direct read |
| `lib/application/finance/budget/budget_cubit.dart` | Per-category spend vs. limit | ⚠️ HOLLOW (partial) | Wired to UI correctly; the spend figure it computes is sourced from the capped/unsorted `findByMonth` |
| `lib/application/finance/goal/goal_cubit.dart` | Goal contribution + percentage progress | ⚠️ HOLLOW (partial) | Wired to UI correctly; the tagged-transaction half of progress is sourced from the capped/unsorted `findByLinkedGoal` |
| `lib/application/finance/debt/debt_cubit.dart` | Debt CRUD + restore | ✓ VERIFIED | `restoreDebt` present, traced end-to-end in 03-REVIEW.md, undo SnackBar wired |
| `lib/application/finance/recurring/recurring_payment_cubit.dart` | Recurring payment CRUD | ✓ VERIFIED (create/update/pause); ⚠️ delete unreachable (WR-D4, non-blocking for stated SC) | `softDelete` exists on the DAO/repo/cubit chain but has zero callers in `lib/presentation/` (confirmed by grep) — a user cannot delete a recurring payment, only pause it. Not a literal roadmap SC failure (SC4 only requires *logging* a recurring payment), flagged as a warning |
| `lib/application/finance/dashboard/home_dashboard_cubit.dart` | Balance, net worth, category spend | ✓ VERIFIED | Uses `findAllForAggregates` (uncapped), `computeNetWorth`, idempotent `start()` |
| `lib/presentation/finance/widgets/dashboard/dashboard_tab.dart` | Pie + bar charts, month nav, empty states | ✓ VERIFIED | `SpendingPieChart`/`SpendingBarChart` wired to `state.categorySpend`; `EmptyChartMessage` and `FinanceEmptyState` both present |
| `lib/presentation/finance/widgets/finance_empty_state.dart` | Reused empty-state widget | ✓ VERIFIED | Used across transaction, budget, debt, recurring, goal list screens (5/5) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `budget_cubit.dart._reload` | `TransactionRepository.getByMonth` → `TransactionDao.findByMonth` | direct call chain | ✗ NOT SAFE | Link exists and executes, but the data it delivers is capped and unsorted — the link is "wired" in the mechanical sense but delivers wrong data past 500 rows |
| `goal_cubit.dart._refreshGoal` | `TransactionRepository.getByLinkedGoal` → `TransactionDao.findByLinkedGoal` | direct call chain | ✗ NOT SAFE | Same defect class as above |
| `home_dashboard_cubit.dart` | `TransactionDao.findAllForAggregates` | direct call chain | ✓ WIRED | Uncapped; balance/net worth correct at any transaction count (CR-04 fix holds) |
| `debt_list_screen.dart` | `DebtCubit.restoreDebt` | undo SnackBar action, cubit+messenger captured before unmount | ✓ WIRED | Traced end-to-end in 03-REVIEW.md including `clearField` sentinel and mapper round-trip |
| `transaction_list_screen.dart` | `TransactionCubit.restoreTransaction` | `hideCurrentSnackBar()` before `showSnackBar()` | ✓ WIRED | Mutation-tested regression coverage per 03-REVIEW.md CR-01/plan 03-07 |
| `task_detail_screen.dart` (undo) | `TaskListCubit.restoreItem` | cubit captured before `Navigator.pop()` | ✓ WIRED | CR-03 closed, traced in 03-REVIEW.md |
| `recurring_payment_screen.dart` | soft-delete path | `Dismissible` / delete affordance | ✗ NOT_WIRED | Zero presentation-layer callers of `softDelete` for recurring payments (WR-D4) — non-blocking for the literal roadmap SC, flagged as warning |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `budget_overview_screen.dart` (via `BudgetProgressBar`) | `categorySpend` | `BudgetCubit._reload` ← `getByMonth` ← `findByMonth` (capped, unsorted) | Real but potentially INCOMPLETE past 500 expense txns/category/month | ⚠️ STATIC-ISH (silently truncated, not obviously wrong) |
| `goal_detail_screen.dart` (via `GoalProgressCard`) | `taggedTransactionsCents` | `GoalCubit._refreshGoal` ← `getByLinkedGoal` ← `findByLinkedGoal` (capped, unsorted) | Real but potentially INCOMPLETE past 500 tagged txns/goal | ⚠️ STATIC-ISH (silently truncated) |
| `dashboard_tab.dart` | `categorySpend`, `balanceCents`, `netWorthCents` | `HomeDashboardCubit` ← `findAllForAggregates` (uncapped) | Yes | ✓ FLOWING |
| `transaction_list_screen.dart` | `transactions`, `categories` | `TransactionCubit` ← `findAll` (sorted-desc, capped, correct for a display list) | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

Not run as live app execution (no device attached, per phase constraints); relied on the project's own test suite plus direct source-code tracing in lieu of executing the app, consistent with `flutter test` being the project's runnable-check mechanism.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Architecture guard passes | `dart run tool/check_architecture.dart` | "Architecture guard: PASS", exit 0 | ✓ PASS |
| Static analysis budget holds | `flutter analyze --no-fatal-infos --fatal-warnings` (measured by orchestrator) | exit 0, 65 issues, 0 line-length violations | ✓ PASS (trusted from orchestrator's re-measurement; not independently re-run by verifier) |
| Full test suite green | `flutter test --no-pub` (re-run independently by verifier) | 297/297 passed, "All tests passed!" | ✓ PASS |
| `findByMonth`/`findByLinkedGoal` behaviorally tested against the 500-cap defect | `grep -n "findByMonth\|findByLinkedGoal" test/data/finance/transaction_dao_ordering_test.dart` | zero matches | ✗ FAIL — no test exists for this code path at all, source-text or behavioral |

### Probe Execution

No `scripts/*/tests/probe-*.sh` files exist in this repository and neither PLAN.md nor SUMMARY.md files for this phase reference probes. Step 7c: SKIPPED (no probes declared or discovered).

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| FIN-01 | 01,02,03,04,06,09,12 | Log income transactions | ✓ SATISFIED | `Transaction.type == income`, form + list wired, UAT test 2 confirmed working post-fix |
| FIN-02 | 01,02,03,04,06,12 | Log expense transactions | ✓ SATISFIED | Same mechanism as FIN-01 |
| FIN-03 | 01,02,03,04,07 | Edit and delete transactions | ✓ SATISFIED | `TransactionCubit.update/softDelete/restoreTransaction`; UAT test 3 confirmed working post-fix (host-verified) |
| FIN-04 | 01,03,04 | Monthly budget limit per category | ⚠️ PARTIALLY SATISFIED | Setting/UI mechanism works (UAT test 4 pass); underlying spend total can be silently wrong past 500 txns/category/month (BL-01) |
| FIN-05 | 01,03,04,08 | Define savings goals | ✓ SATISFIED | `SavingsGoal` entity, `goal_form_screen.dart`, target + optional deadline present |
| FIN-06 | 01,03,04,11 | Track savings goal progress | ⚠️ PARTIALLY SATISFIED | Manual-contribution half correct (UAT test 5 fixed+device-reverified); tagged-transaction half can be silently wrong past 500 tagged txns/goal (BL-01) |
| FIN-07 | 01,03,04,09,10 | Log debts with direction/amount/due date | ✓ SATISFIED | `Debt` entity + `debt_form_screen.dart`; UAT test 6 pass; CR-01 delete-recoverability closed |
| FIN-08 | 01,03,03,04,09 | Log recurring payments | ✓ SATISFIED | `RecurringPayment` entity + `recurring_payment_form_screen.dart`; UAT test 7 pass. (Delete affordance missing — WR-D4 — but not required by the FIN-08 wording, which is about logging, not removing) |
| FIN-09 | 03,05 | Dashboard balance + net worth | ✓ SATISFIED | `DashboardSummaryCard`, `HomeDashboardCubit` uncapped aggregate (CR-04 dashboard half fixed) |
| FIN-10 | 03,05 | Spending charts (pie + bar) | ✓ SATISFIED | `SpendingPieChart`/`SpendingBarChart` wired to `categorySpend`, UAT test 8 pass |
| UX-04 | 05 | Empty states with action prompts | ✓ SATISFIED | `FinanceEmptyState` present on all 5 finance list screens |

No orphaned requirements — all 11 phase requirement IDs (FIN-01 through FIN-10, UX-04) appear in at least one plan's `requirements:` frontmatter and are cross-referenced above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/data/finance/transaction/transaction_dao.dart` | 5-11 | Misleading class doc — claims `findAllForAggregates` is "the single, deliberate exception" to the 500-row cap | ⚠️ Warning | A future reader trusting this comment will believe the aggregate-truncation problem (CR-04) is fully solved; it is not (BL-01) |
| `lib/application/finance/recurring/recurring_payment_cubit.dart` etc. | — | Unreachable dead code: `softDelete` chain exists at 4 layers with zero presentation callers (WR-D4, carried from 03-REVIEW.md) | ⚠️ Warning | Not a roadmap-SC blocker (SC4 only requires logging), but a real usability gap for a finance app — no way to remove a cancelled subscription |
| `test/data/finance/transaction_dao_ordering_test.dart` | whole file | Tests assert on source *text* (`readAsStringSync` + substring match) rather than query *behavior* — confirmed by direct inspection; zero references to `findByMonth`/`findByLinkedGoal` | ⚠️ Warning (carried as WR-D6 from 03-REVIEW.md) | The 297-test green suite would not catch a regression or a fix to BL-01 — passing tests are not evidence either way for this specific defect class |
| No `TBD`/`FIXME`/`XXX` markers found | — | — | — | Debt-marker gate: clean. Scanned all `.dart` files referenced across the 12 phase SUMMARY.md files (95 unique paths); zero matches |

### Human Verification Required

### 1. On-device UAT re-run at current HEAD

**Test:** Execute the full 10-step UAT flow from `03-UAT.md` on a physical Android device (or iOS) against the current commit (`b9ce9d3`), specifically re-exercising tests 2 (category name resolution), 3 (double-swipe undo), and 9 (task-detail finance chip name) — all fixed since the last device session (2026-08-11) but only ever verified host-side.
**Expected:** All 10 flows behave as documented; in particular the fixes for tests 2/3/9 hold on real hardware exactly as they do in widget tests.
**Why human:** This project's own UAT history shows host-side "pass" does not reliably predict device behavior — the test-2 category stub was recorded as working in an earlier lightly-tested pass and only failed once actually run on the Infinix X6831. No device has touched the code since 2026-08-11; three device-sensitive fixes (SnackBar timing/queueing, category resolution, chip resolution) and four more recent Critical-finding fixes (03-09 through 03-12) have zero device evidence behind them.

### Gaps Summary

The phase's mechanical scaffolding for every one of the five roadmap success criteria is present, correctly wired for the common case, and covered by a green 297-test suite. Direct source inspection (not test-suite trust, per this verification's mandate) confirms two roadmap success criteria are **not fully true** at HEAD:

- **SC2 (budget progress)** and **SC3 (goal progress)** both partially rely on `TransactionDao` reads (`findByMonth`, `findByLinkedGoal`) that carry `.limit(500)` with no `sortBy`. Because Isar returns unsorted results in id/insertion order, the cap silently retains the *oldest* rows and drops the *newest* — the identical failure mode that made `findAll`'s equivalent defect (CR-04) a Critical finding requiring its own gap-closure plan (03-09). That plan fixed the dashboard's balance/net-worth path (`findAllForAggregates`) but left these two paths, which the phase's own delta code review (`03-REVIEW.md`, finding **BL-01**, filed minutes before this verification and independently confirmed by both the orchestrator and this verifier via direct source read) explicitly identifies as unremediated.

  Reasoning on exposure, as requested: `findByLinkedGoal` has no time-window filter, so 500 tagged transactions accumulating against one long-lived savings goal over a multi-year usage horizon (the app's own stated design target — "open AGENDA at any moment... morning, midday, or night") is a plausible real-world trigger, not a purely theoretical one. `findByMonth` is narrower (bounded to expense-type transactions within a single calendar month for a single category), making 500 harder to reach for most users but not impossible for a power user logging multiple transactions per day in one category — and regardless of raw likelihood, the failure is *silent and directional* (understates spend, which can hide an over-limit state a user is relying on the app to warn them about), which is a materially worse outcome than the app doing nothing at all. The review's own framing — "a budget bar that under-reports spend is worse than one that reports nothing" — was independently corroborated by tracing `budget_cubit.dart._reload` and `goal_cubit.dart._refreshGoal` directly to the capped calls.

  Per the task instructions, a passing test suite is explicitly not accepted as evidence here: `test/data/finance/transaction_dao_ordering_test.dart` was confirmed by grep to contain zero references to either `findByMonth` or `findByLinkedGoal`, so the green 297/297 result provides no signal about this defect either way — a fresh regression would need a genuinely new (and, per WR-D6, genuinely behavioral rather than source-text) test to catch it.

- One additional non-blocking warning (**WR-D4**, carried from the review): the recurring-payment soft-delete chain is fully built at every layer but has zero presentation-layer callers, so a user has no way to remove a cancelled subscription (only pause it). This does not fail the literal roadmap wording for SC4 ("log a recurring payment... with amount and billing cycle"), so it is reported as a warning rather than a blocking gap, but is worth closing before calling recurring payments feature-complete.

Both blocking gaps are the *same root cause* (the `.limit(500)` + missing-sort pattern in `transaction_dao.dart`) applied to two different call sites, and the review's own suggested fix (uncap both, mirroring the `findAllForAggregates` treatment) is a small, well-scoped, already-drafted change — this should be a fast, focused closure plan rather than a broad re-plan.

---

_Verified: 2026-08-15T06:54:25Z_
_Verifier: Claude (gsd-verifier)_
