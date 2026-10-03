<!-- GSD:GENERATED -->
<!-- generated-by: gsd-doc-writer -->

# Architecture

AGENDA is a privacy-first Flutter mobile application structured as a strict layered architecture. It covers both task management and personal finance. All data is stored exclusively on-device via Isar Community. No network layer exists — there are no HTTP clients, no analytics SDKs, and no external service integrations in the current codebase. Platform services for notifications, backup and app lock do not exist yet (Phases 4 and 5). The architecture enforces one-way dependency flow: presentation depends on application, application depends on domain, data and infrastructure implement domain interfaces, and nothing in domain knows about Flutter or Isar.

---

## Layer Overview

```
┌─────────────────────────────────────────────┐
│              presentation/                  │
│   Screens, Widgets (Flutter/Material UI)    │
└───────────────────┬─────────────────────────┘
                    │ reads state, calls cubit methods
┌───────────────────▼─────────────────────────┐
│              application/                   │
│        BLoC/Cubit state management          │
└───────────────────┬─────────────────────────┘
                    │ calls repository interfaces, domain services
┌───────────────────▼─────────────────────────┐
│               domain/                       │
│   Entities, Repository interfaces,          │
│   Domain services (pure Dart)               │
└───────────────┬───┴─────────────────────────┘
                │ implemented by
┌───────────────▼─────────────┐   ┌───────────────────────────────┐
│       infrastructure/       │   │           data/               │
│  Repository implementations │   │  Isar models, DAOs, DB service│
│  (wrap data layer with      │◄──│  ItemMapper, MigrationRunner  │
│   Result<T> error handling) │   │                               │
└─────────────────────────────┘   └───────────────────────────────┘
                    ▲
┌───────────────────┴─────────────────────────┐
│                core/                        │
│   Result<T>/Failure hierarchy, constants,   │
│   extensions, AppConfig                     │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                config/                      │
│   GetIt DI graph (injectable),              │
│   l10n configuration                        │
└─────────────────────────────────────────────┘
```

### Directory roles

| Directory | Role |
|-----------|------|
| `lib/core/` | Cross-cutting utilities: `Result<T>` / `Failure` sealed classes, `AppConfig`, `AppConstants`, datetime/string extensions, storage key constants, and the amount parser and formatter (`lib/core/utils/`). No Flutter imports in non-extension files. |
| `lib/domain/` | Pure Dart entities and abstract interfaces. Tasks: `Item`, `ItemRepository`, `RecurrenceEngine`, enums (`ItemType`, `Priority`, `EisenhowerQuadrant`, `SizeCategory`). Finance (`lib/domain/finance/`): six per-entity folders — `transaction`, `budget`, `goal`, `debt`, `recurring`, `category` — each with its entities and repository interface. Zero Flutter, zero Isar. |
| `lib/data/` | Isar persistence. Tasks: `ItemModel` (`@Collection`), embedded value objects (`MoneyInfo`, `TimeInfo`), `ItemDao`, `ItemMapper`. Finance (`lib/data/finance/`): one folder per entity with its Isar model, DAO and mapper. Shared: `IsarService` singleton wrapper and `MigrationRunner`. Money is stored as integer cents. |
| `lib/infrastructure/` | Implements domain interfaces and always returns `Result<T>` — never throws. `lib/infrastructure/tasks/` holds `ItemRepositoryImpl` and `RecurrenceEngineImpl` (iCal RRULE parsing and next-occurrence dates). `lib/infrastructure/finance/` holds the six finance repository implementations. Platform services (notifications, backup, app lock) will live here in Phases 4-5. |
| `lib/application/` | BLoC/Cubit state machines: task cubits (`TaskListCubit`, `DayPlannerCubit`, `ProjectCubit`), finance cubits (`TransactionCubit`, `BudgetCubit`, `GoalCubit`, `GoalListCubit`, `DebtCubit`, `RecurringPaymentCubit`, `HomeDashboardCubit`) and `LocaleCubit`. All cubits receive dependencies via constructor injection from GetIt. |
| `lib/presentation/` | Flutter screens and widgets, split into `tasks/` and `finance/` slices. Reads cubit state via `BlocBuilder`/`BlocConsumer`. Dispatches user actions to cubit methods. Never calls repositories directly. |
| `lib/config/` | Wiring: GetIt DI modules (`CoreModule`, `TasksModule`, `FinanceModule`, `InfrastructureModule`), generated `injection.config.dart`, and the l10n ARB files and `l10n.yaml`. |
| `lib/generated/` | Code-generated ARB output (`AppLocalizations`, `AppLocalizationsEn`, `AppLocalizationsPt`). Generated, committed, do not edit manually. |

---

## Data Flow

A typical user action — creating a task — moves through the following path:

1. **User taps FAB** on `TaskListScreen` → `_navigateToCreate()` pushes `TaskFormScreen`.
2. **User submits form** → `TaskListCubit.createItem(item)` is called with a domain `Item` (id = 0).
3. **`TaskListCubit`** calls `ItemRepository.createItem(item)` (the abstract interface).
4. **`ItemRepositoryImpl`** (concrete) validates `parentId` if set, stamps `createdAt`/`updatedAt` via `DateTime.now()`, calls `ItemMapper.toModel(item)` to produce an `ItemModel`, then calls `ItemDao.save(model)`.
5. **`ItemDao`** executes an Isar write transaction (`writeTxn → collection.put(model)`). Isar assigns the auto-increment id.
6. **`IsarService.db.collection<ItemModel>().watchLazy()`** fires a change event.
7. **`TaskListCubit._watchSubscription`** listener receives the event and calls `_reload()`.
8. **`_reload()`** calls `ItemRepository.filterItems(...)` with the current `TaskListFilter`, receives `Success<List<Item>>`, and emits `TaskListLoaded(items: ...)`.
9. **`TaskListScreen`** rebuilds via `BlocBuilder` — the new item appears in the list.

This reactive pattern (write → watch stream fires → cubit reloads → UI rebuilds) means cubits never manually reconcile local state after a write; the Isar watch stream is the single source of truth for rebuild triggers.

---

## State Management

All state management uses `flutter_bloc` Cubits (not full Blocs — no event classes).

### Cubits

| Cubit | Lifecycle | Constructor dependencies |
|-------|-----------|--------------------------|
| `TaskListCubit` | Factory — provided to the tab shell in `lib/app.dart` | `ItemRepository`, `RecurrenceEngine` |
| `DayPlannerCubit` | Factory — provided to the tab shell, in-memory only | none |
| `ProjectCubit` | Factory — one per project screen | `ItemRepository` |
| `LocaleCubit` | Factory — provided at app root | `SharedPreferences` |
| `TransactionCubit` | Factory — provided above `MaterialApp` | `TransactionRepository`, `TransactionCategoryRepository` |
| `BudgetCubit` | Factory — provided above `MaterialApp` | `TransactionRepository`, `BudgetRepository`, `TransactionCategoryRepository` |
| `GoalListCubit` | Factory — provided above `MaterialApp` | `GoalRepository` |
| `GoalCubit` | Factory — one per goal detail or form screen | `GoalRepository`, `TransactionRepository` |
| `DebtCubit` | Factory — provided above `MaterialApp` | `DebtRepository` |
| `RecurringPaymentCubit` | Factory — provided above `MaterialApp` | `RecurringPaymentRepository` |
| `HomeDashboardCubit` | Factory — provided above `MaterialApp` | `TransactionRepository`, `GoalRepository`, `DebtRepository`, `TransactionCategoryRepository` |

The finance cubits follow the same reactive pattern as the task cubits: `TransactionCubit` and `HomeDashboardCubit` subscribe to `TransactionRepository.watchChanges()` and reload on every write. They are provided above `MaterialApp` so every pushed route inherits the same instances. `HomeDashboardCubit` reads the uncapped aggregate query (`getAllTransactionsForAggregates`), because balance and net worth are totals and must see every non-deleted row.

### State shapes

`TaskListCubit` uses a sealed class hierarchy with five concrete states:

- `TaskListInitial` — pre-load
- `TaskListLoading` — query in flight
- `TaskListLoaded(items, filter, searchQuery)` — data ready
- `TaskListWithPendingUndo(deletedItemId, items, filter, searchQuery)` — soft-delete committed; 5-second undo window active
- `TaskListError(failure)` — repository returned `Err`

All state classes extend `Equatable` for value-based equality. The sealed class constraint (Dart `sealed`) makes all `switch` expressions over state exhaustive at compile time — missing a case is a compile error.

### Reactive reload pattern

`TaskListCubit.start()` subscribes to `ItemRepository.watchChanges()`, which proxies `ItemDao.watchLazy()` (Isar's `collection.watchLazy()` stream). Any write to the `ItemModel` collection — regardless of which cubit caused it — fires the stream and triggers `_reload()`. This keeps the task list synchronized across screens without manual cache invalidation.

---

## Error Handling

All fallible operations use the `Result<T>` / `AsyncResult<T>` types defined in `lib/core/failures/result.dart`. Methods never throw — they return `Err(failure)`.

```dart
sealed class Result<T> { ... }
final class Success<T> extends Result<T> { final T value; }
final class Err<T>     extends Result<T> { final Failure failure; }
typedef AsyncResult<T> = Future<Result<T>>;
```

The `Failure` sealed class hierarchy:

| Subtype | When used |
|---------|-----------|
| `DatabaseFailure` | Isar read/write or transaction errors |
| `ValidationFailure` | Business rule violations (e.g. `parentId` must point to a project) |
| `NotificationFailure` | Reserved for Phase 4 notification scheduling |
| `BackupFailure` | Reserved for Phase 4 CSV export/import |
| `SecurityFailure` | Reserved for Phase 5 PIN/biometric auth |

Pattern matching at call sites is exhaustive — adding a new `Failure` subtype forces all `switch` expressions to handle it or the compiler rejects the build.

---

## Dependency Injection

AGENDA uses GetIt 9.2.1 as the service locator with injectable 2.7.1 for annotation-driven code generation. The DI graph is built in `configureDependencies()` (called in `main()` before `runApp`).

### Modules

| Module | Registers |
|--------|-----------|
| `CoreModule` | `IsarService` (singleton) and `SharedPreferences` (async, pre-resolved) |
| `TasksModule` | `ItemDao` and `ItemMapper` (lazy singletons) |
| `FinanceModule` | The six finance DAOs and six mappers (lazy singletons) |
| `InfrastructureModule` | Empty placeholder until the platform services of Phases 4-5 |

Repository implementations (`ItemRepositoryImpl`, `RecurrenceEngineImpl` and the six finance repositories) register themselves through `@LazySingleton(as: ...)` class annotations. Every cubit is annotated `@injectable`, so it is a factory.

`SharedPreferences` is pre-resolved (`@preResolve`) so it is available synchronously at all call sites after `configureDependencies()` completes. All Cubits are factories (not singletons) — a fresh instance is created each time `getIt<CubitType>()` is called.

The generated wiring lives in `lib/config/di/injection.config.dart` and must not be edited by hand. Regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Database Schema

AGENDA uses isar_community 3.3.2 (community-maintained fork of the abandoned `isar` package). The database file is stored in the application documents directory via `path_provider`.

### Collections overview

The schema version is **3**. Money is stored as integer cents (`amountCents`), never as a floating-point number. Version 3 added the finance collections and seeds 13 default categories (9 expense, 4 income).

| Collection | Model file |
|------------|------------|
| Items (projects, tasks, subtasks) | `lib/data/tasks/item_model.dart` |
| Transactions | `lib/data/finance/transaction/transaction_model.dart` |
| Transaction categories | `lib/data/finance/category/transaction_category_model.dart` |
| Budgets | `lib/data/finance/budget/budget_model.dart` |
| Savings goals | `lib/data/finance/goal/savings_goal_model.dart` |
| Debts | `lib/data/finance/debt/debt_model.dart` |
| Recurring payments | `lib/data/finance/recurring/recurring_payment_model.dart` |

### Items collection: `ItemModel`

One unified collection stores projects, tasks, and subtasks. The `type` field (`ItemType` enum: `project`, `task`, `subtask`) discriminates between them. Parent/child relationships use an integer `parentId` field (non-null only for subtasks).

**Indexes:**

| Index | Fields | Purpose |
|-------|--------|---------|
| Composite | `(type, deletedAt)` | Fast active-items-by-type queries |
| Single | `parentId` | Subtask lookups by project |
| Single | `deletedAt` | Soft-delete filter |
| Single | `dueDate` | Due-date range queries |

**Embedded value objects:**

- `TimeInfo` — `dueTimeMinutes` (int, minutes since midnight) and `recurrenceRule` (iCal RRULE string). `dueDate` is promoted to a top-level field (not embedded) so Isar can index it.
- `MoneyInfo` — `amount` (double) and `currencyCode` (ISO 4217 string). Populated only if either field is non-null.

**Key design decisions:**

- `EisenhowerQuadrant` is never stored — it is computed from `(isUrgent, isImportant)` as a getter on the domain `Item` entity.
- All list queries apply `.deletedAtIsNull()` and `.limit(500)`. Soft-deleted records remain in the collection with a non-null `deletedAt` timestamp.
- Enums are persisted as strings (`@Enumerated(EnumType.name)`) for forward-compatibility.
- `linkedGoalId` and `linkedDebtId` are null-capable `int?` columns. They are set when the user links a task to a savings goal or a debt from the task form.

### Migration system

`MigrationRunner` runs on every cold start inside `IsarService.open()`. The current schema version is stored in `SharedPreferences` under `StorageKeys.schemaVersion`. Migrations execute once in ascending order; each successful migration writes the new version before proceeding to the next. The target version is the `AppConfig.schemaVersion` constant (currently `3`).

---

## Navigation

Navigation uses Flutter's imperative `Navigator.of(context).push(MaterialPageRoute(...))` — `go_router` is declared as a dependency but is not wired yet (nothing imports it). The tab structure is managed by `_AppShell` in `lib/app.dart` (a `StatefulWidget` with `IndexedStack`).

**Tab screens (persistent — kept alive via `IndexedStack`):**

| Index | Screen | Cubit |
|-------|--------|-------|
| 0 | `TaskListScreen` | `TaskListCubit` |
| 1 | `EisenhowerScreen` | `TaskListCubit` (provided to the tab shell) |
| 2 | `DayPlannerScreen` | `DayPlannerCubit` |
| 3 | `GtdFilterScreen` | `TaskListCubit` (provided to the tab shell) |
| 4 | `FinanceDashboardScreen` | the finance cubits provided above `MaterialApp` |

`FinanceDashboardScreen` hosts six sub-tabs: dashboard, transactions (`TransactionListScreen`), budgets (`BudgetOverviewScreen`), goals (`GoalListScreen`), debts (`DebtListScreen`) and recurring payments (`RecurringPaymentScreen`).

**Task modal routes (pushed over tabs):**

- `TaskFormScreen` — create/edit a task or project
- `TaskDetailScreen` — read-only task detail with Edit and Delete actions
- `ProjectScreen` — project detail with subtask rollup (creates its own `ProjectCubit` factory instance)

**Finance routes (pushed over the finance tab):**

- `TransactionFormScreen`, `DebtFormScreen`, `RecurringPaymentFormScreen` — create/edit forms
- `GoalFormScreen` and `GoalDetailScreen` (under `lib/presentation/finance/goals/`) — goal form and contribution history; each creates its own `GoalCubit`

---

## Localization

AGENDA ships PT-BR (default) and English translations. `LocaleCubit` persists the locale to `SharedPreferences`, but `setLocale` has no caller yet: the in-app language switch arrives with the Settings screen in Phase 5. The Flutter ARB pipeline (`flutter gen-l10n`) generates `AppLocalizations` from ARB files. The `l10n.yaml` configuration drives generation; output lands in `lib/generated/l10n/`.

Supported locales are `[Locale('pt', 'BR'), Locale('en')]`. `LocaleCubit` defaults to PT-BR when no preference is stored.

---

## Key Abstractions

| Abstraction | File | Description |
|-------------|------|-------------|
| `Item` | `lib/domain/tasks/item.dart` | Core domain entity for projects, tasks, and subtasks. Pure Dart, immutable, with `copyWith` using a `clearField` sentinel for nullable fields. |
| `ItemRepository` | `lib/domain/tasks/item_repository.dart` | Abstract interface for all item persistence operations. Returns `AsyncResult<T>` — never throws. |
| `RecurrenceEngine` | `lib/domain/tasks/recurrence_engine.dart` | Abstract domain service for iCal RRULE parsing and next-occurrence computation. |
| `Result<T>` / `AsyncResult<T>` | `lib/core/failures/result.dart` | Sealed `Success<T>` / `Err<T>` discriminated union. The standard return type for all fallible operations. |
| `Failure` | `lib/core/failures/failure.dart` | Sealed failure hierarchy. Exhaustive `switch` at call sites is compiler-enforced. |
| `ItemModel` | `lib/data/tasks/item_model.dart` | Isar `@Collection` — the only class that touches Isar APIs. |
| `ItemMapper` | `lib/data/tasks/item_mapper.dart` | Pure bidirectional converter between `ItemModel` and `Item`. The only place where data-layer and domain-layer enums are mapped. |
| `ItemDao` | `lib/data/tasks/item_dao.dart` | All raw Isar queries in one place. Async only — no `*Sync` methods. |
| `IsarService` | `lib/data/database/isar_service.dart` | Process-wide singleton wrapping the `Isar` instance. `open()` is idempotent. |
| `TaskListCubit` | `lib/application/tasks/task_list/task_list_cubit.dart` | Primary task management state machine. Subscribes to `ItemRepository.watchChanges()` for reactive reloads. |
| `AppConfig` | `lib/core/config/app_config.dart` | Compile-time constants: app name, package id, version, schema version, notification ID namespaces. |
| `TransactionRepository` | `lib/domain/finance/transaction/transaction_repository.dart` | Abstract interface for transaction persistence, including the uncapped aggregate read used by dashboards. Implemented by `lib/infrastructure/finance/transaction_repository_impl.dart`. |
| `TransactionModel` | `lib/data/finance/transaction/transaction_model.dart` | Isar `@Collection` for transactions; stores `amountCents` as an integer. |
| `HomeDashboardCubit` | `lib/application/finance/dashboard/home_dashboard_cubit.dart` | Balance, net worth and per-category spend for the selected month; aggregation lives in `dashboard_aggregator.dart`. |
| `IsarTestHarness` | `test/support/isar_test_harness.dart` | Opens a real Isar instance in an isolated temp directory for tests. See [TESTING.md](TESTING.md). |
| Architecture guard | `tool/check_architecture.dart` | Enforces the house rules below; exemptions live in `tool/architecture_exemptions.dart`. |

---

## House rules and the architecture guard

Three rules are checked by `dart run tool/check_architecture.dart`:

1. No hand-written `lib/` file exceeds 150 lines (generated files are exempt).
2. No directory holds more than 10 hand-written `.dart` files.
3. Every directory under `lib/presentation/` and `lib/application/` has a `README.md`.

Documented exemptions live in `tool/architecture_exemptions.dart` (one line-cap exemption exists: `lib/core/constants/currencies.dart`). The guard runs in CI right after the Analyze step and fails the build on any violation. A worked example of a compliant slice is [`lib/presentation/finance/goals/README.md`](../lib/presentation/finance/goals/README.md).
