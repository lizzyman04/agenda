---
status: complete
phase: 03-finance-core
source: [03-VERIFICATION.md]
started: 2026-08-24T03:50:00Z
updated: 2026-10-03T06:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Full 10-step UAT device pass on current HEAD

Re-exercise the full 10-flow script in `03-UAT.md` on a physical Android device
against current HEAD, paying particular attention to tests 2, 3 and 9 — all three
were fixed since the last device session (2026-08-11 / 2026-08-14) but have only
ever been verified host-side. Current HEAD also carries the 03-13/03-14 BL-01
closure, which is DAO-level only and changes no UI.

expected: All 10 flows behave as documented in `03-UAT.md`. Tests 2 (category name
resolution on the transaction list), 3 (double-swipe undo replacing rather than
queueing the SnackBar), and 9 (task-detail finance chip showing the linked
goal/debt title rather than a raw entity id) hold on real hardware exactly as they
do in the widget tests.

why_human: `03-UAT.md`'s own device session on 2026-08-11 already demonstrated that
a host-side pass does not guarantee device-observed correctness for this codebase —
test 2 was recorded as passing in an earlier lightly-tested pass, then failed on the
first real device retest, revealing the category-id stub bug. No device has touched
this code since 2026-08-11/14. Requires physical device access.

result: pass
tested_by: claude-adb
device_run: |
  2026-10-03, Infinix X6831 (099344034M008322), debug APK built from HEAD 08c9d8f, `pm clear` first.
  1 Cold start: pass. Boot clean, Finanças -> Resumo 'Sem dados financeiros'.
  2 Transactions: pass. Cards show 'Salário' / 'Alimentação' / 'Transporte' (no '#id'); note renders once, as a chip.
  3 Undo: pass. Two swipes ~1s apart -> exactly one SnackBar; Desfazer restored the SECOND-deleted tx, first stayed deleted.
    SnackBar auto-dismissed (gone by next sample). Task side: Tarefas delete (trash button) -> 'Tarefa excluída' SnackBar,
    gone after ~6s untouched, force-stop + relaunch -> 'Nenhuma tarefa' (task stayed deleted).
  4 Budget: pass. Alimentação limit 1.000 vs 1.200 spent -> full red bar, sheet closes with no crash. under/near states NOT swept.
  5 Goal contribution: pass. 250 -> 'MT 250,00 de MT 1.000,00' 25%, history entry, no crash.
  6 Debt: pass. 'A receber' MT 500,00, toggled Pendente -> Pago.
  7 Recurring: pass. Netflix MT 350,00 Mensal listed, Ativo.
  8 Resumo: pass. Summary card, donut renders, month nav outubro<->setembro works, empty state 'Sem gastos em setembro'.
  9 Task link: pass. Detail chip 'Ligado a EmprestimoJoao' (name, not raw id).
  10 Money format: pass, with one cosmetic note: negatives render as 'MT - 1.200,00' (space after minus).

## Summary

total: 1
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
