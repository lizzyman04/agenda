import 'package:agenda/core/constants/app_constants.dart';

/// Absorbs floating point noise so a goal exactly at the tolerance edge is
/// treated as on track.
const double _epsilon = 1e-9;

/// Whether a goal is off track at [asOf] (D-06, D-15).
///
/// Off track means the saved share of the target is more than
/// `AppConstants.goalOffTrackTolerance` below the linear expected progress
/// between [createdAt] and [deadline]. "10%" is ten percentage points of the
/// target, not ten percent of the expected value (assumption A14), and the
/// comparison is strict: exactly ten points below is still on track.
///
/// Expected progress is clamped to 0..1, so a goal past its deadline expects
/// 100% and keeps being flagged weekly until it is completed or deleted.
/// Goals without a deadline, with a non-positive target or with a deadline not
/// after [createdAt] are never off track.
bool isGoalOffTrack({
  required int savedCents,
  required int targetCents,
  required DateTime createdAt,
  required DateTime? deadline,
  required DateTime asOf,
}) {
  if (deadline == null || targetCents <= 0) return false;
  final span = deadline.difference(createdAt).inMilliseconds;
  if (span <= 0) return false;
  final elapsed = asOf.difference(createdAt).inMilliseconds.clamp(0, span);
  final expected = elapsed / span;
  final actual = savedCents / targetCents;
  return actual < expected - AppConstants.goalOffTrackTolerance - _epsilon;
}
