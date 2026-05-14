import 'package:flutter/material.dart';

/// Reusable empty state widget for all finance list screens.
///
/// Extends the Phase 2 empty state pattern (UX-04) by adding a body text
/// and a CTA [FilledButton] to guide the user to their first action.
///
/// Pure presentation widget — no BLoC imports.
class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  /// The icon displayed above the heading.
  final IconData icon;

  /// Short heading text (titleMedium).
  final String heading;

  /// Longer body text explaining the empty state (bodyMedium).
  final String body;

  /// Label for the CTA [FilledButton].
  final String ctaLabel;

  /// Called when the CTA button is tapped.
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              heading,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onCta,
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}
