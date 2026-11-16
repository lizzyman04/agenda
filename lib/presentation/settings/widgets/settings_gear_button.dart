import 'dart:async';

import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';

/// The single entry point to Settings (D-09): a gear in the Tasks AppBar.
///
/// Settings is not a shell tab, and no other tab carries a gear.
class SettingsGearButton extends StatelessWidget {
  const SettingsGearButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: AppLocalizations.of(context).settingsTitle,
      onPressed: () => unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        ),
      ),
    );
  }
}
