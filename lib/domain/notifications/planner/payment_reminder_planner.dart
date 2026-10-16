import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planning/effective_due_date.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';

/// Plans the next reminder of every active recurring payment (NOTF-07).
///
/// The due date is advanced in memory by [nextPaymentReminderDue], so an
/// active payment always has an upcoming reminder even when its stored
/// `nextDueDate` is in the past. This planner only reads the payments: the
/// stored date is never written (D-15). Paused and deleted payments get
/// nothing.
final class PaymentReminderPlanner implements KindPlanner {
  const PaymentReminderPlanner();

  @override
  List<PlannedNotification> plan(PlannerInput input) {
    const kind = NotificationKind.recurringPayment;
    final planned = <PlannedNotification>[];
    for (final payment in input.payments) {
      if (!_isEligible(payment)) continue;
      final due = nextPaymentReminderDue(payment, input.now);
      if (due == null) continue;
      planned.add(
        PlannedNotification(
          kind: kind,
          id: notificationId(
            base: kind.idBase,
            entityId: payment.id,
            type: kind.idType,
          ),
          fireAt: dayBeforeAt9(due),
          entityId: payment.id,
          subject: payment.title,
        ),
      );
    }
    return planned;
  }

  static bool _isEligible(RecurringPayment payment) =>
      payment.isActive &&
      payment.deletedAt == null &&
      payment.id >= 0 &&
      payment.id <= maxNotificationEntityId;
}
