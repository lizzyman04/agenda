import 'dart:convert';

import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/data/backup/csv/csv_snapshot_reader.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/backup/json/budget_json_codec.dart';
import 'package:agenda/data/backup/json/category_json_codec.dart';
import 'package:agenda/data/backup/json/debt_json_codec.dart';
import 'package:agenda/data/backup/json/goal_json_codec.dart';
import 'package:agenda/data/backup/json/item_json_codec.dart';
import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/backup/json/payment_json_codec.dart';
import 'package:agenda/data/backup/json/transaction_json_codec.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/import_preview.dart';

/// Largest single file accepted (25 MiB), checked on the byte length before
/// any decoding (T-04-11-02).
const int maxImportFileBytes = 26214400;

/// Most files accepted in one import: one CSV per entity (tasks, transactions,
/// budgets, goals, debts, payments), per D-10 and D-14.
const int maxImportFiles = 6;

/// Largest combined size of a selection (50 MiB). Every file is held in memory
/// and decoded to a string, so the total matters as much as each file.
const int maxImportTotalBytes = 52428800;

/// Describes how a selection of files with these byte [sizes] breaks the
/// import limits, or returns null when it is within them. The detail holds
/// counts and byte numbers only, never file names.
String? importLimitViolation(
  Iterable<int> sizes, {
  int maxFiles = maxImportFiles,
  int maxEach = maxImportFileBytes,
  int maxTotal = maxImportTotalBytes,
}) {
  final list = sizes.toList();
  if (list.length > maxFiles) {
    return '${list.length} files exceed the limit of $maxFiles';
  }
  var total = 0;
  for (var i = 0; i < list.length; i++) {
    if (list[i] > maxEach) return 'file $i exceeds $maxEach bytes';
    total += list[i];
  }
  if (total > maxTotal) return 'files total $total bytes, over $maxTotal';
  return null;
}

BackupImportException _bad(String code, String detail) =>
    BackupImportException(code, detail);

/// Turns picked files into a [BackupSnapshot] without writing anything.
///
/// Order: empty check, count and size limits ([importLimitViolation]), UTF-8
/// decode, JSON/CSV
/// classification, then the format-specific decode. Picked file NAMES are
/// never used; errors refer to files by position.
BackupSnapshot parseBackupFiles(
  List<BackupFile> files, {
  required DateTime now,
  int maxBytes = maxImportFileBytes,
  int maxFiles = maxImportFiles,
  int maxTotalBytes = maxImportTotalBytes,
}) {
  if (files.isEmpty) throw _bad(ImportErrorCode.empty, 'no file was chosen');
  final violation = importLimitViolation(
    files.map((f) => f.bytes.length),
    maxFiles: maxFiles,
    maxEach: maxBytes,
    maxTotal: maxTotalBytes,
  );
  if (violation != null) throw _bad(ImportErrorCode.tooLarge, violation);
  final texts = <String>[];
  for (var i = 0; i < files.length; i++) {
    try {
      final text = utf8.decode(files[i].bytes);
      texts.add(text.startsWith('﻿') ? text.substring(1) : text);
    } on FormatException {
      throw _bad(ImportErrorCode.unsupported, 'file $i is not UTF-8 text');
    }
  }
  final jsonCount = texts.where((t) => t.trimLeft().startsWith('{')).length;
  if (jsonCount > 1 || (jsonCount == 1 && texts.length > 1)) {
    throw _bad(ImportErrorCode.mixed, 'choose one JSON file or CSV files');
  }
  return jsonCount == 1
      ? _readJson(texts.single)
      : readCsvSnapshot(texts, now: now);
}

int? _intAt(Object? decoded, String key) =>
    decoded is Map && decoded[key] is int ? decoded[key] as int : null;

BackupSnapshot _readJson(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw _bad(ImportErrorCode.unsupported, 'the file is not valid JSON');
  }
  final format = _intAt(decoded, 'formatVersion');
  final schema = _intAt(decoded, 'schemaVersion');
  if ((format ?? 0) > backupFormatVersion ||
      (schema ?? 0) > AppConfig.schemaVersion) {
    throw _bad(ImportErrorCode.newerVersion, 'made by a newer AGENDA');
  }
  final ParsedEnvelope envelope;
  try {
    envelope = parseBackupEnvelope(decoded);
  } on FormatException catch (e) {
    throw _bad(ImportErrorCode.unsupported, e.message);
  }
  if (envelope.formatVersion < 1) {
    throw _bad(ImportErrorCode.unsupported, 'formatVersion: not supported');
  }
  List<T> decode<T>(String key, T Function(JsonObjectReader) fromJson) {
    try {
      return envelope.rows(key).map(fromJson).toList();
    } on FormatException catch (e) {
      final missing = e.message.endsWith('collection is missing');
      throw _bad(
        missing ? ImportErrorCode.unsupported : ImportErrorCode.invalid,
        e.message,
      );
    }
  }

  return BackupSnapshot(
    source: ImportSource.json,
    exportedAt: envelope.exportedAt,
    items: decode(BackupJsonKeys.items, itemFromJson),
    transactions: decode(BackupJsonKeys.transactions, transactionFromJson),
    categories: decode(BackupJsonKeys.categories, categoryFromJson),
    budgets: decode(BackupJsonKeys.budgets, budgetFromJson),
    goals: decode(BackupJsonKeys.goals, goalFromJson),
    debts: decode(BackupJsonKeys.debts, debtFromJson),
    recurringPayments: decode(
      BackupJsonKeys.recurringPayments,
      paymentFromJson,
    ),
  );
}
