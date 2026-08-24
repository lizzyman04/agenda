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

    test(
      'tempDir survives a failed open() and close() still removes it '
      '(WR-01)',
      () async {
        final harness = IsarTestHarness();
        addTearDown(harness.close);

        // A schema list Isar genuinely rejects: the same collection listed
        // twice throws IsarError('Duplicate collection ...') from inside
        // Isar.open() itself — an honest, reliable way to force the throw
        // this test needs, not a mock of the harness.
        await expectLater(
          () => harness.open(
            [TransactionModelSchema, TransactionModelSchema],
          ),
          throwsA(anything),
        );

        final dir = harness.tempDir;
        expect(
          dir,
          isNotNull,
          reason: 'tempDir must survive a failed Isar.open() so close() '
              'has something to clean up',
        );
        expect(dir!.existsSync(), isTrue);

        await harness.close();

        expect(dir.existsSync(), isFalse);
      },
    );

    test('open() throws StateError when called a second time (WR-02)',
        () async {
      final harness = IsarTestHarness();
      addTearDown(harness.close);

      final isar = await harness.open([TransactionModelSchema]);

      await expectLater(
        () => harness.open([TransactionModelSchema]),
        throwsA(isA<StateError>()),
      );

      expect(harness.isar, same(isar));
      expect(harness.isar!.isOpen, isTrue);
    });
  });
}
