import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:injectable/injectable.dart';

/// Longest free text (a task title, say) allowed on a notification.
const int _maxSubjectLength = 100;

String _clip(String text) =>
    text.length <= _maxSubjectLength
        ? text
        : '${text.substring(0, _maxSubjectLength)}…';

/// Turns a [PlannedNotification] into localised title and body text.
///
/// Text is produced at schedule time from the stored locale. It carries
/// titles only: no amount is ever added, so a locked phone never reveals
/// money figures (T-04-12-03).
@lazySingleton
class NotificationContentBuilder {
  const NotificationContentBuilder();

  ({String title, String body}) build(
    PlannedNotification p,
    AppLocalizations l10n,
  ) {
    final subject = _clip(p.subject);
    final extras = [for (final e in p.extras) _clip(e)];
    return switch (p.kind) {
      NotificationKind.taskReminder => (
        title: l10n.notifTaskReminderTitle,
        body: _taskBody(p, subject, extras, l10n),
      ),
      NotificationKind.recurringTaskReminder => (
        title: l10n.notifRecurringTaskTitle,
        body: _taskBody(p, subject, extras, l10n),
      ),
      NotificationKind.morningBriefing => (
        title: l10n.notifBriefingTitle(p.count),
        body: _briefingBody(p, extras, l10n),
      ),
      NotificationKind.budgetAlert => _budget(p.count, subject, l10n),
      NotificationKind.debtReminder => (
        title:
            p.variant == 1
                ? l10n.notifDebtReceiveTitle
                : l10n.notifDebtDueTitle,
        body: l10n.notifDebtBody(subject),
      ),
      NotificationKind.goalOffTrack => (
        title: l10n.notifGoalOffTrackTitle,
        body: l10n.notifGoalOffTrackBody(subject),
      ),
      NotificationKind.recurringPayment => (
        title: l10n.notifPaymentDueTitle,
        body: l10n.notifPaymentBody(subject),
      ),
      NotificationKind.motivationalQuote => (
        title: l10n.notifQuoteTitle,
        body: subject,
      ),
    };
  }

  static String _taskBody(
    PlannedNotification p,
    String subject,
    List<String> extras,
    AppLocalizations l10n,
  ) =>
      p.variant == 1 || extras.isEmpty
          ? l10n.notifTaskDueTodayBody(subject)
          : l10n.notifTaskReminderBody(subject, extras.first);

  static String _briefingBody(
    PlannedNotification p,
    List<String> titles,
    AppLocalizations l10n,
  ) {
    final joined = titles.join(', ');
    final remaining = p.count - titles.length;
    return remaining > 0
        ? l10n.notifBriefingBodyMore(joined, remaining)
        : l10n.notifBriefingBody(joined);
  }

  static ({String title, String body}) _budget(
    int percent,
    String category,
    AppLocalizations l10n,
  ) =>
      percent >= 100
          ? (
            title: l10n.notifBudget100Title(category),
            body: l10n.notifBudget100Body,
          )
          : (
            title: l10n.notifBudget80Title(category),
            body: l10n.notifBudget80Body,
          );
}
