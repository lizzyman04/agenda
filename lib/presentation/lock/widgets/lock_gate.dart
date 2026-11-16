import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Key of the lock layer's [FadeTransition] (unlock fade, tests).
const Key lockFadeKey = ValueKey('lock-fade');

/// Covers the whole app with the lock screen while [AppLockState.locked]
/// (DATA-05, RESEARCH Pattern 1).
///
/// Mounted from `MaterialApp.builder`, so it sits above the app Navigator
/// and no route, dialog or sheet can draw over the lock. Layer order is
/// fixed: app below, lock above. The lock layer has its own Navigator,
/// which gives it an Overlay for tooltips and dialogs.
///
/// While locked the app is [Offstage] (not painted, not hit-testable, no
/// semantics) with tickers off, and keeps its navigation state. On unlock
/// the app is onstage in the same frame and only the lock layer fades out
/// over 150 ms, instantly when animations are disabled. Locking is always
/// instant.
///
/// System back while locked (RESEARCH Pitfall 12, accepted): the event goes
/// to the app Navigator, which may pop a hidden route or leave the app. The
/// lock layer is not a route, so it stays.
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
              _LockLayer(locked: state.locked),
            ],
          ),
    );
  }
}

class _LockLayer extends StatefulWidget {
  const _LockLayer({required this.locked});

  final bool locked;

  @override
  State<_LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends State<_LockLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    value: widget.locked ? 1 : 0,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status.isDismissed && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_LockLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !oldWidget.locked) {
      // A soft keyboard opened by a hidden field must not stay up.
      FocusManager.instance.primaryFocus?.unfocus();
      _fade.value = 1;
    } else if (!widget.locked && oldWidget.locked) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _fade.value = 0;
      } else {
        unawaited(_fade.reverse(from: 1));
      }
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.locked && _fade.isDismissed) return const SizedBox.shrink();
    // The structure stays the same while fading, so the lock screen is not
    // rebuilt; it only stops taking input and leaves the semantics tree.
    return IgnorePointer(
      ignoring: !widget.locked,
      child: ExcludeSemantics(
        excluding: !widget.locked,
        child: FadeTransition(
          key: lockFadeKey,
          opacity: _fade,
          child: const _LockNavigator(),
        ),
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
