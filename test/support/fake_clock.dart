/// A controllable wall clock for tests.
///
/// Pass `clock.call` wherever production code takes a
/// `DateTime Function()`; move time with [advance] or [set].
class FakeClock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime.utc(2026, 1, 1, 12);

  DateTime _now;

  /// The current fake time.
  DateTime call() => _now;

  /// Moves the clock forward by [by] (backward when negative).
  void advance(Duration by) => _now = _now.add(by);

  /// Jumps the clock to [to].
  // A setter would not fit the call-site style `clock.set(t)`.
  // ignore: use_setters_to_change_properties
  void set(DateTime to) => _now = to;
}
