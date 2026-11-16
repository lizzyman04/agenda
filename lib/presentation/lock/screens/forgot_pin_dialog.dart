import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Explains that the PIN cannot be reset on a device without a screen lock
/// (UI-SPEC "Forgot PIN", user decision 1: fail closed). The only recovery
/// is reinstalling and restoring a JSON backup; the app stays locked.
Future<void> showForgotPinUnavailableDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(l10n.lockForgotUnavailableTitle),
          content: SingleChildScrollView(
            child: Text(l10n.lockForgotUnavailableBody),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.lockGotIt),
            ),
          ],
        ),
  );
}
