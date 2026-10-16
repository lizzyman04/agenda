/// Keys of the persisted goal-week markers (the `firedAlertKeys` set).
///
/// Two families share one set:
/// - fired (`gf:<goalId>:<weekKey>`): an immediate off-track alert was shown
///   that week;
/// - scheduled (`gs:<goalId>:<weekKey>`): the weekly one-shot for that week
///   was scheduled.
///
/// The planner reads only the fired family. The on-open evaluator (plan
/// 04-14) reads both, which is what prevents a duplicate alert within one
/// week.
library;

/// Marker that an immediate alert for [goalId] was shown in [weekKey].
String goalFiredKey(int goalId, String weekKey) => 'gf:$goalId:$weekKey';

/// Marker that the weekly alert for [goalId] was scheduled for [weekKey].
String goalScheduledKey(int goalId, String weekKey) => 'gs:$goalId:$weekKey';
