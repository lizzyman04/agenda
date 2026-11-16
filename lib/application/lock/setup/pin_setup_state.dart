import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:equatable/equatable.dart';

/// Why the PIN setup screen was opened (UI-SPEC "PIN setup screen").
enum PinSetupMode {
  /// Switch the lock on: new PIN, then its confirmation.
  create,

  /// Current PIN, then a new PIN and its confirmation.
  change,

  /// Current PIN only, then the lock is switched off.
  verify,

  /// Forgot PIN (D-06): new PIN and confirmation after the device credential.
  reset,
}

/// Which PIN the keypad is asking for.
enum PinSetupStep { current, create, confirm }

/// What the setup keypad accepts right now.
enum PinSetupPhase {
  /// Digits may be entered.
  entering,

  /// The current PIN is being checked; input is ignored.
  verifying,

  /// A D-07 cooldown from the shared counter is running; input is ignored.
  coolingDown,

  /// The PIN is being saved or the lock switched off; input is ignored.
  saving,

  /// Finished; the screen closes (or unlocks in reset mode).
  done,
}

/// PIN setup keypad state.
///
/// Like the lock screen, it holds only how MANY digits were entered, never
/// the digits, so no PIN can leak through state, equality or `toString`.
final class PinSetupState extends Equatable {
  const PinSetupState({
    required this.mode,
    required this.step,
    this.phase = PinSetupPhase.entering,
    this.digitCount = 0,
    this.message,
    this.errorTick = 0,
  });

  /// The first step of [mode]: the current PIN for change and verify,
  /// otherwise the new PIN.
  factory PinSetupState.initial(PinSetupMode mode) => PinSetupState(
    mode: mode,
    step: switch (mode) {
      PinSetupMode.change || PinSetupMode.verify => PinSetupStep.current,
      PinSetupMode.create || PinSetupMode.reset => PinSetupStep.create,
    },
  );

  final PinSetupMode mode;
  final PinSetupStep step;
  final PinSetupPhase phase;

  /// Number of digits entered, 0 to 4.
  final int digitCount;

  /// The status-line message, or null for an empty line.
  final LockMessage? message;

  /// Increments on every rejected entry; the PIN dots shake when it changes.
  final int errorTick;

  /// A copy; [clearMessage] drops [message] (a null [message] keeps it).
  PinSetupState copyWith({
    PinSetupStep? step,
    PinSetupPhase? phase,
    int? digitCount,
    LockMessage? message,
    bool clearMessage = false,
    int? errorTick,
  }) => PinSetupState(
    mode: mode,
    step: step ?? this.step,
    phase: phase ?? this.phase,
    digitCount: digitCount ?? this.digitCount,
    message: clearMessage ? null : message ?? this.message,
    errorTick: errorTick ?? this.errorTick,
  );

  /// Asks for [step] with no digits; [bump] shakes the dots.
  PinSetupState ask(
    PinSetupStep step, {
    LockMessage? message,
    bool bump = false,
  }) => PinSetupState(
    mode: mode,
    step: step,
    message: message,
    errorTick: bump ? errorTick + 1 : errorTick,
  );

  /// The current-PIN step during a D-07 cooldown with [left] to wait.
  PinSetupState cooling(Duration left, int tick) => PinSetupState(
    mode: mode,
    step: PinSetupStep.current,
    phase: PinSetupPhase.coolingDown,
    message: CooldownMessage(left),
    errorTick: tick,
  );

  /// Four digits entered, now [phase]; the message is cleared.
  PinSetupState busy(PinSetupPhase phase) =>
      copyWith(phase: phase, digitCount: 4, clearMessage: true);

  @override
  List<Object?> get props => [
    mode,
    step,
    phase,
    digitCount,
    message,
    errorTick,
  ];
}
