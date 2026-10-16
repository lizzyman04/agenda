import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/notifications/rules/tap_target.dart';
import 'package:flutter_test/flutter_test.dart';

String _payload(NotificationKind kind, {int id = 7}) => encodePayload(
  kind: kind,
  entityId: id,
  fireAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  exact: true,
);

void main() {
  group('resolveTapTarget', () {
    test('task and recurring task reminders open the task', () {
      for (final kind in [
        NotificationKind.taskReminder,
        NotificationKind.recurringTaskReminder,
      ]) {
        final target = resolveTapTarget(_payload(kind, id: 42));
        expect(target, isA<OpenTask>());
        expect((target as OpenTask).taskId, 42);
      }
    });

    test('a briefing opens the tasks tab', () {
      expect(
        resolveTapTarget(_payload(NotificationKind.morningBriefing)),
        isA<OpenBriefing>(),
      );
    });

    test('budget, debt and payment notifications open their sub-tab', () {
      expect(
        resolveTapTarget(_payload(NotificationKind.budgetAlert)),
        isA<OpenBudgets>(),
      );
      expect(
        resolveTapTarget(_payload(NotificationKind.debtReminder)),
        isA<OpenDebts>(),
      );
      expect(
        resolveTapTarget(_payload(NotificationKind.recurringPayment)),
        isA<OpenPayments>(),
      );
    });

    test('a goal notification opens that goal', () {
      final target = resolveTapTarget(
        _payload(NotificationKind.goalOffTrack, id: 9),
      );
      expect(target, isA<OpenGoal>());
      expect((target as OpenGoal).goalId, 9);
    });

    test('a quote only opens the app', () {
      expect(
        resolveTapTarget(_payload(NotificationKind.motivationalQuote)),
        isA<AppOnly>(),
      );
    });

    test('null, empty, malformed, wrong version and unknown kind', () {
      for (final raw in [
        null,
        '',
        'garbage',
        'v2|tk|1|1700000000|e',
        'v1|zz|1|1700000000|e',
        'v1|tk|-1|1700000000|e',
        'v1|tk|1|1700000000|x',
        'v1|tk|1|1700000000',
        'v1|tk|1|1700000000|e|extra',
        'v1|tk|${'9' * 80}|1|e',
      ]) {
        expect(resolveTapTarget(raw), isA<AppOnly>(), reason: '$raw');
      }
    });
  });
}
