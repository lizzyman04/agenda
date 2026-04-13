/// DateTime convenience extensions used across layers.
extension DateTimeExtensions on DateTime {
  /// Returns midnight (00:00:00.000) of this date.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns 23:59:59.999 of this date.
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);

  /// True if this date falls on the same calendar day as [DateTime.now()].
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// True if this date is strictly before today (ignoring time).
  bool get isPast => startOfDay.isBefore(DateTime.now().startOfDay);

  /// True if this date is strictly after today (ignoring time).
  bool get isFuture => startOfDay.isAfter(DateTime.now().startOfDay);
}
