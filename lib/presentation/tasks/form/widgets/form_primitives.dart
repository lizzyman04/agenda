import 'package:flutter/material.dart';

/// Shared layout primitives for the task form.
///
/// Purely presentational: no state, no cubit, no domain knowledge. Kept
/// together because they are only meaningful as a set — a card that holds
/// rows, the rows themselves, and the divider between them.

/// Rounded surface container that groups related form rows.
class FormCard extends StatelessWidget {
  const FormCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

/// A single labelled form row: leading icon plus an expanded field.
class FieldRow extends StatelessWidget {
  const FieldRow({required this.icon, required this.child, super.key});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Hairline separator between [FieldRow]s, inset to align with the fields.
class FieldDivider extends StatelessWidget {
  const FieldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 48, endIndent: 16);
  }
}
