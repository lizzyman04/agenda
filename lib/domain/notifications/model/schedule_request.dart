import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:equatable/equatable.dart';

/// A fully localized request the gateway hands to the plugin.
final class ScheduleRequest extends Equatable {
  const ScheduleRequest({
    required this.id,
    required this.kind,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.payload,
    required this.exact,
  });

  final int id;
  final NotificationKind kind;

  /// Local wall-clock fire time.
  final DateTime fireAt;
  final String title;
  final String body;

  /// Tap payload (see `encodePayload`).
  final String payload;

  /// Whether the platform may use an exact alarm.
  final bool exact;

  @override
  List<Object?> get props => [id, kind, fireAt, title, body, payload, exact];
}

/// The shape the plugin returns for a pending request.
final class PendingNotification extends Equatable {
  const PendingNotification({
    required this.id,
    this.title,
    this.body,
    this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;

  @override
  List<Object?> get props => [id, title, body, payload];
}
