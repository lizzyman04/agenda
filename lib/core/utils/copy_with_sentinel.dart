/// Sentinel value used by `Item.copyWith` to distinguish "not provided"
/// from "explicitly set to null" for nullable fields.
///
/// Pass [clearField] as the named argument to explicitly null out a field:
/// ```dart
/// item.copyWith(dueDate: clearField); // sets dueDate to null
/// item.copyWith(dueDate: someDate);   // sets dueDate to someDate
/// item.copyWith();                    // keeps existing dueDate
/// ```
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}
