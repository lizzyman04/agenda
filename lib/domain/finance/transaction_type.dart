/// Discriminates between income and expense transactions.
///
/// Pure Dart — no Flutter or Isar annotations in this domain layer.
/// The data layer (TransactionModel) applies @Enumerated(EnumType.name).
enum TransactionType {
  income,
  expense,
}
