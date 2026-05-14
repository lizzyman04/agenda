---
phase: "03-finance-core"
plan: "02"
subsystem: "data/finance + infrastructure/finance + config/di"
tags: ["isar", "dao", "mapper", "repository-impl", "di", "migration", "tdd"]
dependency_graph:
  requires:
    - "03-01: domain entities and repository interfaces"
  provides:
    - "lib/data/finance/transaction_model.dart"
    - "lib/data/finance/transaction_category_model.dart"
    - "lib/data/finance/budget_model.dart"
    - "lib/data/finance/savings_goal_model.dart"
    - "lib/data/finance/debt_model.dart"
    - "lib/data/finance/recurring_payment_model.dart"
    - "lib/data/finance/finance_mappers.dart"
    - "lib/data/finance/transaction_dao.dart"
    - "lib/data/finance/transaction_category_dao.dart"
    - "lib/data/finance/budget_dao.dart"
    - "lib/data/finance/savings_goal_dao.dart"
    - "lib/data/finance/debt_dao.dart"
    - "lib/data/finance/recurring_payment_dao.dart"
    - "lib/infrastructure/finance/transaction_repository_impl.dart"
    - "lib/infrastructure/finance/transaction_category_repository_impl.dart"
    - "lib/infrastructure/finance/budget_repository_impl.dart"
    - "lib/infrastructure/finance/goal_repository_impl.dart"
    - "lib/infrastructure/finance/debt_repository_impl.dart"
    - "lib/infrastructure/finance/recurring_payment_repository_impl.dart"
  affects:
    - "03-03: Application cubits consume repository impls via DI"
    - "03-04: Presentation layer reads domain entities from repositories"
    - "03-05: Dashboard cubit reads TransactionRepository and GoalRepository"
tech_stack:
  added:
    - "isar_community @Collection pattern for finance domain (6 new collections)"
    - "isar_community @embedded GoalContribution with List.empty(growable: true)"
  patterns:
    - "TransactionType/DebtDirection/RecurringCycle enums in data layer annotated @Enumerated(EnumType.name)"
    - "DAO pattern: const constructor + IsarService + deletedAtIsNull + limit(500)"
    - "BudgetModel composite unique index (month, year, categoryId)"
    - "Repository impls: @LazySingleton(as: Interface) self-registration"
    - "MigrationRunner case-N pattern — idempotent seeding via count() guard"
    - "FakeIsar test double for writeTxn testing (avoids libisar.so dependency)"
key_files:
  created:
    - "lib/data/finance/transaction_model.dart"
    - "lib/data/finance/transaction_model.g.dart"
    - "lib/data/finance/transaction_category_model.dart"
    - "lib/data/finance/transaction_category_model.g.dart"
    - "lib/data/finance/budget_model.dart"
    - "lib/data/finance/budget_model.g.dart"
    - "lib/data/finance/savings_goal_model.dart"
    - "lib/data/finance/savings_goal_model.g.dart"
    - "lib/data/finance/debt_model.dart"
    - "lib/data/finance/debt_model.g.dart"
    - "lib/data/finance/recurring_payment_model.dart"
    - "lib/data/finance/recurring_payment_model.g.dart"
    - "lib/data/finance/finance_mappers.dart"
    - "lib/data/finance/transaction_dao.dart"
    - "lib/data/finance/transaction_category_dao.dart"
    - "lib/data/finance/budget_dao.dart"
    - "lib/data/finance/savings_goal_dao.dart"
    - "lib/data/finance/debt_dao.dart"
    - "lib/data/finance/recurring_payment_dao.dart"
    - "lib/infrastructure/finance/transaction_repository_impl.dart"
    - "lib/infrastructure/finance/transaction_category_repository_impl.dart"
    - "lib/infrastructure/finance/budget_repository_impl.dart"
    - "lib/infrastructure/finance/goal_repository_impl.dart"
    - "lib/infrastructure/finance/debt_repository_impl.dart"
    - "lib/infrastructure/finance/recurring_payment_repository_impl.dart"
    - "test/data/finance/transaction_mapper_test.dart"
    - "test/data/finance/savings_goal_mapper_test.dart"
    - "test/data/database/migration_runner_test.dart"
  modified:
    - "lib/data/database/migration_runner.dart"
    - "lib/core/config/app_config.dart"
    - "lib/config/di/finance_module.dart"
    - "lib/config/di/injection.config.dart"
    - "lib/main.dart"
decisions:
  - "FakeIsar test double used instead of MockIsar for writeTxn tests — libisar.so unavailable in VM test mode; FakeIsar executes callback and captures putAll arguments"
  - "TransactionType enum defined in transaction_model.dart and imported by transaction_category_model.dart — single source of truth for Isar-layer enum"
  - "MigrationRunner uses isar.collection<T>() generic accessor (not generated extension) for compatibility with FakeIsar test double"
  - "BudgetDao.findByCategoryMonthYear uses .limit(1).findAll() then checks isEmpty — avoids .first on empty list crash"
metrics:
  duration: "~50 minutes"
  completed: "2026-05-14"
  tasks_completed: 3
  tasks_total: 3
  files_created: 28
  files_modified: 5
  tests_written: 22
  tests_passing: 22
---

# Phase 3 Plan 2: Finance Data Layer Summary

Six Isar @Collection models with DAOs, mappers, and repository implementations — all finance persistence contracts wired into the DI graph, schema seeded with 13 default categories, and injection.config.dart regenerated.

## What Was Built

### Task 1a: Isar @Collection Models, Build Runner, Mappers, and Tests (commit a1af0df)

Six Isar @Collection model files in `lib/data/finance/`:

- **TransactionModel** — amountCents (int), @Enumerated TransactionType, @Index categoryId, @Index date, note, linkedGoalId, @Index deletedAt
- **TransactionCategoryModel** — namePtBr, nameEn (nullable), @Enumerated TransactionType, isDefault; NO deletedAt (categories are not soft-deleted)
- **BudgetModel** — categoryId, month, year, limitCents; composite unique index on (month, year, categoryId) enforces one budget per slot
- **SavingsGoalModel** — title, targetAmountCents, deadline, `List<GoalContribution> contributions = List.empty(growable: true)`, isCompleted, @Index deletedAt
- **DebtModel** — title, amountCents, @Enumerated DebtDirection (toPay/toReceive), counterparty, @Index dueDate, isPaid, paidAt, @Index deletedAt
- **RecurringPaymentModel** — title, amountCents, categoryId, @Enumerated RecurringCycle, @Index nextDueDate, isActive, @Index deletedAt

`@embedded GoalContribution` with no-arg constructor, amountCents = 0, late DateTime date, String? note.

Six generated `.g.dart` schema files from build_runner.

`finance_mappers.dart`: TransactionMapper, TransactionCategoryMapper, BudgetMapper, GoalMapper, DebtMapper, RecurringPaymentMapper — each with const-constructable class, toDomain/toModel methods, switch-based enum converters, autoIncrement guard (id == 0 → don't set model.id).

**Tests:** 13 mapper unit tests passing — amountCents round-trip, autoIncrement guard (id=0 → not set), id=5 → model.id=5, income/expense enum round-trips, growable list append test, 2-contribution list mapping, DebtDirection.toPay and toReceive round-trips.

### Task 1b: Six DAOs (commit bed9d7c)

Six DAO classes in `lib/data/finance/`:

- **TransactionDao** — findAll (deletedAtIsNull), findById, findByMonth (expense type + date range with exclusive upper bound), findByLinkedGoal, save, softDelete, watchLazy
- **TransactionCategoryDao** — findAll, findById, findByType, count, save, putAll, hardDelete
- **BudgetDao** — findByCategoryMonthYear (.limit(1).findAll()), findByMonth, save, deleteWhere
- **SavingsGoalDao** — findAll (deletedAtIsNull), findById, save, softDelete, watchLazy
- **DebtDao** — findAll (deletedAtIsNull), findById, save, softDelete, watchLazy
- **RecurringPaymentDao** — findAll (isActive=true + deletedAtIsNull), findById, save, softDelete

All DAOs: `const DaoName(this._isarService); final IsarService _isarService;` pattern.

### Task 2: Repository Impls, DI Wiring, Schema Registration, Migration Case 3 (commit 8240499)

Six repository implementations in `lib/infrastructure/finance/`:

- **TransactionRepositoryImpl** — amountCents > 0 and categoryId > 0 validation on create/update; softDelete reads back via findById (bypasses deletedAtIsNull)
- **TransactionCategoryRepositoryImpl** — guards isDefault on delete and update; loads model first to check flag (T-03-02-02)
- **BudgetRepositoryImpl** — setLimit upserts by loading findByCategoryMonthYear; limitCents > 0 validation
- **GoalRepositoryImpl** — title non-empty + targetAmountCents > 0 on create; addContribution validates amountCents > 0, appends to growable embedded list (T-03-02-04)
- **DebtRepositoryImpl** — title non-empty + amountCents > 0; togglePaid flips isPaid + manages paidAt
- **RecurringPaymentRepositoryImpl** — title non-empty + amountCents > 0 + categoryId > 0

`AppConfig.schemaVersion` bumped from 2 → 3.

`MigrationRunner` case 3 added: `_seedDefaultCategories(isar)` with count() idempotency guard. Seeds 9 expense categories (Alimentação, Transporte, Moradia, Saúde, Educação, Lazer, Roupas, Tecnologia, Outros) and 4 income categories (Salário, Freelance, Investimentos, Outros). All with `isDefault = true` and Portuguese + English names.

`FinanceModule` populated: 6 DAO factory methods + 6 mapper getter singletons. Repository impls self-register via `@LazySingleton(as: InterfaceType)`.

`lib/main.dart` updated: `IsarService.instance.open([ItemModelSchema, TransactionModelSchema, TransactionCategoryModelSchema, BudgetModelSchema, SavingsGoalModelSchema, DebtModelSchema, RecurringPaymentModelSchema])`.

`injection.config.dart` regenerated with all finance module registrations.

**Migration Tests:** 9 tests passing — version tracking (v1→v3), no-op for current target, idempotency guard (existing categories = skip), putAll called with exactly 13 models, all 9 expense PT-BR names, all 4 income PT-BR names, all isDefault = true.

## Verification Results

```
flutter test test/data/finance/ test/data/database/migration_runner_test.dart
22/22 tests passed

dart analyze lib/data/finance/ lib/infrastructure/finance/ lib/config/di/finance_module.dart
0 errors (infos only — line length, doc comment HTML)

grep -c "schemaVersion = 3" lib/core/config/app_config.dart → 1
grep -c "TransactionModelSchema" lib/main.dart → 1
grep -c "List.empty(growable: true)" lib/data/finance/savings_goal_model.dart → 1
grep -c "case 3" lib/data/database/migration_runner.dart → 2
grep -c "TransactionDao" lib/config/di/finance_module.dart → 2
grep "FinanceModule\|TransactionDao\|GoalMapper\|DebtRepository" injection.config.dart → 8 matches
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test used `const SavingsGoalContribution(date: DateTime(...))` which is invalid**
- **Found during:** Task 1a, test RED phase
- **Issue:** `SavingsGoalContribution` is `const` but `DateTime(2026, 1, 1)` is not a `const` expression in Dart
- **Fix:** Changed `const SavingsGoalContribution(...)` to `SavingsGoalContribution(...)` (no const) in test
- **Files modified:** `test/data/finance/savings_goal_mapper_test.dart`
- **Commit:** a1af0df

**2. [Rule 1 - Bug] MockIsar.writeTxn returned null for generic Future<T> callbacks**
- **Found during:** Task 2, migration test GREEN phase
- **Issue:** Mocktail's `when(() => mockIsar.writeTxn(any())).thenAnswer((_) async {})` returns null, but the internal callback from `collection.putAll()` returns `Future<List<int>>`, causing a type mismatch at runtime
- **Fix:** Replaced `MockIsar` with `FakeIsar` — a `Fake implements Isar` subclass that actually executes the callback and exposes `writeTxnCallCount` for verification. Also added `MockIsarCollection` to capture `putAll` arguments for content assertions
- **Files modified:** `test/data/database/migration_runner_test.dart`
- **Commit:** 8240499

**3. [Rule 1 - Bug] MigrationRunner used Isar extension accessor (.transactionCategoryModels) incompatible with FakeIsar**
- **Found during:** Task 2, recognizing that generated extensions (`.transactionModels`, `.transactionCategoryModels`) are only available on real Isar instances
- **Fix:** Changed MigrationRunner to use `isar.collection<TransactionCategoryModel>()` (generic accessor) which works with both real Isar and the FakeIsar test double. This is also more resilient to collection name changes.
- **Files modified:** `lib/data/database/migration_runner.dart`
- **Commit:** 8240499

**4. [Rule 1 - Bug] Pre-existing AppConfig test checked schemaVersion == 2, failed after bump to 3**
- **Found during:** Post-commit comprehensive test run
- **Issue:** `test/core/config/app_config_test.dart` had `expect(AppConfig.schemaVersion, 2)` — broken by the legitimate schemaVersion bump
- **Fix:** Updated test description and expected value to `3`
- **Files modified:** `test/core/config/app_config_test.dart`
- **Commit:** 348360d

## Known Stubs

None — this plan is data and infrastructure layer only. No UI rendering, no display-only stubs.

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model. All created files are local Dart data layer code with no network endpoints, no auth paths, and no external service dependencies.

## Self-Check: PASSED
