import 'dart:async';
import 'dart:math' as math;

import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Four PIN dots: [count] filled in `cs.primary`, the rest as 2 dp
/// `cs.outline` rings (UI-SPEC "PinKeypad"). Screen readers hear one label,
/// `lockDigitsEntered(count)`, never the individual circles.
///
/// Each change of [errorTick] plays the wrong-entry feedback: all four dots
/// in `cs.error` for 300 ms, shaking ±8 dp over 3 cycles (`easeInOut`) with
/// a medium haptic. Under `MediaQuery.disableAnimations` the shake is
/// skipped and only the error dots show.
class PinDots extends StatefulWidget {
  const PinDots({required this.count, this.errorTick = 0, super.key});

  /// Digits entered, 0 to 4.
  final int count;

  /// Changes on every rejected entry.
  final int errorTick;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  static const int _total = 4;
  static const double _amplitude = 8;
  static const int _cycles = 3;

  // `preserve`: the error dots last 300 ms even when the platform asks for
  // shorter animations; reduced motion only removes the movement.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void didUpdateWidget(PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorTick != oldWidget.errorTick) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(_shake.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  double _offset(bool reduceMotion) {
    if (reduceMotion || !_shake.isAnimating) return 0;
    final t = Curves.easeInOut.transform(_shake.value);
    return _amplitude * math.sin(t * _cycles * 2 * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label: AppLocalizations.of(context).lockDigitsEntered(widget.count),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, _) {
            final error = _shake.isAnimating;
            return Transform.translate(
              key: const ValueKey('pin-dots-shake'),
              offset: Offset(_offset(reduceMotion), 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _total; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    _Dot(
                      kind:
                          error
                              ? _DotKind.error
                              : i < widget.count
                              ? _DotKind.filled
                              : _DotKind.empty,
                      colors: cs,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _DotKind { empty, filled, error }

class _Dot extends StatelessWidget {
  const _Dot({required this.kind, required this.colors});

  final _DotKind kind;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('pin-dot-${kind.name}'),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (kind) {
          _DotKind.empty => Colors.transparent,
          _DotKind.filled => colors.primary,
          _DotKind.error => colors.error,
        },
        border:
            kind == _DotKind.empty
                ? Border.all(color: colors.outline, width: 2)
                : null,
      ),
    );
  }
}
