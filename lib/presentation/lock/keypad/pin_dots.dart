import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Four PIN dots: [count] filled in `cs.primary`, the rest as 2 dp
/// `cs.outline` rings (UI-SPEC "PinKeypad"). Screen readers hear one label,
/// `lockDigitsEntered(count)`, never the individual circles.
class PinDots extends StatelessWidget {
  const PinDots({required this.count, super.key});

  /// Digits entered, 0 to 4.
  final int count;

  static const int _total = 4;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: AppLocalizations.of(context).lockDigitsEntered(count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _total; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _Dot(filled: i < count, colors: cs),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.colors});

  final bool filled;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(filled ? 'pin-dot-filled' : 'pin-dot-empty'),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.primary : Colors.transparent,
        border: filled ? null : Border.all(color: colors.outline, width: 2),
      ),
    );
  }
}
