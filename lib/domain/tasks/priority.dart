/// Task priority classification — independent of Eisenhower quadrant.
///
/// Default: Priority.medium (enforced in ItemModel and Item factory).
/// Persisted in Isar via @enumerated(EnumType.name).
enum Priority { low, medium, high, critical, urgent }
