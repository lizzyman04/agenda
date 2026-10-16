import 'dart:async';

import 'package:agenda/application/notifications/budget_alert_evaluator.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/planning/budget_threshold.dart';
import 'package:agenda/infrastructure/notifications/prefs/alert_state_store_impl.dart';
import 'package:agenda/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart';
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockBudgets extends Mock implements BudgetRepository {}

class _MockCategories extends Mock implements TransactionCategoryRepository {}

class _MockDispatcher extends Mock implements ImmediateAlertDispatcher {}

final DateTime _now = DateTime(2026, 10, 16, 12);

Transaction _spend(int cents, {int category = 1, DateTime? date}) =>
    Transaction(
      id: 1,
      type: TransactionType.expense,
      amountCents: cents,
      categoryId: category,
      date: date ?? _now,
      createdAt: _now,
      updatedAt: _now,
    );

Budget _budget(int limit, {int category = 1}) => Budget(
  id: 1,
  categoryId: category,
  month: 10,
  year: 2026,
  limitCents: limit,
  createdAt: _now,
  updatedAt: _now,
);

TransactionCategory _category(int id, String pt, {String? en}) =>
    TransactionCategory(
      id: id,
      namePtBr: pt,
      nameEn: en,
      type: TransactionType.expense,
      isDefault: false,
      createdAt: _now,
    );

void main() {
  late _MockTransactions transactions;
  late _MockBudgets budgets;
  late _MockCategories categories;
  late _MockDispatcher dispatcher;
  late NotificationPrefsRepositoryImpl prefs;
  late AlertStateStoreImpl alerts;
  late SharedPreferences store;
  late BudgetAlertEvaluator evaluator;
  late List<PlannedNotification> dispatched;

  void stubMonth({
    required List<Transaction> spent,
    required List<Budget> limits,
    List<TransactionCategory>? names,
  }) {
    when(
      () => transactions.getByMonth(any(), any()),
    ).thenAnswer((_) async => Success(spent));
    when(
      () => budgets.getForMonth(any(), any()),
    ).thenAnswer((_) async => Success(limits));
    when(() => categories.getByType(TransactionType.expense)).thenAnswer(
      (_) async => Success(names ?? [_category(1, 'Comida', en: 'Food')]),
    );
  }

  Future<void> build([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    store = await SharedPreferences.getInstance();
    prefs = NotificationPrefsRepositoryImpl(store);
    alerts = AlertStateStoreImpl(store);
    evaluator = BudgetAlertEvaluator(
      transactions,
      budgets,
      categories,
      alerts,
      dispatcher,
      prefs,
      store,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      PlannedNotification(
        kind: NotificationKind.budgetAlert,
        id: 1,
        fireAt: DateTime(2026),
      ),
    );
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    transactions = _MockTransactions();
    budgets = _MockBudgets();
    categories = _MockCategories();
    dispatcher = _MockDispatcher();
    dispatched = [];
    when(
      () => dispatcher.dispatch(any(), now: any(named: 'now')),
    ).thenAnswer((invocation) async {
      dispatched.add(
        invocation.positionalArguments.first as PlannedNotification,
      );
      return true;
    });
    when(
      () => transactions.watchChanges(),
    ).thenAnswer((_) => const Stream<void>.empty());
    when(
      () => budgets.watchChanges(),
    ).thenAnswer((_) => const Stream<void>.empty());
    await build();
  });

  group('evaluate', () {
    test('crossing 80 percent dispatches once, then nothing', () async {
      stubMonth(spent: [_spend(8500)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      await evaluator.evaluate(now: _now);

      expect(dispatched, hasLength(1));
      final alert = dispatched.single;
      expect(alert.kind, NotificationKind.budgetAlert);
      expect(alert.subject, 'Comida');
      expect(alert.count, 80);
      expect(alert.entityId, 1);
      expect(
        await alerts.contains(budgetAlertKey(2026, 10, 1, 80)),
        isTrue,
      );
    });

    test('crossing 100 after 80 dispatches exactly one more', () async {
      stubMonth(spent: [_spend(8500)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      stubMonth(spent: [_spend(10200)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      await evaluator.evaluate(now: _now);

      expect(dispatched.map((p) => p.count), [80, 100]);
    });

    test('a jump to 110 percent dispatches only 100 and marks 80', () async {
      stubMonth(spent: [_spend(11000)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);

      expect(dispatched.map((p) => p.count), [100]);
      expect(await alerts.contains(budgetAlertKey(2026, 10, 1, 80)), isTrue);
      expect(await alerts.contains(budgetAlertKey(2026, 10, 1, 100)), isTrue);
    });

    test('the notification carries the name and percent, no amount', () async {
      stubMonth(spent: [_spend(8500)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      final alert = dispatched.single;
      expect(alert.subject, isNot(contains('85')));
      expect(alert.extras, isEmpty);
      expect(alert.count, 80);
    });

    test('the English locale uses the English category name', () async {
      await build({'locale': 'en'});
      stubMonth(spent: [_spend(9000)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      expect(dispatched.single.subject, 'Food');
    });

    test('a zero limit produces nothing', () async {
      stubMonth(spent: [_spend(5000)], limits: [_budget(0)]);
      await evaluator.evaluate(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.keys(), isEmpty);
    });

    test('a category without a budget produces nothing', () async {
      stubMonth(spent: [_spend(5000)], limits: []);
      await evaluator.evaluate(now: _now);
      expect(dispatched, isEmpty);
    });

    test('only the current month is requested from the repositories', () async {
      // The repository is asked for the current month only.
      stubMonth(spent: [], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      verify(() => transactions.getByMonth(10, 2026)).called(1);
      verify(() => budgets.getForMonth(10, 2026)).called(1);
      expect(dispatched, isEmpty);
    });

    test('a new month alerts again for the same category', () async {
      stubMonth(spent: [_spend(8500)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      await evaluator.evaluate(now: DateTime(2026, 11, 3, 9));
      expect(dispatched, hasLength(2));
    });

    test('a disabled kind dispatches nothing and writes no key', () async {
      await prefs.save(
        prefs.load().withEnabled(NotificationKind.budgetAlert, value: false),
      );
      stubMonth(spent: [_spend(11000)], limits: [_budget(10000)]);
      await evaluator.evaluate(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.keys(), isEmpty);

      await prefs.save(
        prefs.load().withEnabled(NotificationKind.budgetAlert, value: true),
      );
      await evaluator.evaluate(now: _now);
      expect(dispatched.map((p) => p.count), [100]);
    });

    test('a repository error returns quietly and writes nothing', () async {
      stubMonth(spent: [_spend(11000)], limits: [_budget(10000)]);
      when(() => budgets.getForMonth(any(), any())).thenAnswer(
        (_) async => const Err(DatabaseFailure('down')),
      );
      await evaluator.evaluate(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.keys(), isEmpty);
    });

    test('a category without a stored name is skipped', () async {
      stubMonth(
        spent: [_spend(9000, category: 9)],
        limits: [_budget(10000, category: 9)],
      );
      await evaluator.evaluate(now: _now);
      expect(dispatched, isEmpty);
    });
  });

  group('seeding and pruning', () {
    final categories2 = [
      _category(1, 'Comida', en: 'Food'),
      _category(2, 'Lazer', en: 'Fun'),
    ];

    void stubOverspend() => stubMonth(
      spent: [_spend(8500), _spend(12000, category: 2)],
      limits: [_budget(10000), _budget(10000, category: 2)],
      names: categories2,
    );

    BudgetAlertEvaluator another() => BudgetAlertEvaluator(
      transactions,
      budgets,
      categories,
      alerts,
      dispatcher,
      prefs,
      store,
    );

    test('the first start seeds crossed thresholds silently', () async {
      stubOverspend();
      await evaluator.start(now: _now);
      await evaluator.dispose();

      expect(dispatched, isEmpty);
      expect(
        await alerts.keys(),
        containsAll([
          budgetAlertKey(2026, 10, 1, 80),
          budgetAlertKey(2026, 10, 2, 80),
          budgetAlertKey(2026, 10, 2, 100),
          budgetSeededKey(2026, 10),
        ]),
      );
      expect(
        await alerts.contains(budgetAlertKey(2026, 10, 1, 100)),
        isFalse,
      );
    });

    test('a second start in the same month seeds nothing', () async {
      stubOverspend();
      await evaluator.start(now: _now);
      await evaluator.dispose();
      final second = another();
      await second.start(now: _now);
      await second.dispose();

      verify(() => transactions.getByMonth(any(), any())).called(1);
    });

    test('seeded thresholds do not alert later, new ones do', () async {
      stubOverspend();
      await evaluator.start(now: _now);
      await evaluator.evaluate(now: _now);
      expect(dispatched, isEmpty);

      stubMonth(
        spent: [_spend(10500), _spend(12000, category: 2)],
        limits: [_budget(10000), _budget(10000, category: 2)],
        names: categories2,
      );
      await evaluator.evaluate(now: _now);
      await evaluator.dispose();
      expect(dispatched.map((p) => p.entityId), [1]);
      expect(dispatched.single.count, 100);
    });

    test('start does not seed while the kind is disabled', () async {
      await prefs.save(
        prefs.load().withEnabled(NotificationKind.budgetAlert, value: false),
      );
      stubOverspend();
      await evaluator.start(now: _now);
      await evaluator.dispose();
      expect(await alerts.keys(), isEmpty);
    });

    test(
      'reseedAfterImport rebuilds budget markers, keeps goal ones',
      () async {
        await alerts.addAll([
          budgetAlertKey(2026, 10, 9, 80),
          budgetSeededKey(2026, 10),
          'gf:3:2026-10-12',
        ]);
        stubOverspend();
        await evaluator.reseedAfterImport(now: _now);

        final keys = await alerts.keys();
        expect(keys, isNot(contains(budgetAlertKey(2026, 10, 9, 80))));
        expect(keys, contains('gf:3:2026-10-12'));
        expect(keys, contains(budgetAlertKey(2026, 10, 2, 100)));
        expect(keys, contains(budgetSeededKey(2026, 10)));
        expect(dispatched, isEmpty);
      },
    );

    test('start prunes stale markers and keeps current ones', () async {
      await alerts.addAll([
        'b:2026-07:1:80',
        'b:2026-08:1:80',
        'seeded:2026-09',
        'gf:1:2026-08-10',
        'gf:1:2026-09-14',
        'gs:2:2026-08-24',
        'gs:2:2026-01-05',
        budgetAlertKey(2026, 10, 1, 80),
      ]);
      stubMonth(spent: [], limits: []);
      await evaluator.start(now: _now);
      await evaluator.dispose();

      final keys = await alerts.keys();
      expect(keys, isNot(contains('b:2026-07:1:80')));
      expect(keys, isNot(contains('seeded:2026-09')));
      expect(keys, isNot(contains('gf:1:2026-08-10')));
      expect(keys, isNot(contains('gs:2:2026-01-05')));
      expect(keys, contains('b:2026-08:1:80'));
      expect(keys, contains('gf:1:2026-09-14'));
      expect(keys, contains('gs:2:2026-08-24'));
      expect(keys, contains(budgetAlertKey(2026, 10, 1, 80)));
    });
  });

  group('start', () {
    test('a change burst evaluates once after the debounce', () async {
      final saved = BudgetAlertEvaluator.debounceDuration;
      BudgetAlertEvaluator.debounceDuration = const Duration(milliseconds: 20);
      addTearDown(() => BudgetAlertEvaluator.debounceDuration = saved);
      final changes = StreamController<void>.broadcast();
      addTearDown(changes.close);
      when(() => transactions.watchChanges()).thenAnswer((_) => changes.stream);
      await build();
      stubMonth(spent: [_spend(9000)], limits: [_budget(10000)]);

      await evaluator.start();
      clearInteractions(transactions); // forget the start-up seeding read
      changes
        ..add(null)
        ..add(null)
        ..add(null);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await evaluator.dispose();

      verify(() => transactions.getByMonth(any(), any())).called(1);
    });

    test('start does not evaluate on its own', () async {
      stubMonth(spent: [_spend(9000)], limits: [_budget(10000)]);
      await evaluator.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await evaluator.dispose();
      expect(dispatched, isEmpty);
    });
  });
}
