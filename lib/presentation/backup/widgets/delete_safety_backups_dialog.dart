import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks the user to confirm deleting every safety backup.
///
/// Returns `true` only when the user confirms; cancelling or dismissing the
/// dialog returns `false`. The caller owns the deletion.
Future<bool> confirmDeleteSafetyBackups(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(l10n.backupSafetyDeleteTitle),
        content: Text(l10n.backupSafetyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: Text(l10n.backupSafetyDeleteButton),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
