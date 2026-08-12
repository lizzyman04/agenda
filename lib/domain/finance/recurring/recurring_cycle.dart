/// Recurrence cycle for recurring payments.
///
/// Pure Dart — no Flutter or Isar annotations in this domain layer.
/// The data layer (RecurringPaymentModel) applies @Enumerated(EnumType.name).
enum RecurringCycle {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}
