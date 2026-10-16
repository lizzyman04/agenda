/// Moves [t] out of the quiet-hours window, never dropping it (D-08).
///
/// The window is start-inclusive and end-exclusive and wraps overnight when
/// [startMinutes] is greater than [endMinutes]. Equal bounds mean no window.
/// The evening part of a wrapping window ends on the next calendar day.
/// The result uses the component constructor so DST shifts cannot skew it.
DateTime deferOutOfQuietHours(
  DateTime t, {
  required int startMinutes,
  required int endMinutes,
}) {
  if (startMinutes == endMinutes) return t;
  final minutes = t.hour * 60 + t.minute;
  final wraps = startMinutes > endMinutes;
  final inside = wraps
      ? (minutes >= startMinutes || minutes < endMinutes)
      : (minutes >= startMinutes && minutes < endMinutes);
  if (!inside) return t;
  final nextDay = wraps && minutes >= startMinutes;
  return DateTime(
    t.year,
    t.month,
    t.day + (nextDay ? 1 : 0),
    endMinutes ~/ 60,
    endMinutes % 60,
  );
}
