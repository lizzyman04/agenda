import 'package:agenda/application/notifications/goal_alert_evaluator.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/infrastructure/notifications/prefs/alert_state_store_impl.dart';
import 'package:agenda/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart';
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGoals extends Mock implements GoalRepository {}

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockDispatcher extends Mock implements ImmediateAlertDispatcher {}

// The Monday of this week is 2026-10-12. Created 09-01, due 11-01: about 48
// percent of the time has passed, so a goal with nothing saved is off track.
final DateTime _now = DateTime(2026, 10, 16, 12);
const String _week = '2026-10-12';

SavingsGoal _goal(
  int id, {
  int saved = 0,
  bool completed = false,
  DateTime? deadline,
  bool noDeadline = false,
  DateTime? deletedAt,
}) => SavingsGoal(
  id: id,
  title: 'Trip $id',
  targetAmountCents: 100000,
  contributions: [
    if (saved > 0) SavingsGoalContribution(amountCents: saved, date: _now),
  ],
  isCompleted: completed,
  deadline: noDeadline ? null : (deadline ?? DateTime(2026, 11)),
  deletedAt: deletedAt,
  createdAt: DateTime(2026, 9),
  updatedAt: DateTime(2026, 9),
);

Transaction _tagged(int goalId, int cents) => Transaction(
  id: 1,
  type: TransactionType.income,
  amountCents: cents,
  categoryId: 1,
  date: _now,
  createdAt: _now,
  updatedAt: _now,
  linkedGoalId: goalId,
);

void main() {
  late _MockGoals goals;
  late _MockTransactions transactions;
  late _MockDispatcher dispatcher;
  late NotificationPrefsRepositoryImpl prefs;
  late AlertStateStoreImpl alerts;
  late GoalAlertEvaluator evaluator;
  late List<PlannedNotification> dispatched;

  void stubGoals(
    List<SavingsGoal> list, [
    List<Transaction> tagged = const [],
  ]) {
    when(() => goals.getActiveGoals()).thenAnswer((_) async => Success(list));
    when(
      () => transactions.getAllTransactionsForAggregates(),
    ).thenAnswer((_) async => Success(tagged));
  }

  setUpAll(() {
    registerFallbackValue(
      PlannedNotification(
        kind: NotificationKind.goalOffTrack,
        id: 1,
        fireAt: DateTime(2026),
      ),
    );
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    goals = _MockGoals();
    transactions = _MockTransactions();
    dispatcher = _MockDispatcher();
    prefs = NotificationPrefsRepositoryImpl(store);
    alerts = AlertStateStoreImpl(store);
    dispatched = [];
    when(
      () => dispatcher.dispatch(any(), now: any(named: 'now')),
    ).thenAnswer((invocation) async {
      dispatched.add(
        invocation.positionalArguments.first as PlannedNotification,
      );
      return true;
    });
    evaluator = GoalAlertEvaluator(
      goals,
      transactions,
      alerts,
      dispatcher,
      prefs,
    );
  });

  group('evaluateOnOpen', () {
    test('an off-track goal alerts once and records the week', () async {
      stubGoals([_goal(1)]);
      await evaluator.evaluateOnOpen(now: _now);
      await evaluator.evaluateOnOpen(now: _now);

      expect(dispatched, hasLength(1));
      final alert = dispatched.single;
      expect(alert.kind, NotificationKind.goalOffTrack);
      expect(alert.subject, 'Trip 1');
      expect(alert.entityId, 1);
      expect(
        decodeNotificationId(alert.id)!.type,
        NotificationIdTypes.goalImmediate,
      );
      expect(isPlannerOwnedId(alert.id), isFalse);
      expect(await alerts.contains('gf:1:$_week'), isTrue);
    });

    test('a new week alerts again', () async {
      stubGoals([_goal(1)]);
      await evaluator.evaluateOnOpen(now: _now);
      await evaluator.evaluateOnOpen(now: DateTime(2026, 10, 20, 9));
      expect(dispatched, hasLength(2));
    });

    test('a scheduled marker for this week suppresses the alert', () async {
      await alerts.add('gs:1:$_week');
      stubGoals([_goal(1)]);
      await evaluator.evaluateOnOpen(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.contains('gf:1:$_week'), isFalse);
    });

    test('goals that are not off track dispatch nothing', () async {
      stubGoals([
        _goal(1, completed: true),
        _goal(2, noDeadline: true),
        _goal(3, saved: 80000),
        _goal(4, deletedAt: DateTime(2026, 10)),
      ]);
      await evaluator.evaluateOnOpen(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.keys(), isEmpty);
    });

    test('tagged transactions count towards the saved amount', () async {
      stubGoals([_goal(1)], [_tagged(1, 80000)]);
      await evaluator.evaluateOnOpen(now: _now);
      expect(dispatched, isEmpty);
    });

    test('a disabled kind dispatches nothing and writes no key', () async {
      await prefs.save(
        prefs.load().withEnabled(NotificationKind.goalOffTrack, value: false),
      );
      stubGoals([_goal(1)]);
      await evaluator.evaluateOnOpen(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.keys(), isEmpty);
    });

    test('a repository error returns quietly', () async {
      stubGoals([_goal(1)]);
      when(() => goals.getActiveGoals()).thenAnswer(
        (_) async => const Err(DatabaseFailure('down')),
      );
      await evaluator.evaluateOnOpen(now: _now);
      expect(dispatched, isEmpty);
      expect(await alerts.keys(), isEmpty);
    });
  });

  group('reseedAfterImport', () {
    test('clears goal markers and marks off-track goals silently', () async {
      await alerts.addAll(['gf:9:2026-10-05', 'gs:9:$_week', 'b:2026-10:1:80']);
      stubGoals([_goal(1), _goal(2, saved: 80000)]);
      await evaluator.reseedAfterImport(now: _now);

      final keys = await alerts.keys();
      expect(keys, isNot(contains('gf:9:2026-10-05')));
      expect(keys, isNot(contains('gs:9:$_week')));
      expect(keys, contains('gf:1:$_week'));
      expect(keys, isNot(contains('gf:2:$_week')));
      expect(keys, contains('b:2026-10:1:80'));
      expect(dispatched, isEmpty);
    });

    test('the seeded goal does not alert on the next open', () async {
      stubGoals([_goal(1)]);
      await evaluator.reseedAfterImport(now: _now);
      await evaluator.evaluateOnOpen(now: _now);
      expect(dispatched, isEmpty);
    });
  });
}
