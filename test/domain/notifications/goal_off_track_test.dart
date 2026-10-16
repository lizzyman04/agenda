import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/goal_off_track_planner.dart';
import 'package:agenda/domain/notifications/planning/goal_alert_keys.dart';
import 'package:agenda/domain/notifications/planning/goal_off_track.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

bool _offTrack(
  int saved, {
  int target = 1000,
  DateTime? created,
  DateTime? deadline,
  DateTime? asOf,
  bool noDeadline = false,
}) => isGoalOffTrack(
  savedCents: saved,
  targetCents: target,
  createdAt: created ?? DateTime(2026),
  deadline: noDeadline ? null : (deadline ?? DateTime(2026, 1, 11)),
  asOf: asOf ?? DateTime(2026, 1, 6),
);

SavingsGoal _goal({
  int id = 7,
  int target = 1000,
  DateTime? deadline,
  bool noDeadline = false,
  bool isCompleted = false,
  DateTime? deletedAt,
}) => SavingsGoal(
  id: id,
  title: 'Trip',
  targetAmountCents: target,
  contributions: const [],
  isCompleted: isCompleted,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deadline: noDeadline ? null : (deadline ?? DateTime(2027)),
  deletedAt: deletedAt,
);

PlannerInput _input(
  DateTime now,
  List<GoalProgress> goals, {
  Set<String> fired = const {},
}) => PlannerInput(
  now: now,
  prefs: NotificationPrefs.defaults(),
  goals: goals,
  firedAlertKeys: fired,
);

List<int> _hm(DateTime d) => [d.month, d.day, d.hour, d.minute];

void main() {
  group('isGoalOffTrack', () {
    test('exactly ten points below is on track, one cent less is off', () {
      expect(_offTrack(400), isFalse);
      expect(_offTrack(399), isTrue);
    });

    test('never flags missing deadline, bad target or bad span', () {
      expect(_offTrack(0, noDeadline: true), isFalse);
      expect(_offTrack(0, target: 0), isFalse);
      expect(_offTrack(0, target: -5), isFalse);
      expect(_offTrack(0, deadline: DateTime(2026)), isFalse);
      expect(_offTrack(0, deadline: DateTime(2025)), isFalse);
    });

    test('asOf before createdAt expects zero progress', () {
      expect(_offTrack(0, asOf: DateTime(2025, 12, 25)), isFalse);
    });

    test('after the deadline expected progress clamps to 1.0', () {
      final late = DateTime(2026, 6);
      expect(_offTrack(899, asOf: late), isTrue);
      expect(_offTrack(900, asOf: late), isFalse);
    });
  });

  group('goal alert keys', () {
    test('fired and scheduled families', () {
      expect(goalFiredKey(7, '2026-10-12'), 'gf:7:2026-10-12');
      expect(goalScheduledKey(7, '2026-10-12'), 'gs:7:2026-10-12');
    });
  });

  group('GoalOffTrackPlanner', () {
    const planner = GoalOffTrackPlanner();
    final offTrack = GoalProgress(goal: _goal(), savedCents: 0);

    test('Wednesday plans next Monday 09:00 with the weekly id', () {
      final out = planner.plan(_input(DateTime(2026, 10, 14, 12), [offTrack]));
      expect(out, hasLength(1));
      expect(_hm(out.single.fireAt), [10, 19, 9, 0]);
      expect(out.single.kind, NotificationKind.goalOffTrack);
      expect(out.single.subject, 'Trip');
      expect(out.single.id, notificationId(base: 20, entityId: 7, type: 2));
    });

    test('Monday 08:00 plans today, Monday 09:00 plans next Monday', () {
      final early = planner.plan(_input(DateTime(2026, 10, 12, 8), [offTrack]));
      expect(_hm(early.single.fireAt), [10, 12, 9, 0]);
      final exact = planner.plan(_input(DateTime(2026, 10, 12, 9), [offTrack]));
      expect(_hm(exact.single.fireAt), [10, 19, 9, 0]);
    });

    test('a fired marker skips to the following Monday', () {
      final out = planner.plan(
        _input(
          DateTime(2026, 10, 14, 12),
          [offTrack],
          fired: {goalFiredKey(7, '2026-10-19')},
        ),
      );
      expect(_hm(out.single.fireAt), [10, 26, 9, 0]);
    });

    test('on track, completed, deleted, undated or zero target: nothing', () {
      final now = DateTime(2026, 10, 14, 12);
      final out = planner.plan(
        _input(now, [
          GoalProgress(goal: _goal(), savedCents: 1000),
          GoalProgress(goal: _goal(id: 8, isCompleted: true), savedCents: 0),
          GoalProgress(
            goal: _goal(id: 9, deletedAt: DateTime(2026, 10)),
            savedCents: 0,
          ),
          GoalProgress(goal: _goal(id: 10, noDeadline: true), savedCents: 0),
          GoalProgress(goal: _goal(id: 11, target: 0), savedCents: 0),
        ]),
      );
      expect(out, isEmpty);
    });
  });
}
