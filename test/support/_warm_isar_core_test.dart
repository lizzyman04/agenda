// CI pre-warm trigger for the Isar Core native binary cache.
//
// Run as its own CI step, strictly before the main `Test` step:
//   flutter test --no-pub -j 1 test/support/_warm_isar_core_test.dart
//
// This file's ONLY purpose is to be a `flutter test` invocation that
// triggers `Isar.initializeIsarCore(download: true)` once, single-process,
// before the main `Test` step fans out across concurrent worker processes.
// Because this file is itself run via `flutter test`, never via the other
// Dart CLI entrypoint, it resolves `Platform.script` — and therefore the
// Isar Core download directory — identically to the later parallel `Test`
// step's workers. See `test/support/isar_test_harness.dart`'s top-of-file
// doc comment for the full explanation of the race this prevents and the
// other-entrypoint path mismatch that made this plan's first mitigation
// attempt a no-op.

import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'isar_test_harness.dart';

void main() {
  test('warms the Isar Core native binary cache before the parallel test '
      'suite runs', () async {
    final harness = IsarTestHarness();
    await harness.open([TransactionModelSchema]);
    await harness.close();
  });
}
