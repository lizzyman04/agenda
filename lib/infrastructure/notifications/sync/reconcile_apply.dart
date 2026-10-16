import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/alert_state_store.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/domain/notifications/planning/goal_alert_keys.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/notifications/rules/schedule_diff.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_report.dart';

/// Evaluator-raised alerts (budget, immediate goal) are not planner-owned,
/// so the schedule diff ignores them. They are cancelled only when their
/// kind is switched off; entries that do not decode as ours are never
/// touched (T-04-12-02).
List<int> disabledAlertIds(
  List<PendingNotification> pending,
  NotificationPrefs prefs,
) => [
  for (final p in pending)
    if (!isPlannerOwnedId(p.id) && decodeNotificationId(p.id) != null)
      if (decodePayload(p.payload) case final payload?
          when !prefs.isEnabled(payload.kind))
        p.id,
];

/// Applies [diff] one id at a time: cancels first, then schedules.
///
/// A failing call is counted and never stops the others. Every goal
/// off-track one-shot that reaches the OS records its week marker, so the
/// on-open evaluator (04-14) cannot raise a duplicate in the same week.
Future<ReconcileReport> applyDiff(
  LocalNotificationGateway gateway,
  AlertStateStore alerts,
  ScheduleDiff diff, {
  required int truncated,
}) async {
  var scheduled = 0;
  var cancelled = 0;
  var failures = 0;
  for (final id in diff.cancelIds) {
    if (await gateway.cancel(id) is Success<void>) {
      cancelled++;
    } else {
      failures++;
    }
  }
  for (final request in diff.toSchedule) {
    if (await gateway.schedule(request) is Success<void>) {
      scheduled++;
      await _markGoalWeek(alerts, request);
    } else {
      failures++;
    }
  }
  return ReconcileReport(
    scheduled: scheduled,
    cancelled: cancelled,
    truncated: truncated,
    failures: failures,
  );
}

Future<void> _markGoalWeek(
  AlertStateStore alerts,
  ScheduleRequest request,
) async {
  if (request.kind != NotificationKind.goalOffTrack) return;
  final payload = decodePayload(request.payload);
  if (payload == null) return;
  await alerts.add(
    goalScheduledKey(payload.entityId, weekKey(request.fireAt)),
  );
}
