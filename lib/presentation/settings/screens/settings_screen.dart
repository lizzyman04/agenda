import 'dart:async';

import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/screens/backup_screen.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_screen.dart';
import 'package:agenda/presentation/onboarding/screens/privacy_statement_screen.dart';
import 'package:agenda/presentation/settings/widgets/language_dialog.dart';
import 'package:agenda/presentation/settings/widgets/settings_section_header.dart';
import 'package:flutter/material.dart';

/// One scrollable Settings list (D-10), opened from the Tasks AppBar gear.
///
/// Sections, top to bottom: General, (Security, 05-13), Notifications, Data,
/// About. Feature pages are mounted unchanged; this screen owns no state.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SettingsSectionHeader(l10n.settingsSectionGeneral),
          const LanguageTile(),
          // 05-13 inserts the Security section here (D-10).
          SettingsSectionHeader(l10n.settingsSectionNotifications),
          _LinkTile(
            icon: Icons.notifications_outlined,
            title: l10n.notifSettingsTitle,
            subtitle: l10n.settingsNotificationsDesc,
            builder: (_) => const NotificationSettingsScreen(),
          ),
          SettingsSectionHeader(l10n.settingsSectionData),
          _LinkTile(
            icon: Icons.backup_outlined,
            title: l10n.backupMenuLabel,
            subtitle: l10n.settingsDataDesc,
            builder: (_) => const BackupScreen(),
          ),
          SettingsSectionHeader(l10n.settingsSectionAbout),
          const _AboutRows(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// About: the read-only privacy statement (D-14) and the app version.
class _AboutRows extends StatelessWidget {
  const _AboutRows();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _LinkTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.settingsPrivacyLabel,
          subtitle: l10n.privacyStatement,
          builder: (_) => const PrivacyStatementScreen(readOnly: true),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.settingsVersionLabel),
          subtitle: const Text(AppConfig.version),
        ),
      ],
    );
  }
}

/// A row that pushes a feature page. Subtitles wrap; nothing is ellipsized.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          () => unawaited(
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: builder)),
          ),
    );
  }
}
