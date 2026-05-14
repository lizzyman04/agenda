import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget_dao.dart';
import 'package:agenda/data/finance/debt_dao.dart';
import 'package:agenda/data/finance/finance_mappers.dart';
import 'package:agenda/data/finance/recurring_payment_dao.dart';
import 'package:agenda/data/finance/savings_goal_dao.dart';
import 'package:agenda/data/finance/transaction_category_dao.dart';
import 'package:agenda/data/finance/transaction_dao.dart';
import 'package:injectable/injectable.dart';

/// DI registrations for the Finance domain.
///
/// DAOs registered here (plain classes — no @injectable annotation on them).
/// Mapper singletons registered here via const-constructable getters.
/// Repository impls self-register via @LazySingleton(as: ...) class annotations —
/// injectable_generator picks them up automatically.
@module
abstract class FinanceModule {
  // --- DAOs ---

  @lazySingleton
  TransactionDao transactionDao(IsarService isarService) =>
      TransactionDao(isarService);

  @lazySingleton
  TransactionCategoryDao transactionCategoryDao(IsarService isarService) =>
      TransactionCategoryDao(isarService);

  @lazySingleton
  BudgetDao budgetDao(IsarService isarService) => BudgetDao(isarService);

  @lazySingleton
  SavingsGoalDao savingsGoalDao(IsarService isarService) =>
      SavingsGoalDao(isarService);

  @lazySingleton
  DebtDao debtDao(IsarService isarService) => DebtDao(isarService);

  @lazySingleton
  RecurringPaymentDao recurringPaymentDao(IsarService isarService) =>
      RecurringPaymentDao(isarService);

  // --- Mappers ---

  @lazySingleton
  TransactionMapper get transactionMapper => const TransactionMapper();

  @lazySingleton
  TransactionCategoryMapper get transactionCategoryMapper =>
      const TransactionCategoryMapper();

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
