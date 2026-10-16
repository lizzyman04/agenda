import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/notifications/alert_state_store.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/planning/goal_alert_keys.dart';
import 'package:agenda/domain/notifications/planning/goal_off_track.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart';
import 'package:injectable/injectable.dart';

/// Raises an immediate off-track alert for a savings goal when the app opens
/// (D-06), at most once per goal per week.
///
/// A week that already has a fired marker (an earlier open) or a scheduled
/// marker (the planner's weekly one-shot) is left alone, so the user never
/// gets two alerts for one goal in one week. The marker is written before
/// dispatching, and none is written while the kind is off (T-04-14-03). The
/// text is the goal title only (T-04-14-01).
@lazySingleton
class GoalAlertEvaluator {
  GoalAlertEvaluator(
    this._goals,
    this._transactions,
    this._alerts,
    this._dispatcher,
    this._prefs,
  );

  final GoalRepository _goals;
  final TransactionRepository _transactions;
  final AlertStateStore _alerts;
  final ImmediateAlertDispatcher _dispatcher;
  final NotificationPrefsRepository _prefs;

  bool get _enabled => _prefs.load().isEnabled(NotificationKind.goalOffTrack);

  /// Alerts for every off-track goal that has no marker for this week.
  Future<void> evaluateOnOpen({DateTime? now}) async {
    if (!_enabled) return;
    final at = now ?? DateTime.now();
    final goals = await _offTrackGoals(at);
    if (goals == null) return;
    final keys = await _alerts.keys();
    final week = weekKey(at);
    for (final goal in goals) {
      final fired = goalFiredKey(goal.id, week);
      if (keys.contains(fired) ||
          keys.contains(goalScheduledKey(goal.id, week))) {
        continue;
      }
      await _alerts.add(fired);
      await _dispatcher.dispatch(_planned(goal, at), now: at);
    }
  }

  /// Clears the goal markers and marks every goal that is off track now as
  /// already alerted this week, so imported data raises no alert storm
  /// (T-04-14-02). Marking is skipped while the kind is off.
  Future<void> reseedAfterImport({DateTime? now}) async {
    await _alerts.removeWhere(
      (key) => key.startsWith('gf:') || key.startsWith('gs:'),
    );
    if (!_enabled) return;
    final at = now ?? DateTime.now();
    final goals = await _offTrackGoals(at);
    if (goals == null) return;
    final week = weekKey(at);
    await _alerts.addAll([for (final g in goals) goalFiredKey(g.id, week)]);
  }

  PlannedNotification _planned(SavingsGoal goal, DateTime at) =>
      PlannedNotification(
        kind: NotificationKind.goalOffTrack,
        id: notificationId(
          base: NotificationKind.goalOffTrack.idBase,
          entityId: goal.id,
          type: NotificationIdTypes.goalImmediate,
        ),
        fireAt: at,
        entityId: goal.id,
        subject: goal.title,
      );

  /// Open goals with a deadline that are behind schedule at [at], or null
  /// when a read fails. Saved amounts are computed like the goal screen:
  /// contributions plus every tagged transaction, uncapped.
  Future<List<SavingsGoal>?> _offTrackGoals(DateTime at) async {
    final goals = await _goals.getActiveGoals();
    final all = await _transactions.getAllTransactionsForAggregates();
    if (goals is! Success<List<SavingsGoal>> ||
        all is! Success<List<Transaction>>) {
      return null;
    }
    final tagged = <int, int>{};
    for (final tx in all.value) {
      final goalId = tx.linkedGoalId;
      if (goalId == null) continue;
      tagged[goalId] = (tagged[goalId] ?? 0) + tx.amountCents;
    }
    return [
      for (final goal in goals.value)
        if (!goal.isCompleted &&
            goal.deletedAt == null &&
            goal.id >= 0 &&
            goal.id <= maxNotificationEntityId &&
            isGoalOffTrack(
              savedCents: goal.amountSavedCents(tagged[goal.id] ?? 0),
              targetCents: goal.targetAmountCents,
              createdAt: goal.createdAt,
              deadline: goal.deadline,
              asOf: at,
            ))
          goal,
    ];
  }
}
