import 'package:flutter/material.dart';

/// Smallest shared pieces of GTD guide chrome.
///
/// Grouped in one file because none is meaningful alone and each is a handful
/// of lines; splitting them further would add imports without adding clarity.

/// Rounded tinted square holding a leading icon, used as a question heading.
class GtdIconBox extends StatelessWidget {
  const GtdIconBox({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: foreground, size: 24),
      );
}

/// One label/value line in the review summary.
class GtdReviewRow extends StatelessWidget {
  const GtdReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint separator between [GtdReviewRow]s.
class GtdRowDivider extends StatelessWidget {
  const GtdRowDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha: 0.4,
            ),
      );
}
