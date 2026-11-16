import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/settings/widgets/language_dialog.dart';
import 'package:agenda/presentation/settings/widgets/settings_section_header.dart';
import 'package:flutter/material.dart';

/// One scrollable Settings list (D-10), opened from the Tasks AppBar gear.
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
