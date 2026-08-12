import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all HomeDashboard states.
sealed class HomeDashboardState extends Equatable {
  const HomeDashboardState();
}

/// Emitted on construction before any data is loaded.
final class HomeDashboardInitial extends HomeDashboardState {
  const HomeDashboardInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository queries are in flight.
final class HomeDashboardLoading extends HomeDashboardState {
  const HomeDashboardLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when all dashboard data is loaded and ready for display.
///
/// [balanceCents] — lifetime income minus lifetime expenses (D-07).
/// [netWorthCents] — balance + goal savings − unpaid toPay debts (D-08).
/// [selectedMonth] — the calendar month the chart is currently showing.
/// [categorySpend] — `Map<categoryId, totalExpenseCents>` for [selectedMonth].
/// [categories] — all expense categories for label lookup in charts.
final class HomeDashboardLoaded extends HomeDashboardState {
  const HomeDashboardLoaded({
    required this.balanceCents,
    required this.netWorthCents,
    required this.selectedMonth,
    required this.categorySpend,
    required this.categories,
  });

  /// Lifetime balance = Σ income − Σ expenses (D-07). No monthly reset.
  final int balanceCents;

  /// Net worth per D-08 formula:
  /// balance + Σ(active goal savings) − Σ(toPay && !isPaid debt amounts).
  /// Debts-to-receive are excluded per D-08.
  final int netWorthCents;

  /// The calendar month currently selected for the chart (D-09, D-10).
  final DateTime selectedMonth;

  /// Expense spending grouped by categoryId for [selectedMonth].
  /// Used for pie and bar chart rendering (D-09).
  final Map<int, int> categorySpend;

  /// All expense categories for chart label resolution.
  final List<TransactionCategory> categories;

  @override
  List<Object?> get props => [
        balanceCents,
        netWorthCents,
        selectedMonth,
        categorySpend,
        categories,
      ];
}

/// Emitted when a repository call returns an Err.
final class HomeDashboardError extends HomeDashboardState {
  const HomeDashboardError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
