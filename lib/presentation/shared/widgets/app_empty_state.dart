import 'package:flutter/material.dart';

/// Shared empty-state layout for every list screen (UX-04).
///
/// Reproduces the approved Phase 3 finance empty-state layout: a 72px
/// icon, a `titleMedium` heading, a `bodyMedium` body and, only when both
/// [ctaLabel] and [onCta] are given, a CTA [FilledButton].
///
/// Pure presentation widget — no BLoC imports.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.heading,
    required this.body,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  /// The icon displayed above the heading.
  final IconData icon;

  /// Short heading text (titleMedium).
  final String heading;

  /// Longer body text explaining the empty state (bodyMedium).
  final String body;

  /// Label for the optional CTA [FilledButton].
  final String? ctaLabel;

  /// Called when the CTA button is tapped. The button renders only when
  /// both this and [ctaLabel] are non-null.
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = ctaLabel;
    final onPressed = onCta;

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
            if (label != null && onPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onPressed,
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
