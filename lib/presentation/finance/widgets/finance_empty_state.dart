import 'package:agenda/presentation/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

/// Reusable empty state widget for all finance list screens.
///
/// Extends the Phase 2 empty state pattern (UX-04) by adding a body text
/// and a CTA [FilledButton] to guide the user to their first action.
///
/// Delegates to the shared [AppEmptyState] so finance and task empty
/// states render from one layout; this wrapper keeps the required-CTA
/// constructor every finance list already calls.
///
/// Pure presentation widget — no BLoC imports.
class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({
    required this.icon,
    required this.heading,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    super.key,
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
    return AppEmptyState(
      icon: icon,
      heading: heading,
      body: body,
      ctaLabel: ctaLabel,
      onCta: onCta,
    );
  }
}
