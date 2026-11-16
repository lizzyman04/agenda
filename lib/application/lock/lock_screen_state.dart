import 'package:equatable/equatable.dart';

/// What the lock-screen keypad accepts right now.
enum LockEntryPhase {
  /// The persisted attempt state is still loading; input is ignored.
  loading,

  /// Digits may be entered.
  ready,

  /// Four digits were entered and are being checked; input is ignored.
  verifying,
}

/// Lock-screen keypad state.
///
/// Holds only how MANY digits were entered, never the digits themselves, so
/// no PIN can leak through state, equality or `toString`.
final class LockScreenState extends Equatable {
  const LockScreenState({required this.phase, this.digitCount = 0});

  /// The state before the attempt state has loaded.
  static const LockScreenState initial = LockScreenState(
    phase: LockEntryPhase.loading,
  );

  final LockEntryPhase phase;

  /// Number of digits entered, 0 to 4.
  final int digitCount;

  LockScreenState copyWith({LockEntryPhase? phase, int? digitCount}) =>
      LockScreenState(
        phase: phase ?? this.phase,
        digitCount: digitCount ?? this.digitCount,
      );

  @override
  List<Object?> get props => [phase, digitCount];
}
