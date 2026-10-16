/// Retention rule for the persisted alert markers.
///
/// The marker set grows by a few keys a month. Budget markers are only
/// meaningful for their own month, goal markers for their own week, so old
/// ones are dropped to keep the store small. Unknown or unparseable keys are
/// never stale: they are left alone.
library;

import 'package:agenda/domain/notifications/rules/day_math.dart';

const int _budgetMonthsKept = 2;
const int _goalWeeksKept = 8;

int _monthIndex(int year, int month) => year * 12 + month;

/// `YYYY-MM` at the start of [text] as a month index, or null.
int? _parseMonth(String text) {
  if (text.length < 7 || text[4] != '-') return null;
  final year = int.tryParse(text.substring(0, 4));
  final month = int.tryParse(text.substring(5, 7));
  if (year == null || month == null || month < 1 || month > 12) return null;
  return _monthIndex(year, month);
}

/// Whether [key] belongs to a month or week that is too old to matter at
/// [now].
///
/// - `b:<yyyy>-<mm>:...`: stale when more than two months before [now];
/// - `seeded:<yyyy>-<mm>`: stale when before the current month;
/// - `gf:` and `gs:` goal-week markers: stale when more than eight weeks
///   before the current week.
bool isStaleAlertKey(String key, DateTime now) {
  final current = _monthIndex(now.year, now.month);
  if (key.startsWith('b:')) {
    final month = _parseMonth(key.substring(2));
    return month != null && month < current - _budgetMonthsKept;
  }
  if (key.startsWith('seeded:')) {
    final month = _parseMonth(key.substring(7));
    return month != null && month < current;
  }
  if (key.startsWith('gf:') || key.startsWith('gs:')) {
    final parts = key.split(':');
    if (parts.length != 3) return false;
    final week = DateTime.tryParse(parts[2]);
    if (week == null) return false;
    return week.isBefore(addDays(mondayOf(now), -7 * _goalWeeksKept));
  }
  return false;
}
