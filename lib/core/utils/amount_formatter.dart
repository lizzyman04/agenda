import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats an amount stored as integer cents into a display string.
///
/// The format follows the user's locale (D-18):
/// - PT-BR: `MT 1.250,00` (period as thousands separator, comma as decimal)
/// - EN: `MT 1,250.00` (comma as thousands separator, period as decimal)
///
/// [amountCents] is divided by 100.0 for display only — the double value
/// is never stored. The symbol is prepended with a space separator.
///
/// Example:
/// ```dart
/// formatAmount(125000, 'MT', const Locale('pt', 'BR')); // 'MT 1.250,00'
/// formatAmount(125000, 'MT', const Locale('en'));        // 'MT 1,250.00'
/// ```
String formatAmount(int amountCents, String currencySymbol, Locale locale) {
  final amount = amountCents / 100.0;
  final formatter = NumberFormat.currency(
    locale: locale.toString(),
    symbol: '',
    decimalDigits: 2,
  );
  return '$currencySymbol ${formatter.format(amount).trim()}';
}
