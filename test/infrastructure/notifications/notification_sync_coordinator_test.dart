import 'dart:async';

import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/infrastructure/notifications/sync/notification_sync_coordinator.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_report.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRunner extends Mock implements ReconcileRunner {}

class _MockItems extends Mock implements ItemRepository {}

class _MockDebts extends Mock implements DebtRepository {}

class _MockGoals extends Mock implements GoalRepository {}

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockPayments extends Mock implements RecurringPaymentRepository {}

class _MockPrefs extends Mock implements NotificationPrefsRepository {}

const Duration _debounce = Duration(milliseconds: 20);
const Duration _settle = Duration(milliseconds: 120);

void main() {
  late _MockRunner runner;
  late StreamController<void> items;
  late StreamController<void> debts;
  late StreamController<void> goals;
  late StreamController<void> transactions;
  late StreamController<void> payments;
  late StreamController<NotificationPrefs> prefs;
  late NotificationSyncCoordinator coordinator;
  late Duration savedDebounce;
  late List<ReconcileReason> reasons;

  setUpAll(() {
    registerFallbackValue(ReconcileReason.appStart);
    registerFallbackValue(DateTime(2026));
  });

  void stubRunner([Future<ReconcileReport> Function()? body]) {
    when(
      () => runner.run(
        now: any(named: 'now'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((invocation) {
      reasons.add(invocation.namedArguments[#reason] as ReconcileReason);
      return body == null ? Future.value(const ReconcileReport()) : body();
    });
  }

  setUp(() {
    savedDebounce = NotificationSyncCoordinator.debounceDuration;
    NotificationSyncCoordinator.debounceDuration = _debounce;
    reasons = [];
    runner = _MockRunner();
    items = StreamController<void>.broadcast();
    debts = StreamController<void>.broadcast();
    goals = StreamController<void>.broadcast();
    transactions = StreamController<void>.broadcast();
    payments = StreamController<void>.broadcast();
    prefs = StreamController<NotificationPrefs>.broadcast();
    final itemRepo = _MockItems();
    final debtRepo = _MockDebts();
    final goalRepo = _MockGoals();
    final txRepo = _MockTransactions();
    final paymentRepo = _MockPayments();
    final prefsRepo = _MockPrefs();
    when(itemRepo.watchChanges).thenAnswer((_) => items.stream);
    when(debtRepo.watchChanges).thenAnswer((_) => debts.stream);
    when(goalRepo.watchChanges).thenAnswer((_) => goals.stream);
    when(txRepo.watchChanges).thenAnswer((_) => transactions.stream);
    when(paymentRepo.watchChanges).thenAnswer((_) => payments.stream);
    when(prefsRepo.watch).thenAnswer((_) => prefs.stream);
    stubRunner();
    coordinator = NotificationSyncCoordinator(
      runner,
      itemRepo,
      debtRepo,
      goalRepo,
      txRepo,
      paymentRepo,
      prefsRepo,
    );
  });

  tearDown(() async {
    NotificationSyncCoordinator.debounceDuration = savedDebounce;
    await coordinator.dispose();
    for (final c in [items, debts, goals, transactions, payments]) {
      await c.close();
    }
    await prefs.close();
  });

  int runs() => reasons.length;

  test('five requests inside the debounce window cause one run', () async {
    for (var i = 0; i < 5; i++) {
      coordinator.requestReconcile(ReconcileReason.dataChange);
    }
    await Future<void>.delayed(_settle);

    expect(runs(), 1);
    expect(reasons.single, ReconcileReason.dataChange);
  });

  test('requests during a run cause exactly one additional run', () async {
    final gate = Completer<ReconcileReport>();
    var first = true;
    stubRunner(() {
      if (!first) return Future.value(const ReconcileReport());
      first = false;
      return gate.future;
    });

    coordinator.requestReconcile(ReconcileReason.dataChange);
    await Future<void>.delayed(_settle);
    expect(runs(), 1);

    for (var i = 0; i < 3; i++) {
      coordinator.requestReconcile(ReconcileReason.prefsChange);
      await Future<void>.delayed(_settle);
    }
    expect(runs(), 1, reason: 'nothing starts while a run is executing');

    gate.complete(const ReconcileReport());
    await Future<void>.delayed(_settle);

    expect(runs(), 2);
    expect(reasons.last, ReconcileReason.prefsChange);
  });

  test('reconcileNow completes after a fresh run', () async {
    final gate = Completer<ReconcileReport>();
    stubRunner(() => gate.future);
    var done = false;

    final future = coordinator
        .reconcileNow(ReconcileReason.afterImport)
        .then((_) => done = true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(done, isFalse);
    expect(runs(), 1);

    gate.complete(const ReconcileReport());
    await future;

    expect(done, isTrue);
    expect(reasons.single, ReconcileReason.afterImport);
  });

  test('a runner that throws never escapes', () async {
    stubRunner(() => throw StateError('boom'));

    coordinator.requestReconcile(ReconcileReason.dataChange);
    await Future<void>.delayed(_settle);
    await expectLater(
      coordinator.reconcileNow(ReconcileReason.appResume),
      completes,
    );

    expect(runs(), 2);
  });

  test('dispose cancels the pending timer', () async {
    coordinator.requestReconcile(ReconcileReason.dataChange);
    await coordinator.dispose();
    await Future<void>.delayed(_settle);

    expect(runs(), 0);
  });

  test('requests after dispose do nothing', () async {
    await coordinator.dispose();

    coordinator.requestReconcile(ReconcileReason.dataChange);
    await coordinator.reconcileNow(ReconcileReason.appResume);
    await Future<void>.delayed(_settle);

    expect(runs(), 0);
  });

  test('truncatedCount emits the runner figure after each run', () async {
    var next = 3;
    stubRunner(() async => ReconcileReport(truncated: next++));
    final seen = <int>[];
    final sub = coordinator.truncatedCount.listen(seen.add);

    await coordinator.reconcileNow(ReconcileReason.appStart);
    await coordinator.reconcileNow(ReconcileReason.dataChange);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    expect(seen, [3, 4]);
  });

  test('start subscribes to every source and reconciles once', () async {
    await coordinator.start();

    expect(runs(), 1);
    expect(reasons.single, ReconcileReason.appStart);
    for (final c in [items, debts, goals, transactions, payments, prefs]) {
      expect(c.hasListener, isTrue);
    }

    items.add(null);
    await Future<void>.delayed(_settle);
    expect(reasons.last, ReconcileReason.dataChange);
    expect(runs(), 2);

    prefs.add(NotificationPrefs.defaults());
    await Future<void>.delayed(_settle);
    expect(reasons.last, ReconcileReason.prefsChange);
    expect(runs(), 3);
  });

  test('every data source triggers a reconcile', () async {
    await coordinator.start();
    var expected = 1;
    for (final c in [items, debts, goals, transactions, payments]) {
      c.add(null);
      await Future<void>.delayed(_settle);
      expected++;
      expect(runs(), expected);
    }
  });

  test('start is idempotent', () async {
    await coordinator.start();
    await coordinator.start();

    expect(runs(), 1);
  });
}
