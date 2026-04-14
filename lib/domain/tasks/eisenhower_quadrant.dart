/// Eisenhower Matrix quadrant — NEVER persisted to Isar.
///
/// Computed from the (isUrgent, isImportant) pair on the Item entity.
/// Sealed so exhaustive switch expressions are enforced at compile time.
enum EisenhowerQuadrant {
  /// Q1 — Urgent + Important: Do Now
  doNow,
  /// Q2 — Not Urgent + Important: Schedule
  schedule,
  /// Q3 — Urgent + Not Important: Delegate
  delegate,
  /// Q4 — Not Urgent + Not Important: Eliminate
  eliminate,
}
