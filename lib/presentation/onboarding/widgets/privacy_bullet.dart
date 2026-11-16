import 'package:flutter/material.dart';

/// One line of the privacy statement: a leading icon and wrapping text.
///
/// The text has no `maxLines` and no ellipsis, so long translations wrap
/// onto several lines instead of being cut off.
class PrivacyBullet extends StatelessWidget {
  const PrivacyBullet({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
