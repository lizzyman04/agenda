import 'dart:async';

import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/keypad/biometric_key.dart';
import 'package:agenda/presentation/lock/keypad/lock_status_line.dart';
import 'package:agenda/presentation/lock/keypad/pin_dots.dart';
import 'package:agenda/presentation/lock/keypad/pin_keypad.dart';
import 'package:agenda/presentation/lock/screens/forgot_pin_button.dart';
import 'package:agenda/presentation/lock/screens/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The PIN lock screen (UI-SPEC "Lock screen", DATA-05).
///
/// Lives in the lock layer's own Navigator inside `LockGate`, above every
/// app route. Owns its [LockScreenCubit], one per lock episode. When
/// biometrics are offered it opens the OS prompt once, after the first frame
/// and only while the app is resumed (D-08, RESEARCH Pitfall 10).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LockScreenCubit _cubit;
  AppLifecycleListener? _resumeListener;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LockScreenCubit>();
    unawaited(_startThenPrompt());
  }

  Future<void> _startThenPrompt() async {
    await _cubit.start();
    if (!mounted) return;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _autoPrompt())
      ..ensureVisualUpdate();
  }

  /// Prompts now if the app is resumed, else on the next `resumed`; a
  /// prompt before the app is active fails on iOS (RESEARCH Pitfall 10).
  void _autoPrompt() {
    if (!mounted) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.resumed) {
      unawaited(_cubit.autoPromptBiometric(_prompt()));
    } else {
      _resumeListener ??= AppLifecycleListener(
        onResume: () {
          if (mounted) unawaited(_cubit.autoPromptBiometric(_prompt()));
        },
      );
    }
  }

  void _requestBiometric() => unawaited(_cubit.requestBiometric(_prompt()));

  DeviceAuthPrompt _prompt() {
    final l10n = AppLocalizations.of(context);
    return lockAuthPrompt(l10n, l10n.lockBiometricReason);
  }

  @override
  void dispose() {
    _resumeListener?.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: BlocBuilder<LockScreenCubit, LockScreenState>(
                bloc: _cubit,
                builder:
                    (context, state) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 48),
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.lockEnterPinTitle,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        LockStatusLine(message: state.message),
                        const SizedBox(height: 24),
                        PinDots(
                          count: state.digitCount,
                          errorTick: state.errorTick,
                        ),
                        const SizedBox(height: 48),
                        PinKeypad(
                          digitCount: state.digitCount,
                          // Disabled while loading, verifying and during a
                          // D-07 cooldown (the countdown is in the status).
                          enabled: state.phase == LockEntryPhase.ready,
                          onDigit: _cubit.addDigit,
                          onBackspace: _cubit.removeDigit,
                          onClear: _cubit.clearDigits,
                          // Null keeps the empty 72 dp slot, so 0 stays
                          // centred. A cancelled prompt shows no message.
                          leading:
                              state.biometricOffered
                                  ? BiometricKey(onPressed: _requestBiometric)
                                  : null,
                        ),
                        const SizedBox(height: 24),
                        ForgotPinButton(
                          onConfirm: _cubit.confirmForgotPin,
                          resetPage: const PinSetupScreen(
                            mode: PinSetupMode.reset,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
