import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/quotes/quotes_catalog.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/infrastructure/notifications/prefs/alert_state_store_impl.dart';
import 'package:agenda/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart';
import 'package:agenda/infrastructure/notifications/sync/snapshot_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockItems extends Mock implements ItemRepository {}

class _MockDebts extends Mock implements DebtRepository {}

class _MockGoals extends Mock implements GoalRepository {}

class _MockPayments extends Mock implements RecurringPaymentRepository {}

class _MockTransactions extends Mock implements TransactionRepository {}

final DateTime _now = DateTime(2026, 10, 12, 8, 30);

SavingsGoal _goal(int id, {int contributed = 0}) => SavingsGoal(
  id: id,
  title: 'Trip',
  targetAmountCents: 100000,
  contributions: [
    if (contributed > 0)
      SavingsGoalContribution(amountCents: contributed, date: _now),
  ],
  isCompleted: false,
  createdAt: _now,
  updatedAt: _now,
);

Transaction _tx(int amount, {int? goalId}) => Transaction(
  id: 1,
  type: TransactionType.income,
  amountCents: amount,
  categoryId: 1,
  date: _now,
  createdAt: _now,
  updatedAt: _now,
  linkedGoalId: goalId,
);

void main() {
  late _MockItems items;
  late _MockDebts debts;
  late _MockGoals goals;
  late _MockPayments payments;
  late _MockTransactions transactions;
  late NotificationPrefsRepositoryImpl prefs;
  late AlertStateStoreImpl alerts;
  late SharedPreferences store;

  Future<SnapshotLoader> build([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    store = await SharedPreferences.getInstance();
    prefs = NotificationPrefsRepositoryImpl(store);
    alerts = AlertStateStoreImpl(store);
    return SnapshotLoader(
      items,
      debts,
      goals,
      payments,
      transactions,
      prefs,
      alerts,
      store,
    );
  }

  setUp(() {
    items = _MockItems();
    debts = _MockDebts();
    goals = _MockGoals();
    payments = _MockPayments();
    transactions = _MockTransactions();
    when(
      () => items.getRemindableItems(
        from: any(named: 'from'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Success(<Item>[]));
    when(
      () => items.getItemsDueInWindow(
        from: any(named: 'from'),
        toExclusive: any(named: 'toExclusive'),
      ),
    ).thenAnswer((_) async => const Success(<Item>[]));
    when(
      () => debts.getDebts(),
    ).thenAnswer((_) async => const Success(<Debt>[]));
    when(
      () => goals.getActiveGoals(),
    ).thenAnswer((_) async => const Success(<SavingsGoal>[]));
    when(
      () => payments.getPayments(),
    ).thenAnswer((_) async => const Success(<RecurringPayment>[]));
    when(
      () => transactions.getAllTransactionsForAggregates(),
    ).thenAnswer((_) async => const Success(<Transaction>[]));
  });

  test(
    'asks for the soonest 2x budget from today and the 7 day window',
    () async {
      final loader = await build();
      await loader.load(now: _now, slotBudget: 200);

      verify(
        () =>
            items.getRemindableItems(from: DateTime(2026, 10, 12), limit: 400),
      ).called(1);
      verify(
        () => items.getItemsDueInWindow(
          from: DateTime(2026, 10, 12),
          toExclusive: DateTime(2026, 10, 19),
        ),
      ).called(1);
    },
  );

  test('goal saved cents = contributions + tagged transactions', () async {
    when(() => goals.getActiveGoals()).thenAnswer(
      (_) async => Success([_goal(5, contributed: 1000), _goal(6)]),
    );
    when(() => transactions.getAllTransactionsForAggregates()).thenAnswer(
      (_) async => Success([
        _tx(500, goalId: 5),
        _tx(250, goalId: 5),
        _tx(9999, goalId: 99),
        _tx(7777),
      ]),
    );
    final loader = await build();

    final result = await loader.load(now: _now, slotBudget: 60);

    final input = (result as Success<PlannerInput>).value;
    expect(input.goals.map((g) => g.savedCents), [1750, 0]);
    expect(input.slotBudget, 60);
  });

  test('quotes are empty while the quote kind is disabled', () async {
    final loader = await build();

    final result = await loader.load(now: _now, slotBudget: 200);

    expect((result as Success<PlannerInput>).value.quotes, isEmpty);
  });

  test('quotes of the stored locale load when the kind is enabled', () async {
    final loader = await build({
      '${StorageKeys.notifEnabledPrefix}'
              '${NotificationKind.motivationalQuote.code}':
          true,
      StorageKeys.locale: 'en',
    });

    final input =
        ((await loader.load(now: _now, slotBudget: 200))
                as Success<PlannerInput>)
            .value;

    expect(input.localeCode, 'en');
    expect(input.quotes, quotesFor('en'));
  });

  test('any locale other than en is treated as pt', () async {
    final loader = await build({StorageKeys.locale: 'fr'});

    final input =
        ((await loader.load(now: _now, slotBudget: 200))
                as Success<PlannerInput>)
            .value;

    expect(input.localeCode, 'pt');
  });

  test('fired alert keys are passed through', () async {
    final loader = await build();
    await alerts.add('gf:5:2026-10-12');

    final input =
        ((await loader.load(now: _now, slotBudget: 200))
                as Success<PlannerInput>)
            .value;

    expect(input.firedAlertKeys, {'gf:5:2026-10-12'});
  });

  test('the first repository Err short-circuits to Err', () async {
    when(() => debts.getDebts()).thenAnswer(
      (_) async => const Err(DatabaseFailure('debts down')),
    );
    final loader = await build();

    final result = await loader.load(now: _now, slotBudget: 200);

    expect(result, isA<Err<PlannerInput>>());
    expect(
      (result as Err<PlannerInput>).failure,
      isA<DatabaseFailure>(),
    );
    verifyNever(() => goals.getActiveGoals());
    verifyNever(() => transactions.getAllTransactionsForAggregates());
    verifyNever(() => payments.getPayments());
  });
}
