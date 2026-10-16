import 'dart:async';

import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/widgets/notification_type_labels.dart';
import 'package:agenda/presentation/notifications/widgets/notification_type_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The order the kinds appear in on the page.
const List<NotificationKind> _kindOrder = [
  NotificationKind.taskReminder,
  NotificationKind.recurringTaskReminder,
  NotificationKind.morningBriefing,
  NotificationKind.budgetAlert,
  NotificationKind.debtReminder,
  NotificationKind.goalOffTrack,
  NotificationKind.recurringPayment,
  NotificationKind.motivationalQuote,
];

/// Standalone notification settings page (D-09). Owns its cubit so the
/// Phase 5 Settings screen can mount it unchanged.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  late final NotificationSettingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationSettingsCubit>();
    unawaited(_cubit.start());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_cubit.refreshPermissions());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider<NotificationSettingsCubit>.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
        body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
          builder:
              (context, state) => switch (state) {
                NotificationSettingsInitial() => const Center(
                  child: CircularProgressIndicator(),
                ),
                NotificationSettingsLoaded() => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.notifSettingsTypesHeader,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final kind in _kindOrder)
                      NotificationTypeTile(
                        label: notificationTypeLabel(l10n, kind),
                        description: notificationTypeDescription(l10n, kind),
                        value: state.prefs.isEnabled(kind),
                        onChanged:
                            (value) => unawaited(
                              _cubit.setEnabled(kind, enabled: value),
                            ),
                      ),
                  ],
                ),
              },
        ),
      ),
    );
  }
}
