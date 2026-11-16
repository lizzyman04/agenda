import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "Guarde um backup" (UI-SPEC "No device screen lock", D-06 fallback).
///
/// Shown before PIN creation on a device with no screen lock, where a
/// forgotten PIN cannot be reset. True only for "Criar PIN mesmo assim";
/// Cancel and dismissal answer false.
Future<bool> showNoDeviceLockDialog(BuildContext context) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return AlertDialog(
        title: Text(l10n.pinNoDeviceLockTitle),
        content: SingleChildScrollView(child: Text(l10n.pinNoDeviceLockBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pinNoDeviceLockContinue),
          ),
        ],
      );
    },
  );
  return proceed ?? false;
}
