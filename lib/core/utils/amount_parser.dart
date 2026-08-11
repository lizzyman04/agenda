/// Parses and formats currency amount strings for the finance forms.
///
/// Deduplicates the identical amount-cents parsing expression and pre-fill
/// formatting expression previously re-implemented inline in
/// `transaction_form_screen.dart`, `recurring_payment_form_screen.dart`,
/// `debt_form_screen.dart`, and `goal_form_screen.dart`.
///
/// This preserves the *exact* pre-existing parsing behavior of those 4
/// forms, quirks included — it is not an idealized re-design. Notably:
/// - Input is not locale-strict: both `,` and `.` are accepted as the
///   decimal separator, matching the app's PT-BR-first, EN-toggle input.
/// - Thousands separators are NOT supported. An input like `'1.250,50'`
///   converts its comma to a dot (yielding `'1.250.50'`, two dots), which
///   is not valid `double` syntax and parses to `null`. This mirrors what
///   happens today if a user types a thousands separator into any of the
///   4 forms — it is not new breakage introduced by this extraction.
/// - Non-digit, non-dot characters (including a leading `-`) are stripped
///   before parsing, so a value like `'-5'` becomes `'5'` and parses as a
///   positive amount rather than being rejected.
library;

/// Parses a raw, user-typed amount string into integer cents.
///
/// Returns `null` if the string is empty, not a valid number after
/// cleaning, or parses to a value `<= 0`.
///
/// Example:
/// ```dart
/// parseAmountCentsOrNull('12,50'); // 1250
/// parseAmountCentsOrNull('12.50'); // 1250
/// parseAmountCentsOrNull('abc');   // null
/// ```
int? parseAmountCentsOrNull(String raw) {
  final cleaned = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
  final parsed = double.tryParse(cleaned);
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return (parsed * 100).round();
}

/// Formats integer cents back into the comma-decimal string used to
/// pre-fill an amount input field.
///
/// Returns `''` for `cents <= 0`, matching the `cents > 0 ? ... : ''`
/// ternary pattern used in every form's `initState`.
///
/// Example:
/// ```dart
/// formatCentsForInput(1250); // '12,50'
/// formatCentsForInput(0);    // ''
/// ```
String formatCentsForInput(int cents) {
  if (cents <= 0) {
    return '';
  }
  return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
}
