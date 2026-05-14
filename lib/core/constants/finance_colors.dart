import 'package:flutter/material.dart';

/// Finance semantic color constants for Phase 3.
///
/// These three values complement the inherited Material 3 ColorScheme
/// from Phase 2 (ColorScheme.fromSeed(seedColor: Colors.deepPurple)).
///
/// **Usage is exhaustive — do not repurpose these colors for other roles:**
/// - [incomeGreen]: income transaction amount text, income icon, income dot
/// - [expenseRed]: expense transaction amount text, expense row dot
/// - [warningAmber]: budget progress bar when spend reaches 80–99% of limit
///
/// Per the Phase 3 UI Design Contract (03-UI-SPEC.md).
abstract final class FinanceColors {
  /// Income indicator — green (#2E7D32).
  /// Used on income transaction amounts, income category icon, income row dot.
  static const Color incomeGreen = Color(0xFF2E7D32);

  /// Expense indicator — red (#C62828).
  /// Used on expense transaction amounts, expense row leading dot.
  static const Color expenseRed = Color(0xFFC62828);

  /// Budget warning — amber (#F57F17).
  /// Used on the budget progress bar when 80%–99% of the limit is spent.
  static const Color warningAmber = Color(0xFFF57F17);
}
