import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/import/backup_importer.dart';
import 'package:agenda/data/backup/import/safety_backup_store.dart';
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
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/infrastructure/backup/csv_export_builder.dart';
import 'package:agenda/infrastructure/backup/import_session.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [BackupRepository].
///
/// Privacy: export content (row values, field values, encoded bytes) is
/// never logged. A failure carries only the exception TYPE, because the
/// message of an encoding error can quote the offending value (T-04-04-02).
@LazySingleton(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._dao);

  final BackupDao _dao;

  final SafetyBackupStore _store = SafetyBackupStore();

  late final ImportSession _import = ImportSession(
    dao: _dao,
    importer: BackupImporter(_dao.isarService),
    store: _store,
    exportJson: exportJson,
  );

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
      final rows = await _dao.readAll();
      return Success(
        buildCsvExport(
          rows,
          languageCode: languageCode,
          at: now ?? DateTime.now(),
        ),
      );
    } on Object catch (e) {
      return Err(BackupFailure('exportCsv failed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<ImportPreview> prepareImport(List<BackupFile> files) =>
      _import.prepare(files);

  @override
  AsyncResult<ImportResult> commitImport() => _import.commit();

  @override
  void discardImport() => _import.discard();

  @override
  String? get lastSafetyBackupPath => _import.lastSafetyBackupPath;

  @override
  AsyncResult<int> safetyBackupCount() async {
    try {
      return Success((await _store.list()).length);
    } on Object catch (e) {
      return Err(BackupFailure('safetyBackupCount failed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<BackupFile?> latestSafetyBackup() async {
    try {
      final file = await _store.newest();
      if (file == null) return const Success(null);
      return Success(
        BackupFile(
          name: file.uri.pathSegments.last,
          bytes: await file.readAsBytes(),
        ),
      );
    } on Object catch (e) {
      return Err(BackupFailure('latestSafetyBackup failed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<int> deleteSafetyBackups() async {
    try {
      return Success(await _store.deleteAll());
    } on Object catch (e) {
      return Err(BackupFailure('deleteSafetyBackups failed: ${e.runtimeType}'));
    }
  }

  static String _fileName(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'agenda-backup-$y-$m-$day.json';
  }
}
