/// Supported iCal RRULE frequencies for Phase 2.
///
/// No UNTIL, no COUNT — unlimited recurrence only.
enum RruleFreq { daily, weekly, monthly, yearly }

/// Parsed representation of a RRULE string.
class ParsedRrule {
  const ParsedRrule({
    required this.freq,
    this.byDay = const [],
    this.byMonthDay,
  });

  /// Recurrence frequency.
  final RruleFreq freq;

  /// Day-of-week codes for WEEKLY (e.g. ['MO', 'WE', 'FR']).
  /// Empty list means "every week on the same day as the seed date".
  final List<String> byDay;

  /// Day-of-month for MONTHLY (e.g. 1, 15).
  /// Null means "same day of month as the seed date".
  final int? byMonthDay;
}

/// Domain service for iCal RRULE parsing and next-occurrence computation.
///
/// Pure Dart — zero Flutter, zero Isar imports.
/// Supports: FREQ=DAILY, FREQ=WEEKLY;BYDAY=MO, FREQ=MONTHLY;BYMONTHDAY=15,
///           FREQ=YEARLY.
/// Phase 2 does NOT support UNTIL or COUNT.
abstract class RecurrenceEngine {
  /// Parses a RRULE string into a [ParsedRrule].
  ///
  /// Returns null when [rrule] is null or the string cannot be parsed.
  /// Implementations must not throw — return null for unrecognised rules.
  ParsedRrule? parse(String? rrule);

  /// Computes the next occurrence after [from] according to [rule].
  ///
  /// [from] is typically the completed item's dueDate.
  /// Called by ItemRepository.completeRecurring after marking an item done.
  DateTime nextOccurrence(DateTime from, ParsedRrule rule);
}
