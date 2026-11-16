import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:agenda/presentation/lock/widgets/privacy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Key of the lock layer's [FadeTransition] (unlock fade, tests).
const Key lockFadeKey = ValueKey('lock-fade');

/// Covers the whole app with the lock screen while [AppLockState.locked]
/// and with [PrivacyOverlay] while [AppLockState.obscured] (DATA-05,
/// RESEARCH Patterns 1 and 3).
///
/// Mounted from `MaterialApp.builder`, above the app Navigator. Layer
/// order: app, lock layer (own Navigator), overlay. Forwards `inactive`,
/// `hidden` and `resumed` to [AppLockCubit]. While locked the app is
/// [Offstage] with tickers off and keeps its navigation state. Locking is
/// instant; unlock fades the lock layer over 150 ms. System back while
/// locked goes to the app Navigator (RESEARCH Pitfall 12, accepted).
class LockGate extends StatefulWidget {
  const LockGate({required this.child, super.key});

  /// The app Navigator from `MaterialApp.builder`.
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => context.read<AppLockCubit>().onInactive(),
      onHide: () => context.read<AppLockCubit>().onHidden(),
      onResume: () => context.read<AppLockCubit>().onResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder:
          (context, state) => Stack(
            fit: StackFit.expand,
            children: [
              Offstage(
                offstage: state.locked,
                child: TickerMode(enabled: !state.locked, child: widget.child),
              ),
              _LockLayer(locked: state.locked),
              if (state.obscured) const PrivacyOverlay(),
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
