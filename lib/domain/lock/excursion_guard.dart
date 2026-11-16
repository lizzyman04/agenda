/// Marks app-initiated trips outside the app (D-03, RESEARCH Pattern 4).
///
/// Wrap every call that launches UI outside the app — the file picker, OS
/// permission dialogs, system settings, `local_auth` — in [run], so the
/// return trip does not count as leaving the app. A trip that starts during
/// an excursion still locks once it reaches the excursion cap
/// (`LockPolicy.excursionCapSeconds`).
///
/// Implementations live in `lib/infrastructure/lock/`.
abstract interface class ExcursionGuard {
  /// Runs [action] as an excursion and returns (or rethrows) its outcome.
  /// Nested and concurrent runs are allowed.
  Future<T> run<T>(Future<T> Function() action);

  /// Whether an excursion is in flight at [now], or ended within a short
  /// grace window before it.
  bool isActive(DateTime now);
}
