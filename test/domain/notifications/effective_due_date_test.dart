import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/notifications/planning/effective_due_date.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringPayment _payment(DateTime due, RecurringCycle cycle) =>
    RecurringPayment(
      id: 1,
      title: 'Rent',
      amountCents: 100,
      categoryId: 1,
      cycle: cycle,
      nextDueDate: due,
      isActive: true,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

List<int> _ymd(DateTime d) => [d.year, d.month, d.day];

void main() {
  group('paymentOccurrence', () {
    test('monthly Jan 31 clamps to Feb 28 and returns to Mar 31', () {
      final anchor = DateTime(2026, 1, 31);
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.monthly, 0)),
        [2026, 1, 31],
      );
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.monthly, 1)),
        [2026, 2, 28],
      );
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.monthly, 2)),
        [2026, 3, 31],
      );
    });

    test('leap year gives Feb 29 then Mar 31', () {
      final anchor = DateTime(2028, 1, 31);
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.monthly, 1)),
        [2028, 2, 29],
      );
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.monthly, 2)),
        [2028, 3, 31],
      );
    });

    test('quarterly Nov 30 step 1 is Feb 28', () {
      expect(
        _ymd(
          paymentOccurrence(
            DateTime(2025, 11, 30),
            RecurringCycle.quarterly,
            1,
          ),
        ),
        [2026, 2, 28],
      );
    });

    test('yearly Feb 29 2028 gives Feb 28 2029', () {
      expect(
        _ymd(
          paymentOccurrence(DateTime(2028, 2, 29), RecurringCycle.yearly, 1),
        ),
        [2029, 2, 28],
      );
    });

    test('daily, weekly and biweekly step by days', () {
      final anchor = DateTime(2026, 12, 30);
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.daily, 3)),
        [2027, 1, 2],
      );
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.weekly, 1)),
        [2027, 1, 6],
      );
      expect(
        _ymd(paymentOccurrence(anchor, RecurringCycle.biweekly, 1)),
        [2027, 1, 13],
      );
    });

    test('result is date-only', () {
      final d = paymentOccurrence(
        DateTime(2026, 1, 31, 15, 30),
        RecurringCycle.monthly,
        1,
      );
      expect([d.hour, d.minute], [0, 0]);
    });
  });

  group('dayBeforeAt9', () {
    test('is the previous day at 09:00', () {
      final r = dayBeforeAt9(DateTime(2026, 10, 20));
      expect([r.year, r.month, r.day, r.hour, r.minute], [2026, 10, 19, 9, 0]);
    });

    test('rolls over the month by components', () {
      final r = dayBeforeAt9(DateTime(2026, 11));
      expect([r.year, r.month, r.day, r.hour], [2026, 10, 31, 9]);
    });
  });

  group('nextPaymentReminderDue', () {
    test('anchor a year back returns the first future reminder', () {
      final now = DateTime(2026, 10, 12, 8);
      final due = nextPaymentReminderDue(
        _payment(DateTime(2025, 10, 5), RecurringCycle.monthly),
        now,
      );
      expect(_ymd(due!), [2026, 11, 5]);
      expect(dayBeforeAt9(due).isAfter(now), isTrue);
    });

    test('due tomorrow after 09:00 today moves to the following cycle', () {
      final now = DateTime(2026, 10, 12, 10);
      final due = nextPaymentReminderDue(
        _payment(DateTime(2026, 10, 13), RecurringCycle.monthly),
        now,
      );
      expect(_ymd(due!), [2026, 11, 13]);
    });

    test('daily due tomorrow before 09:00 returns tomorrow', () {
      final now = DateTime(2026, 10, 12, 8);
      final due = nextPaymentReminderDue(
        _payment(DateTime(2026, 10, 13), RecurringCycle.daily),
        now,
      );
      expect(_ymd(due!), [2026, 10, 13]);
    });

    test('gives up with null beyond the step bound', () {
      final now = DateTime(2026, 10, 12, 8);
      final due = nextPaymentReminderDue(
        _payment(DateTime(2000), RecurringCycle.daily),
        now,
      );
      expect(due, isNull);
    });
  });
}
