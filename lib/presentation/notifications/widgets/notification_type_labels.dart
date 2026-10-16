import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';

/// The localized name of [kind], shared with its Android channel name.
String notificationTypeLabel(AppLocalizations l10n, NotificationKind kind) =>
    switch (kind) {
      NotificationKind.taskReminder => l10n.notifChannelTasksName,
      NotificationKind.recurringTaskReminder => l10n.notifChannelRecurringName,
      NotificationKind.morningBriefing => l10n.notifChannelBriefingName,
      NotificationKind.budgetAlert => l10n.notifChannelBudgetName,
      NotificationKind.debtReminder => l10n.notifChannelDebtsName,
      NotificationKind.goalOffTrack => l10n.notifChannelGoalsName,
      NotificationKind.recurringPayment => l10n.notifChannelPaymentsName,
      NotificationKind.motivationalQuote => l10n.notifChannelQuotesName,
    };

/// The localized one-line description of [kind].
String notificationTypeDescription(
  AppLocalizations l10n,
  NotificationKind kind,
) => switch (kind) {
  NotificationKind.taskReminder => l10n.notifChannelTasksDesc,
  NotificationKind.recurringTaskReminder => l10n.notifChannelRecurringDesc,
  NotificationKind.morningBriefing => l10n.notifChannelBriefingDesc,
  NotificationKind.budgetAlert => l10n.notifChannelBudgetDesc,
  NotificationKind.debtReminder => l10n.notifChannelDebtsDesc,
  NotificationKind.goalOffTrack => l10n.notifChannelGoalsDesc,
  NotificationKind.recurringPayment => l10n.notifChannelPaymentsDesc,
  NotificationKind.motivationalQuote => l10n.notifChannelQuotesDesc,
};
