import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diameter of every keypad target (UI-SPEC: 72 dp, above the 48 dp
/// minimum).
const double keypadKeySize = 72;

/// A round 0-9 key: `cs.surfaceContainerHighest` fill, `headlineMedium`
/// digit, selection haptic. Disabled (cooldown) keys use the M3 disabled
/// colors: label at 38% and fill at 12% of `cs.onSurface`.
class DigitKey extends StatelessWidget {
  const DigitKey({
    required this.digit,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final int digit;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = enabled ? cs.onSurface : cs.onSurface.withValues(alpha: .38);
    final fill =
        enabled
            ? cs.surfaceContainerHighest
            : cs.onSurface.withValues(alpha: .12);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: '$digit',
      child: SizedBox(
        width: keypadKeySize,
        height: keypadKeySize,
        child: Material(
          shape: const CircleBorder(),
          color: fill,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? _tap : null,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  '$digit',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tap() {
    unawaited(HapticFeedback.selectionClick());
    onTap();
  }
}

/// A transparent round icon key with a tooltip (backspace, biometrics).
/// Null [onTap] disables it.
class KeypadIconKey extends StatelessWidget {
  const KeypadIconKey({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.size = 24,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Icon size; the target is always [keypadKeySize].
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // The container sits outside the Tooltip so the tooltip text names this
    // node for screen readers.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: keypadKeySize,
          height: keypadKeySize,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Icon(
              icon,
              size: size,
              color: enabled ? color : color.withValues(alpha: .38),
            ),
          ),
        ),
      ),
    );
  }
}
