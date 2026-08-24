// Proves IsarTestHarness (isar_test_harness.dart) works: opens a real
// isar_community instance, accepts a write, returns it on read, and leaves
// no temp directory behind after close().
//
// If Isar.initializeIsarCore(download: true) fails in this execution
// environment because no network is reachable and no binary is cached,
// that is the residual risk documented in isar_test_harness.dart's
// top-of-file doc comment materializing — see this plan's SUMMARY for
// whether that happened here.

import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'isar_test_harness.dart';

TransactionModel _model(
  int id,
  DateTime date, {
  int amountCents = 100,
}) =>
    TransactionModel()
      ..id = id
      ..type = TransactionType.income
      ..amountCents = amountCents
      ..categoryId = 1
      ..date = date
      ..createdAt = date
      ..updatedAt = date;

void main() {
  group('IsarTestHarness', () {
    test('opens a real Isar, writes a row, and reads it back', () async {
      final harness = IsarTestHarness();
      final isar = await harness.open([TransactionModelSchema]);
      addTearDown(harness.close);

      final date = DateTime(2026, 8, 24);
      final model = _model(1, date, amountCents: 1234);

      await isar.writeTxn(() => isar.collection<TransactionModel>().put(model));

      final read = await isar.collection<TransactionModel>().get(model.id);

      expect(read, isNotNull);
      expect(read!.amountCents, 1234);
      expect(read.type, TransactionType.income);
      expect(read.categoryId, 1);
      expect(read.date, date);
    });

    test('close() removes the temp directory', () async {
      final harness = IsarTestHarness();
      await harness.open([TransactionModelSchema]);

      final dir = harness.tempDir!;
      expect(dir.existsSync(), isTrue);

      await harness.close();

      expect(dir.existsSync(), isFalse);
    });
  });
}
