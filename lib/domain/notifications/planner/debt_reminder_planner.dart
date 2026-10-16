import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planning/effective_due_date.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';

/// Plans one reminder per unpaid debt at 09:00 the day before it is due
/// (NOTF-05, D-02).
///
/// A debt due today or already overdue gets nothing: its reminder time has
/// passed, so the reminder fires once and never repeats. Paid, deleted and
/// out-of-range-id debts are skipped. Carries only the title, never an
/// amount or counterparty (T-04-07-01).
final class DebtReminderPlanner implements KindPlanner {
  const DebtReminderPlanner();

  @override
  List<PlannedNotification> plan(PlannerInput input) {
    const kind = NotificationKind.debtReminder;
    final planned = <PlannedNotification>[];
    for (final debt in input.debts) {
      if (!_isEligible(debt)) continue;
      final fireAt = dayBeforeAt9(debt.dueDate);
      if (!fireAt.isAfter(input.now)) continue;
      planned.add(
        PlannedNotification(
          kind: kind,
          id: notificationId(
            base: kind.idBase,
            entityId: debt.id,
            type: kind.idType,
          ),
          fireAt: fireAt,
          entityId: debt.id,
          subject: debt.title,
          variant: debt.direction == DebtDirection.toPay ? 0 : 1,
        ),
      );
    }
    return planned;
  }

  static bool _isEligible(Debt debt) =>
      !debt.isPaid &&
      debt.deletedAt == null &&
      debt.id >= 0 &&
      debt.id <= maxNotificationEntityId;
}
