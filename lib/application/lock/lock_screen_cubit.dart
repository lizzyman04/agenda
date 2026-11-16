import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Drives the lock-screen keypad (DATA-05).
///
/// The entered digits live only in a private field; state carries the count.
/// The 4th digit auto-submits exactly once. Only [PinVerified] unlocks:
/// every other outcome, including a check failure, keeps the lock (fail
/// closed, T-05-20).
@injectable
class LockScreenCubit extends Cubit<LockScreenState> {
  LockScreenCubit(
    this._verifier,
    this._appLock, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(LockScreenState.initial);

  final PinVerifier _verifier;
  final AppLockCubit _appLock;
  final DateTime Function() _clock;

  String _digits = '';

  /// Loads the persisted attempt state, then accepts input.
  Future<void> start() async {
    if (isClosed) return;
    if (state != LockScreenState.initial) emit(LockScreenState.initial);
    try {
      await _verifier.loadAttempts();
    } on Object {
      // 05-09 surfaces load failures; entry stays possible (verify fails
      // closed on its own).
    }
    if (isClosed) return;
    _digits = '';
    emit(const LockScreenState(phase: LockEntryPhase.ready));
  }

  /// Appends [digit] (0-9). The 4th digit submits.
  void addDigit(int digit) {
    if (state.phase != LockEntryPhase.ready) return;
    if (_digits.length >= pinLength || digit < 0 || digit > 9) return;
    _digits = '$_digits$digit';
    if (_digits.length < pinLength) {
      emit(state.copyWith(digitCount: _digits.length));
      return;
    }
    emit(
      const LockScreenState(
        phase: LockEntryPhase.verifying,
        digitCount: pinLength,
      ),
    );
    unawaited(_submit(_digits));
  }

  /// Removes the last digit.
  void removeDigit() {
    if (state.phase != LockEntryPhase.ready || _digits.isEmpty) return;
    _digits = _digits.substring(0, _digits.length - 1);
    emit(state.copyWith(digitCount: _digits.length));
  }

  /// Removes every digit.
  void clearDigits() {
    if (state.phase != LockEntryPhase.ready) return;
    _digits = '';
    emit(state.copyWith(digitCount: 0));
  }

  Future<void> _submit(String pin) async {
    PinVerifyOutcome outcome;
    try {
      outcome = await _verifier.verify(pin, _clock());
    } on Object {
      outcome = const PinCheckFailed();
    }
    if (isClosed) return;
    _digits = '';
    if (outcome is PinVerified) {
      _appLock.unlock();
      return;
    }
    emit(const LockScreenState(phase: LockEntryPhase.ready));
  }
}
