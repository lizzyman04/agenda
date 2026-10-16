/// Calendar helpers for the planners. Every function builds results with the
/// `DateTime` component constructor, so a DST change never skews the
/// wall-clock hour and `month + 1` style overflow is never hand-rolled.
library;

/// Midnight at the start of [d]'s calendar day.
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// [d] moved by [days] calendar days, keeping the hour and minute.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

/// The moment [minutes] after midnight of [day]; negative or over-1440
/// values normalise to the neighbouring days.
DateTime atMinutes(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, 0, minutes);

/// Minutes elapsed since midnight in [d]'s local day.
int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;

/// Days since 1970-01-01 of [d]'s calendar date, independent of time zone.
int epochDay(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

/// Midnight of the ISO-week Monday containing [d].
DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

/// The ISO week of [d] as its Monday's date, `yyyy-MM-dd`.
String weekKey(DateTime d) {
  final monday = mondayOf(d);
  final year = monday.year.toString().padLeft(4, '0');
  final month = monday.month.toString().padLeft(2, '0');
  final day = monday.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// First [weekday] at [minutes] after midnight strictly after [now].
DateTime nextWeekdayAt(
  DateTime now, {
  required int weekday,
  required int minutes,
}) {
  final ahead = (weekday - now.weekday) % 7;
  final day = DateTime(now.year, now.month, now.day + ahead);
  final candidate = atMinutes(day, minutes);
  if (candidate.isAfter(now)) return candidate;
  return atMinutes(addDays(day, 7), minutes);
}
