import 'dart:async';

import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/application/settings/security_settings_cubit.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/screens/pin_setup_screen.dart';
import 'package:agenda/presentation/settings/security/biometric_tile.dart';
import 'package:agenda/presentation/settings/security/no_device_lock_dialog.dart';
import 'package:agenda/presentation/settings/security/pin_disable_dialog.dart';
import 'package:agenda/presentation/settings/security/timeout_dialog.dart';
import 'package:agenda/presentation/settings/widgets/settings_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Settings > Security (SC-3, DATA-05, D-02, D-08). Reads
/// [SecuritySettingsCubit] from context.
///
/// PIN off: only the switch. PIN on: switch, Alterar PIN, the biometrics
/// tile (when the device has the hardware) and Bloquear após.
///
/// The PIN switch shows `state.pinEnabled` only: turning it on or off opens
/// PIN setup, and the value changes when the lock itself changes, never
/// optimistically (T-05-40). Turning it off needs the confirm dialog and
/// the current PIN (T-05-41).
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<SecuritySettingsCubit>();
    final state = cubit.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.settingsSectionSecurity),
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: Text(l10n.lockPinToggle),
          subtitle: Text(l10n.lockPinToggleDesc),
          value: state.pinEnabled,
          onChanged:
              (on) => unawaited(on ? _turnOn(context) : _turnOff(context)),
        ),
        // Removed, not disabled, while the PIN is off.
        if (state.pinEnabled) ...[
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(l10n.lockChangePin),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => unawaited(
                  _runSetup(
                    context,
                    PinSetupMode.change,
                    (l10n) => l10n.pinChangedSnack,
                  ),
                ),
          ),
          const BiometricTile(),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.lockTimeoutLabel),
            subtitle: Text(lockTimeoutLabel(l10n, state.timeoutSeconds)),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => unawaited(
                  showLockTimeoutDialog(
                    context,
                    current: state.timeoutSeconds,
                    onSelected: (s) => unawaited(cubit.setTimeoutSeconds(s)),
                  ),
                ),
          ),
        ],
      ],
    );
  }

  /// On a device with no screen lock a forgotten PIN cannot be reset, so
  /// the backup warning comes first; Cancel leaves the switch OFF.
  Future<void> _turnOn(BuildContext context) async {
    final cubit = context.read<SecuritySettingsCubit>();
    if (!await cubit.hasDeviceCredential()) {
      if (!context.mounted || !await showNoDeviceLockDialog(context)) return;
    }
    if (!context.mounted) return;
    await _runSetup(
      context,
      PinSetupMode.create,
      (l10n) => l10n.pinEnabledSnack,
    );
  }

  Future<void> _turnOff(BuildContext context) async {
    if (!await showPinDisableDialog(context)) return;
    if (!context.mounted) return;
    await _runSetup(
      context,
      PinSetupMode.verify,
      (l10n) => l10n.pinDisabledSnack,
    );
  }
}

/// Pushes [PinSetupScreen] in [mode] and, when it pops true, confirms with
/// a floating SnackBar. False (closed, backed out) changes nothing.
Future<void> _runSetup(
  BuildContext context,
  PinSetupMode mode,
  String Function(AppLocalizations l10n) snack,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => PinSetupScreen(mode: mode)),
  );
  if (done != true || !context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(snack(AppLocalizations.of(context))),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
