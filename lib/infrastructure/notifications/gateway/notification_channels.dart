import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Short channel name of each kind: one channel per kind.
String _channelName(NotificationKind kind) => switch (kind) {
  NotificationKind.taskReminder => 'tasks',
  NotificationKind.recurringTaskReminder => 'recurring',
  NotificationKind.morningBriefing => 'briefing',
  NotificationKind.budgetAlert => 'budget',
  NotificationKind.debtReminder => 'debts',
  NotificationKind.goalOffTrack => 'goals',
  NotificationKind.recurringPayment => 'payments',
  NotificationKind.motivationalQuote => 'quotes',
};

/// Android channel id of [kind].
///
/// The `_v1` suffix matters: a channel's importance and sound are frozen
/// after first creation, so changing them later needs a new `_v2` id.
String channelIdFor(NotificationKind kind) => 'agenda_${_channelName(kind)}_v1';

/// The localizations used for text the OS shows outside the widget tree.
///
/// Same rule as `LocaleCubit`: `'en'` is English, anything else is PT-BR.
AppLocalizations notificationL10n(String? localeCode) => lookupAppLocalizations(
  localeCode == 'en' ? const Locale('en') : const Locale('pt', 'BR'),
);

(String, String) _textFor(NotificationKind kind, AppLocalizations l10n) =>
    switch (kind) {
      NotificationKind.taskReminder => (
        l10n.notifChannelTasksName,
        l10n.notifChannelTasksDesc,
      ),
      NotificationKind.recurringTaskReminder => (
        l10n.notifChannelRecurringName,
        l10n.notifChannelRecurringDesc,
      ),
      NotificationKind.morningBriefing => (
        l10n.notifChannelBriefingName,
        l10n.notifChannelBriefingDesc,
      ),
      NotificationKind.budgetAlert => (
        l10n.notifChannelBudgetName,
        l10n.notifChannelBudgetDesc,
      ),
      NotificationKind.debtReminder => (
        l10n.notifChannelDebtsName,
        l10n.notifChannelDebtsDesc,
      ),
      NotificationKind.goalOffTrack => (
        l10n.notifChannelGoalsName,
        l10n.notifChannelGoalsDesc,
      ),
      NotificationKind.recurringPayment => (
        l10n.notifChannelPaymentsName,
        l10n.notifChannelPaymentsDesc,
      ),
      NotificationKind.motivationalQuote => (
        l10n.notifChannelQuotesName,
        l10n.notifChannelQuotesDesc,
      ),
    };

Importance _importance(NotificationKind kind) =>
    kind == NotificationKind.motivationalQuote
        ? Importance.defaultImportance
        : Importance.high;

/// The eight Android channels, named in the language of [l10n].
List<AndroidNotificationChannel> androidChannels(AppLocalizations l10n) => [
  for (final kind in NotificationKind.values)
    AndroidNotificationChannel(
      channelIdFor(kind),
      _textFor(kind, l10n).$1,
      description: _textFor(kind, l10n).$2,
      importance: _importance(kind),
    ),
];

/// Per-notification platform details for [kind].
///
/// Android visibility is private: on a secure lock screen the content is
/// hidden behind a generic notice (T-04-10-01).
NotificationDetails detailsFor(NotificationKind kind, AppLocalizations l10n) {
  final (name, description) = _textFor(kind, l10n);
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channelIdFor(kind),
      name,
      channelDescription: description,
      importance: _importance(kind),
      priority:
          kind == NotificationKind.motivationalQuote
              ? Priority.defaultPriority
              : Priority.high,
      visibility: NotificationVisibility.private,
      groupKey: 'agenda_${kind.code}',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      threadIdentifier: kind.code,
    ),
  );
}
