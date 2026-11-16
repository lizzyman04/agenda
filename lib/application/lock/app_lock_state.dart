import 'package:equatable/equatable.dart';

/// App-wide lock state (DATA-05, D-01).
///
/// [locked] decides whether the lock layer covers the app; [obscured] is the
/// privacy overlay shown while the app is in the background (plan 05-08).
final class AppLockState extends Equatable {
  const AppLockState({
    required this.pinEnabled,
    required this.locked,
    this.obscured = false,
  });

  /// Whether a PIN is configured (`StorageKeys.pinConfigured`).
  final bool pinEnabled;

  /// Whether the lock screen covers the app.
  final bool locked;

  /// Whether the privacy overlay covers the app.
  final bool obscured;

  AppLockState copyWith({bool? pinEnabled, bool? locked, bool? obscured}) =>
      AppLockState(
        pinEnabled: pinEnabled ?? this.pinEnabled,
        locked: locked ?? this.locked,
        obscured: obscured ?? this.obscured,
      );

  @override
  List<Object?> get props => [pinEnabled, locked, obscured];
}
