import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/notifications/rules/quiet_hours.dart';
import 'package:agenda/domain/notifications/rules/schedule_diff.dart';
import 'package:flutter_test/flutter_test.dart';

const int _start = 22 * 60;
const int _end = 7 * 60;

DateTime _defer(DateTime t) =>
    deferOutOfQuietHours(t, startMinutes: _start, endMinutes: _end);

void _expectAt(DateTime actual, int day, int hour, int minute) {
  expect(actual.day, day);
  expect(actual.hour, hour);
  expect(actual.minute, minute);
}

ScheduleRequest _request(PlannedNotification p, {String? title}) =>
    ScheduleRequest(
      id: p.id,
      kind: p.kind,
      fireAt: p.fireAt,
      title: title ?? 'title ${p.id}',
      body: 'body',
      payload: 'v1|${p.kind.code}|${p.entityId}|${p.fireAt.day}|e',
      exact: true,
    );

PendingNotification _pending(ScheduleRequest r) => PendingNotification(
  id: r.id,
  title: r.title,
  body: r.body,
  payload: r.payload,
);

PlannedNotification _planned(int entityId, DateTime fireAt) =>
    PlannedNotification(
      kind: NotificationKind.taskReminder,
      id: notificationId(base: 10, entityId: entityId, type: 0),
      fireAt: fireAt,
      entityId: entityId,
    );

void main() {
  group('notificationId', () {
    test('derives base * 10M + entity * 10 + type', () {
      expect(notificationId(base: 10, entityId: 5, type: 0), 100000050);
    });

    test('task and debt with the same entity id differ', () {
      final task = notificationId(base: 10, entityId: 7, type: 0);
      final debt = notificationId(base: 20, entityId: 7, type: 0);
      expect(task, isNot(debt));
    });

    test('largest legal id fits int32', () {
      final id = notificationId(base: 30, entityId: 999999, type: 9);
      expect(id, lessThan(2147483647));
    });

    test('entity id 1000000 throws RangeError', () {
      expect(
        () => notificationId(base: 10, entityId: 1000000, type: 0),
        throwsRangeError,
      );
    });

    test('type outside 0..9 throws RangeError', () {
      expect(
        () => notificationId(base: 10, entityId: 1, type: 10),
        throwsRangeError,
      );
    });

    test('grid of 360 ids round-trips with no collisions', () {
      final seen = <int>{};
      for (final base in [10, 20, 30]) {
        for (var e = 0; e < 12; e++) {
          for (var type = 0; type < 10; type++) {
            final id = notificationId(base: base, entityId: e, type: type);
            expect(seen.add(id), isTrue);
            final parts = decodeNotificationId(id);
            expect(parts?.base, base);
            expect(parts?.entityId, e);
            expect(parts?.type, type);
          }
        }
      }
      expect(seen.length, 360);
    });

    test('isPlannerOwnedId excludes finance types 3, 4 and 5', () {
      for (final type in [3, 4, 5]) {
        final id = notificationId(base: 20, entityId: 1, type: type);
        expect(isPlannerOwnedId(id), isFalse);
      }
      expect(isPlannerOwnedId(100000050), isTrue);
      expect(
        isPlannerOwnedId(notificationId(base: 30, entityId: 3, type: 1)),
        isTrue,
      );
      expect(
        isPlannerOwnedId(notificationId(base: 20, entityId: 3, type: 2)),
        isTrue,
      );
      expect(isPlannerOwnedId(7), isFalse);
    });
  });

  group('deferOutOfQuietHours 22:00-07:00', () {
    test('21:59 is unchanged', () {
      final t = DateTime(2026, 10, 12, 21, 59);
      expect(_defer(t), t);
    });

    test('22:00 and 23:30 move to 07:00 the next day', () {
      _expectAt(_defer(DateTime(2026, 10, 12, 22)), 13, 7, 0);
      _expectAt(_defer(DateTime(2026, 10, 12, 23, 30)), 13, 7, 0);
    });

    test('03:00 and 06:59 move to 07:00 the same day', () {
      _expectAt(_defer(DateTime(2026, 10, 12, 3)), 12, 7, 0);
      _expectAt(_defer(DateTime(2026, 10, 12, 6, 59)), 12, 7, 0);
    });

    test('07:00 and 12:00 are unchanged', () {
      final seven = DateTime(2026, 10, 12, 7);
      final noon = DateTime(2026, 10, 12, 12);
      expect(_defer(seven), seven);
      expect(_defer(noon), noon);
    });

    test('late evening on the last day of a month rolls over', () {
      final result = _defer(DateTime(2026, 10, 31, 23));
      expect(result.month, 11);
      _expectAt(result, 1, 7, 0);
    });
  });

  group('deferOutOfQuietHours non-wrapping and degenerate windows', () {
    DateTime defer(DateTime t) =>
        deferOutOfQuietHours(t, startMinutes: 13 * 60, endMinutes: 15 * 60);

    test('14:00 moves to 15:00 the same day, 15:00 is unchanged', () {
      _expectAt(defer(DateTime(2026, 10, 12, 14)), 12, 15, 0);
      final edge = DateTime(2026, 10, 12, 15);
      expect(defer(edge), edge);
    });

    test('equal start and end never changes anything', () {
      final t = DateTime(2026, 10, 12, 3);
      expect(
        deferOutOfQuietHours(t, startMinutes: 60, endMinutes: 60),
        t,
      );
    });
  });

  group('pipeline: defer, request, diff', () {
    final planned = [
      _planned(1, DateTime(2026, 10, 12, 9)),
      _planned(2, DateTime(2026, 10, 12, 23)),
      _planned(3, DateTime(2026, 10, 13, 10)),
    ];
    final deferred = [
      for (final p in planned) p.copyWith(fireAt: _defer(p.fireAt)),
    ];
    final desired = [for (final p in deferred) _request(p)];

    test('the 23:00 entry is deferred to 07:00 next day', () {
      _expectAt(deferred[1].fireAt, 13, 7, 0);
    });

    test('everything is scheduled against empty pending', () {
      final diff = diffSchedules(desired: desired, pending: const []);
      expect(diff.toSchedule.length, 3);
      expect(diff.cancelIds, isEmpty);
    });

    test('unchanged state produces an empty diff', () {
      final diff = diffSchedules(
        desired: desired,
        pending: [for (final r in desired) _pending(r)],
      );
      expect(diff.cancelIds, isEmpty);
      expect(diff.toSchedule, isEmpty);
      expect(diff.isEmpty, isTrue);
    });

    test('a changed title schedules exactly that id', () {
      final changed = [
        desired[0],
        _request(deferred[1], title: 'renamed'),
        desired[2],
      ];
      final diff = diffSchedules(
        desired: changed,
        pending: [for (final r in desired) _pending(r)],
      );
      expect(diff.toSchedule.map((r) => r.id), [desired[1].id]);
      expect(diff.cancelIds, isEmpty);
    });

    test('a dropped desired entry is cancelled', () {
      final diff = diffSchedules(
        desired: [desired[0], desired[2]],
        pending: [for (final r in desired) _pending(r)],
      );
      expect(diff.cancelIds, [desired[1].id]);
      expect(diff.toSchedule, isEmpty);
    });

    test('duplicate desired ids keep the first', () {
      final first = _request(deferred[0]);
      final second = _request(deferred[0], title: 'other');
      final diff = diffSchedules(
        desired: [first, second],
        pending: const [],
      );
      expect(diff.toSchedule.length, 1);
      expect(diff.toSchedule.single.title, first.title);
    });
  });
}
