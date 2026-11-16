import 'dart:math' as math;

/// Lock timeout options and the resume-lock rule (DATA-05, D-01, D-02, D-03).
///
/// The caller passes a wall-clock `now` (never a Stopwatch: its monotonic
/// clock does not advance while the process is suspended on some platforms).
/// Cold start always locks when a PIN is set, regardless of this rule; it
/// only decides whether a return from the background locks.
abstract final class LockPolicy {
  /// The timeout choices in seconds, in dialog order: Immediately, 30 s,
  /// 1 min, 5 min, 15 min.
  static const List<int> timeoutOptionsSeconds = [0, 30, 60, 300, 900];

  /// The timeout used when none, or an unknown value, is stored.
  static const int defaultTimeoutSeconds = 60;

  /// The minimum lock window for a background trip that began during an
  /// app-initiated excursion (file picker, share sheet).
  static const int excursionCapSeconds = 300;

  /// [stored] when it is one of [timeoutOptionsSeconds], else the default.
  static int effectiveTimeoutSeconds(int? stored) =>
      timeoutOptionsSeconds.contains(stored) ? stored! : defaultTimeoutSeconds;
}

/// Whether the app must lock when it resumes at [now].
///
/// [hiddenAt] is when the app last reached `hidden`; null means it only got
/// to `inactive` (notification shade, biometric sheet), which never locks.
/// A negative elapsed time (clock moved back) locks, fail-closed. Trips that
/// started during an excursion lock once elapsed reaches
/// max([timeoutSeconds], [LockPolicy.excursionCapSeconds]).
bool shouldLockOnResume({
  required DateTime? hiddenAt,
  required DateTime now,
  required int timeoutSeconds,
  required bool hiddenDuringExcursion,
}) {
  if (hiddenAt == null) return false;
  final elapsed = now.difference(hiddenAt);
  if (elapsed.isNegative) return true;
  final limit =
      hiddenDuringExcursion
          ? math.max(timeoutSeconds, LockPolicy.excursionCapSeconds)
          : timeoutSeconds;
  return elapsed >= Duration(seconds: limit);
}
