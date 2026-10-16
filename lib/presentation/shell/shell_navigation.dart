import 'package:flutter/foundation.dart';

/// Selected bottom-navigation index: 0 Tasks, 1 Eisenhower, 2 Day planner,
/// 3 GTD, 4 Finance.
///
/// Shared so a notification tap can change tabs from outside the shell.
final ValueNotifier<int> appTabIndex = ValueNotifier<int>(0);

/// One-shot request for a Finance sub-tab (0..5: summary, transactions,
/// budgets, goals, debts, recurring).
///
/// The Finance screen consumes the request and resets it to null.
final ValueNotifier<int?> financeSubTabRequest = ValueNotifier<int?>(null);
