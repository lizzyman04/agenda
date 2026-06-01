---
slug: getit-finance-cubits-not-registered
status: resolved
trigger: "Finance tab crashes with GetIt 'not registered' errors for TransactionCubit, BudgetCubit, GoalListCubit, DebtCubit, RecurringPaymentCubit, HomeDashboardCubit. DI registration gap from Phase 3 Wave 3 execution."
created: 2026-06-01
updated: 2026-06-01
---

## Symptoms

- **Expected:** Finance tab loads and shows financial data (transactions, budgets, goals, debts, recurring payments, dashboard)
- **Actual:** App crashes on Finance tab navigation with GetIt "Object/factory with type X is not registered" errors
- **Errors:**
  - `GetIt: Object/ factory with type TransactionCubit is not registered`
  - `GetIt: Object/ factory with type BudgetCubit is not registered`
  - `GetIt: Object/ factory with type GoalListCubit is not registered`
  - `GetIt: Object/ factory with type DebtCubit is not registered`
  - `GetIt: Object/ factory with type RecurringPaymentCubit is not registered`
  - `GetIt: Object/ factory with type HomeDashboardCubit is not registered`
- **Timeline:** Started after Phase 3 Wave 3 plan execution — cubits were created but finance DI module was not wired into injection
- **Reproduction:** Open app → tap Finance tab → immediate crash

## Current Focus

hypothesis: "CONFIRMED — injection.config.dart was not regenerated after all six finance cubits were written, despite all six having correct @injectable annotations."
test: "Verified injection.config.dart was missing all six cubit registrations. Ran build_runner. Verified all six now present."
expecting: "App Finance tab no longer crashes."
next_action: "resolved"
reasoning_checkpoint: "All six cubits had correct @injectable annotations. The infrastructure finance repos also had correct @LazySingleton annotations and were already in injection.config.dart (build_runner was run at an earlier point). The cubits were added after that last build_runner run, so they were missing from the generated file. build_runner re-run regenerated 34 outputs including injection.config.dart with all six cubits registered as factories."
tdd_checkpoint: ""

## Evidence

- timestamp: 2026-06-01T00:00:00
  file: lib/config/di/injection.config.dart (pre-fix)
  finding: "All six finance cubits absent from generated registrations. DAOs, mappers, and repository impls were registered — only cubits missing. Last build_runner run predated Wave 3 cubit files."

- timestamp: 2026-06-01T00:00:00
  file: lib/application/finance/{transaction,budget,goal,debt,recurring,dashboard}/*_cubit.dart
  finding: "All six cubits have @injectable annotation and correct constructor signatures. Annotations were never the problem."

- timestamp: 2026-06-01T00:00:00
  command: "dart run build_runner build --delete-conflicting-outputs"
  finding: "Succeeded in 92s. Wrote 34 outputs. injectable_config_builder produced 1 output (injection.config.dart)."

- timestamp: 2026-06-01T00:00:00
  file: lib/config/di/injection.config.dart (post-fix)
  finding: "All six cubits now registered: RecurringPaymentCubit, DebtCubit, HomeDashboardCubit, GoalListCubit, BudgetCubit, TransactionCubit — all as gh.factory<T>."

## Eliminated

- Missing @injectable annotations on cubits — eliminated. All six had correct annotations.
- FinanceModule not imported in injection.dart — eliminated. FinanceModule was already imported.
- main.dart not calling configureDependencies() — eliminated. Call was present and awaited before runApp.

## Resolution

root_cause: "build_runner was not re-run after Phase 3 Wave 3 added the six finance cubits. The injection.config.dart file was stale — it included the finance DAOs, mappers, and repositories (written earlier) but not the cubits (written later). GetIt had no factory registered for any of the six cubit types."
fix: "Ran `dart run build_runner build --delete-conflicting-outputs`. The injectable_generator picked up all six @injectable-annotated cubits and regenerated injection.config.dart with their factory registrations."
verification: "Grepped injection.config.dart for all six cubit types — 12 lines matched (import + gh.factory registration for each). Build succeeded with 34 outputs written."
files_changed:
  - lib/config/di/injection.config.dart
