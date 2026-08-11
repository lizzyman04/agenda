import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_atoms.dart';
import 'package:flutter/material.dart';

/// Renders a [GtdTextSpec]: a question heading, a text field, and a Next
/// button.
///
/// The controller belongs to the guide sheet, not to this widget — the sheet
/// outlives individual nodes, so text typed at q1 survives navigating back and
/// forth through the tree.
class GtdTextNode extends StatelessWidget {
  const GtdTextNode({required this.spec, super.key});

  final GtdTextSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
        const SizedBox(height: 20),
        TextField(
          controller: spec.controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: spec.maxLength,
          decoration: InputDecoration(
            hintText: spec.hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: cs.surfaceContainerLow,
          ),
          onSubmitted: (_) => spec.onNext(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: spec.onNext,
          child: const Text('Próximo →'),
        ),
      ],
    );
  }
}
