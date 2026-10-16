import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/task_reminder_planner.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_report.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_runner.dart';
import 'package:agenda/infrastructure/notifications/sync/snapshot_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  PlannerInput inputOf(List<Item> items, {NotificationPrefs? prefs}) =>
      PlannerInput(
        now: _now,
        prefs: prefs ?? NotificationPrefs.defaults(),
        items: items,
      );

  setUp(() {
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
    runner = ReconcileRunner(
      loader,
      const ReminderPlanner([TaskReminderPlanner()]),
      const NotificationContentBuilder(),
      gateway,
      permissions,
    );
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
    final other = ReconcileRunner(
      loader,
      const ReminderPlanner([TaskReminderPlanner()]),
      const NotificationContentBuilder(),
      failing,
      permissions,
    );

    final report = await other.run(now: _now, reason: ReconcileReason.appStart);

    expect(report.aborted, isTrue);
    expect(failing.scheduleCalls, 0);
    expect(failing.cancelledIds, isEmpty);
  });
}
