import 'package:flutter/material.dart';

/// Top chrome of the GTD guide sheet: drag handle, back/close control, and a
/// progress bar over the tree's main path.
///
/// [step] is zero-based; [totalSteps] counts only the main path, so the
/// follow-up `q*b` branches do not make the bar jump backwards.
class GtdSheetHeader extends StatelessWidget {
  const GtdSheetHeader({
    required this.step,
    required this.totalSteps,
    required this.canGoBack,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  final int step;
  final int totalSteps;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(canGoBack ? Icons.arrow_back : Icons.close),
                onPressed: canGoBack ? onBack : onClose,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Pergunta ${step + 1} de $totalSteps',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (step + 1) / totalSteps,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
