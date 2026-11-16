import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/cooldown_ticker.dart';
import 'package:agenda/application/lock/lock_device_auth.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/core/utils/guarded.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Drives the lock-screen keypad (DATA-05), biometrics (DATA-06) and the
/// forgot-PIN check (D-06); state holds the digit count, never the digits.
/// Only [PinVerified] or a biometric success unlocks, a throw never does
/// (T-05-20, T-05-33). A D-07 cooldown blocks digits, nothing else.
@injectable
class LockScreenCubit extends Cubit<LockScreenState> {
  LockScreenCubit(
    this._verifier,
    this._appLock,
    this._deviceAuth, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(LockScreenState.initial);

  final PinVerifier _verifier;
  final AppLockCubit _appLock;
  final LockDeviceAuth _deviceAuth;
  final DateTime Function() _clock;
  late final _countdown = CooldownTicker(clock: _clock);
  String _digits = '';
  bool _offered = false;
  bool _autoPrompted = false;
  bool _prompting = false;

  /// Loads the attempts and the biometric offer. A running cooldown resumes
  /// at once; an unreadable state shows [CheckFailedMessage] (retry allowed).
  Future<void> start() async {
    if (isClosed) return;
    _countdown.cancel();
    if (state != LockScreenState.initial) emit(LockScreenState.initial);
    final loaded = await guarded(_verifier.loadAttempts, null);
    _offered = await guarded(_deviceAuth.biometricOffered, false);
    if (isClosed) return;
    _digits = '';
    switch (loaded) {
      case Success(:final value) when value.isCoolingDown(_clock()):
        _coolDown(value, 0);
      case _:
        const failed = CheckFailedMessage();
        _show(LockEntryPhase.ready, 0, loaded is Success ? null : failed);
    }
  }

  /// Appends [digit] (0-9), clearing any message; the 4th digit submits once.
  void addDigit(int digit) {
    if (state.phase != LockEntryPhase.ready) return;
    if (_digits.length >= pinLength || digit < 0 || digit > 9) return;
    _digits = '$_digits$digit';
    final n = _digits.length;
    final next = n == pinLength ? LockEntryPhase.verifying : null;
    emit(state.copyWith(phase: next, digitCount: n, clearMessage: true));
    if (n == pinLength) unawaited(_submit(_digits));
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

  /// Biometric prompt: success resets the D-07 counter and unlocks;
  /// `unavailable` hides the key; anything else keeps the keypad (D-08).
  Future<void> requestBiometric(DeviceAuthPrompt prompt) async {
    if (!_offered || _prompting) return;
    if (state.phase == LockEntryPhase.verifying) return;
    _prompting = true;
    final result = await _deviceAuth.unlockWithBiometrics(prompt);
    _prompting = false;
    if (isClosed) return;
    if (result == DeviceAuthResult.success) {
      await guarded<void>(_verifier.resetAttempts, null);
      _appLock.unlock();
    } else if (result == DeviceAuthResult.unavailable) {
      _offered = false;
      emit(state.copyWith(biometricOffered: false));
    }
  }

  /// The D-08 auto-prompt: at most once per cubit (one per lock episode).
  Future<void> autoPromptBiometric(DeviceAuthPrompt prompt) async {
    if (_autoPrompted || !_offered) return;
    _autoPrompted = true;
    await requestBiometric(prompt);
  }

  /// Forgot PIN (D-06), in any phase; see [LockDeviceAuth.confirmForgotPin].
  Future<DeviceAuthResult> confirmForgotPin(DeviceAuthPrompt prompt) =>
      _deviceAuth.confirmForgotPin(prompt);

  Future<void> _submit(String pin) async {
    final outcome = await guarded<PinVerifyOutcome>(
      () => _verifier.verify(pin, _clock()),
      const PinCheckFailed(),
    );
    if (isClosed) return;
    _digits = '';
    final tick = state.errorTick + 1;
    switch (outcome) {
      case PinVerified():
        _appLock.unlock();
      case PinCoolingDown(:final attempts):
        _coolDown(attempts, tick);
      case PinRejected() || PinCheckFailed():
        _show(LockEntryPhase.ready, tick, rejectionMessage(outcome));
    }
  }

  /// Shows [attempts]' countdown every second, then `ready`.
  void _coolDown(LockAttempts attempts, int tick) => _countdown.start(
    attempts,
    onTick:
        (left) =>
            _show(LockEntryPhase.coolingDown, tick, CooldownMessage(left)),
    onDone: () => _show(LockEntryPhase.ready, tick),
  );

  /// Emits [phase] with no digits; the dots shake when [tick] changes.
  void _show(LockEntryPhase phase, int tick, [LockMessage? message]) => emit(
    LockScreenState.entry(phase, tick, message, biometricOffered: _offered),
  );

  @override
  Future<void> close() {
    _countdown.cancel();
    return super.close();
  }
}
