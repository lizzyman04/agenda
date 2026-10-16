/// Why the schedule is being rebuilt.
enum ReconcileReason {
  appStart,
  appResume,
  dataChange,
  prefsChange,
  localeChange,
  afterImport,
}

/// Keeps the OS notification schedule equal to what the planners want.
///
/// Implemented by the notification coordinator in plan 04-12. The settings
/// cubit and the backup cubit consume it: the first asks for a rebuild
/// after a preference change, the second after an import.
abstract interface class NotificationReconciler {
  /// Starts listening to data, preference and locale changes and performs
  /// the first reconcile.
  Future<void> start();

  /// Asks for a rebuild. Debounced and fire and forget: bursts of calls
  /// collapse into one run.
  void requestReconcile(ReconcileReason reason);

  /// Rebuilds now and completes when the schedule has been applied.
  Future<void> reconcileNow(ReconcileReason reason);

  /// How many reminders the last run left out because of the slot budget.
  /// Broadcast stream.
  Stream<int> get truncatedCount;

  /// Stops listening and releases resources.
  Future<void> dispose();
}
