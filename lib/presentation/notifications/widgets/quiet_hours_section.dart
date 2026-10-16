import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/widgets/time_setting_tile.dart';
import 'package:flutter/material.dart';

/// Quiet hours: an enable switch and the start and end times (NOTF-10).
class QuietHoursSection extends StatelessWidget {
  const QuietHoursSection({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
    required this.onEnabled,
    required this.onStart,
    required this.onEnd,
    super.key,
  });

  final bool enabled;
  final int startMinutes;
  final int endMinutes;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.notifSettingsQuietHeader,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SwitchListTile(
          title: Text(l10n.notifSettingsQuietEnabled),
          subtitle: Text(l10n.notifSettingsQuietDesc),
          value: enabled,
          onChanged: onEnabled,
        ),
        TimeSettingTile(
          label: l10n.notifSettingsQuietStart,
          minutes: startMinutes,
          onPicked: onStart,
          enabled: enabled,
        ),
        TimeSettingTile(
          label: l10n.notifSettingsQuietEnd,
          minutes: endMinutes,
          onPicked: onEnd,
          enabled: enabled,
        ),
      ],
    );
  }
}
