import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/transaction_csv_mapper.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/backup/json/budget_json_codec.dart';
import 'package:agenda/data/backup/json/category_json_codec.dart';
import 'package:agenda/data/backup/json/debt_json_codec.dart';
import 'package:agenda/data/backup/json/goal_json_codec.dart';
import 'package:agenda/data/backup/json/item_json_codec.dart';
import 'package:agenda/data/backup/json/payment_json_codec.dart';
import 'package:agenda/data/backup/json/transaction_json_codec.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [BackupRepository].
///
/// Privacy: export content (row values, field values, encoded bytes) is
/// never logged. A failure carries only the exception TYPE, because the
/// message of an encoding error can quote the offending value (T-04-04-02).
@LazySingleton(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._dao);

  final BackupDao _dao;

  @override
  AsyncResult<BackupFile> exportJson({DateTime? now}) async {
    try {
      final at = now ?? DateTime.now();
      final rows = await _dao.readAll();
      final envelope = buildBackupEnvelope(
        exportedAt: at,
        collections: {
          BackupJsonKeys.items: rows.items.map(itemToJson).toList(),
          BackupJsonKeys.transactions:
              rows.transactions.map(transactionToJson).toList(),
          BackupJsonKeys.categories:
              rows.categories.map(categoryToJson).toList(),
          BackupJsonKeys.budgets: rows.budgets.map(budgetToJson).toList(),
          BackupJsonKeys.goals: rows.goals.map(goalToJson).toList(),
          BackupJsonKeys.debts: rows.debts.map(debtToJson).toList(),
          BackupJsonKeys.recurringPayments:
              rows.recurringPayments.map(paymentToJson).toList(),
        },
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
      return Success(BackupFile(name: _fileName(at), bytes: bytes));
    } on Object catch (e) {
      return Err(BackupFailure('exportJson failed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<List<BackupFile>> exportCsv({
    required String languageCode,
    DateTime? now,
  }) async {
    try {
      final at = now ?? DateTime.now();
      final rows = await _dao.readAll();
      final english = languageCode == 'en';
      final ctx = CsvContext(
        dialect: CsvDialect.forLanguage(languageCode),
        categoryNames: {
          for (final c in rows.categories)
            c.id: english && c.nameEn != null ? c.nameEn! : c.namePtBr,
        },
      );
      BackupFile file(
        String stem,
        List<String> header,
        List<List<Object?>> r,
      ) => BackupFile(
        name: _csvFileName(stem, at),
        bytes: Uint8List.fromList(
          utf8.encode(
            encodeCsvTable(header: header, rows: r, dialect: ctx.dialect),
          ),
        ),
      );

      const transactions = TransactionCsvMapper();
      final active =
          rows.transactions.where((m) => m.deletedAt == null).toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      return Success([
        file(TransactionCsvMapper.fileStem, TransactionCsvMapper.header, [
          for (final m in active) transactions.toRow(m, ctx),
        ]),
      ]);
    } on Object catch (e) {
      return Err(BackupFailure('exportCsv failed: ${e.runtimeType}'));
    }
  }

  static String _csvFileName(String stem, DateTime d) =>
      'agenda-$stem-${_datePart(d)}.csv';

  static String _datePart(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _fileName(DateTime d) {
    return 'agenda-backup-${_datePart(d)}.json';
  }
}
