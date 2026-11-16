import 'package:equatable/equatable.dart';

/// What the lock-screen keypad accepts right now.
enum LockEntryPhase {
  /// The persisted attempt state is still loading; input is ignored.
  loading,

  /// Digits may be entered.
  ready,

  /// Four digits were entered and are being checked; input is ignored.
  verifying,

  /// A D-07 cooldown is running; digit and backspace input is ignored.
  coolingDown,
}

/// What the lock-screen status line says (UI-SPEC "Lock screen" row 6).
///
/// Messages state only how many attempts remain or how long to wait, never
/// anything about the digits (T-05-28).
sealed class LockMessage extends Equatable {
  const LockMessage();

  @override
  List<Object?> get props => [];
}

/// A wrong PIN; [remaining] more wrong PINs before the first cooldown.
final class WrongPinMessage extends LockMessage {
  const WrongPinMessage(this.remaining);

  final int remaining;

  @override
  List<Object?> get props => [remaining];
}

/// A cooldown is running; [remaining] is the time left.
final class CooldownMessage extends LockMessage {
  const CooldownMessage(this.remaining);

  final Duration remaining;

  @override
  List<Object?> get props => [remaining];
}

/// The attempt state or the PIN record could not be read; retry is allowed.
final class CheckFailedMessage extends LockMessage {
  const CheckFailedMessage();
}

/// Lock-screen keypad state.
///
/// Holds only how MANY digits were entered, never the digits themselves, so
/// no PIN can leak through state, equality or `toString`.
final class LockScreenState extends Equatable {
  const LockScreenState({
    required this.phase,
    this.digitCount = 0,
    this.message,
    this.errorTick = 0,
  });

  /// The state before the attempt state has loaded.
  static const LockScreenState initial = LockScreenState(
    phase: LockEntryPhase.loading,
  );

  final LockEntryPhase phase;

  /// Number of digits entered, 0 to 4.
  final int digitCount;

  /// The status-line message, or null for an empty line.
  final LockMessage? message;

  /// Increments on every rejected entry; the PIN dots shake when it changes.
  final int errorTick;

  /// A copy; [clearMessage] drops [message] (a null [message] keeps it).
  LockScreenState copyWith({
    LockEntryPhase? phase,
    int? digitCount,
    LockMessage? message,
    bool clearMessage = false,
    int? errorTick,
  }) => LockScreenState(
    phase: phase ?? this.phase,
    digitCount: digitCount ?? this.digitCount,
    message: clearMessage ? null : message ?? this.message,
    errorTick: errorTick ?? this.errorTick,
  );

  @override
  List<Object?> get props => [phase, digitCount, message, errorTick];
}
