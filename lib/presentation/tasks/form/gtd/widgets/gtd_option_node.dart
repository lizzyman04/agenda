import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_atoms.dart';
import 'package:flutter/material.dart';

/// Renders a [GtdOptionSpec]: a question heading plus a card of tappable
/// options.
///
/// Presentation only — each option carries its own callback, so this widget
/// never touches the answers or the navigation stack.
class GtdOptionNode extends StatelessWidget {
  const GtdOptionNode({required this.spec, super.key});

  final GtdOptionSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subtitle = spec.subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GtdIconBox(
              icon: spec.icon,
              background: cs.primaryContainer,
              foreground: cs.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(spec.question, style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: spec.options.indexed.map((entry) {
              final (index, (icon, label, onTap)) = entry;
              final isFirst = index == 0;
              final isLast = index == spec.options.length - 1;

              return ListTile(
                leading: Icon(icon, color: cs.primary, size: 22),
                title: Text(label, style: theme.textTheme.bodyLarge),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: onTap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? const Radius.circular(16) : Radius.zero,
                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
