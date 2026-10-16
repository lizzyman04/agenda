// Money cells for CSV. The strict parser here exists because the legacy
// form-input parser under lib/core/utils rejects `1.250,50` and turns `-5`
// into +500 cents; neither may happen to a user's data. Do not delegate to it.

/// Formats [cents] as digits, [decimalSeparator] and exactly two decimals,
/// with no thousands separator. A negative value keeps its minus sign.
String formatAmountCell(int cents, String decimalSeparator) {
  final abs = cents.abs();
  final frac = (abs % 100).toString().padLeft(2, '0');
  return '${cents < 0 ? '-' : ''}${abs ~/ 100}$decimalSeparator$frac';
}

const int _maxDigits = 13;

// Plain digits with an optional one or two digit fraction.
final RegExp _plain = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$');
// Grouped digits: the group separator is the opposite of the decimal
// separator and the fraction is mandatory (so `1.250` stays ambiguous and is
// rejected).
final RegExp _groupedPt = RegExp(r'^(\d{1,3}(?:\.\d{3})+),(\d{1,2})$');
final RegExp _groupedEn = RegExp(r'^(\d{1,3}(?:,\d{3})+)\.(\d{1,2})$');

/// Parses a money cell into integer cents, or returns null when it is not a
/// well-formed non-negative amount (blank, signed, with a currency symbol,
/// inner spaces, an ambiguous thousands group, or more than 13 digits).
int? parseAmountCell(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (RegExp(r'\d').allMatches(s).length > _maxDigits) return null;
  final match =
      _plain.firstMatch(s) ??
      _groupedPt.firstMatch(s) ??
      _groupedEn.firstMatch(s);
  if (match == null) return null;
  final whole = int.parse(match[1]!.replaceAll(RegExp('[.,]'), ''));
  final fraction = match[2];
  final frac = fraction == null ? 0 : int.parse(fraction.padRight(2, '0'));
  return whole * 100 + frac;
}
