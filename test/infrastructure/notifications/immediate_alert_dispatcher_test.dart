import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart';
import 'package:agenda/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart';
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart';
import 'package:agenda/infrastructure/notifications/sync/permission_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_gateway.dart';

PlannedNotification _alert({
  NotificationKind kind = NotificationKind.budgetAlert,
}) => PlannedNotification(
  kind: kind,
  id: 200000043,
  fireAt: DateTime(2026, 10, 16, 12),
  entityId: 4,
  subject: 'Food',
  count: 80,
);

void main() {
  late FakeNotificationGateway gateway;
  late FakeNotificationPermissionService permissions;
  late NotificationPrefsRepositoryImpl prefs;
  late ImmediateAlertDispatcher dispatcher;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    gateway = FakeNotificationGateway();
    permissions = FakeNotificationPermissionService();
    prefs = NotificationPrefsRepositoryImpl(store);
    dispatcher = ImmediateAlertDispatcher(
      gateway,
      prefs,
      permissions,
      PermissionGate(permissions, store),
      const NotificationContentBuilder(),
      store,
    );
  });

  test('outside quiet hours the alert is shown now', () async {
    final now = DateTime(2026, 10, 16, 12);
    expect(await dispatcher.dispatch(_alert(), now: now), isTrue);
    expect(gateway.shown, hasLength(1));
    expect(gateway.scheduled, isEmpty);
  });

  test('inside quiet hours it is scheduled for the window end', () async {
    final now = DateTime(2026, 10, 16, 23);
    expect(await dispatcher.dispatch(_alert(), now: now), isTrue);
    expect(gateway.shown, isEmpty);
    expect(gateway.scheduled, hasLength(1));
    expect(gateway.scheduled.values.single.fireAt, DateTime(2026, 10, 17, 7));
  });

  test('quiet hours switched off shows even late at night', () async {
    await prefs.save(
      prefs.load().copyWith(quietHoursEnabled: false),
    );
    final now = DateTime(2026, 10, 16, 23);
    await dispatcher.dispatch(_alert(), now: now);
    expect(gateway.shown, hasLength(1));
    expect(gateway.scheduled, isEmpty);
  });

  test('a disabled kind does nothing', () async {
    await prefs.save(
      prefs.load().withEnabled(NotificationKind.budgetAlert, value: false),
    );
    final result = await dispatcher.dispatch(
      _alert(),
      now: DateTime(2026, 10, 16, 12),
    );
    expect(result, isFalse);
    expect(gateway.shown, isEmpty);
    expect(gateway.scheduled, isEmpty);
    expect(permissions.notificationRequests, 0);
  });

  test('the permission is requested once across two dispatches', () async {
    final now = DateTime(2026, 10, 16, 12);
    await dispatcher.dispatch(_alert(), now: now);
    await dispatcher.dispatch(_alert(), now: now);
    expect(permissions.notificationRequests, 1);
    expect(gateway.shown, hasLength(2));
  });

  test('without prompting, a denied permission raises nothing', () async {
    final store = await SharedPreferences.getInstance();
    final result = await dispatcher.dispatch(
      _alert(),
      now: DateTime(2026, 10, 16, 12),
      promptIfNeeded: false,
    );
    expect(result, isFalse);
    expect(gateway.shown, isEmpty);
    expect(gateway.scheduled, isEmpty);
    expect(permissions.notificationRequests, 0);
    expect(PermissionGate(permissions, store).asked, isFalse);
  });

  test('without prompting, a granted permission shows the alert', () async {
    permissions.permission = NotificationPermission.granted;
    final now = DateTime(2026, 10, 16, 12);
    expect(
      await dispatcher.dispatch(_alert(), now: now, promptIfNeeded: false),
      isTrue,
    );
    expect(gateway.shown, hasLength(1));
    expect(permissions.notificationRequests, 0);
  });

  test('without prompting, a granted permission defers in quiet hours',
      () async {
    permissions.permission = NotificationPermission.granted;
    final now = DateTime(2026, 10, 16, 23);
    expect(
      await dispatcher.dispatch(_alert(), now: now, promptIfNeeded: false),
      isTrue,
    );
    expect(gateway.scheduled.values.single.fireAt, DateTime(2026, 10, 17, 7));
    expect(permissions.notificationRequests, 0);
  });

  test('the payload decodes to the budget alert kind', () async {
    await dispatcher.dispatch(_alert(), now: DateTime(2026, 10, 16, 12));
    final payload = decodePayload(gateway.shown.single.payload);
    expect(payload, isNotNull);
    expect(payload!.kind, NotificationKind.budgetAlert);
    expect(payload.entityId, 4);
  });

  test('the text names the category and never an amount', () async {
    await dispatcher.dispatch(_alert(), now: DateTime(2026, 10, 16, 12));
    final request = gateway.shown.single;
    expect(request.title, contains('Food'));
    expect('${request.title} ${request.body}', isNot(contains(r'$')));
  });
}
