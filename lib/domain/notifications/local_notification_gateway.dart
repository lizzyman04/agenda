import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';

/// The only door to the operating system's notification center.
///
/// Implementations live in `lib/infrastructure/notifications/gateway/`.
/// Fallible methods return [AsyncResult] and never throw, so one bad
/// request cannot abort a batch of schedule calls.
abstract interface class LocalNotificationGateway {
  /// Prepares the plugin and the notification channels.
  ///
  /// Idempotent. Never asks the user for permission: the prompt happens
  /// later, in context.
  AsyncResult<void> initialize();

  /// Notifications currently waiting in the OS schedule.
  AsyncResult<List<PendingNotification>> pending();

  /// Schedules a one-shot notification at `request.fireAt`, replacing any
  /// pending notification with the same id.
  AsyncResult<void> schedule(ScheduleRequest request);

  /// Shows [request] immediately, ignoring `fireAt`.
  AsyncResult<void> showNow(ScheduleRequest request);

  /// Cancels the pending notification with [id]. Unknown ids are not an
  /// error.
  AsyncResult<void> cancel(int id);

  /// Payloads of notifications tapped while the app is running.
  ///
  /// Broadcast stream. The payload is untrusted text: parse it with the
  /// strict payload decoder before acting on it.
  Stream<String> get tapPayloads;

  /// The payload of the notification that cold-started the app, or null
  /// when the app was launched any other way.
  Future<String?> launchPayload();
}
