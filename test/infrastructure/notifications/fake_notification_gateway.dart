import 'dart:async';

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';

/// In-memory [LocalNotificationGateway] for coordinator, evaluator and
/// cubit tests.
class FakeNotificationGateway implements LocalNotificationGateway {
  /// Requests currently scheduled, by notification id.
  final Map<int, ScheduleRequest> scheduled = {};

  /// Requests passed to [showNow], in call order.
  final List<ScheduleRequest> shown = [];

  /// Ids passed to [cancel], in call order.
  final List<int> cancelledIds = [];

  /// Ids for which [schedule] returns an `Err`.
  final Set<int> failScheduleIds = {};

  /// Payload returned by [launchPayload].
  String? launch;

  /// Number of [initialize] calls.
  int initializeCalls = 0;

  final StreamController<String> _taps = StreamController<String>.broadcast();

  /// Simulates the user tapping a notification while the app runs.
  void tap(String payload) => _taps.add(payload);

  @override
  AsyncResult<void> initialize() async {
    initializeCalls++;
    return const Success(null);
  }

  @override
  AsyncResult<List<PendingNotification>> pending() async => Success([
    for (final request in scheduled.values)
      PendingNotification(
        id: request.id,
        title: request.title,
        body: request.body,
        payload: request.payload,
      ),
  ]);

  @override
  AsyncResult<void> schedule(ScheduleRequest request) async {
    if (failScheduleIds.contains(request.id)) {
      return Err(NotificationFailure('fake schedule failure ${request.id}'));
    }
    scheduled[request.id] = request;
    return const Success(null);
  }

  @override
  AsyncResult<void> showNow(ScheduleRequest request) async {
    shown.add(request);
    return const Success(null);
  }

  @override
  AsyncResult<void> cancel(int id) async {
    cancelledIds.add(id);
    scheduled.remove(id);
    return const Success(null);
  }

  @override
  Stream<String> get tapPayloads => _taps.stream;

  @override
  Future<String?> launchPayload() async => launch;

  /// Releases the tap controller.
  Future<void> dispose() => _taps.close();
}
