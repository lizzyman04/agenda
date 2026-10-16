import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/task_reminder_planner.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart';
import 'package:agenda/infrastructure/notifications/prefs/alert_state_store_impl.dart';
import 'package:agenda/infrastructure/notifications/sync/permission_gate.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_report.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_runner.dart';
import 'package:agenda/infrastructure/notifications/sync/snapshot_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_gateway.dart';

class _MockLoader extends Mock implements SnapshotLoader {}

/// Counts schedule calls so idempotence can be asserted.
class _CountingGateway extends FakeNotificationGateway {
  int scheduleCalls = 0;

  @override
  AsyncResult<void> schedule(ScheduleRequest request) {
    scheduleCalls++;
    return super.schedule(request);
  }
}

class _PendingFailsGateway extends _CountingGateway {
  @override
  AsyncResult<List<PendingNotification>> pending() async =>
      const Err(NotificationFailure('pending down'));
}

/// Always plans one goal off-track alert, as the real planner would.
class _GoalStub implements KindPlanner {
  @override
  List<PlannedNotification> plan(PlannerInput input) => [
    PlannedNotification(
      kind: NotificationKind.goalOffTrack,
      id: notificationId(
        base: NotificationKind.goalOffTrack.idBase,
        entityId: 3,
        type: NotificationKind.goalOffTrack.idType,
      ),
      fireAt: DateTime(2026, 10, 19, 9),
      entityId: 3,
      subject: 'Trip',
    ),
  ];
}

final DateTime _now = DateTime(2026, 10, 12, 8);

Item _task(int id, {String title = 'Write report', int day = 14}) => Item(
  id: id,
  type: ItemType.task,
  title: title,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dueDate: DateTime(2026, 10, day),
  dueTimeMinutes: 600,
);

int _taskNotificationId(int itemId) => notificationId(
  base: NotificationKind.taskReminder.idBase,
  entityId: itemId,
  type: NotificationKind.taskReminder.idType,
);

void main() {
  late _MockLoader loader;
  late _CountingGateway gateway;
  late FakeNotificationPermissionService permissions;
  late PlannerInput input;
  late ReconcileRunner runner;
  late SharedPreferences store;
  late AlertStateStoreImpl alerts;

  PlannerInput inputOf(List<Item> items, {NotificationPrefs? prefs}) =>
      PlannerInput(
        now: _now,
        prefs: prefs ?? NotificationPrefs.defaults(),
        items: items,
      );

  ReconcileRunner runnerWith(
    LocalNotificationGateway gw, [
    List<KindPlanner> planners = const [TaskReminderPlanner()],
  ]) => ReconcileRunner(
    loader,
    ReminderPlanner(planners),
    const NotificationContentBuilder(),
    gw,
    permissions,
    PermissionGate(permissions, store),
    alerts,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SharedPreferences.getInstance();
    alerts = AlertStateStoreImpl(store);
    loader = _MockLoader();
    gateway = _CountingGateway();
    permissions = FakeNotificationPermissionService();
    input = inputOf([_task(7)]);
    when(
      () => loader.load(
        now: any(named: 'now'),
        slotBudget: any(named: 'slotBudget'),
      ),
    ).thenAnswer((_) async => Success(input));
    runner = runnerWith(gateway);
  });

  Future<ReconcileReport> reconcile([
    ReconcileReason reason = ReconcileReason.appStart,
  ]) => runner.run(now: _now, reason: reason);

  test('a due task is scheduled, localised, with the exact payload', () async {
    final report = await reconcile();

    final request = gateway.scheduled[_taskNotificationId(7)]!;
    expect(report.scheduled, 1);
    expect(request.title, 'Task due soon');
    expect(request.body, 'Write report is due at 10:00');
    expect(request.exact, isTrue);
    expect(
      request.payload,
      encodePayload(
        kind: NotificationKind.taskReminder,
        entityId: 7,
        fireAt: DateTime(2026, 10, 14, 9, 30),
        exact: true,
      ),
    );
  });

  test('a second run schedules and cancels nothing', () async {
    await reconcile();
    final callsAfterFirst = gateway.scheduleCalls;

    final report = await reconcile(ReconcileReason.appResume);

    expect(gateway.scheduleCalls, callsAfterFirst);
    expect(gateway.cancelledIds, isEmpty);
    expect(report.scheduled, 0);
    expect(report.cancelled, 0);
    expect(report.failures, 0);
  });

  test('changing a title reschedules only that id', () async {
    input = inputOf([_task(7), _task(8, title: 'Pay rent', day: 15)]);
    await reconcile();
    gateway.scheduleCalls = 0;
    input = inputOf([_task(7), _task(8, title: 'Pay the rent', day: 15)]);

    final report = await reconcile();

    expect(gateway.scheduleCalls, 1);
    expect(report.scheduled, 1);
    expect(
      gateway.scheduled[_taskNotificationId(8)]!.body,
      contains('the rent'),
    );
    expect(gateway.cancelledIds, isEmpty);
  });

  test('a removed task is cancelled', () async {
    await reconcile();
    input = inputOf(const []);

    final report = await reconcile(ReconcileReason.dataChange);

    expect(gateway.cancelledIds, [_taskNotificationId(7)]);
    expect(report.cancelled, 1);
    expect(gateway.scheduled, isEmpty);
  });

  test('a disabled kind is cancelled', () async {
    await reconcile();
    input = inputOf(
      [_task(7)],
      prefs: NotificationPrefs.defaults().withEnabled(
        NotificationKind.taskReminder,
        value: false,
      ),
    );

    await reconcile(ReconcileReason.prefsChange);

    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelledIds, [_taskNotificationId(7)]);
  });

  test('an aborted load cancels nothing', () async {
    await reconcile();
    when(
      () => loader.load(
        now: any(named: 'now'),
        slotBudget: any(named: 'slotBudget'),
      ),
    ).thenAnswer((_) async => const Err(DatabaseFailure('read failed')));

    final report = await reconcile(ReconcileReason.dataChange);

    expect(report.aborted, isTrue);
    expect(gateway.cancelledIds, isEmpty);
    expect(gateway.scheduled, hasLength(1));
  });

  test('a failed pending read aborts without touching the schedule', () async {
    final failing = _PendingFailsGateway();
    final other = runnerWith(failing);

    final report = await other.run(now: _now, reason: ReconcileReason.appStart);

    expect(report.aborted, isTrue);
    expect(failing.scheduleCalls, 0);
    expect(failing.cancelledIds, isEmpty);
  });

  group('evaluator-owned alerts', () {
    final budgetId = notificationId(base: 20, entityId: 3, type: 3);

    Future<void> seedBudgetAlert() async {
      await gateway.schedule(
        ScheduleRequest(
          id: budgetId,
          kind: NotificationKind.budgetAlert,
          fireAt: DateTime(2026, 10, 12, 9),
          title: 'Food: 80% of the budget used',
          body: 'You have used 80% of this month\'s limit.',
          payload: encodePayload(
            kind: NotificationKind.budgetAlert,
            entityId: 3,
            fireAt: DateTime(2026, 10, 12, 9),
            exact: true,
          ),
          exact: true,
        ),
      );
    }

    test('a pending budget alert survives the diff', () async {
      await seedBudgetAlert();

      await reconcile();

      expect(gateway.cancelledIds, isEmpty);
      expect(gateway.scheduled, contains(budgetId));
    });

    test('it is cancelled once its kind is switched off', () async {
      await seedBudgetAlert();
      input = inputOf(
        [_task(7)],
        prefs: NotificationPrefs.defaults().withEnabled(
          NotificationKind.budgetAlert,
          value: false,
        ),
      );

      await reconcile(ReconcileReason.prefsChange);

      expect(gateway.cancelledIds, [budgetId]);
    });

    test('an undecodable payload on a foreign id is left alone', () async {
      await gateway.schedule(
        ScheduleRequest(
          id: 5,
          kind: NotificationKind.budgetAlert,
          fireAt: DateTime(2026, 10, 12, 9),
          title: 't',
          body: 'b',
          payload: 'garbage',
          exact: true,
        ),
      );
      input = inputOf(
        const [],
        prefs: NotificationPrefs.defaults().withEnabled(
          NotificationKind.budgetAlert,
          value: false,
        ),
      );

      await reconcile(ReconcileReason.prefsChange);

      expect(gateway.cancelledIds, isEmpty);
      expect(gateway.scheduled, contains(5));
    });
  });

  group('permission gate', () {
    test('a data change that schedules something asks exactly once', () async {
      await reconcile(ReconcileReason.dataChange);
      input = inputOf([_task(7), _task(8, day: 15)]);
      await reconcile(ReconcileReason.dataChange);

      expect(permissions.notificationRequests, 1);
      expect(store.getBool(StorageKeys.notifPermissionAsked), isTrue);
    });

    test('a preference change that schedules something asks', () async {
      await reconcile(ReconcileReason.prefsChange);

      expect(permissions.notificationRequests, 1);
    });

    test('start, resume and import never ask', () async {
      for (final reason in [
        ReconcileReason.appStart,
        ReconcileReason.appResume,
        ReconcileReason.afterImport,
      ]) {
        input = inputOf([_task(7, day: 14 + reason.index)]);
        await reconcile(reason);
      }

      expect(permissions.notificationRequests, 0);
      expect(store.getBool(StorageKeys.notifPermissionAsked), isNull);
    });

    test('a data change with nothing to schedule does not ask', () async {
      input = inputOf(const []);

      await reconcile(ReconcileReason.dataChange);

      expect(permissions.notificationRequests, 0);
    });
  });

  group('exact mode', () {
    test(
      'inexact payloads are upgraded once exact alarms are granted',
      () async {
        permissions.exact = false;
        await reconcile();
        final id = _taskNotificationId(7);
        expect(gateway.scheduled[id]!.exact, isFalse);
        expect(gateway.scheduled[id]!.payload, endsWith('|i'));

        permissions.exact = true;
        final report = await reconcile(ReconcileReason.appResume);

        expect(report.scheduled, 1);
        expect(gateway.scheduled[id]!.exact, isTrue);
        expect(gateway.scheduled[id]!.payload, endsWith('|e'));
      },
    );
  });

  test('a scheduled goal alert records its week marker', () async {
    final goalRunner = runnerWith(gateway, [_GoalStub()]);

    await goalRunner.run(now: _now, reason: ReconcileReason.appStart);

    expect(await alerts.keys(), {'gs:3:2026-10-19'});
  });

  test('one failing id is counted and does not stop the others', () async {
    input = inputOf([_task(7), _task(8, day: 15)]);
    gateway.failScheduleIds.add(_taskNotificationId(7));

    final report = await reconcile();

    expect(report.failures, 1);
    expect(report.scheduled, 1);
    expect(gateway.scheduled, contains(_taskNotificationId(8)));
    expect(gateway.scheduled, isNot(contains(_taskNotificationId(7))));
  });
}
