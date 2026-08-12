import 'package:agenda/domain/finance/transaction_type.dart';

/// Sentinel value used by [TransactionCategory.copyWith] to distinguish
/// "not provided" from "explicitly set to null" for nullable fields.
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}

/// Domain entity for a transaction category.
///
/// Categories can be system-default (isDefault = true) or user-defined.
/// Default categories cannot be deleted or renamed (D-03).
/// Pure Dart — zero Flutter and zero Isar imports.
class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.namePtBr,
    required this.type,
    required this.isDefault,
    required this.createdAt,
    this.nameEn,
  });

  /// Isar auto-increment id (0 for unsaved entities).
  final int id;

  /// Primary display name in Portuguese (PT-BR).
  final String namePtBr;

  /// Optional English display name for EN locale toggle.
  final String? nameEn;

  /// Discriminates income vs expense categories (D-02).
  final TransactionType type;

  /// True for seeded default categories — cannot be deleted or renamed.
  final bool isDefault;

  final DateTime createdAt;

  /// Returns a copy with the specified fields replaced.
  TransactionCategory copyWith({
    int? id,
    String? namePtBr,
    Object? nameEn = clearField,
    TransactionType? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      namePtBr: namePtBr ?? this.namePtBr,
      nameEn: nameEn is _Absent ? this.nameEn : nameEn as String?,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
