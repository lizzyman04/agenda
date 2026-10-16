import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/debt_reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/payment_reminder_planner.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 10, 12, 8);

Debt _debt({
  int id = 3,
  DateTime? due,
  DebtDirection direction = DebtDirection.toPay,
  bool isPaid = false,
  DateTime? deletedAt,
}) => Debt(
  id: id,
  title: 'Loan',
  amountCents: 5000,
  direction: direction,
  counterparty: 'Ana',
  dueDate: due ?? DateTime(2026, 10, 14),
  isPaid: isPaid,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deletedAt: deletedAt,
);

RecurringPayment _payment({
  int id = 5,
  bool isActive = true,
  DateTime? deletedAt,
  DateTime? due,
}) => RecurringPayment(
  id: id,
  title: 'Netflix',
  amountCents: 100,
  categoryId: 1,
  cycle: RecurringCycle.monthly,
  nextDueDate: due ?? DateTime(2026, 10, 20),
  isActive: isActive,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deletedAt: deletedAt,
);

PlannerInput _input({
  DateTime? now,
  List<Debt> debts = const [],
  List<RecurringPayment> payments = const [],
}) => PlannerInput(
  now: now ?? _now,
  prefs: NotificationPrefs.defaults(),
  debts: debts,
  payments: payments,
);

void main() {
  group('DebtReminderPlanner', () {
    const planner = DebtReminderPlanner();

    test('due in 2 days fires 09:00 tomorrow', () {
      final out = planner.plan(_input(debts: [_debt()]));
      expect(out, hasLength(1));
      final f = out.single.fireAt;
      expect([f.year, f.month, f.day, f.hour, f.minute], [2026, 10, 13, 9, 0]);
      expect(out.single.kind, NotificationKind.debtReminder);
      expect(out.single.subject, 'Loan');
    });

    test('due tomorrow with now at 10:00 gives nothing', () {
      final out = planner.plan(
        _input(
          now: DateTime(2026, 10, 12, 10),
          debts: [_debt(due: DateTime(2026, 10, 13))],
        ),
      );
      expect(out, isEmpty);
    });

    test('due today, overdue, paid and deleted give nothing', () {
      final out = planner.plan(
        _input(
          debts: [
            _debt(due: DateTime(2026, 10, 12)),
            _debt(id: 4, due: DateTime(2026, 9)),
            _debt(id: 5, isPaid: true),
            _debt(id: 6, deletedAt: DateTime(2026, 10)),
          ],
        ),
      );
      expect(out, isEmpty);
    });

    test('variant follows the direction and id is finance/debt', () {
      final out = planner.plan(
        _input(
          debts: [
            _debt(),
            _debt(id: 4, direction: DebtDirection.toReceive),
          ],
        ),
      );
      expect(out.map((e) => e.variant), [0, 1]);
      expect(
        out.first.id,
        notificationId(base: 20, entityId: 3, type: 0),
      );
    });

    test('an id beyond the range is skipped', () {
      final out = planner.plan(
        _input(debts: [_debt(id: maxNotificationEntityId + 1)]),
      );
      expect(out, isEmpty);
    });
  });

  group('PaymentReminderPlanner', () {
    const planner = PaymentReminderPlanner();

    test('active payment gets exactly one entry', () {
      final out = planner.plan(_input(payments: [_payment()]));
      expect(out, hasLength(1));
      final e = out.single;
      expect(e.kind, NotificationKind.recurringPayment);
      expect(e.subject, 'Netflix');
      expect(e.id, notificationId(base: 20, entityId: 5, type: 1));
      expect(
        [e.fireAt.month, e.fireAt.day, e.fireAt.hour],
        [10, 19, 9],
      );
    });

    test('a past stored due date advances in memory only', () {
      final payment = _payment(due: DateTime(2026, 8, 20));
      final out = planner.plan(_input(payments: [payment]));
      expect(out.single.fireAt, DateTime(2026, 10, 19, 9));
      expect(payment.nextDueDate, DateTime(2026, 8, 20));
    });

    test('paused and deleted payments give nothing', () {
      final out = planner.plan(
        _input(
          payments: [
            _payment(isActive: false),
            _payment(id: 6, deletedAt: DateTime(2026, 10)),
          ],
        ),
      );
      expect(out, isEmpty);
    });
  });
}
