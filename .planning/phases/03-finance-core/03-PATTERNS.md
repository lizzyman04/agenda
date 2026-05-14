# Phase 3: Finance Core — Pattern Map

**Mapped:** 2026-05-14
**Files analyzed:** 47 new/modified files
**Analogs found:** 45 / 47

---

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `lib/domain/finance/transaction.dart` | model (domain entity) | transform | `lib/domain/tasks/item.dart` | exact |
| `lib/domain/finance/transaction_repository.dart` | repository (interface) | CRUD | `lib/domain/tasks/item_repository.dart` | exact |
| `lib/domain/finance/transaction_type.dart` | model (enum) | — | `lib/domain/tasks/item_type.dart` | exact |
| `lib/domain/finance/budget.dart` | model (domain entity) | transform | `lib/domain/tasks/item.dart` | role-match |
| `lib/domain/finance/budget_repository.dart` | repository (interface) | CRUD | `lib/domain/tasks/item_repository.dart` | exact |
| `lib/domain/finance/savings_goal.dart` | model (domain entity) | transform | `lib/domain/tasks/item.dart` | role-match |
| `lib/domain/finance/goal_repository.dart` | repository (interface) | CRUD | `lib/domain/tasks/item_repository.dart` | exact |
| `lib/domain/finance/debt.dart` | model (domain entity) | transform | `lib/domain/tasks/item.dart` | role-match |
| `lib/domain/finance/debt_repository.dart` | repository (interface) | CRUD | `lib/domain/tasks/item_repository.dart` | exact |
| `lib/domain/finance/debt_direction.dart` | model (enum) | — | `lib/domain/tasks/item_type.dart` | exact |
| `lib/domain/finance/recurring_payment.dart` | model (domain entity) | transform | `lib/domain/tasks/item.dart` | role-match |
| `lib/domain/finance/recurring_payment_repository.dart` | repository (interface) | CRUD | `lib/domain/tasks/item_repository.dart` | exact |
| `lib/domain/finance/recurring_cycle.dart` | model (enum) | — | `lib/domain/tasks/item_type.dart` | exact |
| `lib/data/finance/transaction_model.dart` | model (Isar collection) | CRUD | `lib/data/tasks/item_model.dart` | exact |
| `lib/data/finance/transaction_category_model.dart` | model (Isar collection) | CRUD | `lib/data/tasks/item_model.dart` | exact |
| `lib/data/finance/savings_goal_model.dart` | model (Isar collection, embedded list) | CRUD | `lib/data/tasks/item_model.dart` | exact |
| `lib/data/finance/budget_model.dart` | model (Isar collection) | CRUD | `lib/data/tasks/item_model.dart` | exact |
| `lib/data/finance/debt_model.dart` | model (Isar collection) | CRUD | `lib/data/tasks/item_model.dart` | exact |
| `lib/data/finance/recurring_payment_model.dart` | model (Isar collection) | CRUD | `lib/data/tasks/item_model.dart` | exact |
| `lib/data/finance/transaction_dao.dart` | dao | CRUD | `lib/data/tasks/item_dao.dart` | exact |
| `lib/data/finance/transaction_category_dao.dart` | dao | CRUD | `lib/data/tasks/item_dao.dart` | exact |
| `lib/data/finance/savings_goal_dao.dart` | dao | CRUD | `lib/data/tasks/item_dao.dart` | exact |
| `lib/data/finance/budget_dao.dart` | dao | CRUD | `lib/data/tasks/item_dao.dart` | exact |
| `lib/data/finance/debt_dao.dart` | dao | CRUD | `lib/data/tasks/item_dao.dart` | exact |
| `lib/data/finance/recurring_payment_dao.dart` | dao | CRUD | `lib/data/tasks/item_dao.dart` | exact |
| `lib/data/finance/finance_mappers.dart` | mapper | transform | `lib/data/tasks/item_mapper.dart` | exact |
| `lib/infrastructure/finance/transaction_repository_impl.dart` | repository (impl) | CRUD | `lib/infrastructure/tasks/item_repository_impl.dart` | exact |
| `lib/infrastructure/finance/budget_repository_impl.dart` | repository (impl) | CRUD | `lib/infrastructure/tasks/item_repository_impl.dart` | exact |
| `lib/infrastructure/finance/goal_repository_impl.dart` | repository (impl) | CRUD | `lib/infrastructure/tasks/item_repository_impl.dart` | exact |
| `lib/infrastructure/finance/debt_repository_impl.dart` | repository (impl) | CRUD | `lib/infrastructure/tasks/item_repository_impl.dart` | exact |
| `lib/infrastructure/finance/recurring_payment_repository_impl.dart` | repository (impl) | CRUD | `lib/infrastructure/tasks/item_repository_impl.dart` | exact |
| `lib/application/finance/transaction/transaction_cubit.dart` | cubit | CRUD | `lib/application/tasks/task_list/task_list_cubit.dart` | exact |
| `lib/application/finance/transaction/transaction_state.dart` | state | — | `lib/application/tasks/task_list/task_list_state.dart` | exact |
| `lib/application/finance/budget/budget_cubit.dart` | cubit | CRUD | `lib/application/tasks/task_list/task_list_cubit.dart` | exact |
| `lib/application/finance/budget/budget_state.dart` | state | — | `lib/application/tasks/task_list/task_list_state.dart` | exact |
| `lib/application/finance/goal/goal_cubit.dart` | cubit | CRUD | `lib/application/tasks/project/project_cubit.dart` | exact |
| `lib/application/finance/goal/goal_state.dart` | state | — | `lib/application/tasks/task_list/task_list_state.dart` | exact |
| `lib/application/finance/debt/debt_cubit.dart` | cubit | CRUD | `lib/application/tasks/task_list/task_list_cubit.dart` | exact |
| `lib/application/finance/debt/debt_state.dart` | state | — | `lib/application/tasks/task_list/task_list_state.dart` | exact |
| `lib/application/finance/dashboard/home_dashboard_cubit.dart` | cubit | event-driven (watchLazy) | `lib/application/tasks/task_list/task_list_cubit.dart` | exact |
| `lib/application/finance/dashboard/home_dashboard_state.dart` | state | — | `lib/application/tasks/task_list/task_list_state.dart` | exact |
| `lib/presentation/finance/screens/transaction_list_screen.dart` | screen | request-response | `lib/presentation/tasks/screens/task_list_screen.dart` | exact |
| `lib/presentation/finance/screens/transaction_form_screen.dart` | screen (form) | request-response | `lib/presentation/tasks/screens/task_form_screen.dart` | exact |
| `lib/presentation/finance/screens/budget_overview_screen.dart` | screen | request-response | `lib/presentation/tasks/screens/task_list_screen.dart` | role-match |
| `lib/presentation/finance/screens/goal_list_screen.dart` | screen | request-response | `lib/presentation/tasks/screens/task_list_screen.dart` | role-match |
| `lib/presentation/finance/screens/goal_detail_screen.dart` | screen | request-response | `lib/presentation/tasks/screens/task_detail_screen.dart` | role-match |
| `lib/presentation/finance/screens/debt_list_screen.dart` | screen | request-response | `lib/presentation/tasks/screens/task_list_screen.dart` | role-match |
| `lib/presentation/finance/screens/recurring_payment_screen.dart` | screen | request-response | `lib/presentation/tasks/screens/task_list_screen.dart` | role-match |
| `lib/presentation/finance/widgets/transaction_card.dart` | widget | request-response | `lib/presentation/tasks/widgets/task_card.dart` | exact |
| `lib/presentation/finance/widgets/budget_progress_bar.dart` | widget | request-response | `lib/presentation/tasks/widgets/slot_section.dart` | role-match |
| `lib/presentation/finance/widgets/goal_progress_card.dart` | widget | request-response | `lib/presentation/tasks/widgets/task_card.dart` | role-match |
| `lib/presentation/finance/widgets/spending_pie_chart.dart` | widget | request-response | none (fl_chart new) | no analog |
| `lib/presentation/finance/widgets/spending_bar_chart.dart` | widget | request-response | none (fl_chart new) | no analog |
| `lib/presentation/finance/widgets/finance_empty_state.dart` | widget | request-response | `lib/presentation/tasks/screens/task_list_screen.dart` `_EmptyState` | role-match |
| `lib/core/constants/currencies.dart` | utility (static data) | transform | `lib/core/constants/app_constants.dart` | role-match |
| `lib/config/di/finance_module.dart` | config (DI module) | — | `lib/config/di/tasks_module.dart` | exact |
| `lib/core/config/app_config.dart` (modify) | config | — | self | — |
| `lib/data/database/isar_service.dart` (modify) | service | — | self | — |
| `lib/data/database/migration_runner.dart` (modify) | migration | — | self | — |
| `lib/data/tasks/item_model.dart` (modify — linkedGoalId/linkedDebtId write targets) | model | — | self | — |

---

## Pattern Assignments

---

### Domain Entity Pattern
**Analog:** `lib/domain/tasks/item.dart`
**Apply to:** All files in `lib/domain/finance/`

**Imports pattern** (lines 1–4):
```dart
import 'package:agenda/domain/tasks/eisenhower_quadrant.dart'; // replace with finance imports
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
```
Finance equivalent: zero Flutter/Isar imports. Only `package:agenda/domain/finance/` types.

**clearField sentinel pattern** (lines 8–19 of `item.dart`):
```dart
/// Sentinel value used by [Entity.copyWith] to distinguish "not provided"
/// from "explicitly set to null" for nullable fields.
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}
```
Copy this verbatim into each domain entity file that has nullable fields.

**Class structure pattern** (lines 26–52 of `item.dart`):
```dart
/// Domain entity — pure Dart, zero Flutter and zero Isar imports.
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amountCents,  // int, not double
    required this.categoryId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.linkedGoalId,
    this.deletedAt,
  });

  final int id;
  // ... fields ...
}
```

**copyWith pattern with clearField** (lines 146–218 of `item.dart`):
```dart
Transaction copyWith({
  int? id,
  Object? note = clearField,       // nullable: use clearField sentinel
  DateTime? createdAt,             // non-nullable: plain nullable param
  Object? deletedAt = clearField,
}) {
  return Transaction(
    id: id ?? this.id,
    note: note is _Absent ? this.note : note as String?,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt is _Absent ? this.deletedAt : deletedAt as DateTime?,
  );
}
```

---

### Repository Interface Pattern
**Analog:** `lib/domain/tasks/item_repository.dart`
**Apply to:** All `lib/domain/finance/*_repository.dart` files

**Imports pattern** (lines 1–4 of `item_repository.dart`):
```dart
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/transaction.dart';
// No Flutter/Isar imports — domain layer is pure Dart
```

**Method signature pattern** (lines 11–66 of `item_repository.dart`):
```dart
abstract class TransactionRepository {
  /// Creates a new transaction and returns it with the assigned Isar id.
  AsyncResult<Transaction> createTransaction(Transaction transaction);

  /// Returns the transaction with [id], or Err(DatabaseFailure) if not found.
  AsyncResult<Transaction> getTransaction(int id);

  /// Returns all active (non-deleted) transactions. Limit 500.
  AsyncResult<List<Transaction>> getTransactions();

  /// Overwrites the stored transaction with [transaction].
  /// Updates updatedAt to DateTime.now() before writing.
  AsyncResult<Transaction> updateTransaction(Transaction transaction);

  /// Soft-deletes by setting deletedAt = DateTime.now().
  AsyncResult<Transaction> softDelete(int id);

  /// Stream that fires when the TransactionModel collection changes.
  Stream<void> watchChanges();
}
```
Rule: every method returns `AsyncResult<T>` or `Stream<void>`. Never `void`, never `throws`.

---

### Isar Model Pattern
**Analog:** `lib/data/tasks/item_model.dart`
**Apply to:** All files in `lib/data/finance/*_model.dart`

**File structure pattern** (lines 1–3 of `item_model.dart`):
```dart
import 'package:isar_community/isar.dart';

part 'transaction_model.g.dart';
```

**Embedded value object pattern** (lines 11–16 of `item_model.dart`):
```dart
@embedded
class GoalContribution {
  GoalContribution();         // required no-arg constructor for Isar
  int amountCents = 0;
  late DateTime date;
  String? note;
}
```

**Collection class with enum annotation pattern** (lines 49–57 of `item_model.dart`):
```dart
@Collection()
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)   // MANDATORY on every enum field — no exceptions
  late TransactionType type;

  late int amountCents;        // int cents — NEVER double for money

  @Index()
  late int categoryId;

  @Index()
  late DateTime date;

  String? note;
  int? linkedGoalId;

  @Index()
  DateTime? deletedAt;         // soft delete pattern

  late DateTime createdAt;
  late DateTime updatedAt;
}
```

**Composite index pattern** (lines 54–57 of `item_model.dart`):
```dart
@Index(composite: [CompositeIndex('deletedAt')])
@Enumerated(EnumType.name)
late ItemType type;
```
For BudgetModel, the composite index covers `(month, year, categoryId)` for O(1) monthly lookups.

**Embedded list initialization (CRITICAL)** — from RESEARCH.md Pattern 8:
```dart
// CORRECT — growable required for Isar embedded-list writes
List<GoalContribution> contributions = List.empty(growable: true);

// WRONG — compiles but throws at runtime on Isar write
// List<GoalContribution> contributions = [];
```

---

### DAO Pattern
**Analog:** `lib/data/tasks/item_dao.dart`
**Apply to:** All files in `lib/data/finance/*_dao.dart`

**Class + collection accessor pattern** (lines 9–16 of `item_dao.dart`):
```dart
class TransactionDao {
  const TransactionDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<TransactionModel> get _collection =>
      _isarService.db.collection<TransactionModel>();
}
```

**Read with deletedAtIsNull + limit(500) pattern** (lines 21–27 of `item_dao.dart`):
```dart
Future<List<TransactionModel>> findAll() async => _collection
    .filter()
    .deletedAtIsNull()
    .limit(500)
    .findAll();
```

**Date-range filter pattern (for monthly budget/chart queries)** (lines 45–109 of `item_dao.dart`, adapted):
```dart
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

**Write transaction pattern** (lines 131–132 of `item_dao.dart`):
```dart
Future<int> save(TransactionModel model) async =>
    _isarService.db.writeTxn(() => _collection.put(model));
```

**Soft delete pattern** (lines 138–145 of `item_dao.dart`):
```dart
Future<void> softDelete(int id) async {
  await _isarService.db.writeTxn(() async {
    final model = await _collection.get(id);
    if (model == null) return;
    model.deletedAt = DateTime.now();
    await _collection.put(model);
  });
}
```

**watchLazy pattern** (lines 176–178 of `item_dao.dart`):
```dart
Stream<void> watchLazy() =>
    _isarService.db.collection<TransactionModel>().watchLazy();
```

---

### Mapper Pattern
**Analog:** `lib/data/tasks/item_mapper.dart`
**Apply to:** `lib/data/finance/finance_mappers.dart` (all finance mappers in one file)

**Imports and class pattern** (lines 1–12 of `item_mapper.dart`):
```dart
import 'package:agenda/data/finance/transaction_model.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_type.dart' as domain;
// Note: alias 'as domain' when model and domain share enum names

class TransactionMapper {
  const TransactionMapper();
  // ...
}
```

**toDomain method pattern** (lines 16–43 of `item_mapper.dart`):
```dart
Transaction toDomain(TransactionModel model) {
  return Transaction(
    id: model.id,
    type: _toDomainType(model.type),
    amountCents: model.amountCents,
    categoryId: model.categoryId,
    date: model.date,
    note: model.note,
    linkedGoalId: model.linkedGoalId,
    deletedAt: model.deletedAt,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
  );
}
```

**toModel method with autoIncrement guard** (lines 50–57 of `item_mapper.dart`):
```dart
TransactionModel toModel(Transaction tx) {
  final model = TransactionModel();
  // Only set id for existing records; leave autoIncrement sentinel for new ones
  if (tx.id != 0) {
    model.id = tx.id;
  }
  model
    ..type = _toModelType(tx.type)
    ..amountCents = tx.amountCents
    ..categoryId = tx.categoryId
    ..date = tx.date
    ..note = tx.note
    ..linkedGoalId = tx.linkedGoalId
    ..deletedAt = tx.deletedAt
    ..createdAt = tx.createdAt
    ..updatedAt = tx.updatedAt;
  return model;
}
```

**Switch-based enum converter pattern** (lines 101–110 of `item_mapper.dart`):
```dart
domain.TransactionType _toDomainType(TransactionType t) => switch (t) {
  TransactionType.income  => domain.TransactionType.income,
  TransactionType.expense => domain.TransactionType.expense,
};

TransactionType _toModelType(domain.TransactionType t) => switch (t) {
  domain.TransactionType.income  => TransactionType.income,
  domain.TransactionType.expense => TransactionType.expense,
};
```

---

### Repository Implementation Pattern
**Analog:** `lib/infrastructure/tasks/item_repository_impl.dart`
**Apply to:** All files in `lib/infrastructure/finance/*_repository_impl.dart`

**Imports and @LazySingleton annotation** (lines 1–17 of `item_repository_impl.dart`):
```dart
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/transaction_dao.dart';
import 'package:agenda/data/finance/finance_mappers.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dao, this._mapper);

  final TransactionDao _dao;
  final TransactionMapper _mapper;
}
```

**CRUD method with try/catch + Result wrapping** (lines 28–57 of `item_repository_impl.dart`):
```dart
@override
AsyncResult<Transaction> createTransaction(Transaction transaction) async {
  try {
    final now = DateTime.now();
    // Validation: amountCents must be > 0
    if (transaction.amountCents <= 0) {
      return const Err<Transaction>(
        ValidationFailure('amountCents must be greater than zero'),
      );
    }
    final toSave = transaction.copyWith(createdAt: now, updatedAt: now);
    final model = _mapper.toModel(toSave);
    final id = await _dao.save(model);
    final saved = await _dao.findById(id);
    return Success<Transaction>(_mapper.toDomain(saved!));
  } on Object catch (e) {
    return Err<Transaction>(DatabaseFailure('createTransaction failed: $e'));
  }
}
```

**watchChanges delegation pattern** (line 199 of `item_repository_impl.dart`):
```dart
@override
Stream<void> watchChanges() => _dao.watchLazy();
```

**Soft delete read-back note** (lines 107–117 of `item_repository_impl.dart`):
```dart
@override
AsyncResult<Transaction> softDelete(int id) async {
  try {
    await _dao.softDelete(id);
    // Read model directly by raw id — bypasses deletedAtIsNull filter
    // so result is consistent. Do NOT call getTransaction() — it may
    // exclude soft-deleted rows.
    final model = await _dao.findById(id);
    if (model == null) {
      return Err<Transaction>(DatabaseFailure('Transaction $id not found after softDelete'));
    }
    return Success<Transaction>(_mapper.toDomain(model));
  } on Object catch (e) {
    return Err<Transaction>(DatabaseFailure('softDelete failed: $e'));
  }
}
```

---

### Cubit Pattern (list / CRUD)
**Analog:** `lib/application/tasks/task_list/task_list_cubit.dart`
**Apply to:** `TransactionCubit`, `BudgetCubit`, `DebtCubit`

**Imports + @injectable annotation** (lines 1–12 of `task_list_cubit.dart`):
```dart
import 'dart:async';

import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this._repository) : super(const TransactionInitial());

  final TransactionRepository _repository;
  StreamSubscription<void>? _watchSubscription;
```

**start() + watchChanges listener + _reload() pattern** (lines 36–41 of `task_list_cubit.dart`):
```dart
Future<void> start() async {
  _watchSubscription = _repository.watchChanges().listen((_) async {
    await _reload();
  });
  await _reload();
}
```

**_reload() with isClosed guard** (lines 174–200 of `task_list_cubit.dart`):
```dart
Future<void> _reload() async {
  if (isClosed) return;

  final result = await _repository.getTransactions();

  if (isClosed) return;

  if (result is Success<List<Transaction>>) {
    emit(TransactionLoaded(transactions: result.value));
  } else if (result is Err<List<Transaction>>) {
    emit(TransactionError(result.failure));
  }
}
```

**close() subscription cleanup pattern** (lines 211–215 of `task_list_cubit.dart`):
```dart
@override
Future<void> close() async {
  await _watchSubscription?.cancel();
  return super.close();
}
```

---

### Cubit Pattern (detail / aggregate — GoalCubit)
**Analog:** `lib/application/tasks/project/project_cubit.dart`
**Apply to:** `GoalCubit`

**Load + aggregate refresh pattern** (lines 19–31 of `project_cubit.dart`):
```dart
Future<void> loadGoal(int goalId) async {
  emit(const GoalLoading());
  final goalResult = await _goalRepository.getGoal(goalId);
  final SavingsGoal goal;
  switch (goalResult) {
    case Err<SavingsGoal>():
      emit(GoalError(goalResult.failure));
      return;
    case Success<SavingsGoal>(:final value):
      goal = value;
  }
  await _refreshGoal(goal);
}
```

**Error propagation with switch exhaustiveness** (lines 89–116 of `project_cubit.dart`):
```dart
Future<void> _refreshGoal(SavingsGoal goal) async {
  // Load tagged transactions for this goal
  final txResult = await _transactionRepository.getByLinkedGoal(goal.id);
  final List<Transaction> tagged;
  switch (txResult) {
    case Err<List<Transaction>>():
      emit(GoalError(txResult.failure));
      return;
    case Success<List<Transaction>>(:final value):
      tagged = value;
  }
  // Compute progress in Dart — no N+1 queries
  final taggedCents = tagged.fold(0, (sum, tx) => sum + tx.amountCents);
  emit(GoalLoaded(goal: goal, taggedTransactionsCents: taggedCents));
}
```

---

### Cubit State Pattern
**Analog:** `lib/application/tasks/task_list/task_list_state.dart`
**Apply to:** All `lib/application/finance/*/` state files

**Sealed class + Equatable + final subclasses** (lines 1–70 of `task_list_state.dart`):
```dart
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:equatable/equatable.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
  @override
  List<Object?> get props => [];
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
  @override
  List<Object?> get props => [];
}

final class TransactionLoaded extends TransactionState {
  const TransactionLoaded({required this.transactions});
  final List<Transaction> transactions;
  @override
  List<Object?> get props => [transactions];
}

final class TransactionError extends TransactionState {
  const TransactionError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

**HomeDashboardLoaded state** carries additional computed fields:
```dart
final class HomeDashboardLoaded extends HomeDashboardState {
  const HomeDashboardLoaded({
    required this.balanceCents,
    required this.netWorthCents,
    required this.selectedMonth,
    required this.categorySpend, // Map<int, int> categoryId -> totalCents
    required this.categories,    // List<TransactionCategory> for label lookup
  });
  final int balanceCents;
  final int netWorthCents;
  final DateTime selectedMonth;
  final Map<int, int> categorySpend;
  final List<TransactionCategory> categories;
  @override
  List<Object?> get props => [balanceCents, netWorthCents, selectedMonth, categorySpend, categories];
}
```

---

### HomeDashboardCubit Pattern
**Analog:** `lib/application/tasks/task_list/task_list_cubit.dart` (watchLazy stream structure)
**Apply to:** `lib/application/finance/dashboard/home_dashboard_cubit.dart`

**Multi-repository injection + month field** (lines 21–31 of `task_list_cubit.dart`, adapted):
```dart
@injectable
class HomeDashboardCubit extends Cubit<HomeDashboardState> {
  HomeDashboardCubit(
    this._transactionRepository,
    this._goalRepository,
    this._debtRepository,
    this._categoryRepository,
  ) : super(const HomeDashboardInitial());

  final TransactionRepository _transactionRepository;
  final GoalRepository _goalRepository;
  final DebtRepository _debtRepository;
  final TransactionCategoryRepository _categoryRepository;

  StreamSubscription<void>? _txWatchSub;
  DateTime _selectedMonth = DateTime.now();
```

**selectMonth method**:
```dart
Future<void> selectMonth(DateTime month) async {
  _selectedMonth = DateTime(month.year, month.month);
  await _reload();
}
```

**Single-pass _reload() aggregation** (combines start() + _reload() patterns from `task_list_cubit.dart` lines 36–41, 174–200):
```dart
Future<void> _reload() async {
  if (isClosed) return;

  // 1. Load all non-deleted transactions (500 cap) — single query
  final txResult = await _transactionRepository.getTransactions();
  if (isClosed) return;
  if (txResult is Err<List<Transaction>>) {
    emit(HomeDashboardError((txResult as Err<List<Transaction>>).failure));
    return;
  }
  final allTx = (txResult as Success<List<Transaction>>).value;

  // 2. Balance = lifetime income - lifetime expenses (single pass)
  int income = 0, expenses = 0;
  for (final tx in allTx) {
    if (tx.type == TransactionType.income) income += tx.amountCents;
    else expenses += tx.amountCents;
  }
  final balance = income - expenses;

  // 3. Net worth: load active goals + unpaid toPay debts
  final goalsResult = await _goalRepository.getActiveGoals();
  final debtsResult = await _debtRepository.getDebts();
  // ... switch on each, compute per D-08 formula ...

  // 4. Filter to selectedMonth for chart
  final monthTx = allTx.where((tx) =>
    tx.type == TransactionType.expense &&
    tx.date.year == _selectedMonth.year &&
    tx.date.month == _selectedMonth.month &&
    tx.deletedAt == null,
  ).toList();

  // 5. groupBy categoryId in Dart (single pass — no Isar GROUP BY)
  final categorySpend = <int, int>{};
  for (final tx in monthTx) {
    categorySpend[tx.categoryId] =
        (categorySpend[tx.categoryId] ?? 0) + tx.amountCents;
  }

  // 6. Load category labels for chart display
  final catResult = await _categoryRepository.getAll();
  // ...

  emit(HomeDashboardLoaded(
    balanceCents: balance,
    netWorthCents: netWorth,
    selectedMonth: _selectedMonth,
    categorySpend: categorySpend,
    categories: categories,
  ));
}
```

---

### DI Module Pattern
**Analog:** `lib/config/di/tasks_module.dart`
**Apply to:** `lib/config/di/finance_module.dart`

**@module abstract class with @lazySingleton factory methods** (lines 1–24 of `tasks_module.dart`):
```dart
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/transaction_dao.dart';
// ... all DAO + mapper imports ...
import 'package:injectable/injectable.dart';

@module
abstract class FinanceModule {
  /// DAOs — each requires IsarService; registered as lazy singletons.
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

  /// Mappers — pure converters, no constructor args.
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

// Repository impls use class-level annotation — not declared in the module:
// @LazySingleton(as: TransactionRepository)
// class TransactionRepositoryImpl implements TransactionRepository { ... }
```

---

### List Screen Pattern
**Analog:** `lib/presentation/tasks/screens/task_list_screen.dart`
**Apply to:** `transaction_list_screen.dart`, `goal_list_screen.dart`, `debt_list_screen.dart`, `recurring_payment_screen.dart`

**StatefulWidget + initState calling cubit.start()** (lines 22–34 of `task_list_screen.dart`):
```dart
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});
  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().start();
  }
```

**BlocConsumer with exhaustive switch on state** (lines 111–150 of `task_list_screen.dart`):
```dart
body: BlocConsumer<TransactionCubit, TransactionState>(
  listener: (context, state) {
    // handle side effects (SnackBars, navigation)
  },
  builder: (context, state) {
    return switch (state) {
      TransactionInitial() || TransactionLoading() =>
        const Center(child: CircularProgressIndicator()),
      TransactionError(:final failure) =>
        Center(child: Text(failure.message)),
      TransactionLoaded(:final transactions) when transactions.isEmpty =>
        const _FinanceEmptyState(),
      TransactionLoaded(:final transactions) =>
        _TransactionList(transactions: transactions),
    };
  },
),
```

**Empty state inline widget pattern** (lines 153–173 of `task_list_screen.dart`):
```dart
class _FinanceEmptyState extends StatelessWidget {
  const _FinanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            // l10n string — no hardcoded strings
            AppLocalizations.of(context).noTransactions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
```

---

### Form Screen Pattern
**Analog:** `lib/presentation/tasks/screens/task_form_screen.dart`
**Apply to:** `transaction_form_screen.dart`

**StatefulWidget with form controllers + initState** (lines 11–66 of `task_form_screen.dart`):
```dart
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});
  final Transaction? transaction;
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  // ...
  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.transaction?.note ?? '',
    );
    // For amount: display as decimal (amountCents / 100)
    _amountController = TextEditingController(
      text: widget.transaction != null
          ? (widget.transaction!.amountCents / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
```

**Amount input → int cents conversion at submit**:
```dart
// Convert user-entered decimal string to int cents on form submit
final rawAmount = double.tryParse(_amountController.text.replaceAll(',', '.'));
if (rawAmount == null || rawAmount <= 0) {
  // show validation error
  return;
}
final amountCents = (rawAmount * 100).round(); // NEVER store as double
```

---

### Widget Card Pattern
**Analog:** `lib/presentation/tasks/widgets/task_card.dart`
**Apply to:** `transaction_card.dart`, `goal_progress_card.dart`

**StatelessWidget + domain-only imports** (lines 1–12 of `task_card.dart`):
```dart
import 'package:agenda/domain/finance/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// NO Isar imports — widgets only see domain types

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onTap;
```

**Card layout pattern** (lines 45–118 of `task_card.dart`):
```dart
return Card(
  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // leading icon (income green / expense red)
          Expanded(child: /* title + chips */),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  ),
);
```

---

### MigrationRunner Case 3 Pattern
**Analog:** `lib/data/database/migration_runner.dart` (existing switch block)
**Apply to:** `lib/data/database/migration_runner.dart` (add case 3)

**Existing switch pattern to extend** (lines 35–45 of `migration_runner.dart`):
```dart
static Future<void> _runMigration(Isar isar, int toVersion) async {
  switch (toVersion) {
    case 1:
      return;
    case 2:
      return;
    case 3:  // ADD THIS BLOCK
      await _seedDefaultCategories(isar);
      return;
  }
}
```

**Idempotent seeding helper (new private method)**:
```dart
static Future<void> _seedDefaultCategories(Isar isar) async {
  // Guard: idempotent — only seed if no categories exist (D-06)
  final count = await isar.transactionCategoryModels.count();
  if (count > 0) return;

  final now = DateTime.now();
  const expenseNames = [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde',
    'Educação', 'Lazer', 'Roupas', 'Tecnologia', 'Outros',
  ];
  const incomeNames = ['Salário', 'Freelance', 'Investimentos', 'Outros'];

  final models = [
    ...expenseNames.map((name) => TransactionCategoryModel()
      ..namePtBr = name
      ..nameEn = _defaultNameEn(name)
      ..type = TransactionType.expense
      ..isDefault = true
      ..createdAt = now),
    ...incomeNames.map((name) => TransactionCategoryModel()
      ..namePtBr = name
      ..nameEn = _defaultNameEn(name)
      ..type = TransactionType.income
      ..isDefault = true
      ..createdAt = now),
  ];

  await isar.writeTxn(() => isar.transactionCategoryModels.putAll(models));
}
```

---

### IsarService.open() Schema Extension
**Analog:** `lib/data/database/isar_service.dart` (modify schemas list)
**Apply to:** Same file — add finance schemas to the `Isar.open()` call

**Current call site (line 43 of `isar_service.dart`)**:
```dart
_isar = await Isar.open(schemas, directory: dir.path);
```
The `schemas` parameter is passed in from the caller (main.dart / DI setup). Phase 3 adds all six finance schemas to the list at the call site:
```dart
await IsarService.instance.open([
  ItemModelSchema,                    // Phase 2
  TransactionModelSchema,             // Phase 3
  TransactionCategoryModelSchema,     // Phase 3
  BudgetModelSchema,                  // Phase 3
  SavingsGoalModelSchema,             // Phase 3
  DebtModelSchema,                    // Phase 3
  RecurringPaymentModelSchema,        // Phase 3
]);
```

---

### AppConfig.schemaVersion Bump
**Analog:** `lib/core/config/app_config.dart` (modify constant)
**Apply to:** Same file

**Current value (line 22 of `app_config.dart`)**:
```dart
static const int schemaVersion = 2;
```
Phase 3 bumps to:
```dart
static const int schemaVersion = 3;
```

---

### Core Constants Pattern
**Analog:** `lib/core/constants/app_constants.dart`
**Apply to:** `lib/core/constants/currencies.dart`

**abstract final class with static const** (lines 4–29 of `app_constants.dart`):
```dart
abstract final class Currencies {
  /// Full ISO 4217 static list — no network call, no external package.
  /// Priority entries shown first in Phase 5 picker.
  static const List<Currency> all = [
    Currency(code: 'MZN', name: 'Metical Moçambicano', symbol: 'MT'),
    Currency(code: 'BRL', name: 'Real Brasileiro', symbol: r'R$'),
    Currency(code: 'USD', name: 'US Dollar', symbol: r'$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    // ... full ISO 4217 list ...
  ];

  static const List<String> priorityCodes = [
    'MZN', 'BRL', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'ZAR',
  ];
}

/// Plain Dart value object — no Isar annotation.
class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });
  final String code;
  final String name;
  final String symbol;
}
```

---

## Shared Patterns

### Result<T> / AsyncResult<T> — Applied to All Repository Methods
**Source:** `lib/core/failures/result.dart` (lines 17–41)
**Apply to:** Every method in every `*_repository.dart` interface and `*_repository_impl.dart`

```dart
// Return type is always AsyncResult<T> or Result<T>
// Never: Future<void>, never: throws
AsyncResult<Transaction> createTransaction(Transaction t);
AsyncResult<List<Budget>> getBudgets();
Stream<void> watchChanges(); // stream is the exception — not wrapped in Result
```

Pattern match at call sites (exhaustive, compiler-enforced):
```dart
final result = await _repository.createTransaction(tx);
switch (result) {
  case Success<Transaction>(:final value): // use value
  case Err<Transaction>(:final failure):   // emit error state
}
```

### DatabaseFailure / ValidationFailure — Error Wrapping
**Source:** `lib/core/failures/failure.dart` (lines 31–38)
**Apply to:** All `*_repository_impl.dart` catch blocks and validation checks

```dart
// Validation (input guard — before any Isar call):
if (transaction.amountCents <= 0) {
  return const Err<Transaction>(
    ValidationFailure('amountCents must be greater than zero'),
  );
}

// Database (wrap Isar exceptions in catch):
} on Object catch (e) {
  return Err<Transaction>(DatabaseFailure('createTransaction failed: $e'));
}
```
Finance layer adds no new Failure subtypes — use only `DatabaseFailure` and `ValidationFailure`.

### @Enumerated(EnumType.name) — All Isar-Persisted Enums
**Source:** `lib/data/tasks/item_model.dart` (lines 55–57, 67–68, 73–74)
**Apply to:** Every enum field on every `@Collection()` class in `lib/data/finance/`

```dart
@Enumerated(EnumType.name)  // MANDATORY — no exceptions
late TransactionType type;

@Enumerated(EnumType.name)
late DebtDirection direction;

@Enumerated(EnumType.name)
late RecurringCycle cycle;
```

### Soft Delete — deletedAt nullable DateTime
**Source:** `lib/data/tasks/item_model.dart` (lines 86–87) and `item_dao.dart` (lines 138–145)
**Apply to:** `TransactionModel`, `SavingsGoalModel`, `DebtModel`, `RecurringPaymentModel`
NOT applied to: `TransactionCategoryModel` (custom categories are hard-deleted; defaults are undeletable)

```dart
@Index()
DateTime? deletedAt;
```
All list queries begin with `.deletedAtIsNull()`:
```dart
_collection.filter().deletedAtIsNull().limit(500).findAll()
```

### isClosed Guard in Cubit _reload()
**Source:** `lib/application/tasks/task_list/task_list_cubit.dart` (lines 175, 189)
**Apply to:** Every `_reload()` method in every finance Cubit

```dart
Future<void> _reload() async {
  if (isClosed) return;           // guard before async gap
  final result = await /* query */;
  if (isClosed) return;           // guard after await — widget may have disposed
  // emit(...)
}
```

### package:agenda/... Import Alias Convention
**Source:** All existing source files — zero relative imports anywhere
**Apply to:** Every new file

```dart
// CORRECT
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/data/finance/transaction_model.dart';

// WRONG — never use relative imports
import '../../../domain/finance/transaction.dart';
```

### Amount Display — intl NumberFormat (presentation boundary only)
**Source:** RESEARCH.md Pattern 1 / `lib/presentation/tasks/widgets/task_card.dart` (uses `intl` `DateFormat`)

```dart
// Only at the presentation layer — never in data/domain/application
import 'package:intl/intl.dart';

String formatAmount(int amountCents, String symbol, Locale locale) {
  final amount = amountCents / 100.0;  // double ONLY for display
  final formatter = NumberFormat.currency(
    locale: locale.toString(),
    symbol: '',
    decimalDigits: 2,
  );
  return '$symbol ${formatter.format(amount)}';
}
```

---

## No Analog Found

Files with no close match in the codebase (use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/presentation/finance/widgets/spending_pie_chart.dart` | widget | request-response | No fl_chart usage exists in codebase yet; use RESEARCH.md Pattern 6 (PieChartData API) |
| `lib/presentation/finance/widgets/spending_bar_chart.dart` | widget | request-response | No fl_chart usage exists in codebase yet; use RESEARCH.md Pattern 6 (BarChartData API) |

---

## Metadata

**Analog search scope:** `lib/` (all 51 Dart source files)
**Files scanned:** 17 source files read in full
**Key analogs:** `item_model.dart`, `item_dao.dart`, `item_mapper.dart`, `item_repository_impl.dart`, `task_list_cubit.dart`, `task_list_state.dart`, `project_cubit.dart`, `tasks_module.dart`, `task_list_screen.dart`, `task_card.dart`, `migration_runner.dart`
**Pattern extraction date:** 2026-05-14
