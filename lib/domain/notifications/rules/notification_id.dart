/// Largest entity id that still produces an id fitting a signed int32.
const int maxNotificationEntityId = 999999;

/// Last-digit notification types inside one id namespace.
abstract final class NotificationIdTypes {
  static const int taskDue = 0;
  static const int taskRecurring = 1;
  static const int debt = 0;
  static const int payment = 1;
  static const int goalWeekly = 2;
  static const int budget80 = 3;
  static const int budget100 = 4;
  static const int goalImmediate = 5;
  static const int briefing = 0;
  static const int quote = 1;
}

const Set<int> _bases = {10, 20, 30};
const int _financeBase = 20;
const Set<int> _evaluatorTypes = {
  NotificationIdTypes.budget80,
  NotificationIdTypes.budget100,
  NotificationIdTypes.goalImmediate,
};

/// Derives a deterministic id: `base * 10_000_000 + entityId * 10 + type`.
///
/// The largest result is 309,999,999, below the int32 maximum. Throws
/// [RangeError] when [entityId] is outside 0..[maxNotificationEntityId] or
/// [type] outside 0..9. Planners must skip an entity whose id exceeds the
/// maximum instead of calling this with it.
int notificationId({
  required int base,
  required int entityId,
  required int type,
}) {
  RangeError.checkValueInInterval(
    entityId,
    0,
    maxNotificationEntityId,
    'entityId',
  );
  RangeError.checkValueInInterval(type, 0, 9, 'type');
  return base * 10000000 + entityId * 10 + type;
}

/// Splits an [id] back into its parts, or null when it is not ours.
({int base, int entityId, int type})? decodeNotificationId(int id) {
  if (id < 0) return null;
  final base = id ~/ 10000000;
  if (!_bases.contains(base)) return null;
  final rest = id % 10000000;
  return (base: base, entityId: rest ~/ 10, type: rest % 10);
}

/// True for decodable ids except budget and immediate goal alerts.
bool isPlannerOwnedId(int id) {
  final parts = decodeNotificationId(id);
  if (parts == null) return false;
  return !(parts.base == _financeBase && _evaluatorTypes.contains(parts.type));
}
