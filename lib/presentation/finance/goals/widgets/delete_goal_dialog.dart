import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Confirmation dialog shown before soft-deleting a savings goal.
///
/// Returns `true` when the user confirms, `false` or `null` otherwise. The
/// caller owns the deletion — this widget performs no persistence.
Future<bool> showDeleteGoalDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _DeleteGoalDialog(),
  );
  return confirmed ?? false;
}

class _DeleteGoalDialog extends StatelessWidget {
  const _DeleteGoalDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Excluir objetivo?'),
      content: const Text(
        'O progresso e contribuições serão perdidos. Deseja continuar?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(l10n.deleteButton),
        ),
      ],
    );
  }
}
