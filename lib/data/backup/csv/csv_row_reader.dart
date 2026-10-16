import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/backup/json/json_fields.dart';

/// A decoded model plus the loose references plan 04-11 resolves later.
final class ParsedCsvRow<T> {
  const ParsedCsvRow({
    required this.model,
    required this.rowNumber,
    this.categoryName,
  });

  final T model;

  /// Category display name from the file, when the entity has a category.
  final String? categoryName;

  /// Spreadsheet row (the header is row 1).
  final int rowNumber;
}

final RegExp _intShape = RegExp(r'^-?\d{1,15}$');

/// Strict, row- and column-aware accessor over one data row.
///
/// Every failure throws [FormatException] starting `row <n>, column <name>:`.
/// Columns absent from the file read as null, so optional columns may be
/// dropped and columns may be reordered.
final class CsvRowReader {
  CsvRowReader(List<String> header, List<String> cells, this.rowNumber)
    : _cells = {
        for (var i = 0; i < header.length && i < cells.length; i++)
          header[i]: cells[i],
      };

  final int rowNumber;
  final Map<String, String> _cells;

  Never fail(String column, String problem) =>
      throw FormatException('row $rowNumber, column $column: $problem');

  String? _raw(String column) {
    final v = _cells[column];
    return v == null || v.trim().isEmpty ? null : v;
  }

  /// Free text with the export guard removed; null when blank or absent.
  String? optText(String column) {
    final v = _raw(column);
    if (v == null) return null;
    if (v.length > maxJsonStringLength) fail(column, 'text too long');
    return unguardCsvText(v);
  }

  String requireText(String column) =>
      optText(column) ?? fail(column, 'required value is missing');

  int? optInt(String column) {
    final v = _raw(column)?.trim();
    if (v == null) return null;
    if (!_intShape.hasMatch(v)) fail(column, 'expected an integer');
    return int.parse(v);
  }

  int requireInt(String column) =>
      optInt(column) ?? fail(column, 'required value is missing');

  /// Accepts true/false and 1/0; blank or absent gives [fallback].
  bool boolOr(String column, {required bool fallback}) {
    final v = _raw(column)?.trim().toLowerCase();
    if (v == null) return fallback;
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
    return fail(column, 'expected true or false');
  }

  DateTime? optDate(String column) {
    final v = _raw(column);
    if (v == null) return null;
    return parseCsvDate(v) ?? fail(column, 'expected a date');
  }

  DateTime requireDate(String column) =>
      optDate(column) ?? fail(column, 'required value is missing');

  /// Matches [values] by `name`. Blank gives [fallback]; an unknown name
  /// gives [fallback] when one is supplied and is an error otherwise.
  T enumByName<T extends Enum>(String column, List<T> values, {T? fallback}) {
    final v = _raw(column)?.trim();
    if (v == null) return fallback ?? fail(column, 'required value is missing');
    return values.asNameMap()[v] ?? fallback ?? fail(column, 'unknown value');
  }

  /// Integer cents: the integer [centsColumn] is authoritative; otherwise the
  /// strictly parsed [amountColumn]; null when both are blank.
  int? amountCents(String? centsColumn, String amountColumn) {
    final cents = centsColumn == null ? null : optInt(centsColumn);
    if (cents != null) return cents;
    final amount = _raw(amountColumn);
    if (amount == null) return null;
    return parseAmountCell(amount) ??
        fail(amountColumn, 'expected an amount such as 12,50 or 1.250,50');
  }

  int requireAmountCents(String centsColumn, String amountColumn) =>
      amountCents(centsColumn, amountColumn) ??
      fail(centsColumn, 'required value is missing');
}
