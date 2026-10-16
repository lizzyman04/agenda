import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/widgets/time_setting_tile.dart';
import 'package:flutter/material.dart';

/// Frequency and time controls for motivational quotes (D-07).
///
/// While quotes are off only a hint is shown, so the controls can never be
/// edited for a kind that will not fire.
class QuotesSection extends StatelessWidget {
  const QuotesSection({
    required this.enabled,
    required this.frequency,
    required this.minutes,
    required this.onFrequency,
    required this.onMinutes,
    super.key,
  });

  final bool enabled;
  final QuoteFrequency frequency;
  final int minutes;
  final ValueChanged<QuoteFrequency> onFrequency;
  final ValueChanged<int> onMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.notifSettingsQuotesHeader,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.notifSettingsQuotesOffHint),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.notifSettingsQuoteFrequency),
                const SizedBox(height: 8),
                SegmentedButton<QuoteFrequency>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: QuoteFrequency.daily,
                      label: Text(l10n.notifSettingsQuoteDaily),
                    ),
                    ButtonSegment(
                      value: QuoteFrequency.weekly,
                      label: Text(l10n.notifSettingsQuoteWeekly),
                    ),
                  ],
                  selected: {frequency},
                  onSelectionChanged: (s) => onFrequency(s.first),
                ),
              ],
            ),
          ),
          TimeSettingTile(
            label: l10n.notifSettingsQuoteTime,
            minutes: minutes,
            onPicked: onMinutes,
          ),
        ],
      ],
    );
  }
}
