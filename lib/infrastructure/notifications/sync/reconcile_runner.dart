import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/alert_state_store.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/notifications/rules/schedule_diff.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart';
import 'package:agenda/infrastructure/notifications/gateway/notification_channels.dart';
import 'package:agenda/infrastructure/notifications/sync/permission_gate.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_apply.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_report.dart';
import 'package:agenda/infrastructure/notifications/sync/snapshot_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// One reconcile pass: load, plan, localise, diff, apply.
///
/// The pass is idempotent: when the desired set already equals what is
/// pending it makes no schedule or cancel call. A load or pending failure
/// aborts without changing anything, so a transient read error can never
/// wipe the schedule (T-04-12-01).
@lazySingleton
class ReconcileRunner {
  ReconcileRunner(
    this._loader,
    this._planner,
    this._content,
    this._gateway,
    this._permissions,
    this._gate,
    this._alerts,
  );

  final SnapshotLoader _loader;
  final ReminderPlanner _planner;
  final NotificationContentBuilder _content;
  final LocalNotificationGateway _gateway;
  final NotificationPermissionService _permissions;
  final PermissionGate _gate;
  final AlertStateStore _alerts;

  Future<ReconcileReport> run({
    required DateTime now,
    required ReconcileReason reason,
  }) async {
    final budget =
        defaultTargetPlatform == TargetPlatform.iOS
            ? AppConstants.iosPlannerSlotBudget
            : AppConstants.androidPlannerSlotBudget;
    final loaded = await _loader.load(now: now, slotBudget: budget);
    final pendingResult = await _gateway.pending();
    if (loaded is! Success<PlannerInput> ||
        pendingResult is! Success<List<PendingNotification>>) {
      return const ReconcileReport.aborted();
    }
    final input = loaded.value;
    final plan = _planner.plan(input);
    final exact = await _permissions.canScheduleExact();
    final l10n = notificationL10n(input.localeCode);
    final desired = [
      for (final p in plan.planned) _toRequest(p, l10n, exact: exact),
    ];
    final owned = [
      for (final p in pendingResult.value)
        if (isPlannerOwnedId(p.id)) p,
    ];
    final diff = diffSchedules(desired: desired, pending: owned);
    final disabledAlerts = disabledAlertIds(pendingResult.value, input.prefs);
    final asks =
        reason == ReconcileReason.dataChange ||
        reason == ReconcileReason.prefsChange;
    if (asks && diff.toSchedule.isNotEmpty) await _gate.ensureAsked();
    return applyDiff(
      _gateway,
      _alerts,
      ScheduleDiff(
        cancelIds: [...diff.cancelIds, ...disabledAlerts],
        toSchedule: diff.toSchedule,
      ),
      truncated: plan.truncated,
    );
  }

  ScheduleRequest _toRequest(
    PlannedNotification p,
    AppLocalizations l10n, {
    required bool exact,
  }) {
    final text = _content.build(p, l10n);
    return ScheduleRequest(
      id: p.id,
      kind: p.kind,
      fireAt: p.fireAt,
      title: text.title,
      body: text.body,
      payload: encodePayload(
        kind: p.kind,
        entityId: p.entityId,
        fireAt: p.fireAt,
        exact: exact,
      ),
      exact: exact,
    );
  }
}
