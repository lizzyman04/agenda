/// Pure rules for budget threshold alerts (D-05).
///
/// All money is integer cents and every comparison is integer arithmetic, so
/// a category at exactly 80% or 100% of its limit is never missed or
/// double-counted by floating point rounding.
library;

import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';

final int _percentLow = (AppConstants.budgetAlertThresholdLow * 100).round();
final int _percentHigh = (AppConstants.budgetAlertThresholdHigh * 100).round();

/// The highest alert threshold (100 or 80) that [spentCents] has reached
/// against [limitCents], or null when none is reached.
///
/// A non-positive limit means "no budget" and never crosses anything.
int? crossedBudgetThreshold({
  required int spentCents,
  required int limitCents,
}) {
  if (limitCents <= 0) return null;
  if (spentCents * 100 >= limitCents * _percentHigh) return _percentHigh;
  if (spentCents * 100 >= limitCents * _percentLow) return _percentLow;
  return null;
}

String _month(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

/// Marker that [threshold] (80 or 100) was handled for [categoryId] in the
/// given month: `b:<year>-<mm>:<categoryId>:<threshold>`.
String budgetAlertKey(int year, int month, int categoryId, int threshold) =>
    'b:${_month(year, month)}:$categoryId:$threshold';

/// Marker that the month's already-crossed thresholds were seeded silently:
/// `seeded:<year>-<mm>`.
String budgetSeededKey(int year, int month) => 'seeded:${_month(year, month)}';

/// The immediate alert for [categoryId] reaching [threshold] percent.
///
/// Carries the category [name] and the percentage only, never an amount
/// (T-04-14-01). The id lives in the evaluator namespace, which the planner
/// diff never touches.
PlannedNotification plannedBudgetAlert({
  required int categoryId,
  required String name,
  required int threshold,
  required DateTime at,
}) => PlannedNotification(
  kind: NotificationKind.budgetAlert,
  id: notificationId(
    base: NotificationKind.budgetAlert.idBase,
    entityId: categoryId,
    type:
        threshold >= _percentHigh
            ? NotificationIdTypes.budget100
            : NotificationIdTypes.budget80,
  ),
  fireAt: at,
  entityId: categoryId,
  subject: name,
  count: threshold,
);
