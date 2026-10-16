import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart';
import 'package:agenda/infrastructure/notifications/gateway/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _at = DateTime(2026, 10, 14, 9, 30);
const _builder = NotificationContentBuilder();

PlannedNotification _p(
  NotificationKind kind, {
  String subject = 'Write report',
  int count = 0,
  int variant = 0,
  List<String> extras = const [],
}) => PlannedNotification(
  kind: kind,
  id: 1,
  fireAt: _at,
  subject: subject,
  count: count,
  variant: variant,
  extras: extras,
);

void main() {
  for (final code in ['en', 'pt']) {
    final l10n = notificationL10n(code);

    group('locale $code', () {
      test('timed and date-only task reminders', () {
        final timed = _builder.build(
          _p(NotificationKind.taskReminder, extras: ['10:00']),
          l10n,
        );
        expect(timed.title, l10n.notifTaskReminderTitle);
        expect(timed.body, l10n.notifTaskReminderBody('Write report', '10:00'));

        final dateOnly = _builder.build(
          _p(NotificationKind.taskReminder, variant: 1),
          l10n,
        );
        expect(dateOnly.body, l10n.notifTaskDueTodayBody('Write report'));
      });

      test('recurring task reminder uses its own title', () {
        final text = _builder.build(
          _p(NotificationKind.recurringTaskReminder, extras: ['10:00']),
          l10n,
        );
        expect(text.title, l10n.notifRecurringTaskTitle);
        expect(text.body, l10n.notifTaskReminderBody('Write report', '10:00'));
      });

      test('briefing: plural boundary 1 and 4, with and without overflow', () {
        final one = _builder.build(
          _p(NotificationKind.morningBriefing, count: 1, extras: ['A']),
          l10n,
        );
        expect(one.title, l10n.notifBriefingTitle(1));
        expect(one.body, l10n.notifBriefingBody('A'));

        final four = _builder.build(
          _p(
            NotificationKind.morningBriefing,
            count: 4,
            extras: ['A', 'B', 'C'],
          ),
          l10n,
        );
        expect(four.title, l10n.notifBriefingTitle(4));
        expect(four.body, l10n.notifBriefingBodyMore('A, B, C', 1));
        expect(l10n.notifBriefingTitle(1), isNot(l10n.notifBriefingTitle(4)));
      });

      test('budget alert picks the 80 or 100 pair by count', () {
        final at80 = _builder.build(
          _p(NotificationKind.budgetAlert, subject: 'Food', count: 80),
          l10n,
        );
        expect(at80.title, l10n.notifBudget80Title('Food'));
        expect(at80.body, l10n.notifBudget80Body);

        final at100 = _builder.build(
          _p(NotificationKind.budgetAlert, subject: 'Food', count: 100),
          l10n,
        );
        expect(at100.title, l10n.notifBudget100Title('Food'));
        expect(at100.body, l10n.notifBudget100Body);
      });

      test('debt direction, goal, payment and quote', () {
        final toPay = _builder.build(_p(NotificationKind.debtReminder), l10n);
        expect(toPay.title, l10n.notifDebtDueTitle);
        expect(toPay.body, l10n.notifDebtBody('Write report'));

        final toReceive = _builder.build(
          _p(NotificationKind.debtReminder, variant: 1),
          l10n,
        );
        expect(toReceive.title, l10n.notifDebtReceiveTitle);

        final goal = _builder.build(_p(NotificationKind.goalOffTrack), l10n);
        expect(goal.title, l10n.notifGoalOffTrackTitle);
        expect(goal.body, l10n.notifGoalOffTrackBody('Write report'));

        final payment = _builder.build(
          _p(NotificationKind.recurringPayment),
          l10n,
        );
        expect(payment.title, l10n.notifPaymentDueTitle);
        expect(payment.body, l10n.notifPaymentBody('Write report'));

        final quote = _builder.build(
          _p(NotificationKind.motivationalQuote, subject: 'Keep going'),
          l10n,
        );
        expect(quote.title, l10n.notifQuoteTitle);
        expect(quote.body, 'Keep going');
      });
    });
  }

  test('English and Portuguese titles differ', () {
    final en = _builder.build(
      _p(NotificationKind.goalOffTrack),
      notificationL10n('en'),
    );
    final pt = _builder.build(
      _p(NotificationKind.goalOffTrack),
      notificationL10n('pt'),
    );
    expect(en.title, isNot(pt.title));
  });

  test('a subject longer than 100 characters is clipped with an ellipsis', () {
    final long = 'x' * 150;
    final text = _builder.build(
      _p(NotificationKind.debtReminder, subject: long),
      notificationL10n('en'),
    );
    expect(text.body, '${'x' * 100}…');
    expect(
      _builder
          .build(
            _p(NotificationKind.debtReminder, subject: 'x' * 100),
            notificationL10n('en'),
          )
          .body,
      'x' * 100,
    );
  });
}
