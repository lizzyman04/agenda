import 'dart:async';

import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/rules/tap_target.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/presentation/notifications/routing/tap_navigator.dart';
import 'package:flutter/material.dart';

/// Routes notification taps to the screen they point at.
///
/// Mount it below the app `Navigator` and the cubit providers (the app shell
/// does). Taps while the app runs arrive on the gateway's tap stream; the tap
/// that cold-started the app is read once after the first frame.
class NotificationTapListener extends StatefulWidget {
  const NotificationTapListener({
    required this.child,
    this.gateway,
    this.itemRepository,
    this.goalRepository,
    super.key,
  });

  final Widget child;
  final LocalNotificationGateway? gateway;
  final ItemRepository? itemRepository;
  final GoalRepository? goalRepository;

  @override
  State<NotificationTapListener> createState() =>
      _NotificationTapListenerState();
}

class _NotificationTapListenerState extends State<NotificationTapListener> {
  late final LocalNotificationGateway _gateway =
      widget.gateway ?? getIt<LocalNotificationGateway>();
  late final StreamSubscription<String> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _gateway.tapPayloads.listen(_handle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleLaunch());
    });
  }

  Future<void> _handleLaunch() async {
    try {
      final payload = await _gateway.launchPayload();
      _handle(payload);
    } on Object {
      // A broken launch payload must never stop the app from opening.
    }
  }

  void _handle(String? payload) {
    if (!mounted) return;
    final target = resolveTapTarget(payload);
    if (target is AppOnly) return;
    unawaited(_open(target));
  }

  Future<void> _open(TapTarget target) async {
    try {
      await openTapTarget(
        context,
        target,
        items: widget.itemRepository ?? getIt<ItemRepository>(),
        goals: widget.goalRepository ?? getIt<GoalRepository>(),
      );
    } on Object {
      // Navigation is best effort: a failed tap lands on the current screen.
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
