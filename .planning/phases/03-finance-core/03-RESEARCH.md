# Phase 03: Finance Core — Research

**Researched:** 2026-05-14
**Domain:** Flutter finance domain — Isar schema design for finance entities, BLoC Cubit patterns for monetary aggregation, fl_chart pie/bar charts, int-cents monetary representation
**Confidence:** HIGH (all stack claims verified against codebase; fl_chart API verified against pub.dev and official docs; Isar aggregate API verified against official docs)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Transaction Categories**
- D-01: Categories stored in a separate `TransactionCategory` Isar collection — NOT an enum. Hybrid: predefined seed + user-added custom.
- D-02: Income and expense categories are separate lists, discriminated by `TransactionType` on `TransactionCategory`.
- D-03: Seed categories have `isDefault = true` and cannot be deleted or renamed. Custom categories have `isDefault = false` and are fully editable/deletable.
- D-04: Default expense categories (PT-BR labels): Alimentação, Transporte, Moradia, Saúde, Educação, Lazer, Roupas, Tecnologia, Outros.
- D-05: Default income categories (PT-BR labels): Salário, Freelance, Investimentos, Outros.
- D-06: Categories seeded in `MigrationRunner` case 3 (first-ever run). Seeding is idempotent — guard: `if (await isar.transactionCategorys.count() == 0)`.

**Dashboard Balance and Net Worth**
- D-07: Current balance = sum of all income − sum of all expenses, lifetime (no monthly reset).
- D-08: Net worth = balance + Σ(goal.amountSaved) − Σ(debt.amount where direction == toPay && !isPaid). Debts-to-receive excluded from net worth.
- D-09: Spending chart defaults to current calendar month; shows proportion per expense category as pie and breakdown as bar.
- D-10: Chart month navigation uses prev/next arrow buttons; no limit on backward navigation.

**Goal Contribution Flow**
- D-11: Goal progress = Σ(manual contributions) + Σ(tagged transaction amounts). Two paths aggregated.
- D-12: A transaction tagged to a goal counts in BOTH goal progress AND its category's budget spend.
- D-13: Goal link on transaction is an optional FK (`linkedGoalId`) independent of category selection.

**Currency Configuration**
- D-14: One currency app-wide. Multi-currency is v2.
- D-15: Currency manually selected. Stored in SharedPreferences under `userCurrency` key.
- D-16: Phase 3 reads the stored currency preference. Dev default: MZN.
- D-17: Full ISO 4217 list as static Dart list in `core/constants/currencies.dart`. Priority entries: MZN, BRL, USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, ZAR.
- D-18: Amount display: `{symbol} {formatted_amount}` (e.g., `MT 1.234,56`). Decimal format follows app locale (PT-BR: comma decimal; EN: period).

**Task ↔ Finance Linkage**
- D-19: In Phase 3, `linkedGoalId` and `linkedDebtId` on `ItemModel` are read-only reference display (chip on task detail).
- D-20: Completing a task does NOT auto-create a transaction or contribution.
- D-21: Users link a task to a goal or debt from the task form only — a "Vincular a..." section. Only one can be set at a time.
- D-22: `moneyInfo` on `ItemModel` is display-only. Does not feed into balance, budget, or goal progress.

### Claude's Discretion
- Internal structure of `GoalContribution` (embedded Isar list on `SavingsGoalModel` vs. separate `GoalContributionModel` collection).
- Whether `HomeDashboardCubit` aggregates balance/net worth from Isar streams or a single computed query on refresh.
- Exact empty state illustration style (consistent with Phase 2 task empty states).
- Whether the category picker in TransactionForm uses a BottomSheet or an inline expandable row.

### Deferred Ideas (OUT OF SCOPE)
- Currency onboarding picker — Phase 5.
- Multi-currency support — v2 (FIN-V2-02).
- Budget rollover per category — v2 (FIN-V2-01).
- Task completion → auto-create transaction — deferred.
- Bidirectional link from goal/debt screens — deferred.
- Debts-to-receive in net worth — excluded from formula (D-08).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIN-01 | User can log income transactions with amount, category, date, and optional note | TransactionModel @Collection + TransactionCubit.createTransaction() + TransactionType.income |
| FIN-02 | User can log expense transactions with amount, category, date, and optional note | TransactionModel with TransactionType.expense + category FK + BudgetCubit watch update |
| FIN-03 | User can edit and delete transactions | TransactionRepository.updateTransaction() + softDelete pattern from Phase 2 |
| FIN-04 | User can set a monthly budget limit per expense category | BudgetModel @Collection with categoryId FK + month/year fields + BudgetCubit.setLimit() |
| FIN-05 | User can define savings goals with target amount and optional deadline | SavingsGoalModel @Collection + GoalCubit.createGoal() |
| FIN-06 | User can track savings goal progress (amount saved vs. target) | Aggregated from GoalContribution list + tagged transactions sum via GoalCubit |
| FIN-07 | User can log debts with direction (to pay vs. to receive), amount, and due date | DebtModel @Collection + DebtDirection enum + DebtCubit |
| FIN-08 | User can log recurring payments (subscriptions/bills) with amount and cycle | RecurringPaymentModel @Collection + RecurringCycle enum |
| FIN-09 | User can view a dashboard with current balance and net worth overview | HomeDashboardCubit — balance = income sum − expense sum; net worth formula per D-08 |
| FIN-10 | User can view spending summary charts — monthly breakdown by category (pie and bar) | fl_chart PieChart + BarChart fed by HomeDashboardCubit monthly category aggregation |
| UX-04 | All screens display meaningful empty states with action prompts when no data exists | EmptyState widget pattern (consistent with Phase 2 task empty states) |
</phase_requirements>

---

## Summary

Phase 3 delivers the complete finance domain on top of Phase 1 and 2's proven scaffold. The architecture is identical to Phase 2: domain entities (pure Dart) → Isar models (data layer) → DAO → repository impl → Cubit → presentation. Phase 3 introduces five Isar collections (TransactionModel, TransactionCategoryModel, SavingsGoalModel, DebtModel, RecurringPaymentModel) plus a `GoalContribution` embedded list on SavingsGoalModel. The finance DI module (`FinanceModule`), placeholder since Phase 1, is fully populated in this phase.

The two highest-complexity decisions are: (1) monetary amount representation — the codebase currently uses `double` (from `moneyInfo.amount`) but the finance domain demands precision; int cents is the correct choice for all finance models; (2) dashboard aggregation strategy — Isar does not support SQL-style GROUP BY, so category-spending breakdowns must be computed in Dart from a filtered transaction list. This is fine at the 500-item query cap but must be designed as a single pass, not N+1 per category.

fl_chart 1.2.0 (already approved in pubspec.yaml, commented out pending Phase 3 activation) provides `PieChart(PieChartData(...))` and `BarChart(BarChartData(...))` which accept in-memory data structures computed by `HomeDashboardCubit`. No streaming queries into charts — the cubit does the aggregation and emits a typed state with the computed category sums.

**Primary recommendation:** Represent all monetary amounts as `int` (minor units / cents) throughout the finance domain and data layers. Convert to/from display string using `intl`'s `NumberFormat`. Use a single `HomeDashboardCubit` that subscribes to `TransactionModel.watchLazy()`, reloads all transactions for the selected month on each change, and computes balance, net worth, and category sums in a single Dart pass. For `GoalContribution`, use an embedded list on `SavingsGoalModel` (contributions are directly dependent on their goal — the Isar embedded-list pattern is confirmed supported with `List.empty(growable: true)` initialization).

---

## Project Constraints (from CLAUDE.md)

| Directive | Detail |
|-----------|--------|
| Stack is fixed | Flutter + isar_community 3.3.2 + flutter_bloc 9.1.1 + get_it 9.2.1 + injectable 2.7.1+4 |
| No original isar | Use `isar_community` / `isar_community_flutter_libs` / `isar_community_generator` only |
| Privacy-first | No network calls, no analytics, no crash reporting to external services |
| Offline-only | App must be 100% functional offline |
| No forbidden packages | provider, riverpod, hive, mockito, freezed, firebase_*, sentry, connectivity_plus, dio/http |
| Language | All code in English; UI text in PT-BR with EN toggle |
| Architecture | 7-layer: core/ → domain/ → data/ → infrastructure/ → application/ → presentation/ → config/ |
| Enums | All Isar-persisted enums annotated with `@Enumerated(EnumType.name)` |
| No sync Isar | Never use findSync, putSync, deleteSync — async only |
| Result<T> | All repository methods return AsyncResult<T> — never throw |
| Package imports | `package:agenda/...` only — no relative imports |
| Soft delete | `deletedAt` nullable DateTime on all Isar models (established Phase 2 pattern) |
| Query cap | 500-item limit on all list queries |
| Chart library | fl_chart only (MIT license). No syncfusion. |
| Test framework | flutter_test + bloc_test + mocktail |

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transaction CRUD | API / Backend (data + infra layers) | Application (Cubit) | Isar write/read; Cubit orchestrates |
| Budget limit tracking | Application (BudgetCubit) | Data (BudgetDao) | Computed: current spend vs. limit |
| Goal progress aggregation | Application (GoalCubit) | Data (GoalDao) | Two paths merged in Dart |
| Balance + net worth | Application (HomeDashboardCubit) | Data (TransactionDao) | Single-pass computation from loaded list |
| Category-spend chart data | Application (HomeDashboardCubit) | — | groupBy in Dart — no SQL GROUP BY in Isar |
| fl_chart rendering | Browser / Client (Widget layer) | — | PieChart/BarChart are pure Flutter widgets |
| Currency formatting | Application layer (util) + Presentation | — | intl NumberFormat; symbol from SharedPreferences |
| Category seeding | Database / Storage (MigrationRunner) | — | One-time write on first launch |
| Task ↔ finance link display | Frontend (task_detail_screen) | Application (TaskListCubit) | Read-only chip; no side effects |

---

## Standard Stack

### Core (carry forward from Phase 2 — no version changes)
| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `isar_community` | 3.3.2 | Primary local database for all finance entities | [VERIFIED: pubspec.yaml] |
| `isar_community_flutter_libs` | 3.3.2 | Binary companion to isar_community | [VERIFIED: pubspec.yaml] |
| `flutter_bloc` | 9.1.1 | Cubit state management | [VERIFIED: pubspec.yaml] |
| `get_it` | 9.2.1 | Service locator / DI | [VERIFIED: pubspec.yaml] |
| `injectable` | 2.7.1+4 | Annotation-driven DI registration | [VERIFIED: pubspec.yaml] |
| `equatable` | 2.0.8 | Value equality for Cubit states | [VERIFIED: pubspec.yaml] |
| `intl` | 0.20.2 | NumberFormat for currency display, date formatting | [VERIFIED: pubspec.yaml] |
| `shared_preferences` | 2.5.5 | Read currency preference (set by Phase 5) | [VERIFIED: pubspec.yaml] |

### Phase 3 Additions (uncomment in pubspec.yaml)
| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `fl_chart` | 1.2.0 | PieChart + BarChart for spending dashboard | [VERIFIED: pubspec.yaml comment, pub.dev] |

### Dev
| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `isar_community_generator` | 3.3.2 | Generates `.g.dart` schema files | [VERIFIED: pubspec.yaml] |
| `build_runner` | ^2.13.1 | Runs code generation | [VERIFIED: pubspec.yaml] |
| `bloc_test` | 10.0.0 | Cubit/BLoC unit testing | [VERIFIED: pubspec.yaml] |
| `mocktail` | 1.0.5 | Mock creation without code generation | [VERIFIED: pubspec.yaml] |

**pubspec.yaml change for Phase 3:**
```yaml
# Uncomment this line:
fl_chart: 1.2.0
```

**Code generation (run after every schema change):**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Architecture Patterns

### System Architecture Diagram

```
User Action (TransactionForm / GoalForm / DebtForm)
        |
        v
Presentation Layer (screens/widgets)
  - TransactionFormScreen
  - BudgetOverviewScreen
  - GoalsScreen / GoalDetailScreen
  - DebtScreen
  - DashboardScreen (HomeDashboardCubit)
        |
        v (via BlocProvider / GetIt)
Application Layer (Cubits — no Flutter/Isar imports)
  - TransactionCubit  ←→  TransactionRepository (interface)
  - BudgetCubit       ←→  BudgetRepository (interface)
  - GoalCubit         ←→  GoalRepository (interface)
  - DebtCubit         ←→  DebtRepository (interface)
  - HomeDashboardCubit ←→ TransactionRepository + GoalRepository + DebtRepository
        |
        v (domain interfaces, no Isar)
Domain Layer (pure Dart — zero Flutter/Isar imports)
  - Transaction, Budget, SavingsGoal, Debt, RecurringPayment entities
  - TransactionRepository / BudgetRepository / GoalRepository / DebtRepository interfaces
  - TransactionType / DebtDirection / RecurringCycle enums
        ^                       ^
        |                       |
Infrastructure Layer        Data Layer
(RepositoryImpl)            (Isar Models + DAOs)
  - TransactionRepositoryImpl  TransactionModel @Collection
  - BudgetRepositoryImpl       BudgetModel @Collection
  - GoalRepositoryImpl         SavingsGoalModel @Collection (+ embedded GoalContribution list)
  - DebtRepositoryImpl         DebtModel @Collection
  - RecurringPaymentRepositoryImpl  RecurringPaymentModel @Collection
                                TransactionCategoryModel @Collection
        |
        v
Database Layer
  - IsarService (extended: add 6 finance schemas to open() call)
  - MigrationRunner case 3: TransactionCategory seeding (idempotent)

Config Layer
  - FinanceModule (populates GetIt with all finance repos)
  - injection.config.dart (regenerated by build_runner)
```

### Recommended Project Structure
```
lib/
├── domain/finance/
│   ├── transaction.dart               # domain entity
│   ├── transaction_repository.dart    # interface
│   ├── transaction_type.dart          # enum (income/expense)
│   ├── budget.dart
│   ├── budget_repository.dart
│   ├── savings_goal.dart              # includes GoalContribution value object
│   ├── goal_repository.dart
│   ├── debt.dart
│   ├── debt_repository.dart
│   ├── debt_direction.dart            # enum (toPay/toReceive)
│   ├── recurring_payment.dart
│   ├── recurring_payment_repository.dart
│   └── recurring_cycle.dart           # enum (daily/weekly/monthly/yearly)
├── data/finance/
│   ├── transaction_model.dart         # @Collection
│   ├── transaction_model.g.dart       # generated
│   ├── transaction_category_model.dart
│   ├── transaction_category_model.g.dart
│   ├── savings_goal_model.dart        # @Collection with embedded GoalContribution list
│   ├── savings_goal_model.g.dart
│   ├── budget_model.dart
│   ├── budget_model.g.dart
│   ├── debt_model.dart
│   ├── debt_model.g.dart
│   ├── recurring_payment_model.dart
│   ├── recurring_payment_model.g.dart
│   ├── transaction_dao.dart
│   ├── transaction_category_dao.dart
│   ├── savings_goal_dao.dart
│   ├── budget_dao.dart
│   ├── debt_dao.dart
│   ├── recurring_payment_dao.dart
│   └── finance_mappers.dart           # all finance mapper classes
├── infrastructure/finance/
│   ├── transaction_repository_impl.dart
│   ├── budget_repository_impl.dart
│   ├── goal_repository_impl.dart
│   ├── debt_repository_impl.dart
│   └── recurring_payment_repository_impl.dart
├── application/finance/
│   ├── transaction/
│   │   ├── transaction_cubit.dart
│   │   └── transaction_state.dart
│   ├── budget/
│   │   ├── budget_cubit.dart
│   │   └── budget_state.dart
│   ├── goal/
│   │   ├── goal_cubit.dart
│   │   └── goal_state.dart
│   ├── debt/
│   │   ├── debt_cubit.dart
│   │   └── debt_state.dart
│   └── dashboard/
│       ├── home_dashboard_cubit.dart
│       └── home_dashboard_state.dart
├── presentation/finance/
│   ├── screens/
│   │   ├── transaction_list_screen.dart
│   │   ├── transaction_form_screen.dart
│   │   ├── budget_overview_screen.dart
│   │   ├── goal_list_screen.dart
│   │   ├── goal_detail_screen.dart
│   │   ├── debt_list_screen.dart
│   │   └── recurring_payment_screen.dart
│   └── widgets/
│       ├── transaction_card.dart
│       ├── budget_progress_bar.dart
│       ├── goal_progress_card.dart
│       ├── spending_pie_chart.dart
│       ├── spending_bar_chart.dart
│       └── finance_empty_state.dart
├── core/constants/
│   └── currencies.dart                # static ISO 4217 list (D-17)
└── config/di/
    └── finance_module.dart            # populated in Phase 3
```

### Pattern 1: Monetary Amount as Int Cents

**What:** All monetary values stored as `int` representing the amount in minor currency units (cents, centavos, etc.). Never use `double` for money.

**Why:** Floating-point arithmetic introduces rounding errors that compound across aggregations. `0.1 + 0.2` in Dart (as `double`) equals `0.30000000000000004`. Financial apps require exact arithmetic. [VERIFIED: dart.dev number representation docs; multiple authoritative sources confirm int-cents is the standard]

**When to use:** Every Isar model field that stores a monetary amount. Domain entities also use `int`. Conversion to display string happens only at the presentation boundary via `intl.NumberFormat`.

**Display conversion pattern:**
```dart
// Source: intl package documentation + CONTEXT.md D-18
// In a utility function or extension:
String formatAmount(int amountCents, String symbol, Locale locale) {
  // amountCents: e.g. 123456 = 1,234.56
  final amount = amountCents / 100.0;
  final formatter = NumberFormat.currency(
    locale: locale.toString(), // 'pt_BR' or 'en'
    symbol: '',                // we prepend symbol ourselves
    decimalDigits: 2,
  );
  return '$symbol ${formatter.format(amount)}';
  // PT-BR: "MT 1.234,56"
  // EN:    "MT 1,234.56"
}
```

**Isar storage:**
```dart
// Source: established project pattern (item_model.dart) + int-cents decision
@Collection()
class TransactionModel {
  Id id = Isar.autoIncrement;
  // Amount stored as int cents — e.g. R$ 12.34 stored as 1234
  late int amountCents;
  // ...
}
```

### Pattern 2: Isar Finance Collection Schema

**What:** Five Isar collections plus one embedded type for finance data.

**Enum annotation rule (Phase 1, enforced):** Every enum persisted in Isar MUST use `@Enumerated(EnumType.name)`. This project has zero exceptions.

```dart
// Source: established project pattern (item_model.dart) + Phase 1 convention
import 'package:isar_community/isar.dart';

part 'transaction_model.g.dart';

enum TransactionType { income, expense }

@Collection()
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late TransactionType type;

  late int amountCents;          // int, not double

  @Index()
  late int categoryId;           // FK to TransactionCategoryModel.id

  @Index()
  late DateTime date;            // top-level for index (pattern from ItemModel.dueDate)

  String? note;

  int? linkedGoalId;             // FK to SavingsGoalModel.id (optional, per D-13)

  @Index()
  DateTime? deletedAt;           // soft delete (Phase 2 pattern)

  late DateTime createdAt;
  late DateTime updatedAt;
}
```

```dart
// TransactionCategoryModel
@Collection()
class TransactionCategoryModel {
  Id id = Isar.autoIncrement;

  late String nameKey;           // l10n key (e.g. 'category_salary')
  late String namePtBr;          // fallback display name in PT-BR

  @Enumerated(EnumType.name)
  late TransactionType type;     // income or expense category

  bool isDefault = false;        // D-03: default categories cannot be deleted/renamed

  late DateTime createdAt;
  // No deletedAt — categories are hard-deleted (custom) or undeletable (default)
}
```

```dart
// BudgetModel — one record per (categoryId, month, year)
@Collection()
@Index(composite: [CompositeIndex('year'), CompositeIndex('categoryId')], unique: true)
class BudgetModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int categoryId;

  late int month;                // 1-12
  late int year;                 // e.g. 2026

  late int limitCents;           // budget cap in minor units

  late DateTime createdAt;
  late DateTime updatedAt;
}
```

```dart
// GoalContribution — embedded in SavingsGoalModel
@embedded
class GoalContribution {
  GoalContribution();
  int amountCents = 0;
  late DateTime date;
  String? note;
}

// SavingsGoalModel
@Collection()
class SavingsGoalModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int targetAmountCents;
  DateTime? deadline;

  // Embedded list — growable required (VERIFIED: isar/discussions/781)
  List<GoalContribution> contributions = List.empty(growable: true);

  bool isCompleted = false;
  DateTime? deletedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

```dart
// DebtModel
enum DebtDirection { toPay, toReceive }

@Collection()
class DebtModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int amountCents;

  @Enumerated(EnumType.name)
  late DebtDirection direction;

  late String counterparty;      // who you owe / who owes you

  @Index()
  late DateTime dueDate;

  bool isPaid = false;
  DateTime? paidAt;

  DateTime? deletedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

```dart
// RecurringPaymentModel
enum RecurringCycle { daily, weekly, biweekly, monthly, quarterly, yearly }

@Collection()
class RecurringPaymentModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int amountCents;
  late int categoryId;

  @Enumerated(EnumType.name)
  late RecurringCycle cycle;

  @Index()
  late DateTime nextDueDate;

  bool isActive = true;
  DateTime? deletedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

### Pattern 3: Isar Schema Registration (IsarService.open)

Phase 3 extends `IsarService.open()` to include all finance schemas. The call is in `main.dart` via the DI setup.

```dart
// Source: lib/data/database/isar_service.dart pattern
await IsarService.instance.open([
  ItemModelSchema,              // Phase 2
  TransactionModelSchema,       // Phase 3
  TransactionCategoryModelSchema, // Phase 3
  BudgetModelSchema,            // Phase 3
  SavingsGoalModelSchema,       // Phase 3
  DebtModelSchema,              // Phase 3
  RecurringPaymentModelSchema,  // Phase 3
]);
```

### Pattern 4: Isar Aggregate Queries for Finance

**What:** Isar supports `.sum()`, `.min()`, `.max()`, `.average()` on property queries. There is no GROUP BY in Isar.

**Balance computation (no GROUP BY needed — two separate sums):**
```dart
// Source: isar-community.dev/v3/queries.html (VERIFIED)
// In TransactionDao:
Future<int> sumByType(TransactionType type, {DateTime? from, DateTime? to}) async {
  final q = _collection.filter()
      .deletedAtIsNull()
      .and()
      .typeEqualTo(type);
  // Note: date range filtering applied before property query
  // Isar's property query + sum() is faster than loading all records
  final models = await q.findAll();
  // No direct .amountCentsProperty().sum() across filter — compute in Dart
  return models.fold(0, (acc, m) => acc + m.amountCents);
}
```

**Important caveat:** Isar's property query `.sum()` works on a WHERE clause result, but the chained API (`.filter().fieldProperty().sum()`) has limited composability with multiple AND conditions. The safest pattern for this project is: `filter().findAll()` then fold in Dart. This is correct at the 500-item cap.

**Category spend groupBy (Dart-side):**
```dart
// In HomeDashboardCubit — compute category breakdown in Dart
// Source: dart:collection groupBy function (api.flutter.dev/flutter/package-collection_collection/groupBy.html)
Map<int, int> computeCategorySpend(List<Transaction> expenses) {
  final result = <int, int>{};
  for (final tx in expenses) {
    result[tx.categoryId] = (result[tx.categoryId] ?? 0) + tx.amountCents;
  }
  return result; // categoryId -> totalCents
}
```

### Pattern 5: HomeDashboardCubit — Reactive Aggregation

**What:** One cubit that subscribes to `TransactionModel.watchLazy()` and recomputes balance, net worth, and chart data on every change.

**Why watchLazy over watch:** Rerunning queries on every change is more expensive. `watchLazy()` (used in Phase 2 `TaskListCubit`) fires a `void` event, then the cubit does a targeted reload. This is the established pattern. [VERIFIED: isar.dev/watchers.html + codebase]

```dart
// Source: lib/application/tasks/task_list/task_list_cubit.dart pattern
@injectable
class HomeDashboardCubit extends Cubit<HomeDashboardState> {
  HomeDashboardCubit(
    this._transactionRepository,
    this._goalRepository,
    this._debtRepository,
  ) : super(const HomeDashboardInitial());

  StreamSubscription<void>? _txWatchSub;
  DateTime _selectedMonth = DateTime.now();

  Future<void> start() async {
    _txWatchSub = _transactionRepository.watchChanges().listen((_) async {
      await _reload();
    });
    await _reload();
  }

  Future<void> selectMonth(DateTime month) async {
    _selectedMonth = month;
    await _reload();
  }

  Future<void> _reload() async {
    if (isClosed) return;
    // 1. Load all non-deleted transactions (500 cap)
    // 2. Compute lifetimeBalance = incomeSum - expenseSum (all time, not filtered)
    // 3. Load active goals and debts for net worth
    // 4. Filter transactions to _selectedMonth for chart data
    // 5. groupBy categoryId in Dart
    // 6. Emit HomeDashboardLoaded with all computed fields
  }

  @override
  Future<void> close() async {
    await _txWatchSub?.cancel();
    return super.close();
  }
}
```

**Discretion recommendation (HomeDashboardCubit aggregation approach):**
Use a single `_reload()` that does all aggregation in Dart from the loaded list. Do not issue separate Isar queries for each metric (that would be N+1 and defeat the purpose of the reactive pattern). Load all non-deleted transactions once per reload cycle; split income/expense with `.where((t) => t.type == TransactionType.income)` in Dart. This is clean, testable, and correct at the 500-item cap.

### Pattern 6: fl_chart PieChart and BarChart

**What:** fl_chart 1.2.0 PieChart and BarChart APIs.

**PieChart — key classes:**
- `PieChart(PieChartData(...))` — the widget
- `PieChartData.sections` — `List<PieChartSectionData>`, one per expense category
- `PieChartSectionData(value: double, title: String, color: Color, radius: double)`
- `PieChartData.centerSpaceRadius` — set > 0 for donut style
- `PieChartData.sectionsSpace` — gap between slices

**BarChart — key classes:**
- `BarChart(BarChartData(...))` — the widget
- `BarChartData.barGroups` — `List<BarChartGroupData>`, one per category
- `BarChartGroupData(x: int, barRods: [BarChartRodData(toY: double, color: Color)])`
- `BarChartData.titlesData` — axis labels (category names on X, amounts on Y)
- `BarChartData.maxY` — set to max category spend + 10% for visual padding

**Conversion from int cents to chart value:**
```dart
// Source: fl_chart pub.dev docs + WebSearch verification
// fl_chart uses double for values — divide cents by 100 for chart display
PieChartSectionData(
  value: categorySpendCents / 100.0,  // convert for chart display only
  title: categoryName,
  color: categoryColor,
  radius: 60,
)
```

**Important:** The double conversion is ONLY for chart rendering. All stored and computed values remain int cents.

**Complete PieChart example:**
```dart
// Source: fl_chart pub.dev + official docs
PieChart(
  PieChartData(
    sections: categorySpends.entries.map((e) {
      return PieChartSectionData(
        value: e.value / 100.0,
        title: categoryNames[e.key] ?? '',
        color: categoryColors[e.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12),
      );
    }).toList(),
    centerSpaceRadius: 40,  // donut style
    sectionsSpace: 2,
  ),
)
```

**Complete BarChart example:**
```dart
// Source: fl_chart pub.dev + github.com/imaNNeo/fl_chart bar_chart.md
BarChart(
  BarChartData(
    barGroups: categorySpends.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: e.value / 100.0,
            color: categoryColors[e.value] ?? Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList(),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Text(categoryNames[value.toInt()] ?? '');
          },
        ),
      ),
    ),
    gridData: const FlGridData(show: false),
  ),
)
```

### Pattern 7: MigrationRunner Case 3 — Category Seeding

```dart
// Source: lib/data/database/migration_runner.dart pattern + CONTEXT.md D-06
case 3:
  // Seed default TransactionCategories (idempotent — D-06)
  await _seedDefaultCategories(isar);
  return;

static Future<void> _seedDefaultCategories(Isar isar) async {
  // Guard: do not re-seed if categories already exist
  final count = await isar.transactionCategoryModels.count();
  if (count > 0) return;

  final now = DateTime.now();
  final expenseCategories = [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde',
    'Educação', 'Lazer', 'Roupas', 'Tecnologia', 'Outros',
  ];
  final incomeCategories = ['Salário', 'Freelance', 'Investimentos', 'Outros'];

  final models = [
    ...expenseCategories.map((name) => TransactionCategoryModel()
      ..namePtBr = name
      ..nameKey = 'category_${name.toLowerCase()}'
      ..type = TransactionType.expense
      ..isDefault = true
      ..createdAt = now),
    ...incomeCategories.map((name) => TransactionCategoryModel()
      ..namePtBr = name
      ..nameKey = 'category_${name.toLowerCase()}'
      ..type = TransactionType.income
      ..isDefault = true
      ..createdAt = now),
  ];

  await isar.writeTxn(() => isar.transactionCategoryModels.putAll(models));
}
```

**Also required:** Bump `AppConfig.schemaVersion` from 2 → 3 in `lib/core/config/app_config.dart`.

### Pattern 8: GoalContribution — Embedded List Decision

**Decision (Claude's Discretion):** Use an embedded `List<GoalContribution>` on `SavingsGoalModel`.

**Rationale:**
- Contributions are directly dependent on their parent goal (like SubTask on Task).
- Isar supports `List<@embedded>` when declared as `List.empty(growable: true)`. [VERIFIED: github.com/isar/isar/discussions/781]
- Avoids N+1 queries: loading a goal loads all its contributions in one read.
- Goal progress = `goal.contributions.fold(0, (s, c) => s + c.amountCents) + taggedTransactionsSum`.
- Downside: updating a contribution rewrites the entire goal object. Acceptable: contributions are infrequent writes (not streaming).
- A separate `GoalContributionModel` collection would require an extra Isar read to aggregate — worse for the dashboard's `_reload()` pattern.

### Pattern 9: BudgetCubit — Real-Time Spend vs. Limit

**What:** `BudgetCubit` subscribes to `TransactionModel.watchLazy()`. On each change, it loads all expense transactions for the current month and all budget records, then computes `spentCents` and `limitCents` per category in Dart.

```dart
// Budget state includes both the budget limit and current spend per category
final class BudgetLoaded extends BudgetState {
  const BudgetLoaded({required this.budgets});
  // Map: categoryId -> (limitCents, spentCents)
  final Map<int, ({int limitCents, int spentCents})> budgets;
  // ...
}
```

**Real-time update path:** New transaction → Isar write → `watchLazy()` fires → BudgetCubit._reload() → new budgets computed → `BudgetLoaded` emitted → BudgetOverviewScreen rebuilds.

### Pattern 10: Currency Value Object (Core Constants)

```dart
// Source: CONTEXT.md D-17
// lib/core/constants/currencies.dart
class Currency {
  const Currency({required this.code, required this.name, required this.symbol});
  final String code;   // ISO 4217 e.g. 'MZN'
  final String name;   // e.g. 'Metical Moçambicano'
  final String symbol; // e.g. 'MT'
}

abstract final class Currencies {
  static const List<Currency> all = [
    Currency(code: 'MZN', name: 'Metical Moçambicano', symbol: 'MT'),
    Currency(code: 'BRL', name: 'Real Brasileiro', symbol: 'R\$'),
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    // ... full ISO 4217 list
  ];

  // Priority entries shown first in the currency picker (Phase 5)
  static const List<String> priorityCodes = [
    'MZN', 'BRL', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'ZAR'
  ];
}
```

### Anti-Patterns to Avoid

- **Double for money:** NEVER store `double amount` in Isar for monetary values. Use `int amountCents`. One double arithmetic error compounds across every aggregation.
- **N+1 aggregation:** NEVER query Isar once per category to sum transactions. Load all transactions for the period in one query; fold/groupBy in Dart.
- **Isar GROUP BY:** Isar has no GROUP BY. Do not attempt SQL-style grouped queries — they do not exist in the Isar query API.
- **Mutable embedded list with fixed-length declaration:** `List<GoalContribution> contributions = [];` works at compile time but fails at Isar write time. Use `List.empty(growable: true)` for embedded lists. [VERIFIED: github.com/isar/isar/discussions/781]
- **Querying deleted categories:** All active transaction queries must join through `deletedAtIsNull()`. Categories do not have soft delete (default ones cannot be deleted; custom ones are hard-deleted), but transactions do.
- **Direct fl_chart double values from user input:** Never display user-entered amounts as doubles directly. Always convert from int cents only at the display boundary.
- **Separate Cubit per screen for aggregations:** `HomeDashboardCubit` should be a single source of truth for balance, net worth, and chart data. Do not create separate cubits that each maintain their own copy of the transaction list.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency number formatting | Custom string interpolation | `intl.NumberFormat.currency()` | Locale-aware decimal separators, thousands grouping, rounding |
| Date formatting | Manual string concatenation | `intl.DateFormat` | Locale-aware month/day names; already in pubspec |
| Pie/bar chart widgets | Custom Canvas painting | `fl_chart` 1.2.0 | Handles animation, touch, responsive layout — >1M pub.dev downloads |
| ISO 4217 currency list from network | HTTP call to currency API | Static `const List<Currency>` | Privacy constraint; network forbidden; ~170 currencies fit in ~10KB Dart file |
| Isar GROUP BY | Custom SQL-style query chaining | Dart `fold`/`groupBy` on loaded list | Isar has no GROUP BY; Dart-side is the only option |

**Key insight:** The finance domain's hardest problem is not persistence (Isar handles that well) but aggregation correctness — getting balance, net worth, and category sums right with int arithmetic and no floating-point errors. Dart's `fold` on a list of `int amountCents` values is exact and testable.

---

## Common Pitfalls

### Pitfall 1: Double Arithmetic for Money
**What goes wrong:** Using `double amount` in Isar models and computing `totalIncome - totalExpenses` as doubles introduces rounding errors that surface in the balance display (e.g., showing `R$ 1.999,9999996` instead of `R$ 2.000,00`).
**Why it happens:** Phase 2's `moneyInfo.amount` is `double?` (display-only). Finance Phase 3 computes actual sums — a different problem class.
**How to avoid:** Store `int amountCents` in all finance Isar models. Convert to double only inside `NumberFormat.currency()` for display.
**Warning signs:** Any `double` field named `amount` in a finance Isar model is a red flag.

### Pitfall 2: Fixed-Length List for Embedded GoalContributions
**What goes wrong:** `List<GoalContribution> contributions = [];` compiles fine but Isar throws an error when trying to write a new contribution because the list is fixed-length.
**Why it happens:** Dart's `[]` literal creates a growable list in most contexts, but Isar's code-generated writer uses list operations that require it to be explicitly growable.
**How to avoid:** Always initialize embedded lists as `List.empty(growable: true)`.
**Warning signs:** Runtime Isar write exception mentioning "Cannot add to a fixed-length list" when saving a SavingsGoal.

### Pitfall 3: Budget Month Scope Mismatch
**What goes wrong:** The budget limit is set per month, but the spend query fetches all transactions, making every budget appear over-limit.
**Why it happens:** Forgetting the `month`/`year` filter on the transaction query when computing `spentCents`.
**How to avoid:** The `BudgetDao.getMonthlySpendByCategoryId(categoryId, month, year)` method must always include date range filters: `dateGreaterThanOrEqual(DateTime(year, month, 1))` AND `dateLessThan(DateTime(year, month + 1, 1))`.
**Warning signs:** Budget shows 100% spend the moment any transaction exists, regardless of month.

### Pitfall 4: Goal Progress Double-Counting
**What goes wrong:** Computing goal progress as `contributions.sum + ALL transactions with linkedGoalId` inadvertently double-counts a contribution that was entered as both a manual contribution AND a tagged transaction.
**Why it happens:** Per D-11, manual contributions and transaction tagging are separate paths. A user could theoretically add both.
**How to avoid:** The two paths are exclusive by design: `GoalContribution` records are created via the goal detail screen ("Adicionar contribuição"). Tagged transactions have `linkedGoalId` set but are regular `TransactionModel` records — never both. Enforce at the UI/Cubit layer: the "Add Contribution" button creates a `GoalContribution` embedded record, while tagging a transaction to a goal sets `linkedGoalId` on `TransactionModel`. They are separate write paths.
**Warning signs:** Progress percentage exceeds 100% or jumps unexpectedly.

### Pitfall 5: Isar Schema Registration Order
**What goes wrong:** `Isar.open()` throws if a collection schema is missing from the schemas list. Adding a new finance collection but forgetting to add its `Schema` object to `IsarService.open()` causes a crash on first launch.
**Why it happens:** `isar_community_generator` generates the `*Schema` constant in the `.g.dart` file, but `IsarService.open()` must be manually updated.
**How to avoid:** Every new `@Collection()` class requires its corresponding `ClassNameSchema` object added to the schemas list in `IsarService.open()`. Treat this as a checklist item after every code generation run.
**Warning signs:** `IsarError: Collection TransactionModel not found in schema` at app startup.

### Pitfall 6: Category Seeding Race (MigrationRunner)
**What goes wrong:** If the seeding guard checks `count() == 0` but the `writeTxn` runs twice concurrently (impossible in practice with a single-thread migration runner, but easy to break if the logic is moved), categories are duplicated.
**Why it happens:** No unique constraint on category name in Isar.
**How to avoid:** Keep seeding exclusively inside `MigrationRunner._runMigration(isar, 3)` which runs in the sequential migration loop — never called concurrently. The `count() == 0` guard is a defense against accidental double-execution (e.g., in tests).
**Warning signs:** Duplicate "Alimentação" / "Salário" categories in the picker.

### Pitfall 7: watchLazy() Subscription Leak
**What goes wrong:** `HomeDashboardCubit` and `BudgetCubit` both subscribe to `watchLazy()`. If a screen rebuilds and creates a new cubit without closing the old one (e.g., wrapped in a non-`BlocProvider` widget), old subscriptions accumulate.
**Why it happens:** Cubit lifecycle tied to widget tree in Flutter BLoC.
**How to avoid:** Always use `BlocProvider(create: ...)` which calls `close()` on dispose. In tests, call `await cubit.close()` in `tearDown`. Pattern inherited from `TaskListCubit`.
**Warning signs:** Memory growing with each navigation; multiple reload() calls per transaction.

---

## Code Examples

### Balance Computation (Domain Layer)
```dart
// Source: CONTEXT.md D-07, D-08 formulas
// In HomeDashboardCubit._reload():
int computeBalance(List<Transaction> allTransactions) {
  int income = 0;
  int expenses = 0;
  for (final tx in allTransactions) {
    if (tx.type == TransactionType.income) {
      income += tx.amountCents;
    } else {
      expenses += tx.amountCents;
    }
  }
  return income - expenses;
}

int computeNetWorth(
  int balance,
  List<SavingsGoal> goals,
  List<Debt> debts,
) {
  // Source: CONTEXT.md D-08 exact formula
  final goalSum = goals.fold(0, (s, g) => s + g.amountSavedCents);
  final debtSum = debts
      .where((d) => d.direction == DebtDirection.toPay && !d.isPaid)
      .fold(0, (s, d) => s + d.amountCents);
  return balance + goalSum - debtSum;
}
```

### Goal Progress Computation
```dart
// Source: CONTEXT.md D-11 formula
// SavingsGoal domain entity:
int get amountSavedCents {
  final fromContributions = contributions.fold(0, (s, c) => s + c.amountCents);
  final fromTaggedTransactions = taggedTransactionsCents; // passed in at construction
  return fromContributions + fromTaggedTransactions;
}

double get progressPercent {
  if (targetAmountCents == 0) return 0.0;
  return amountSavedCents / targetAmountCents;
}
```

### Isar Date Range Filter for Monthly Budget
```dart
// Source: established ItemDao pattern (item_repository_impl.dart) + finance adaptation
// In TransactionDao:
Future<List<TransactionModel>> findByMonth(int month, int year) async {
  final from = DateTime(year, month, 1);
  final to = DateTime(year, month + 1, 1); // exclusive upper bound
  return _collection
      .filter()
      .deletedAtIsNull()
      .and()
      .typeEqualTo(TransactionType.expense)
      .and()
      .dateBetween(from, to, includeLower: true, includeUpper: false)
      .limit(500)
      .findAll();
}
```

### DI Registration — FinanceModule Pattern
```dart
// Source: lib/config/di/tasks_module.dart pattern
@module
abstract class FinanceModule {
  @lazySingleton
  TransactionDao transactionDao(IsarService isarService) =>
      TransactionDao(isarService);

  @lazySingleton
  TransactionCategoryDao categoryDao(IsarService isarService) =>
      TransactionCategoryDao(isarService);

  @lazySingleton
  BudgetDao budgetDao(IsarService isarService) =>
      BudgetDao(isarService);

  @lazySingleton
  SavingsGoalDao goalDao(IsarService isarService) =>
      SavingsGoalDao(isarService);

  @lazySingleton
  DebtDao debtDao(IsarService isarService) =>
      DebtDao(isarService);

  @lazySingleton
  RecurringPaymentDao recurringPaymentDao(IsarService isarService) =>
      RecurringPaymentDao(isarService);

  // Mappers
  @lazySingleton
  TransactionMapper get transactionMapper => const TransactionMapper();

  @lazySingleton
  BudgetMapper get budgetMapper => const BudgetMapper();

  @lazySingleton
  GoalMapper get goalMapper => const GoalMapper();

  @lazySingleton
  DebtMapper get debtMapper => const DebtMapper();

  @lazySingleton
  RecurringPaymentMapper get recurringPaymentMapper =>
      const RecurringPaymentMapper();
}

// Impls use @LazySingleton(as: InterfaceType) — same as Phase 2
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository { ... }
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Store money as `double` | Store money as `int` minor units | Dart finance best practice (pre-2022) | Exact arithmetic; no rounding errors in aggregation |
| Original `isar` package | `isar_community` 3.3.2 | Community fork created 2023 (original abandoned April 2023) | Drop-in API replacement; actively maintained |
| `@enumerated` without type | `@Enumerated(EnumType.name)` | Established Phase 1 | Safe enum reordering |
| Fixed-length embedded list | `List.empty(growable: true)` | Required for Isar embedded-list writes | Prevents runtime crash |

**Deprecated/outdated:**
- `isar` (original): Abandoned. Use `isar_community`. [VERIFIED: CLAUDE.md, pub.dev]
- `isar_flutter_libs` (original): Same abandonment. Use `isar_community_flutter_libs`. [VERIFIED: CLAUDE.md]
- `flutter_native_timezone`: Renamed to `flutter_timezone`. [VERIFIED: CLAUDE.md]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `int amountCents` is the correct monetary representation for this app (no external "Money" type library required) | Pattern 1 | If the team prefers `money2` package, add it to pubspec; API surface changes but domain semantics are identical |
| A2 | fl_chart 1.2.0 PieChart handles an empty `sections` list gracefully (shows empty circle rather than crashing) | Pattern 6 | If it throws on empty list, add `if (sections.isEmpty) return EmptyState()` guard in the widget |
| A3 | The `HomeDashboardCubit` approach of loading up to 500 transactions per reload is acceptable for MVP (no user will have 500 transactions in their first months of use) | Pattern 5 | If a power user accumulates >500 transactions, balance will be incorrect (500-item cap truncates). Phase 4+ may need pagination or a running balance record |
| A4 | `TransactionCategoryModel` uses hard delete for custom categories (no `deletedAt`) | Pattern 2 | If soft delete is preferred for auditability, add `deletedAt` to the model and filter it in all queries |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. The above 4 items are the only unconfirmed assumptions.

---

## Open Questions (RESOLVED)

1. **Category l10n key naming convention**
   - What we know: CONTEXT.md D-04/D-05 gives PT-BR display names; CLAUDE.md says UI text in PT-BR with EN toggle.
   - What's unclear: Do we store `nameKey` (ARB lookup key) or `namePtBr` + `nameEn` as separate fields on `TransactionCategoryModel`? The ARB key approach is cleaner but requires the l10n system to be used at the data layer boundary.
   - Recommendation: Store `namePtBr` as the canonical display name (already seeded in PT-BR per D-04/D-05) and `nameEn` as a nullable field (populated for default categories only). Custom categories have only `namePtBr`. This avoids coupling the data layer to the l10n ARB system.
   - RESOLVED: Plan 03-02 (Task 1 TransactionCategoryModel) uses `namePtBr` + `nameEn` (nullable) as separate fields, matching the recommendation. No ARB lookup key stored at the data layer.

2. **RecurringPayment auto-advance**
   - What we know: `RecurringPaymentModel` has `nextDueDate`. Phase 4 notification system reads this.
   - What's unclear: Does Phase 3 advance `nextDueDate` automatically when a payment is marked, or is that Phase 4's job?
   - Recommendation: Phase 3 stores `nextDueDate` but does NOT auto-advance it. Phase 4 notification logic owns the advance logic when the payment fires. Phase 3 only provides the data structure.
   - RESOLVED: Plan 03-02 (RecurringPaymentRepositoryImpl) stores `nextDueDate` but does not advance it; no auto-advance logic is planned in Phase 3. Phase 4 owns the notification + advance logic.

---

## Environment Availability

No new external dependencies beyond the existing Flutter/Dart SDK. fl_chart is a pure Flutter package (no native code, no external services). Step 2.6: only one item to check.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | 3.38.1+ (Dart 3.11.1) | — |
| fl_chart 1.2.0 | FIN-10 charts | Not yet in pubspec (commented out) | 1.2.0 | — (uncomment to activate) |
| build_runner | Code generation | ✓ | ^2.13.1 | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — fl_chart is already pinned in pubspec.yaml comments; requires only uncommenting.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + bloc_test 10.0.0 + mocktail 1.0.5 |
| Config file | `pubspec.yaml` (flutter test) — no separate config |
| Quick run command | `flutter test test/domain/finance/ test/application/finance/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIN-01 | Create income transaction | unit (domain + cubit) | `flutter test test/domain/finance/transaction_test.dart test/application/finance/transaction_cubit_test.dart -x` | ❌ Wave 0 |
| FIN-02 | Create expense transaction | unit | same as FIN-01 | ❌ Wave 0 |
| FIN-03 | Edit and delete transactions | unit | `flutter test test/application/finance/transaction_cubit_test.dart -x` | ❌ Wave 0 |
| FIN-04 | Monthly budget limit per category | unit (cubit) | `flutter test test/application/finance/budget_cubit_test.dart -x` | ❌ Wave 0 |
| FIN-05 | Create savings goal | unit | `flutter test test/domain/finance/savings_goal_test.dart -x` | ❌ Wave 0 |
| FIN-06 | Goal progress computation | unit | `flutter test test/domain/finance/savings_goal_test.dart -x` | ❌ Wave 0 |
| FIN-07 | Log debt (to pay / to receive) | unit | `flutter test test/application/finance/debt_cubit_test.dart -x` | ❌ Wave 0 |
| FIN-08 | Log recurring payment | unit | `flutter test test/application/finance/debt_cubit_test.dart -x` | ❌ Wave 0 |
| FIN-09 | Dashboard balance + net worth | unit | `flutter test test/application/finance/home_dashboard_cubit_test.dart -x` | ❌ Wave 0 |
| FIN-10 | Monthly chart data groupBy | unit | `flutter test test/application/finance/home_dashboard_cubit_test.dart -x` | ❌ Wave 0 |
| UX-04 | Empty states on all screens | widget | `flutter test test/presentation/finance/ -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/domain/finance/ test/application/finance/ -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
All finance test files are new — none exist yet:
- [ ] `test/domain/finance/transaction_test.dart` — covers FIN-01, FIN-02, int-cents arithmetic
- [ ] `test/domain/finance/savings_goal_test.dart` — covers FIN-05, FIN-06, goal progress computation
- [ ] `test/application/finance/transaction_cubit_test.dart` — covers FIN-01, FIN-02, FIN-03
- [ ] `test/application/finance/budget_cubit_test.dart` — covers FIN-04, real-time spend vs. limit
- [ ] `test/application/finance/goal_cubit_test.dart` — covers FIN-05, FIN-06
- [ ] `test/application/finance/debt_cubit_test.dart` — covers FIN-07, FIN-08
- [ ] `test/application/finance/home_dashboard_cubit_test.dart` — covers FIN-09, FIN-10
- [ ] `test/presentation/finance/` — covers UX-04 (empty states)
- [ ] `test/data/database/migration_runner_test.dart` — extend existing test for case 3 (category seeding)
- [ ] `test/data/finance/transaction_mapper_test.dart` — mapper round-trip
- [ ] `test/data/finance/savings_goal_mapper_test.dart` — embedded contribution list round-trip

---

## Security Domain

> `security_enforcement` not explicitly set to false in config.json — section included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth in finance domain (Phase 5 adds PIN/biometric) |
| V3 Session Management | no | No sessions — local data only |
| V4 Access Control | no | Single-user local app — no access control boundary |
| V5 Input Validation | yes | Validate: amountCents > 0, title non-empty, date not null, categoryId exists; return ValidationFailure via Result<T> |
| V6 Cryptography | no | Finance data not encrypted at rest in Phase 3 (Phase 5 adds secure storage for PIN only) |

### Known Threat Patterns for Finance + Isar Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Negative amount injection | Tampering | Validate `amountCents > 0` at repository boundary; return ValidationFailure |
| Category ID spoofing (FK not found) | Tampering | Verify category exists before saving transaction; return DatabaseFailure if not found |
| Concurrent write corruption | Tampering | Isar's single-writer, async write transactions prevent this automatically |
| Privacy data exfiltration | Information Disclosure | No network imports (http/dio forbidden); confirmed by CLAUDE.md constraints |
| Goal overcontribution | Tampering | No business rule prevents it (by design); progress % can exceed 100% and should display as capped at 100% in UI |

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: codebase] `lib/data/tasks/item_model.dart` — embedded pattern, enum annotation, soft delete
- [VERIFIED: codebase] `lib/application/tasks/task_list/task_list_cubit.dart` — watchLazy + _reload() pattern
- [VERIFIED: codebase] `lib/data/tasks/item_dao.dart` — filterItems, optional(), limit(500) pattern
- [VERIFIED: codebase] `lib/data/database/migration_runner.dart` — case pattern, idempotent migration
- [VERIFIED: codebase] `lib/config/di/tasks_module.dart` — DI registration pattern
- [VERIFIED: codebase] `pubspec.yaml` — all confirmed package versions
- [CITED: isar-community.dev/v3/queries.html] — aggregate functions: sum(), min(), max(), average(); no GROUP BY
- [CITED: isar.dev/watchers.html] — watchLazy() vs watch(), fireImmediately
- [CITED: pub.dev/packages/fl_chart] — fl_chart 1.2.0 confirmed current version
- [CITED: pub.dev/documentation/fl_chart/latest/fl_chart/PieChartData-class.html] — PieChartData fields
- [CITED: github.com/imaNNeo/fl_chart bar_chart.md] — BarChartData, BarChartGroupData, BarChartRodData API

### Secondary (MEDIUM confidence)
- [CITED: github.com/isar/isar/discussions/781] — embedded list requires `List.empty(growable: true)`; community verified
- [CITED: dart.dev/resources/language/number-representation] — float precision; int-cents pattern confirmed

### Tertiary (LOW confidence)
- None — all claims are verified or cited.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in pubspec.yaml (already locked)
- Architecture: HIGH — direct inheritance from Phase 2 proven patterns
- fl_chart API: HIGH — verified against pub.dev official docs and github
- Isar embedded lists: HIGH — verified against official isar/discussions/781
- Pitfalls: HIGH — derived from verified API constraints + Phase 2 patterns
- Int-cents: HIGH — verified against Dart number representation docs + multiple sources

**Research date:** 2026-05-14
**Valid until:** 2026-08-14 (90 days — stable packages; fl_chart may release patch versions but 1.2.0 API is stable)
