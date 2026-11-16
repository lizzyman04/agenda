import 'dart:async';

import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/screens/forgot_pin_dialog.dart';
import 'package:flutter/material.dart';

/// The OS prompt text of the lock screen, shared by biometric unlock and
/// forgot PIN; only [reason] differs. Fixed strings, no user data
/// (T-05-35).
DeviceAuthPrompt lockAuthPrompt(AppLocalizations l10n, String reason) =>
    DeviceAuthPrompt(
      reason: reason,
      title: l10n.lockBiometricSheetTitle,
      hint: l10n.lockBiometricSheetHint,
      cancelLabel: l10n.lockUsePin,
    );

/// "Esqueci meu PIN" on the lock screen (UI-SPEC "Lock screen" row 12,
/// D-06). Enabled in every phase, a cooldown included: the device
/// credential is not guessable.
///
/// [onConfirm] runs the device credential check. Success pushes
/// [resetPage] (the PIN setup screen in reset mode) on the enclosing
/// Navigator, which is the lock layer's; no screen lock shows
/// [showForgotPinUnavailableDialog]; anything else returns to the keypad
/// silently. Nothing here unlocks or disables the lock (user
/// decision 1): only saving the new PIN does.
class ForgotPinButton extends StatefulWidget {
  const ForgotPinButton({
    required this.onConfirm,
    required this.resetPage,
    super.key,
  });

  final Future<DeviceAuthResult> Function(DeviceAuthPrompt prompt) onConfirm;

  /// Where the new PIN is set once the device credential succeeded.
  final Widget resetPage;

  @override
  State<ForgotPinButton> createState() => _ForgotPinButtonState();
}

class _ForgotPinButtonState extends State<ForgotPinButton> {
  bool _running = false;

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    final l10n = AppLocalizations.of(context);
    final DeviceAuthResult result;
    try {
      result = await widget.onConfirm(
        lockAuthPrompt(l10n, l10n.lockForgotReason),
      );
    } on Object {
      // Fail closed: an error is a cancelled check.
      return;
    } finally {
      _running = false;
    }
    if (!mounted) return;
    switch (result) {
      case DeviceAuthResult.success:
        unawaited(
          Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => widget.resetPage),
          ),
        );
      case DeviceAuthResult.noDeviceCredential:
        await showForgotPinUnavailableDialog(context);
      case DeviceAuthResult.cancelled ||
          DeviceAuthResult.unavailable ||
          DeviceAuthResult.lockedOut:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => unawaited(_run()),
      child: Text(AppLocalizations.of(context).lockForgotPin),
    );
  }
}
