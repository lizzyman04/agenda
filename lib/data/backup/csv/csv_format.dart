/// Single byte order mark (U+FEFF) written first in every exported file so
/// spreadsheet applications detect UTF-8.
const String csvBom = '﻿';

/// RFC 4180 record separator.
const String csvLineDelimiter = '\r\n';

/// Field delimiter and decimal separator of one CSV flavour.
final class CsvDialect {
  const CsvDialect({required this.delimiter, required this.decimalSeparator});

  /// `en` selects [en]; every other language code selects [pt].
  factory CsvDialect.forLanguage(String languageCode) =>
      languageCode == 'en' ? en : pt;

  /// English flavour: `,` between fields, `.` as decimal separator.
  static const CsvDialect en = CsvDialect(
    delimiter: ',',
    decimalSeparator: '.',
  );

  /// PT-BR flavour: `;` between fields (the spreadsheet list separator),
  /// `,` as decimal separator.
  static const CsvDialect pt = CsvDialect(
    delimiter: ';',
    decimalSeparator: ',',
  );

  final String delimiter;
  final String decimalSeparator;
}

/// Everything a mapper needs besides the model itself.
final class CsvContext {
  const CsvContext({
    required this.dialect,
    this.categoryNames = const <int, String>{},
  });

  final CsvDialect dialect;

  /// Category id to display name, in the export language.
  final Map<int, String> categoryNames;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Formats [d] in local time: `yyyy-MM-dd` for a local midnight, otherwise
/// `yyyy-MM-ddTHH:mm:ss.SSS`.
String formatCsvDate(DateTime d) {
  final l = d.toLocal();
  final date =
      '${l.year.toString().padLeft(4, '0')}-${_two(l.month)}-'
      '${_two(l.day)}';
  if (l.hour == 0 &&
      l.minute == 0 &&
      l.second == 0 &&
      l.millisecond == 0 &&
      l.microsecond == 0) {
    return date;
  }
  return '${date}T${_two(l.hour)}:${_two(l.minute)}:${_two(l.second)}.'
      '${l.millisecond.toString().padLeft(3, '0')}';
}

final RegExp _dateShape = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})'
  r'(?:T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})?)?$',
);

/// Parses a date-only or ISO date-time value; any other shape (for example
/// `12/10/2026`) or an impossible calendar value returns null. Values that
/// carry `Z` or an offset are converted to local time.
DateTime? parseCsvDate(String raw) {
  final m = _dateShape.firstMatch(raw.trim());
  if (m == null) return null;
  final y = int.parse(m[1]!);
  final mo = int.parse(m[2]!);
  final d = int.parse(m[3]!);
  final probe = DateTime(y, mo, d);
  if (probe.year != y || probe.month != mo || probe.day != d) return null;
  if (m[4] == null) return probe;
  if (int.parse(m[4]!) > 23 || int.parse(m[5]!) > 59 || int.parse(m[6]!) > 59) {
    return null;
  }
  final parsed = DateTime.tryParse(raw.trim());
  return parsed?.toLocal();
}
