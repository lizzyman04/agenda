import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Covers the whole app with the lock screen while [AppLockState.locked]
/// (DATA-05, RESEARCH Pattern 1).
///
/// Mounted from `MaterialApp.builder`, so it sits above the app Navigator
/// and no route, dialog or sheet can draw over the lock. The lock layer has
/// its own Navigator, which gives it an Overlay for tooltips and dialogs.
/// While locked the app is [Offstage] (not painted, not hit-testable, no
/// semantics) with tickers off, and keeps its navigation state.
class LockGate extends StatelessWidget {
  const LockGate({required this.child, super.key});

  /// The app Navigator from `MaterialApp.builder`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder:
          (context, state) => Stack(
            fit: StackFit.expand,
            children: [
              Offstage(
                offstage: state.locked,
                child: TickerMode(enabled: !state.locked, child: child),
              ),
              if (state.locked) const _LockNavigator(),
            ],
          ),
    );
  }
}

class _LockNavigator extends StatelessWidget {
  const _LockNavigator();

  @override
  Widget build(BuildContext context) {
    // MaterialApp's HeroController belongs to the app Navigator; sharing it
    // with a second Navigator asserts, so the lock layer opts out.
    return HeroControllerScope.none(
      child: Navigator(
        onGenerateRoute:
            (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => const LockScreen(),
            ),
      ),
    );
  }
}
