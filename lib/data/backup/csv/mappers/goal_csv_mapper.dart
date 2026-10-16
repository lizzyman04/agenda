import 'dart:convert';

import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:isar_community/isar.dart';

/// Encodes and decodes [SavingsGoalModel] rows for `goals.csv`.
///
/// Contributions travel as one JSON array cell, `contributions_json`, of
/// `{amountCents, date, note}` objects.
final class GoalCsvMapper {
  const GoalCsvMapper();

  static const String fileStem = 'goals';

  /// Columns that must all be present for a file to be read as goals.
  static const Set<String> signature = {'title', 'deadline'};

  static const List<String> header = [
    'id',
    'title',
    'target',
    'target_cents',
    'deadline',
    'is_completed',
    'contributions_json',
    'created_at',
    'updated_at',
  ];

  List<Object?> toRow(SavingsGoalModel m, CsvContext ctx) => [
    m.id,
    guardCsvText(m.title),
    formatAmountCell(m.targetAmountCents, ctx.dialect.decimalSeparator),
    m.targetAmountCents,
    formatCsvDateOrEmpty(m.deadline),
    m.isCompleted,
    jsonEncode([
      for (final c in m.contributions)
        {
          'amountCents': c.amountCents,
          'date': encodeJsonDate(c.date),
          'note': c.note,
        },
    ]),
    formatCsvDate(m.createdAt),
    formatCsvDate(m.updatedAt),
  ];

  ParsedCsvRow<SavingsGoalModel> fromRow(
    CsvRowReader r, {
    required DateTime now,
  }) {
    final model =
        SavingsGoalModel()
          ..id = r.optInt('id') ?? Isar.autoIncrement
          ..title = r.requireText('title')
          ..targetAmountCents = r.requireAmountCents('target_cents', 'target')
          ..deadline = r.optDate('deadline')
          ..contributions = _contributions(r)
          ..isCompleted = r.boolOr('is_completed', fallback: false)
          ..createdAt = r.optDate('created_at') ?? now
          ..updatedAt = r.optDate('updated_at') ?? now;
    return ParsedCsvRow(model: model, rowNumber: r.rowNumber);
  }

  // Strictly decodes the JSON cell into an explicitly GROWABLE list: a
  // fixed-length list throws at the next contribution write (Phase 03 UAT).
  // The jsonDecode message is never forwarded: it can quote the cell content.
  List<GoalContribution> _contributions(CsvRowReader r) {
    const column = 'contributions_json';
    final contributions = List<GoalContribution>.empty(growable: true);
    final text = r.optText(column);
    if (text == null) return contributions;
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      r.fail(column, 'invalid JSON');
    }
    if (decoded is! List) r.fail(column, 'expected a JSON array');
    for (var i = 0; i < decoded.length; i++) {
      try {
        final c = JsonObjectReader.fromObject(decoded[i], '$column[$i]');
        contributions.add(
          GoalContribution()
            ..amountCents = c.requireInt('amountCents')
            ..date = c.requireDate('date')
            ..note = c.optString('note'),
        );
      } on FormatException catch (e) {
        r.fail(column, e.message);
      }
    }
    return contributions;
  }
}
