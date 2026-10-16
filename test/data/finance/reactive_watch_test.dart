// Real-Isar coverage for the `watchLazy` streams behind the budget and
// recurring-payment repositories' `watchChanges()` (plan 04-09).
//
// The notification coordinator and the budget alert evaluator re-run when
// these collections change, so a stream that silently never fires would leave
// reminders and alerts stale with no error. Only `IsarService` (a thin
// wrapper whose `db` getter the DAOs call) is mocked; the collection and its
// change watcher are real.

import 'dart:async';

import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_dao.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_dao.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

const _emitTimeout = Duration(seconds: 5);

/// Counts events on the stream from the moment of subscription.
///
/// Subscribing before the write is what makes the test meaningful: a lazy
/// watcher only reports changes made while it is listening.
class _EventCounter {
  _EventCounter(Stream<void> stream) {
    _sub = stream.listen((_) {
      count++;
      _waiter?.complete();
    });
  }

  late final StreamSubscription<void> _sub;
  Completer<void>? _waiter;
  int count = 0;

  /// Completes once at least [n] events have been seen.
  Future<void> untilCount(int n) async {
    while (count < n) {
      _waiter = Completer<void>();
      await _waiter!.future.timeout(_emitTimeout);
    }
  }

  Future<void> cancel() => _sub.cancel();
}

BudgetModel _budget({required int categoryId, required int limitCents}) {
  final now = DateTime(2026, 3);
  return BudgetModel()
    ..categoryId = categoryId
    ..month = 3
    ..year = 2026
    ..limitCents = limitCents
    ..createdAt = now
    ..updatedAt = now;
}

RecurringPaymentModel _payment(String title) {
  final now = DateTime(2026, 3);
  return RecurringPaymentModel()
    ..title = title
    ..amountCents = 500
    ..categoryId = 1
    ..cycle = RecurringCycle.monthly
    ..nextDueDate = now
    ..createdAt = now
    ..updatedAt = now;
}

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late MockIsarService mockIsarService;

  setUp(() async {
    harness = IsarTestHarness();
    isar = await harness.open([BudgetModelSchema, RecurringPaymentModelSchema]);
    mockIsarService = MockIsarService();
    when(() => mockIsarService.db).thenReturn(isar);
  });

  tearDown(() async {
    await harness.close();
  });

  group('BudgetDao.watchLazy', () {
    test('emits after each save', () async {
      final dao = BudgetDao(mockIsarService);
      final events = _EventCounter(dao.watchLazy());

      await dao.save(_budget(categoryId: 1, limitCents: 1000));
      await events.untilCount(1);

      await dao.save(_budget(categoryId: 2, limitCents: 2000));
      await events.untilCount(2);

      expect(events.count, greaterThanOrEqualTo(2));
      await events.cancel();
    });
  });

  group('RecurringPaymentDao.watchLazy', () {
    test('emits after each save', () async {
      final dao = RecurringPaymentDao(mockIsarService);
      final events = _EventCounter(dao.watchLazy());

      await dao.save(_payment('rent'));
      await events.untilCount(1);

      await dao.save(_payment('gym'));
      await events.untilCount(2);

      expect(events.count, greaterThanOrEqualTo(2));
      await events.cancel();
    });
  });
}
