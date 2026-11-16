import 'dart:async';

import 'package:agenda/application/settings/security_settings_cubit.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Desbloquear com biometria" (DATA-06, D-08). Reads
/// [SecuritySettingsCubit] from context.
///
/// Absent until availability resolves and on devices without biometric
/// hardware; disabled with `lockBiometricNotEnrolled` when nothing is
/// enrolled; otherwise a switch over the stored preference (default on).
class BiometricTile extends StatelessWidget {
  const BiometricTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<SecuritySettingsCubit>();
    final state = cubit.state;
    final enrolled = state.availability == BiometricAvailability.enrolled;
    return switch (state.availability) {
      null || BiometricAvailability.noHardware => const SizedBox.shrink(),
      _ => SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: Text(l10n.lockBiometricToggle),
        subtitle: Text(
          enrolled
              ? l10n.lockBiometricToggleDesc
              : l10n.lockBiometricNotEnrolled,
        ),
        value: enrolled && state.biometricEnabled,
        onChanged:
            enrolled
                ? (on) => unawaited(cubit.setBiometricEnabled(enabled: on))
                : null,
      ),
    };
  }
}
