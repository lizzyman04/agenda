# Phase 3: Finance Core — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 03-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-14
**Phase:** 03-finance-core
**Areas discussed:** Transaction categories, Dashboard balance scope, Goal contribution flow, Currency configuration, Task ↔ finance linkage

---

## Transaction categories

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed predefined enum | Hard-coded list stored as @enumerated name on TransactionModel. Zero extra schema, no CRUD screen. | |
| User-created custom categories | Separate Categories Isar collection, full CRUD screen. | |
| Hybrid — fixed defaults + user adds | Seed categories (isDefault=true) + user can add custom ones. Categories Isar collection required. | ✓ |

**User's choice:** Hybrid — separate Categories Isar collection with predefined seeds and user-extensible custom categories.

| Option | Description | Selected |
|--------|-------------|----------|
| Separate lists per type | Income categories and expense categories are distinct lists. | ✓ |
| One shared list | Same pool for both income and expenses. | |
| Expenses only | Income uses a fixed enum; only expenses get categories. | |

**User's choice:** Separate lists per transaction type.

| Option | Description | Selected |
|--------|-------------|----------|
| No — defaults protected | Seed categories flagged isDefault=true, cannot be deleted or renamed. | ✓ |
| Yes — full CRUD including defaults | All categories editable/deletable, cascade required. | |
| You decide | Leave to Claude. | |

**User's choice:** Defaults are protected; users can only add on top.

| Option | Description | Selected |
|--------|-------------|----------|
| Standard personal finance set | Expense: Alimentação, Transporte, Moradia, Saúde, Educação, Lazer, Roupas, Tecnologia, Outros. Income: Salário, Freelance, Investimentos, Outros. | ✓ |
| Minimal set | Expense: Alimentação, Transporte, Moradia, Outros. Income: Salário, Outros. | |
| User defines the list | Freeform. | |

**User's choice:** Standard personal finance set.

---

## Dashboard balance scope

| Option | Description | Selected |
|--------|-------------|----------|
| Net of ALL transactions ever | Running total from first entry. Like a bank balance. | ✓ |
| Net of current calendar month only | Resets to zero on the 1st. Monthly budget view, not total wealth. | |
| You decide | Leave to Claude. | |

**User's choice:** Net of ALL transactions ever.

| Option | Description | Selected |
|--------|-------------|----------|
| Balance + savings goal totals − outstanding debts | Full picture: balance + Σ(goal.amountSaved) − Σ(debts-to-pay). | ✓ |
| Transaction balance only | Net worth = balance. Goals and debts shown separately. | |
| You decide | Leave to Claude. | |

**User's choice:** Balance + savings goal totals − outstanding debts-to-pay.

| Option | Description | Selected |
|--------|-------------|----------|
| Current calendar month | Chart opens on current month. Pie + bar for selected month. | ✓ |
| Last 12 months | Bar shows 12 monthly bars (total spend/month). | |
| You decide | Leave to Claude. | |

**User's choice:** Current calendar month with prev/next arrow navigation.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — arrow navigation | Prev/next arrows to browse any historical month. | ✓ |
| No — current month only | Static view, no navigation. | |
| You decide | Leave to Claude. | |

**User's choice:** Yes — arrow navigation.

---

## Goal contribution flow

| Option | Description | Selected |
|--------|-------------|----------|
| Manual "Add contribution" only | Button on goal detail, amount + date entry, GoalContribution entity. | |
| Tag a transaction to a goal | linkedGoalId FK on transaction, goal progress = filtered sum. | |
| Both — manual AND transaction tagging | Two data paths aggregated. GoalContribution entity + linkedGoalId on transactions. | ✓ |

**User's choice:** Both — manual contributions AND transaction tagging. Goal progress = Σ(contributions) + Σ(tagged transactions).

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — counts in both places | Goal-tagged transaction appears in budget spend AND goal progress. | ✓ |
| No — excluded from budget tracking | Separate flow, not in budget. | |
| You decide | Leave to Claude. | |

**User's choice:** Goal-tagged transactions count in both goal progress AND budget category spend.

| Option | Description | Selected |
|--------|-------------|----------|
| Any category can be tagged to any goal | Goal link is optional FK, independent of category. | ✓ |
| Fixed "Poupança" category + can override | Protected savings category as default for goal-tagged transactions. | |

**User's choice:** Any category can be tagged to any goal — no forced category.

---

## Currency configuration

**Notes:** Decision provided directly by user outside AskUserQuestion flow.

**User's decision:**
- Manual selection only — no automatic locale detection
- One currency per user, app-wide (all transactions, goals, debts, budgets)
- Stored in SharedPreferences (`userCurrency` key)
- Default: MZN (Metical Moçambicano, symbol MT)
- Currency list: comprehensive ISO 4217, implemented as static Dart list (no package)
- Priority entries: MZN, BRL, USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, ZAR
- Amount display: `{symbol} {formatted_amount}` with locale-aware decimal formatting
- Phase 3 reads the stored pref; Phase 5 adds the onboarding currency picker

---

## Task ↔ finance linkage

| Option | Description | Selected |
|--------|-------------|----------|
| Read-only reference display only | Task detail shows "Linked to: [Goal/Debt name]" chip. No side-effects on completion. | ✓ |
| Completing a task auto-creates a transaction | Marks complete → auto-contribution with confirmation dialog + undo support. | |
| Defer entirely — fields stay null in Phase 3 | linkedGoalId/linkedDebtId unused in Phase 3. | |

**User's choice:** Read-only reference display only.

| Option | Description | Selected |
|--------|-------------|----------|
| From task form only | New "Vincular a..." picker section in TaskForm. | ✓ |
| From both task form and goal/debt detail screens | Bidirectional linking from either side. | |

**User's choice:** Task form only.

| Option | Description | Selected |
|--------|-------------|----------|
| Display-only — no financial computation | moneyInfo shown on task card/detail; does not feed balance, budget, or goal progress. | ✓ |
| moneyInfo feeds linked goal via "Record contribution" button | User-initiated contribution of moneyInfo amount to linked goal. | |

**User's choice:** Display-only. moneyInfo remains as Phase 2 left it.

---

## Claude's Discretion

- `GoalContribution` storage: embedded list on `SavingsGoalModel` vs. separate `GoalContributionModel` collection (choose to avoid N+1 on progress computation)
- `HomeDashboardCubit` aggregation strategy: Isar streams vs. single computed query on refresh
- Empty state illustration style for finance screens (be consistent with Phase 2 task empty states)
- Category picker UI: BottomSheet vs. inline expandable row in TransactionForm

## Deferred Ideas

- Currency onboarding picker — Phase 5 first-launch screen
- Multi-currency support — v2 (FIN-V2-02)
- Budget rollover per category — v2 (FIN-V2-01)
- Task completion → auto-create transaction — deferred, Phase 4+ or v2
- Bidirectional task-finance link from goal/debt screens — future enhancement
- Debts-to-receive included in net worth — deferred UX decision
