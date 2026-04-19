import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [RecurrenceEngine].
///
/// Pure Dart — no Flutter, no Isar. Supports the 4-frequency iCal RRULE
/// subset defined in Phase 2: DAILY, WEEKLY (with BYDAY), MONTHLY (with
/// BYMONTHDAY), YEARLY.
@LazySingleton(as: RecurrenceEngine)
class RecurrenceEngineImpl implements RecurrenceEngine {
  const RecurrenceEngineImpl();

  static const _dayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  ParsedRrule? parse(String? rrule) {
    if (rrule == null || rrule.isEmpty) return null;

    final parts = <String, String>{};
    for (final segment in rrule.split(';')) {
      final kv = segment.split('=');
      if (kv.length == 2) parts[kv[0].trim().toUpperCase()] = kv[1].trim();
    }

    final freqStr = parts['FREQ'];
    if (freqStr == null) return null;

    final freq = switch (freqStr.toUpperCase()) {
      'DAILY' => RruleFreq.daily,
      'WEEKLY' => RruleFreq.weekly,
      'MONTHLY' => RruleFreq.monthly,
      'YEARLY' => RruleFreq.yearly,
      _ => null,
    };
    if (freq == null) return null;

    final byDay = parts['BYDAY']
            ?.split(',')
            .map((d) => d.trim().toUpperCase())
            .where((d) => _dayNames.contains(d))
            .toList() ??
        const [];

    final byMonthDay = int.tryParse(parts['BYMONTHDAY'] ?? '');

    return ParsedRrule(freq: freq, byDay: byDay, byMonthDay: byMonthDay);
  }

  @override
  DateTime nextOccurrence(DateTime from, ParsedRrule rule) {
    return switch (rule.freq) {
      RruleFreq.daily => from.add(const Duration(days: 1)),
      RruleFreq.weekly => _nextWeekly(from, rule.byDay),
      RruleFreq.monthly => _nextMonthly(from, rule.byMonthDay),
      RruleFreq.yearly => DateTime(
          from.year + 1,
          from.month,
          from.day,
          from.hour,
          from.minute,
          from.second,
          from.millisecond,
          from.microsecond,
        ),
    };
  }

  DateTime _nextWeekly(DateTime from, List<String> byDay) {
    if (byDay.isEmpty) return from.add(const Duration(days: 7));
    // DateTime.weekday: 1=Monday...7=Sunday; _dayNames index 0=MO...6=SU
    final targetDays =
        byDay.map((d) => _dayNames.indexOf(d) + 1).toList()..sort();
    var candidate = from.add(const Duration(days: 1));
    for (var i = 0; i < 8; i++) {
      if (targetDays.contains(candidate.weekday)) return candidate;
      candidate = candidate.add(const Duration(days: 1));
    }
    return from.add(const Duration(days: 7)); // fallback
  }

  DateTime _nextMonthly(DateTime from, int? byMonthDay) {
    final day = byMonthDay ?? from.day;
    // Handle month overflow: if day > days in next month, clamp to last day.
    final nextMonth = from.month == 12
        ? DateTime(from.year + 1)
        : DateTime(from.year, from.month + 1);
    final daysInNextMonth =
        DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final clampedDay = day.clamp(1, daysInNextMonth);
    // Preserve full sub-second precision from the original DateTime.
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      clampedDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }
}
