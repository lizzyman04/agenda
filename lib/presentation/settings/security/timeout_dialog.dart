import 'package:agenda/domain/lock/lock_policy.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The label of a lock timeout option ([seconds] is one of
/// `LockPolicy.timeoutOptionsSeconds`; anything else reads as the default).
String lockTimeoutLabel(AppLocalizations l10n, int seconds) =>
    switch (LockPolicy.effectiveTimeoutSeconds(seconds)) {
      0 => l10n.lockTimeoutImmediate,
      30 => l10n.lockTimeout30s,
      300 => l10n.lockTimeout5m,
      900 => l10n.lockTimeout15m,
      _ => l10n.lockTimeout1m,
    };

/// "Bloquear depois de sair do app" (D-02, UI-SPEC "Timeout dialog").
///
/// Exactly five options in `LockPolicy.timeoutOptionsSeconds` order.
/// Selecting one calls [onSelected] and closes; the only action is Cancel.
/// The dialog scrolls, so every option stays reachable at 200% text.
Future<void> showLockTimeoutDialog(
  BuildContext context, {
  required int current,
  required ValueChanged<int> onSelected,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      void select(int? seconds) {
        if (seconds == null) return;
        onSelected(seconds);
        Navigator.of(dialogContext).pop();
      }

      // The whole dialog scrolls: at 200% text the title and actions alone
      // can outgrow a small screen.
      return AlertDialog(
        scrollable: true,
        title: Text(l10n.lockTimeoutDialogTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: RadioGroup<int>(
          groupValue: current,
          onChanged: select,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final seconds in LockPolicy.timeoutOptionsSeconds)
                RadioListTile<int>(
                  value: seconds,
                  title: Text(lockTimeoutLabel(l10n, seconds)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
        ],
      );
    },
  );
}
