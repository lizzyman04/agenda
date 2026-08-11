---
status: diagnosed
phase: 03-finance-core
source:
  - 03-01-SUMMARY.md
  - 03-02-SUMMARY.md
  - 03-03-SUMMARY.md
  - 03-04-SUMMARY.md
  - 03-05-SUMMARY.md
started: 2026-06-15T00:00:00Z
updated: 2026-08-11T05:20:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete — 4 issues diagnosed, ready for /gsd-plan-phase 3 --gaps]

## Device Test Session (2026-08-11)

All 10 tests executed by Claude over adb on a physical device, at the user's
request, instead of by conversational checkpoint. Tests 1-4 were re-run to
confirm the results recorded in the earlier (human) session.

Device: Infinix X6831 (099344034M008322), Android, debug APK built from source.
Screenshots: /tmp/claude-1000/.../scratchpad/uat/*.png

Re-test outcomes vs. previously documented results:

| Test | Was | Now | Note |
|------|-----|-----|------|
| 1 | pass | pass | confirmed |
| 2 | pass | issue | contradicts — category never resolves in the list |
| 3 | issue | issue | confirmed, trigger isolated |
| 4 | pass | pass | confirmed |

New this session: test 5 blocker, test 9 minor issue, and an app-wide
undo-timer defect that also affects Phase 02's Tarefas screen.

## Tests

### 1. Cold Start Smoke Test
expected: Fresh launch on a clean install (or after clearing app data). App boots without errors, Isar migration adds the 6 finance collections, and the Finance tab opens to the Resumo dashboard showing empty states — no crash, no error screen.
result: pass
retest: "2026-08-11 device re-verification (claude-adb) — CONFIRMS documented result. Ran `pm clear com.omeu.space.agenda` then relaunched the debug build on Infinix X6831. App booted clean; Tarefas showed 'Nenhuma tarefa'; Finanças opened to Resumo with 'Sem dados financeiros'; every finance tab (Transações, Orçamentos, Objetivos, Dívidas, Recorrências) rendered its own empty state. No crash, no error screen."

### 2. Add a Transaction (income + expense)
expected: In Transações, tapping add opens the transaction form. Pick type (income/expense), a category, enter an amount, pick a date, save. The transaction appears in the Transações list and the Resumo balance updates accordingly.
result: issue
retest: "2026-08-11 device re-verification (claude-adb) — CONTRADICTS the documented pass. Saving works (income MT 5.000,00 Salário; expenses MT 1.200,00 Alimentação and MT 300,00 Transporte all persisted, correct green/red semantic colors, correct PT-BR money format, category picker correctly filtered to income vs expense categories). But the list card never shows the category name — it renders the raw id ('#10', '#1', '#2') in both title and subtitle. The category resolves correctly inside the form, only the list is wrong. Separately, when a note exists it is rendered twice on the same card: once as the title and again as a chip below the subtitle."
severity: major
tested_by: claude-adb

### 3. Swipe-to-Delete Transaction + Undo
expected: Swiping a transaction card dismisses it from the list and a SnackBar with Undo appears. Tapping Undo restores the transaction to the list; the balance reverts.
result: issue
reported: "If multiple transactions are added, then a switch-to-delete and undo is performed, it doesn't always restore the transaction that was actually dropped; it might restore a different one. And in other tests, the SnackBar didn't appear."
severity: major
retest: "2026-08-11 device re-verification (claude-adb) — CONFIRMS the report, and pins the trigger. Single swipe in isolation works: correct card dismissed, 'Transação excluída / Desfazer' SnackBar appeared, Desfazer restored that exact transaction. The failure needs a SECOND swipe while the first SnackBar is still on screen: swiped 'Mercado semana', then swiped 'Uber' ~1s later; only one SnackBar was ever visible, and tapping Desfazer restored 'Mercado semana' (the FIRST delete) while Uber stayed deleted. Both halves of the user's report are the same defect — the second SnackBar is queued behind the first, so it 'doesn't appear', and the visible Undo still belongs to the earlier deletion."

### 4. Set a Budget Limit
expected: In Orçamentos, set a monthly limit for a category. The category shows a progress bar of spent-vs-limit that changes color across three states (under = primary, near = amber, over = red) as spending approaches/exceeds the limit.
result: pass
retest: "2026-08-11 device re-verification (claude-adb) — CONFIRMS documented result. Set a MT 1.000,00 limit on Alimentação against MT 1.200,00 spent; card renders 'MT 1.200,00 / MT 1.000,00' with a full RED bar (over state). Category names render correctly on this screen. The budget-limit sheet opened and closed with no _dependents crash — the ae397ae fix holds. Only the over state was exercised; under/near thresholds were not swept."

### 5. Create a Savings Goal + Add Contribution
expected: In Objetivos, create a goal with a name and target amount. Open it and add a contribution. The goal progress card advances toward the target (amount saved + percentage update).
result: issue
reported: "Tested on device (Infinix X6831, Android, debug build). Goal creation works — 'Fundo Emergencia' saved, card shows MT 0,00 de MT 1.000,00 / 0%. Adding a contribution of 250 CRASHES: red error screen 'package:flutter/src/widgets/framework.dart: Failed assertion: line 6268 pos 12: _dependents.isEmpty: is not true'. Contribution is not persisted — goal still MT 0,00 after restart. Reproduced 2/2 deterministically."
severity: blocker
tested_by: claude-adb

### 6. Add a Debt + Toggle Paid
expected: In Dívidas, create a debt with a direction (you owe / owed to you) and amount. It appears in the list; toggling it paid updates its status/visual state.
result: pass
notes: "Device test: created 'Empréstimo Joao', A receber, MT 500,00, contraparte Joao, prazo 10/09/2026. Card rendered with direction chip 'A receber' and 'Pendente' toggle off. Toggling flipped label to 'Pago' with the switch filled. No crash."
tested_by: claude-adb

### 7. Add a Recurring Payment
expected: In Recorrências, create a recurring payment (name, amount, cycle). It appears in the active recurring-payments list.
result: pass
notes: "Device test: created 'Netflix', MT 350,00, categoria Lazer, ciclo Mensal, próximo 10/09/2026. The category-picker bottom sheet opened and closed cleanly (no _dependents crash — this screen owns its controllers in State). Card lists 'Mensal · Próximo: 10/09/2026' with the Ativo toggle on."
tested_by: claude-adb

### 8. Resumo Dashboard — Summary Card + Charts + Month Nav
expected: The Resumo tab shows a summary card (balance + net worth). With data present, a spending pie/donut chart with a legend and a per-category bar chart render. With no data for a month, an empty state shows instead of a broken chart. Month navigation changes the displayed period and the figures update.
result: pass
notes: "Device test: with 5.000,00 income and 1.200,00 expense, summary card showed 'Saldo atual MT 3.800,00' and 'Patrimônio líquido MT 3.800,00' — arithmetic correct. Month selector rendered 'agosto 2026' with < > arrows. Donut chart rendered with legend 'Alimentação · MT 1.200,00' and a per-category bar chart below ('Alime…' truncated label). Category names resolve correctly on this screen, unlike the transaction list. Empty state was separately confirmed at the start of the session on clean data. Month navigation arrows were not exercised — the < > buttons were not tapped, so period switching remains unverified."
tested_by: claude-adb

### 9. Link a Task to a Goal or Debt
expected: In the task form's "Vincular a..." section, link a task to a savings goal or a debt. The task detail screen then shows a finance-link chip reflecting the link.
result: issue
reported: "Device test: linking works end to end — the 'Vincular a...' sheet listed real names under Objetivos ('Fundo Emergencia') and Dívidas ('Empréstimo Joao / Joao'), selection persisted, and the form showed 'Ligado a Empréstimo Joao'. But the task DETAIL screen chip reads 'Ligado a Dívidas #1' — the raw entity id instead of the linked entity's name."
severity: minor
tested_by: claude-adb

### 10. Money Formatting + Currency Symbol
expected: All monetary amounts display formatted with the 'MT' currency symbol and locale-correct decimals (PT-BR comma separator, e.g. 1.234,56). No raw cents or unformatted numbers appear.
result: pass
notes: "Device test: every amount seen across the session formatted correctly with the MT symbol and PT-BR separators — MT 5.000,00, MT 1.200,00, MT 300,00, MT 3.800,00, MT 1.000,00, MT 500,00, MT 350,00. No raw cents, no unformatted numbers. (The '#10'/'#1' strings on transaction cards are category-name placeholders, not money formatting — tracked under test 2.)"
tested_by: claude-adb

## Summary

total: 10
passed: 6
issues: 4
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Swiping a transaction deletes it and a SnackBar with Undo restores that exact transaction; balance reverts."
  status: failed
  reason: "User reported: If multiple transactions are added, then a switch-to-delete and undo is performed, it doesn't always restore the transaction that was actually dropped; it might restore a different one. And in other tests, the SnackBar didn't appear."
  severity: major
  test: 3
  root_cause: "transaction_list_screen.dart `_handleDelete` calls ScaffoldMessenger.showSnackBar without hiding the current one first. Material queues SnackBars FIFO, so a second swipe within the 5s undo window does not replace the visible SnackBar — it waits behind it. The visible SnackBar's SnackBarAction closure still captures the FIRST deleted tx.id, so Desfazer restores the earlier transaction while the just-swiped one stays deleted. The undo itself is correctly id-based (`cubit.restoreTransaction(tx.id)`), so this is purely a SnackBar-lifecycle defect, not a wrong-id lookup."
  artifacts:
    - path: "lib/presentation/finance/screens/transaction_list_screen.dart"
      issue: "_handleDelete (lines 40-54) shows a SnackBar without calling hideCurrentSnackBar()/clearSnackBars() first, so overlapping deletes queue instead of replacing."
  missing:
    - "Call ScaffoldMessenger.of(context).hideCurrentSnackBar() immediately before showSnackBar in _handleDelete so each delete replaces the previous undo prompt."
    - "Add a widget test: delete two transactions within the undo window, assert only the most recent SnackBar is visible and that its Undo restores the most recently deleted transaction."

- truth: "The transaction list card shows the transaction's category name, and shows the note once."
  status: failed
  reason: "Device test: cards render the raw category id ('#10', '#1', '#2') instead of the category name, in both title and subtitle. When a note exists it is shown twice — as the card title and again as a chip."
  severity: major
  test: 2
  root_cause: "transaction_list_screen.dart `_categoryName` (lines 113-118) is an unfinished stub — it ignores the transaction entirely and always returns '#${tx.categoryId}'. Its own comment says 'For now, use a placeholder that works.' The categories are never fetched into this screen, so there is nothing to resolve the id against. Separately, transaction_card.dart renders `transaction.note ?? categoryName` as the title (line 68) AND a Chip with the same note (lines 82-92) whenever `hasNote` is true — and hasNote is true for every note that differs from the category name, so a note always double-renders."
  artifacts:
    - path: "lib/presentation/finance/screens/transaction_list_screen.dart"
      issue: "_categoryName is a hardcoded '#id' placeholder; category list is never loaded into the screen."
    - path: "lib/presentation/finance/widgets/transaction_card.dart"
      issue: "Note rendered twice — as ListTile title (line 68) and as a Chip (lines 82-92)."
  missing:
    - "Expose the category list on TransactionLoaded (or read it from the category cubit) and resolve categoryId → localized name, mirroring the langCode handling in budget_overview_screen.dart."
    - "Decide one layout for the card — e.g. title = category name, chip/subtitle = note — so a note never renders twice."
    - "Note: the same '#id' placeholder pattern also exists in spending_pie_chart.dart:63 and spending_bar_chart.dart:43, but there it is a genuine fallback behind a real lookup, not a stub."
  debug_session: ""

- truth: "Adding a contribution to a savings goal persists it and advances the goal progress card (amount saved + percentage)."
  status: failed
  reason: "Device test: submitting a contribution throws 'InheritedElement._dependents.isEmpty is not true' (framework.dart:6268) and renders the red error screen. Contribution never persists. Reproduced 2/2."
  severity: blocker
  test: 5
  root_cause: "goal_detail_screen.dart `_addContribution` recreates the exact anti-pattern already fixed in budget_overview_screen.dart: the two TextEditingControllers are created in method scope (lines 41-42) and disposed immediately after `await showModalBottomSheet` returns (lines 152-153), while the dismiss transition is still animating and the TextFields are still mounted. Compounding it, `unawaited(cubit.addContribution(...))` fires a cubit emit during sheet teardown, so a rebuild races the disposal. Same failure signature as the budget-limit bug fixed in commit ae397ae."
  artifacts:
    - path: "lib/presentation/finance/screens/goal_detail_screen.dart"
      issue: "Method-scope TextEditingControllers disposed right after the sheet await; sheet body is a StatefulBuilder instead of a StatefulWidget that owns the controllers; mutation dispatched via unawaited() during teardown."
  missing:
    - "Extract the sheet body into a private StatefulWidget (mirror `_BudgetLimitSheet`) that owns amountCtrl/noteCtrl/selectedDate and disposes them in its own State.dispose()."
    - "Return the built SavingsGoalContribution via Navigator.pop instead of calling the cubit from inside the sheet."
    - "Await cubit.addContribution after the sheet has fully closed — drop the unawaited() call."
    - "Add a widget regression test for the contribution sheet, mirroring budget_limit_sheet_test.dart."
  debug_session: ""

- truth: "The task detail screen's finance-link chip names the linked goal or debt."
  status: failed
  reason: "Device test: chip reads 'Ligado a Dívidas #1' instead of 'Ligado a Empréstimo Joao'. The link itself is correct and persisted, and the task FORM shows the proper name — only the detail chip shows the raw id."
  severity: minor
  test: 9
  root_cause: "task_detail_screen.dart:303 interpolates '#${item.linkedGoalId ?? item.linkedDebtId}' directly, because the detail screen never loads the goal/debt entity to resolve a name. Same class of placeholder as the transaction-list category stub."
  artifacts:
    - path: "lib/presentation/tasks/screens/task_detail_screen.dart"
      issue: "Line 303 renders the raw linked entity id instead of resolving the goal/debt name."
  missing:
    - "Resolve the linked goal/debt name on the task detail screen — the same lookup the task form already performs for 'Ligado a Empréstimo Joao'."
  debug_session: ""

- truth: "The 5-second undo window expires on its own: the undo SnackBar auto-dismisses and the pending soft delete commits."
  status: failed
  reason: "Device test: undo SnackBars never auto-dismiss. Fresh app, single swipe-delete, AppConstants.undoSnackbarDuration = 5s — the SnackBar was still on screen at 16s, and in an earlier run one stayed up for ~5 minutes. Reproduced on BOTH Finanças (transaction_list_screen) and Tarefas (task_list_screen), so it is app-wide, not finance-specific. Related symptom: after deleting a task and restarting the app, the task reappeared, suggesting the TaskListCubit's Timer(5s) commit never fired either."
  severity: major
  test: 3
  root_cause: "NOT ISOLATED — needs a debug session. Ruled out so far: (a) Flutter's documented behaviour of suppressing the SnackBar auto-dismiss timer when MediaQuery.accessibleNavigation is true — `dumpsys accessibility` reports touchExplorationEnabled=false (only a JacyBOT USSD service is bound, capabilities=33, no touch exploration), so accessibleNavigation should be false; (b) device animation scales — window and transition scales are both 1.0. Remaining suspects: a global timeDilation / test hook left enabled, a suppressed or non-firing Ticker, or an OEM (Transsion XOS) power-management behaviour throttling Dart timers. This finding makes the test-3 queueing defect far worse: because the first SnackBar never expires, every later one is stuck behind it indefinitely."
  artifacts:
    - path: "lib/core/constants/app_constants.dart"
      issue: "undoSnackbarDuration = 5s is correct; the timers built on it are not firing on device."
    - path: "lib/presentation/finance/screens/transaction_list_screen.dart"
      issue: "Undo SnackBar never auto-dismisses (line 47 duration ignored in practice)."
    - path: "lib/presentation/tasks/screens/task_list_screen.dart"
      issue: "Same non-dismissing SnackBar at line 116 — confirms app-wide scope."
    - path: "lib/application/tasks/task_list/task_list_cubit.dart"
      issue: "Timer at line 78 that commits the soft delete appears not to fire — deleted task returned after app restart."
  missing:
    - "Run /gsd-debug on this: instrument whether the Dart Timer fires at all (log in the TaskListCubit undo timer callback) to separate a Flutter SnackBar-layer problem from a device-level timer-throttling problem."
    - "Re-test on a second device or emulator to confirm whether this is Transsion/XOS-specific before changing app code."
  debug_session: ""
