import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/keypad/keypad_key.dart';
import 'package:flutter/material.dart';

/// The keypad's bottom-left biometric key (UI-SPEC "PinKeypad",
/// DATA-06): a transparent 72 dp target with [Icons.fingerprint] on
/// Android and [Icons.face] on iOS, size 32, `cs.primary`, tooltip
/// `lockBiometricToggle`. Tapping it re-opens the OS prompt.
///
/// Shown only when biometrics are offered. It stays enabled during a D-07
/// cooldown, because a biometric is not guessable.
class BiometricKey extends StatelessWidget {
  const BiometricKey({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KeypadIconKey(
      icon:
          theme.platform == TargetPlatform.iOS ? Icons.face : Icons.fingerprint,
      size: 32,
      tooltip: AppLocalizations.of(context).lockBiometricToggle,
      color: theme.colorScheme.primary,
      onTap: onPressed,
    );
  }
}
