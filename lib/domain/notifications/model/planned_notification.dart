import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:equatable/equatable.dart';

/// A notification the planner wants on the device, before localization.
///
/// Carries no localized text: infrastructure turns it into a
/// `ScheduleRequest` so this layer stays Flutter-free.
final class PlannedNotification extends Equatable {
  const PlannedNotification({
    required this.kind,
    required this.id,
    required this.fireAt,
    this.entityId = 0,
    this.subject = '',
    this.count = 0,
    this.variant = 0,
    this.extras = const [],
  });

  final NotificationKind kind;

  /// Deterministic plugin id (see `notificationId`).
  final int id;

  /// Local wall-clock fire time.
  final DateTime fireAt;

  /// Id of the entity the notification is about (0 when none).
  final int entityId;

  /// Primary free text, for example a task title.
  final String subject;

  /// Briefing task count or budget percentage.
  final int count;

  /// Debt direction (0 toPay, 1 toReceive) or task kind (0 timed, 1 date).
  final int variant;

  /// Briefing top titles or the task due time text.
  final List<String> extras;

  PlannedNotification copyWith({DateTime? fireAt}) => PlannedNotification(
    kind: kind,
    id: id,
    fireAt: fireAt ?? this.fireAt,
    entityId: entityId,
    subject: subject,
    count: count,
    variant: variant,
    extras: extras,
  );

  @override
  List<Object?> get props => [
    kind,
    id,
    fireAt,
    entityId,
    subject,
    count,
    variant,
    extras,
  ];
}
