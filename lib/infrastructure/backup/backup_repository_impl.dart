import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/backup/json/item_json_codec.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_repository.dart';

/// Concrete implementation of [BackupRepository].
///
/// Privacy: export content (row values, field values, encoded bytes) is
/// never logged. A failure carries only the exception TYPE, because the
/// message of an encoding error can quote the offending value (T-04-04-02).
class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._dao);

  final BackupDao _dao;

  @override
  AsyncResult<BackupFile> exportJson({DateTime? now}) async {
    try {
      final at = now ?? DateTime.now();
      final items = await _dao.readItems();
      final envelope = buildBackupEnvelope(
        exportedAt: at,
        collections: {
          BackupJsonKeys.items: items.map(itemToJson).toList(),
          BackupJsonKeys.transactions: const [],
          BackupJsonKeys.categories: const [],
          BackupJsonKeys.budgets: const [],
          BackupJsonKeys.goals: const [],
          BackupJsonKeys.debts: const [],
          BackupJsonKeys.recurringPayments: const [],
        },
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
      return Success(BackupFile(name: _fileName(at), bytes: bytes));
    } on Object catch (e) {
      return Err(BackupFailure('exportJson failed: ${e.runtimeType}'));
    }
  }

  static String _fileName(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'agenda-backup-$y-$m-$day.json';
  }
}
