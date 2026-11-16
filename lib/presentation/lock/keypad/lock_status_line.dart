import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Height of the status slot: two lines of `bodyMedium` (14/20), fixed so a
/// message never moves the dots or the keypad (UI-SPEC "Lock status line").
const double lockStatusLineHeight = 40;

/// [remaining] as `m:ss`, seconds rounded up (29.2 s -> `0:30`), so the
/// countdown never shows `0:00` while input is still blocked.
String formatCooldown(Duration remaining) {
  const perSecond = Duration.microsecondsPerSecond;
  final micros = remaining.inMicroseconds;
  final seconds = micros <= 0 ? 0 : (micros + perSecond - 1) ~/ perSecond;
  final minutes = seconds ~/ 60;
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// The lock-screen status line (UI-SPEC "Lock screen" row 6): wrong PIN and
/// storage failure in `cs.error`, the cooldown countdown in
/// `cs.onSurfaceVariant` (a wait, not a failure), empty when [message] is
/// null. A live region, so screen readers announce every change.
class LockStatusLine extends StatelessWidget {
  const LockStatusLine({this.message, super.key});

  final LockMessage? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (text, color) = switch (message) {
      WrongPinMessage(:final remaining) => (
        l10n.lockWrongPin(remaining),
        cs.error,
      ),
      CooldownMessage(:final remaining) => (
        l10n.lockCooldown(formatCooldown(remaining)),
        cs.onSurfaceVariant,
      ),
      CheckFailedMessage() => (l10n.lockErrorGeneric, cs.error),
      null => ('', cs.onSurfaceVariant),
    };
    return SizedBox(
      height: lockStatusLineHeight,
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            text,
            key: const ValueKey('lock-status-text'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
