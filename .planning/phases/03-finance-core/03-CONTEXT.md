# Phase 3: Finance Core — Context

**Gathered:** 2026-05-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 delivers the complete finance domain: a user can log income and expense transactions with categories, set monthly budgets per category, create and track savings goals (via manual contributions and/or transaction tagging), log debts (to pay / to receive) and recurring payments, and view their financial picture on a dashboard showing current balance, net worth, and a monthly spending breakdown rendered as pie and bar charts — all stored locally in Isar.

Phase 3 also wires the task ↔ finance link established in Phase 2: tasks with `linkedGoalId` or `linkedDebtId` show a read-only reference chip on their detail screen. No side-effects on completion.

The currency setting (which currency symbol/code the app uses) is stored in SharedPreferences and read by Phase 3 at runtime. The onboarding picker for first-launch currency selection is Phase 5's responsibility.

Notifications triggered by finance events (budget threshold alerts, debt due reminders, goal off-track alerts, recurring payment reminders) are Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Transaction Categories

**D-01:** Categories are stored in a separate **`TransactionCategory`** Isar collection — NOT an enum. This supports the hybrid model: predefined seed categories plus user-added custom ones.

**D-02:** Income and expense categories are **separate lists**, discriminated by a `TransactionType` field on `TransactionCategory` (or a separate `CategoryType` enum). A "Salário" income category is independent from expense categories.

**D-03:** Seed categories are flagged `isDefault = true`. Default categories **cannot be deleted or renamed** by the user. User-added custom categories have `isDefault = false` and are fully editable/deletable.

**D-04: Default expense categories (PT-BR labels; EN via l10n):**
Alimentação, Transporte, Moradia, Saúde, Educação, Lazer, Roupas, Tecnologia, Outros

**D-05: Default income categories (PT-BR labels; EN via l10n):**
Salário, Freelance, Investimentos, Outros

**D-06:** Categories are seeded in `MigrationRunner` on schema version 3 (first-ever run). Seeding is idempotent — check if defaults already exist before inserting.

### Dashboard Balance and Net Worth

**D-07:** **Current balance** = sum of all income transactions − sum of all expenses, from the first entry to today. A running lifetime total. No monthly reset.

**D-08:** **Net worth** = current balance + Σ(goal.amountSaved for all active goals) − Σ(debt.amount for debts where direction == `toPay` and `isPaid == false`). Debts-to-receive (money owed TO the user) are NOT added to net worth in Phase 3 — they are shown on the debt screen but excluded from the net worth formula.

**D-09:** The spending **chart** defaults to the **current calendar month**. Pie chart shows proportions per expense category for the selected month. Bar chart shows spend per category for the same selected month.

**D-10:** Chart month navigation uses **prev/next arrow buttons**. Selecting a different month re-queries Isar for that month's transactions. No limit on how far back the user can navigate.

### Goal Contribution Flow

**D-11:** Goal progress is tracked via **two paths, aggregated**:
1. **Manual contributions** — user taps "Adicionar contribuição" on the goal detail screen, enters amount + optional date. Stored as a `GoalContribution` sub-entity (or embedded list on the goal).
2. **Transaction tagging** — when logging a transaction, user optionally links it to a savings goal (`linkedGoalId` FK on `TransactionModel`). Tagged transactions count toward goal progress.
Goal progress = Σ(manual contributions) + Σ(tagged transaction amounts).

**D-12:** A transaction tagged to a goal **counts in both** goal progress AND its category's budget spend. It is a real financial outflow that appears in both views.

**D-13:** Any expense category can be tagged to any goal. The goal link is an **optional foreign key** (`linkedGoalId`) on `TransactionModel`, independent of category selection. No forced "Poupança" category.

### Currency Configuration

**D-14:** **One currency per user, app-wide.** All transactions, goals, debts, budgets, and displayed amounts use the same currency. Multi-currency is v2 scope (FIN-V2-02 in REQUIREMENTS.md).

**D-15:** Currency is **manually selected** by the user — no automatic locale detection. Stored in **SharedPreferences** under a `userCurrency` key (code + symbol + name).

**D-16:** Phase 3 **reads** the stored currency preference to format amounts. Phase 5 adds the first-launch currency picker during onboarding. Dev default: MZN (Metical Moçambicano, symbol MT).

**D-17:** The currency list must be **comprehensive** — full ISO 4217 coverage. Implemented as a **static Dart list** (no extra package dependency). Priority entries: MZN (MT), BRL (R$), USD ($), EUR (€), GBP (£), JPY (¥), CAD (C$), AUD (A$), CHF (CHF), CNY (¥), ZAR (R). The full list is sourced from the ISO 4217 standard and included verbatim.

**D-18:** Amount display format: `{symbol} {formatted_amount}` (e.g., `MT 1.234,56` or `R$ 1.234,56`). Decimal formatting follows the app locale (PT-BR uses comma decimal; EN uses period).

### Task ↔ Finance Linkage

**D-19:** In Phase 3, `linkedGoalId` and `linkedDebtId` on `ItemModel` are **read-only reference display**. When set, the task detail screen shows a chip: "Ligado a: [Goal name]" or "Ligado a: [Debt name]". Tapping the chip navigates to the linked entity's detail screen.

**D-20:** Completing a task does **NOT** auto-create a transaction or contribution. No side-effects on task completion in Phase 3.

**D-21:** Users link a task to a goal or debt from the **task form only** — a new optional "Vincular a..." section with a picker showing active goals and debts. Sets `linkedGoalId` or `linkedDebtId` on `ItemModel` (only one can be set at a time).

**D-22:** `moneyInfo` on `ItemModel` (amount + currencyCode from Phase 2) remains **display-only** in Phase 3. It is shown on the task card and detail screen but does not feed into balance, budget, or goal progress calculations.

### Claude's Discretion

- Internal structure of `GoalContribution` (embedded Isar list on `SavingsGoalModel` vs. a separate `GoalContributionModel` collection — choose whichever avoids N+1 queries for goal progress computation)
- Whether `HomeDashboardCubit` aggregates balance/net worth from Isar streams or from a single computed query on refresh
- Exact empty state illustration style for each finance screen (consistent with Phase 2 task empty states)
- Whether the category picker in TransactionForm uses a BottomSheet or an inline expandable row

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/ROADMAP.md` — Phase 3 goal, plan titles (03-01 through 03-05), success criteria (5 criteria)
- `.planning/REQUIREMENTS.md` — FIN-01 through FIN-10 and UX-04 (all Phase 3 requirements); v2 finance requirements (FIN-V2-01, FIN-V2-02) are explicitly out of scope
- `.planning/PROJECT.md` — constraints, key decisions table, out-of-scope list
- `.planning/STATE.md` — pre-phase decisions including notification ID strategy, schemaVersion pattern

### Phase 2 Contracts (inherit, do not reinvent)
- `.planning/phases/02-task-core/02-CONTEXT.md` — moneyInfo shape (`{ amount: double, currencyCode: String }`); `linkedGoalId`/`linkedDebtId` extensibility contract; Cubit naming conventions; 7-layer enforcement table; Isar schema conventions; Phase 3 extensibility notes
- `.planning/phases/01-foundation/01-CONTEXT.md` — enum annotation convention (`@enumerated(EnumType.name)`), `Result<T>`/`AsyncResult<T>` pattern, sealed Failure hierarchy, DI module split

### Established Codebase Patterns
- `lib/data/database/isar_service.dart` — IsarService singleton; `open()` idempotency pattern; Phase 3 adds finance schemas to the `open()` call
- `lib/data/database/migration_runner.dart` — MigrationRunner; Phase 3 bumps `AppConfig.schemaVersion` to 3 and adds a case 3 block (seed default categories)
- `lib/core/failures/failure.dart` — sealed Failure hierarchy; finance repos use `DatabaseFailure` and `ValidationFailure`
- `lib/core/failures/result.dart` — `Result<T>` / `AsyncResult<T>`; all finance repository interfaces follow this
- `lib/core/config/app_config.dart` — `schemaVersion` (bump to 3); `financeNotificationBase = 20` (Phase 4 reads this — do not remove)
- `lib/config/di/finance_module.dart` — empty placeholder; Phase 3 populates with all finance repo registrations
- `lib/data/tasks/item_model.dart` — `linkedGoalId` (nullable `int?`) and `linkedDebtId` (nullable `int?`) fields are the write targets for D-21; `moneyInfo` field shape for D-22

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/failures/result.dart` — `Result<T>`/`AsyncResult<T>` typedefs; use as-is for all finance repository interfaces
- `lib/core/failures/failure.dart` — `DatabaseFailure`, `ValidationFailure`; finance layer adds no new Failure subtypes in Phase 3
- `lib/data/database/migration_runner.dart` — extend `_runMigration()` with `case 3:` for category seeding; pattern already proven
- `lib/config/di/finance_module.dart` — populate this; follow `lib/config/di/tasks_module.dart` (Phase 2 pattern) for injectable registration style
- `lib/application/tasks/task_list/task_list_cubit.dart` — reference for Cubit state structure and stream emission pattern for `TransactionCubit`, `BudgetCubit`, etc.

### Established Patterns
- **Enum annotation**: every `TransactionType`, `DebtDirection`, `RecurringCycle` enum gets `@enumerated(EnumType.name)` — established Phase 1, no exceptions
- **Soft delete**: `deletedAt` nullable DateTime on Isar models — carry this pattern to all finance entities
- **Repository interface in domain, impl in infrastructure**: `domain/finance/transaction_repository.dart` (interface) ← `infrastructure/finance/transaction_repository_impl.dart` (impl)
- **Result<T> at repo boundary**: no `throw` in domain or data layers; wrap Isar errors in `DatabaseFailure`
- **DI injection**: `@injectable` on impls, `@lazySingleton` on services, registered in `FinanceModule`
- **Query cap**: Phase 2 uses a 500-item cap on active item queries; apply a similar cap to transaction list queries to prevent OOM on large history

### Integration Points
- `ItemModel.linkedGoalId` / `ItemModel.linkedDebtId` — Phase 3 writes these via the task form picker (D-21) and reads them for the task detail chip (D-19). The `ItemDao` already persists these fields; no schema migration needed for `ItemModel`.
- `IsarService.open()` — add finance collection schemas (`TransactionModel`, `TransactionCategoryModel`, `SavingsGoalModel`, `DebtModel`, `RecurringPaymentModel`) to the `schemas:` list
- `AppConfig.schemaVersion` — bump from 2 → 3; triggers `MigrationRunner` case 3 for category seeding
- `FinanceModule` in DI graph — wire all finance repos so `HomeDashboardCubit` and screen-level cubits resolve via GetIt

</code_context>

<specifics>
## Specific Ideas

- **Example task with moneyInfo**: "Desenvolvimento Website K-Desperta" — amount: 8000, currencyCode: "MZN". This drives the task detail chip and moneyInfo display-only rendering (D-22).
- **Net worth formula (exact)**: `netWorth = balance + goals.fold(0, (sum, g) => sum + g.amountSaved) - debts.where((d) => d.direction == DebtDirection.toPay && !d.isPaid).fold(0, (sum, d) => sum + d.amount)`
- **Amount display**: `MT 1.234,56` (PT-BR locale) / `MT 1,234.56` (EN locale). Symbol and code come from SharedPreferences `userCurrency`; decimal formatting follows `intl` locale.
- **ISO 4217 currency list**: implemented as a static `const List<Currency>` in `core/constants/currencies.dart`. `Currency` is a plain Dart value object with `code`, `name`, `symbol` fields — no Isar annotation needed.
- **Category seeding**: `MigrationRunner` case 3 runs `await isar.writeTxn(() async { ... })` to insert default categories with `isDefault = true`. Guard: `if (await isar.transactionCategorys.count() == 0)` before inserting.
- **Chart library**: `fl_chart` — already approved in pubspec (CLAUDE.md). Use `PieChartData` for proportion view and `BarChartData` for category breakdown. No other chart library.

</specifics>

<deferred>
## Deferred Ideas

- **Currency onboarding picker** — Phase 5 adds a first-launch currency selection screen. Phase 3 only reads the stored pref; if unset, defaults to MZN.
- **Multi-currency support** — explicitly v2 (FIN-V2-02 in REQUIREMENTS.md). No conversion logic or per-transaction currency override in Phase 3.
- **Budget rollover per category** — v2 (FIN-V2-01). Phase 3 budgets reset each calendar month with no carry-over.
- **Task completion → auto-create transaction** — deferred. Read-only linkage is enough for Phase 3. Auto-creation logic can be revisited in Phase 4 or as a v2 feature.
- **Bidirectional link from goal/debt screens** — deferred. Phase 3 only links from the task form (D-21). A "Link task" button on the goal or debt detail screen is a future enhancement.
- **Debts-to-receive in net worth** — currently excluded from net worth formula (D-08). Adding them is a UX decision for a future phase; they are shown on the debt screen but not folded into the net worth number.

</deferred>

---

*Phase: 03-finance-core*
*Context gathered: 2026-05-14 via /gsd-discuss-phase session*
