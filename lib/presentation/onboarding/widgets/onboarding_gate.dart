import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/presentation/onboarding/screens/privacy_statement_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows the first-launch privacy statement until it is accepted, then
/// [child] (UX-03, D-12).
///
/// The flag is read synchronously in `initState`, so a later launch builds
/// [child] on the very first frame. Acceptance persists first, then
/// transitions: a failed write keeps the statement on screen. Because the
/// gate swaps its own subtree, no route leads back to the statement.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({required this.child, super.key});

  /// The main UI, built only after the statement was accepted.
  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool _shown;

  @override
  void initState() {
    super.initState();
    _shown = _readShown();
  }

  bool _readShown() {
    try {
      return getIt<SharedPreferences>().getBool(
            StorageKeys.privacyStatementShown,
          ) ??
          false;
    } on Object {
      return false;
    }
  }

  Future<void> _accept() async {
    var saved = false;
    try {
      saved = await getIt<SharedPreferences>().setBool(
        StorageKeys.privacyStatementShown,
        true,
      );
    } on Object {
      saved = false;
    }
    if (saved && mounted) setState(() => _shown = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_shown) return widget.child;
    return PrivacyStatementScreen(onGetStarted: _accept);
  }
}
