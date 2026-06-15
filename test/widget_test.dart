import 'package:agenda/app.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget.dart';
import 'package:agenda/domain/finance/budget_repository.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/domain/finance/recurring_payment_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub repository that never touches Isar.
///
/// Used in widget tests so the full app shell can render without requiring
/// the native Isar binary (libisar.so) which is unavailable in VM test mode.
class _StubItemRepository implements ItemRepository {
  @override
  AsyncResult<Item> createItem(Item item) async =>
      Success(item.copyWith(id: 1));

  @override
  AsyncResult<Item> getItem(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<Item>> getItemsByType(ItemType type) async =>
      const Success([]);

  @override
  AsyncResult<List<Item>> getSubtasks(int projectId) async =>
      const Success([]);

  @override
  AsyncResult<Item> updateItem(Item item) async => Success(item);

  @override
  AsyncResult<Item> softDelete(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<Item> restoreItem(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<Item>> searchByTitle(String query) async =>
      const Success([]);

  @override
  AsyncResult<List<Item>> filterItems({
    ItemType? type,
    EisenhowerQuadrant? quadrant,
    String? gtdContext,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? parentId,
    bool showCompleted = false,
  }) async =>
      const Success([]);

  @override
  AsyncResult<(int, int)> getSubtaskCounts(int projectId) async =>
      const Success((0, 0));

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  AsyncResult<List<String>> getDistinctGtdContexts() async =>
      const Success([]);
}

/// Stub finance repositories that never touch Isar.
///
/// The home shell uses an [IndexedStack], so every tab — including the finance
/// dashboard and its six sub-tabs — mounts eagerly on first frame. Each finance
/// cubit calls into its repository on `start()`, which would otherwise hit the
/// uninitialised `IsarService` in VM test mode. List/stream reads return empty
/// so the dashboard settles into a loaded (empty) state; single-entity writes
/// return a stub error since they are never invoked during a smoke render.
class _StubTransactionRepository implements TransactionRepository {
  @override
  AsyncResult<Transaction> createTransaction(Transaction transaction) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<Transaction> getTransaction(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<Transaction>> getTransactions() async => const Success([]);

  @override
  AsyncResult<List<Transaction>> getByMonth(int month, int year) async =>
      const Success([]);

  @override
  AsyncResult<List<Transaction>> getByLinkedGoal(int goalId) async =>
      const Success([]);

  @override
  AsyncResult<Transaction> updateTransaction(Transaction transaction) async =>
      Success(transaction);

  @override
  AsyncResult<Transaction> softDelete(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  Stream<void> watchChanges() => const Stream.empty();
}

class _StubBudgetRepository implements BudgetRepository {
  @override
  AsyncResult<Budget?> getForCategory(
    int categoryId,
    int month,
    int year,
  ) async =>
      const Success(null);

  @override
  AsyncResult<List<Budget>> getForMonth(int month, int year) async =>
      const Success([]);

  @override
  AsyncResult<Budget> setLimit(
    int categoryId,
    int month,
    int year,
    int limitCents,
  ) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<void> delete(int categoryId, int month, int year) async =>
      const Success(null);
}

class _StubGoalRepository implements GoalRepository {
  @override
  AsyncResult<SavingsGoal> createGoal(SavingsGoal goal) async => Success(goal);

  @override
  AsyncResult<SavingsGoal> getGoal(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<SavingsGoal>> getActiveGoals() async => const Success([]);

  @override
  AsyncResult<SavingsGoal> updateGoal(SavingsGoal goal) async => Success(goal);

  @override
  AsyncResult<SavingsGoal> addContribution(
    int goalId,
    SavingsGoalContribution contribution,
  ) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<SavingsGoal> softDelete(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  Stream<void> watchChanges() => const Stream.empty();
}

class _StubDebtRepository implements DebtRepository {
  @override
  AsyncResult<Debt> createDebt(Debt debt) async => Success(debt);

  @override
  AsyncResult<Debt> getDebt(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<Debt>> getDebts() async => const Success([]);

  @override
  AsyncResult<Debt> updateDebt(Debt debt) async => Success(debt);

  @override
  AsyncResult<Debt> togglePaid(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<Debt> softDelete(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  Stream<void> watchChanges() => const Stream.empty();
}

class _StubRecurringPaymentRepository implements RecurringPaymentRepository {
  @override
  AsyncResult<RecurringPayment> createPayment(
    RecurringPayment payment,
  ) async =>
      Success(payment);

  @override
  AsyncResult<RecurringPayment> getPayment(int id) async =>
      const Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<RecurringPayment>> getActivePayments() async =>
      const Success([]);

  @override
  AsyncResult<RecurringPayment> updatePayment(
    RecurringPayment payment,
  ) async =>
      Success(payment);

  @override
  AsyncResult<RecurringPayment> softDelete(int id) async =>
      const Err(DatabaseFailure('stub'));
}

class _StubTransactionCategoryRepository
    implements TransactionCategoryRepository {
  @override
  AsyncResult<List<TransactionCategory>> getAll() async => const Success([]);

  @override
  AsyncResult<List<TransactionCategory>> getByType(
    TransactionType type,
  ) async =>
      const Success([]);

  @override
  AsyncResult<TransactionCategory> create(TransactionCategory category) async =>
      Success(category);

  @override
  AsyncResult<TransactionCategory> update(TransactionCategory category) async =>
      Success(category);

  @override
  AsyncResult<void> delete(int id) async => const Success(null);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    // The home shell mounts every tab eagerly (IndexedStack), including the
    // finance dashboard and its sub-tabs, so each cubit resolves its repo on
    // start. Swap every Isar-backed repo for a stub that returns empty data
    // instead of hitting libisar.so (unavailable in VM tests).
    getIt
      ..unregister<ItemRepository>()
      ..registerLazySingleton<ItemRepository>(_StubItemRepository.new)
      ..unregister<TransactionRepository>()
      ..registerLazySingleton<TransactionRepository>(
        _StubTransactionRepository.new,
      )
      ..unregister<BudgetRepository>()
      ..registerLazySingleton<BudgetRepository>(_StubBudgetRepository.new)
      ..unregister<GoalRepository>()
      ..registerLazySingleton<GoalRepository>(_StubGoalRepository.new)
      ..unregister<DebtRepository>()
      ..registerLazySingleton<DebtRepository>(_StubDebtRepository.new)
      ..unregister<RecurringPaymentRepository>()
      ..registerLazySingleton<RecurringPaymentRepository>(
        _StubRecurringPaymentRepository.new,
      )
      ..unregister<TransactionCategoryRepository>()
      ..registerLazySingleton<TransactionCategoryRepository>(
        _StubTransactionCategoryRepository.new,
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('App renders bottom navigation shell', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    // The Phase 2 home shell replaced the old single-screen layout.
    // Verify the bottom NavigationBar is present.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
