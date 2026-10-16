/// What one reconcile run did to the OS schedule.
final class ReconcileReport {
  const ReconcileReport({
    this.scheduled = 0,
    this.cancelled = 0,
    this.truncated = 0,
    this.failures = 0,
    this.aborted = false,
  });

  /// A run that stopped before changing anything.
  const ReconcileReport.aborted() : this(aborted: true);

  /// Requests handed to the OS successfully.
  final int scheduled;

  /// Pending notifications cancelled successfully.
  final int cancelled;

  /// Reminders the planner left out because of the slot budget.
  final int truncated;

  /// Schedule or cancel calls that failed.
  final int failures;

  /// True when a load or pending read failed and nothing was touched.
  final bool aborted;
}
