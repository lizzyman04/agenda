import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/keypad/lock_status_line.dart';
import 'package:agenda/presentation/lock/keypad/pin_dots.dart';
import 'package:agenda/presentation/lock/keypad/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The PIN setup screen (UI-SPEC "PIN setup screen", DATA-05).
///
/// The lock-screen column without the lock icon, the biometric key or the
/// forgot-PIN button. Pops `true` once the flow succeeds and `false` when
/// closed or backed out of before the save, which changes nothing. Reset
/// mode (forgot PIN) has no AppBar and cannot be left.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({required this.mode, super.key});

  final PinSetupMode mode;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  late final PinSetupCubit _cubit;

  bool get _reset => widget.mode == PinSetupMode.reset;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PinSetupCubit>()..start(widget.mode);
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  /// Pops true; in reset mode unlocks instead and confirms over the app
  /// (the caller of the other modes shows its own SnackBar).
  void _onDone(BuildContext context, PinSetupState state) {
    if (!_reset) {
      Navigator.of(context).pop(true);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final text = AppLocalizations.of(context).pinChangedSnack;
    context.read<AppLockCubit>().unlock();
    messenger.showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String? _appBarTitle(AppLocalizations l10n) => switch (widget.mode) {
    PinSetupMode.create => l10n.pinSetupTitle,
    PinSetupMode.change => l10n.lockChangePin,
    PinSetupMode.verify => l10n.lockPinToggle,
    PinSetupMode.reset => null,
  };

  static String _prompt(AppLocalizations l10n, PinSetupStep step) =>
      switch (step) {
        PinSetupStep.current => l10n.pinCurrentPrompt,
        PinSetupStep.create => l10n.pinCreatePrompt,
        PinSetupStep.confirm => l10n.pinConfirmPrompt,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = _appBarTitle(l10n);
    // Back counts as cancel (false); in reset mode there is no way back.
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_reset) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar:
            title == null
                ? null
                : AppBar(
                  title: Text(title),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.cancelButton,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: BlocConsumer<PinSetupCubit, PinSetupState>(
                bloc: _cubit,
                listenWhen:
                    (a, b) =>
                        a.phase != b.phase && b.phase == PinSetupPhase.done,
                listener: _onDone,
                builder:
                    (context, state) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 48),
                        AnimatedSwitcher(
                          duration:
                              MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 150),
                          child: Text(
                            _prompt(l10n, state.step),
                            key: ValueKey(state.step),
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
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
                          enabled: state.phase == PinSetupPhase.entering,
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
