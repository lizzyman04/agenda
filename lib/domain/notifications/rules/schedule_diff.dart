import 'package:agenda/domain/notifications/model/schedule_request.dart';

/// What must change on the device to reach the desired schedule.
final class ScheduleDiff {
  const ScheduleDiff({required this.cancelIds, required this.toSchedule});

  final List<int> cancelIds;
  final List<ScheduleRequest> toSchedule;

  bool get isEmpty => cancelIds.isEmpty && toSchedule.isEmpty;
}

/// Diffs [desired] against planner-owned [pending] entries.
///
/// A request is scheduled when no pending entry has its id or the pending
/// title, body or payload differs (the payload embeds fire time and mode).
/// A pending id absent from [desired] is cancelled. Duplicate desired ids
/// keep the first occurrence. An unchanged state yields an empty diff.
ScheduleDiff diffSchedules({
  required List<ScheduleRequest> desired,
  required List<PendingNotification> pending,
}) {
  final pendingById = {for (final p in pending) p.id: p};
  final seen = <int>{};
  final toSchedule = <ScheduleRequest>[];
  for (final request in desired) {
    if (!seen.add(request.id)) continue;
    final current = pendingById[request.id];
    final unchanged =
        current != null &&
        current.title == request.title &&
        current.body == request.body &&
        current.payload == request.payload;
    if (!unchanged) toSchedule.add(request);
  }
  final cancelIds = [
    for (final p in pending)
      if (!seen.contains(p.id)) p.id,
  ];
  return ScheduleDiff(cancelIds: cancelIds, toSchedule: toSchedule);
}
