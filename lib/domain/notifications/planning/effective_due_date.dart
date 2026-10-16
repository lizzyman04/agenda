import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';

/// Most cycle steps [nextPaymentReminderDue] inspects before giving up.
///
/// Bounds the loop (T-04-07-02). A daily payment whose anchor is more than
/// about 13 years in the past yields null rather than looping forever.
const int maxPaymentSteps = 5000;

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _addMonthsClamped(DateTime anchor, int months) {
  final first = DateTime(anchor.year, anchor.month + months);
  final day = anchor.day.clamp(1, _daysInMonth(first.year, first.month));
  return DateTime(first.year, first.month, day);
}

/// The [k]-th occurrence of a recurring payment, as a date-only value.
///
/// Always measured from the ORIGINAL [anchor], never chained from a previous
/// (possibly clamped) occurrence: a Jan 31 monthly payment gives Feb 28/29
/// and then Mar 31 instead of drifting to the 28th for good. Months with
/// fewer days clamp the day to the month's last day.
DateTime paymentOccurrence(DateTime anchor, RecurringCycle cycle, int k) {
  return switch (cycle) {
    RecurringCycle.daily => DateTime(anchor.year, anchor.month, anchor.day + k),
    RecurringCycle.weekly => DateTime(
      anchor.year,
      anchor.month,
      anchor.day + 7 * k,
    ),
    RecurringCycle.biweekly => DateTime(
      anchor.year,
      anchor.month,
      anchor.day + 14 * k,
    ),
    RecurringCycle.monthly => _addMonthsClamped(anchor, k),
    RecurringCycle.quarterly => _addMonthsClamped(anchor, 3 * k),
    RecurringCycle.yearly => _addMonthsClamped(anchor, 12 * k),
  };
}

/// The reminder fire time for [due]: the calendar day before, at the due
/// reminder hour (D-02).
DateTime dayBeforeAt9(DateTime due) =>
    DateTime(due.year, due.month, due.day - 1, AppConstants.dueReminderHour);

/// The next due date of [payment] whose reminder can still fire, or null.
///
/// Computed in memory from the stored `nextDueDate` (D-15). The database is
/// never advanced: silently moving the stored date would imply the user paid.
/// The result is the first occurrence that is not before today and whose
/// day-before reminder is strictly after [now]; null if none is found within
/// [maxPaymentSteps] steps.
DateTime? nextPaymentReminderDue(RecurringPayment payment, DateTime now) {
  final today = startOfDay(now);
  for (var k = 0; k < maxPaymentSteps; k++) {
    final due = paymentOccurrence(payment.nextDueDate, payment.cycle, k);
    if (due.isBefore(today)) continue;
    if (dayBeforeAt9(due).isAfter(now)) return due;
  }
  return null;
}
