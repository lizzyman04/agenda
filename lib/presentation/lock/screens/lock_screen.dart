import 'dart:async';

import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/keypad/lock_status_line.dart';
import 'package:agenda/presentation/lock/keypad/pin_dots.dart';
import 'package:agenda/presentation/lock/keypad/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The PIN lock screen (UI-SPEC "Lock screen", DATA-05).
///
/// Lives in the lock layer's own Navigator inside `LockGate`, above every
/// app route. Owns its [LockScreenCubit].
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LockScreenCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LockScreenCubit>();
    unawaited(_cubit.start());
  }

  @override
  void dispose() {
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
                          onDigit: _cubit.addDigit,
                          onBackspace: _cubit.removeDigit,
                          onClear: _cubit.clearDigits,
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
