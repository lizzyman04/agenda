import 'package:flutter/material.dart';

/// A labelled `HH:mm` row that opens a time picker when tapped.
///
/// The widget owns no state: [onPicked] receives the chosen time as minutes
/// since midnight and the caller persists it. Cancelling the picker reports
/// nothing.
class TimeSettingTile extends StatelessWidget {
  const TimeSettingTile({
    required this.label,
    required this.minutes,
    required this.onPicked,
    this.enabled = true,
    super.key,
  });

  final String label;

  /// Minutes since midnight, 0..1439.
  final int minutes;
  final ValueChanged<int> onPicked;
  final bool enabled;

  /// Zero-padded `HH:mm` for [minutes].
  static String format(int minutes) {
    final hh = (minutes ~/ 60).toString().padLeft(2, '0');
    final mm = (minutes % 60).toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) onPicked(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      title: Text(label),
      trailing: Text(
        format(minutes),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: enabled ? () => _pick(context) : null,
    );
  }
}
