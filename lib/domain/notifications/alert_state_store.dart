/// Remembers which one-time alerts already fired, such as a budget
/// threshold crossing or a goal-week marker.
///
/// Implementations live in `lib/infrastructure/notifications/prefs/`.
abstract interface class AlertStateStore {
  /// Every stored key.
  Future<Set<String>> keys();

  /// Whether [key] is stored.
  Future<bool> contains(String key);

  /// Stores [key]. Idempotent.
  Future<void> add(String key);

  /// Stores every key in [keys]. Idempotent.
  Future<void> addAll(Iterable<String> keys);

  /// Removes every stored key for which [test] returns true.
  Future<void> removeWhere(bool Function(String key) test);

  /// Removes every stored key.
  Future<void> clear();
}
