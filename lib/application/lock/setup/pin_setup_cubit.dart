import 'dart:async';

import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/application/lock/setup/pin_lifecycle.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/core/utils/guarded.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Drives the PIN setup keypad in every [PinSetupMode] (DATA-05, D-06).
///
/// The digits and the first entry of a new PIN live in private fields,
/// never in state. Nothing is written until the confirmation matches (or,
/// in verify mode, the current PIN is proven); closing the cubit earlier
/// changes nothing.
@injectable
class PinSetupCubit extends Cubit<PinSetupState> {
  PinSetupCubit(
    this._lifecycle,
    this._verifier, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(
         const PinSetupState(
           mode: PinSetupMode.create,
           step: PinSetupStep.create,
         ),
       );

  final PinLifecycle _lifecycle;
  final PinVerifier _verifier;
  final DateTime Function() _clock;

  String _digits = '';
  String _first = '';

  /// Starts [mode]: the current PIN first for change and verify, otherwise
  /// the new PIN.
  void start(PinSetupMode mode) {
    _digits = '';
    _first = '';
    final asksCurrent =
        mode == PinSetupMode.change || mode == PinSetupMode.verify;
    emit(
      PinSetupState(
        mode: mode,
        step: asksCurrent ? PinSetupStep.current : PinSetupStep.create,
      ),
    );
  }

  /// Appends [digit] (0-9); the 4th digit completes the step, exactly once.
  void addDigit(int digit) {
    if (state.phase != PinSetupPhase.entering) return;
    if (_digits.length >= pinLength || digit < 0 || digit > 9) return;
    _digits = '$_digits$digit';
    if (_digits.length < pinLength) {
      emit(state.copyWith(digitCount: _digits.length, clearMessage: true));
      return;
    }
    final pin = _digits;
    _digits = '';
    switch (state.step) {
      case PinSetupStep.current:
        emit(state.busy(PinSetupPhase.verifying));
        unawaited(_checkCurrent(pin));
      case PinSetupStep.create:
        _first = pin;
        emit(state.ask(PinSetupStep.confirm));
      case PinSetupStep.confirm when pin == _first:
        emit(state.busy(PinSetupPhase.saving));
        unawaited(_save(pin));
      case PinSetupStep.confirm:
        _first = '';
        const mismatch = MismatchMessage();
        emit(state.ask(PinSetupStep.create, message: mismatch, bump: true));
    }
  }

  /// Removes the last digit.
  void removeDigit() {
    if (state.phase != PinSetupPhase.entering || _digits.isEmpty) return;
    _digits = _digits.substring(0, _digits.length - 1);
    emit(state.copyWith(digitCount: _digits.length));
  }

  /// Removes every digit.
  void clearDigits() {
    if (state.phase != PinSetupPhase.entering) return;
    _digits = '';
    emit(state.copyWith(digitCount: 0));
  }

  /// The current-PIN step: the same [PinVerifier] and persisted counter as
  /// the lock screen (D-07).
  Future<void> _checkCurrent(String pin) async {
    final outcome = await guarded<PinVerifyOutcome>(
      () => _verifier.verify(pin, _clock()),
      const PinCheckFailed(),
    );
    if (isClosed) return;
    final message = switch (outcome) {
      PinCoolingDown(:final attempts) => CooldownMessage(
        attempts.cooldownRemaining(_clock()),
      ),
      _ => rejectionMessage(outcome),
    };
    switch (outcome) {
      case PinVerified() when state.mode == PinSetupMode.verify:
        emit(state.busy(PinSetupPhase.saving));
        _finish(await guarded(_lifecycle.disable, false), PinSetupStep.current);
      case PinVerified():
        emit(state.ask(PinSetupStep.create));
      case PinCoolingDown() || PinRejected() || PinCheckFailed():
        emit(state.ask(PinSetupStep.current, message: message, bump: true));
    }
  }

  Future<void> _save(String pin) async {
    final ok = await guarded(
      () => switch (state.mode) {
        PinSetupMode.create => _lifecycle.enable(pin),
        PinSetupMode.change => _lifecycle.change(pin),
        PinSetupMode.reset => _lifecycle.reset(pin),
        PinSetupMode.verify => Future.value(false),
      },
      false,
    );
    _first = '';
    _finish(ok, PinSetupStep.create);
  }

  /// [ok] ends the flow; otherwise [retry] is asked again, failed closed.
  void _finish(bool ok, PinSetupStep retry) {
    if (isClosed) return;
    const failed = CheckFailedMessage();
    emit(
      ok
          ? state.copyWith(phase: PinSetupPhase.done)
          : state.ask(retry, message: failed, bump: true),
    );
  }
}
