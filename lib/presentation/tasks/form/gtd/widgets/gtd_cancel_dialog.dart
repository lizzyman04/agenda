import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Confirms abandoning the GTD guide once the user has entered something.
///
/// Returns true when the user chooses to discard. The caller owns the actual
/// dismissal — this only asks the question.
Future<bool> showGtdCancelDialog(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.gtdCancelTitle),
      content: Text(l10n.gtdCancelMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.gtdCancelContinue),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.gtdCancelDiscard),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
