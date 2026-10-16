import 'dart:async';

import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/widgets/notification_type_labels.dart';
import 'package:agenda/presentation/notifications/widgets/notification_type_tile.dart';
import 'package:agenda/presentation/notifications/widgets/permission_banner.dart';
import 'package:agenda/presentation/notifications/widgets/quiet_hours_section.dart';
import 'package:agenda/presentation/notifications/widgets/quotes_section.dart';
import 'package:agenda/presentation/notifications/widgets/time_setting_tile.dart';
import 'package:flutter/material.dart';

/// The order the kinds appear in on the page.
const List<NotificationKind> notificationKindOrder = [
  NotificationKind.taskReminder,
  NotificationKind.recurringTaskReminder,
  NotificationKind.morningBriefing,
  NotificationKind.budgetAlert,
  NotificationKind.debtReminder,
  NotificationKind.goalOffTrack,
  NotificationKind.recurringPayment,
  NotificationKind.motivationalQuote,
];

/// The loaded page: banners, one switch per kind, time pickers, quotes,
/// quiet hours, the waiting count and the privacy note.
class NotificationSettingsBody extends StatelessWidget {
  const NotificationSettingsBody({
    required this.state,
    required this.cubit,
    required this.footer,
    super.key,
  });

  final NotificationSettingsLoaded state;
  final NotificationSettingsCubit cubit;

  /// Shown last, below the quiet hours and the waiting count.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = state.prefs;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return ListView(
      children: [
        if (state.permission == NotificationPermission.denied)
          PermissionBanner(
            title: l10n.notifSettingsPermissionDeniedTitle,
            body: l10n.notifSettingsPermissionDeniedBody,
            actionLabel: l10n.notifSettingsAllowButton,
            onAction: () => unawaited(cubit.requestPermission()),
          ),
        if (isAndroid && !state.canScheduleExact)
          PermissionBanner(
            title: l10n.notifSettingsExactTitle,
            body: l10n.notifSettingsExactBody,
            actionLabel: l10n.notifSettingsExactButton,
            onAction: () => unawaited(cubit.requestExactAlarms()),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.notifSettingsTypesHeader,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final kind in notificationKindOrder)
          NotificationTypeTile(
            label: notificationTypeLabel(l10n, kind),
            description: notificationTypeDescription(l10n, kind),
            value: prefs.isEnabled(kind),
            onChanged: (v) => unawaited(cubit.setEnabled(kind, enabled: v)),
          ),
        TimeSettingTile(
          label: l10n.notifSettingsBriefingTime,
          minutes: prefs.briefingMinutes,
          enabled: prefs.isEnabled(NotificationKind.morningBriefing),
          onPicked: (m) => unawaited(cubit.setBriefingMinutes(m)),
        ),
        QuotesSection(
          enabled: prefs.isEnabled(NotificationKind.motivationalQuote),
          frequency: prefs.quoteFrequency,
          minutes: prefs.quoteMinutes,
          onFrequency: (f) => unawaited(cubit.setQuoteFrequency(f)),
          onMinutes: (m) => unawaited(cubit.setQuoteMinutes(m)),
        ),
        QuietHoursSection(
          enabled: prefs.quietHoursEnabled,
          startMinutes: prefs.quietStartMinutes,
          endMinutes: prefs.quietEndMinutes,
          onEnabled: (v) => unawaited(cubit.setQuietHoursEnabled(enabled: v)),
          onStart: (m) => unawaited(cubit.setQuietStart(m)),
          onEnd: (m) => unawaited(cubit.setQuietEnd(m)),
        ),
        if (state.waitingCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l10n.notifSettingsWaiting(state.waitingCount)),
          ),
        footer,
      ],
    );
  }
}
