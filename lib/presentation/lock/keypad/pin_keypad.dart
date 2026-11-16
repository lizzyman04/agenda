import 'dart:async';

import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The shared 3x4 PIN keypad (UI-SPEC "PinKeypad"), used by the lock screen
/// and the PIN setup screen.
///
/// Rows 1-2-3, 4-5-6, 7-8-9, then [leading] / 0 / backspace. Column gap 24,
/// row gap 16; every key is a 72 dp target.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.digitCount,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.enabled = true,
    this.leading,
    super.key,
  });

  /// Digits entered so far, 0 to 4.
  final int digitCount;
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// False disables every digit key and backspace (cooldown).
  final bool enabled;

  /// Bottom-left key (biometrics); an empty 72 dp slot when null.
  final Widget? leading;

  static const double keySize = 72;

  @override
  Widget build(BuildContext context) {
    Widget digit(int d) => _DigitKey(
      digit: d,
      onTap: enabled ? () => onDigit(d) : null,
    );
    Widget row(List<Widget> keys) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        keys[0],
        const SizedBox(width: 24),
        keys[1],
        const SizedBox(width: 24),
        keys[2],
      ],
    );
    final canDelete = enabled && digitCount > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit(1), digit(2), digit(3)]),
        const SizedBox(height: 16),
        row([digit(4), digit(5), digit(6)]),
        const SizedBox(height: 16),
        row([digit(7), digit(8), digit(9)]),
        const SizedBox(height: 16),
        row([
          leading ?? const SizedBox(width: keySize, height: keySize),
          digit(0),
          _BackspaceKey(
            onTap: canDelete ? onBackspace : null,
            onLongPress: canDelete ? onClear : null,
          ),
        ]),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onTap});

  final int digit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: PinKeypad.keySize,
      height: PinKeypad.keySize,
      child: Material(
        shape: const CircleBorder(),
        color: cs.surfaceContainerHighest,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap:
              onTap == null
                  ? null
                  : () {
                    unawaited(HapticFeedback.selectionClick());
                    onTap!();
                  },
          child: Center(
            child: Text(
              '$digit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({required this.onTap, required this.onLongPress});

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context).lockDeleteDigit,
      child: SizedBox(
        width: PinKeypad.keySize,
        height: PinKeypad.keySize,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
