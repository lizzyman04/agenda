import 'dart:async';

import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        bloc: _cubit,
        builder:
            (context, state) => switch (state) {
              NotificationSettingsInitial() => const Center(
                child: CircularProgressIndicator(),
              ),
              NotificationSettingsLoaded() => NotificationSettingsBody(
                state: state,
                cubit: _cubit,
                footer: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.notifSettingsPrivacyNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            },
      ),
    );
  }
}
