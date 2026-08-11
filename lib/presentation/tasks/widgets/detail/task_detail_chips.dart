import 'package:flutter/material.dart';

/// Small presentational chips used on the task detail screen's hero card and
/// flags card. Grouped in one file because none is meaningful alone and each
/// is a handful of lines.

/// Pending/completed status pill.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.color,
    required this.filled,
    super.key,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: filled ? color : color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Dot + label priority indicator.
class PriorityChip extends StatelessWidget {
  const PriorityChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Plain-text size label.
class SizeChip extends StatelessWidget {
  const SizeChip({required this.label, required this.cs, super.key});

  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

/// Icon + label pill used for urgent/important/next-action flags.
class FlagChip extends StatelessWidget {
  const FlagChip({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
