import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "Desativar o bloqueio com PIN?" (UI-SPEC "Destructive confirmation").
///
/// True only for the error-coloured confirm; Cancel, a tap outside or back
/// answer false. The body wraps in both locales; nothing is ellipsized.
Future<bool> showPinDisableDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      final cs = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(l10n.pinDisableTitle),
        content: Text(l10n.pinDisableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pinDisableConfirm),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
