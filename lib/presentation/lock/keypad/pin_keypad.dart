import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/keypad/keypad_key.dart';
import 'package:flutter/material.dart';

/// The shared 3x4 PIN keypad (UI-SPEC "PinKeypad"), used by the lock screen
/// and the PIN setup screen.
///
/// Rows 1-2-3, 4-5-6, 7-8-9, then [leading] / 0 / backspace. Column gap 24,
/// row gap 16; every key is a 72 dp target. Backspace is disabled with no
/// digits; long-pressing it clears every digit.
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

  /// False disables every digit key and backspace (D-07 cooldown). The
  /// [leading] key is untouched: biometrics are not guessable.
  final bool enabled;

  /// Bottom-left key (biometrics); an empty 72 dp slot when null.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    Widget digit(int d) =>
        DigitKey(digit: d, enabled: enabled, onTap: () => onDigit(d));
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
          leading ??
              const SizedBox(width: keypadKeySize, height: keypadKeySize),
          digit(0),
          KeypadIconKey(
            icon: Icons.backspace_outlined,
            tooltip: AppLocalizations.of(context).lockDeleteDigit,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onTap: canDelete ? onBackspace : null,
            onLongPress: canDelete ? onClear : null,
          ),
        ]),
      ],
    );
  }
}
