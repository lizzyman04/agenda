/// Discriminates whether a debt is owed by the user or to the user.
///
/// Pure Dart — no Flutter or Isar annotations in this domain layer.
/// The data layer (DebtModel) applies @Enumerated(EnumType.name).
enum DebtDirection {
  /// The user owes this amount to another party.
  toPay,

  /// Another party owes this amount to the user.
  toReceive,
}
