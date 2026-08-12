import 'package:agenda/data/database/migration_runner.dart';
import 'package:agenda/data/finance/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockIsarCollection extends Mock
    implements IsarCollection<TransactionCategoryModel> {}

/// A test-only Isar subclass that captures writeTxn calls.
///
/// We cannot mock Isar.writeTxn generically because the type parameter
/// varies per call. Instead, this fake implementation executes the callback
/// and tracks call count.
class FakeIsar extends Fake implements Isar {
  FakeIsar(this._categoryCollection);
  int writeTxnCallCount = 0;
  bool shouldExecuteCallback = true;

  final MockIsarCollection _categoryCollection;

  @override
  IsarCollection<T> collection<T>() {
    if (T == TransactionCategoryModel) {
      return _categoryCollection as IsarCollection<T>;
    }
    throw UnimplementedError('FakeIsar.collection<$T>() not implemented');
  }

  @override
  Future<T> writeTxn<T>(
    Future<T> Function() callback, {
    bool silent = false,
  }) async {
    writeTxnCallCount++;
    if (shouldExecuteCallback) {
      return callback();
    }
    // Return a null-safe default when not executing
    return null as T;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockIsarCollection mockCollection;
  late FakeIsar fakeIsar;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockCollection = MockIsarCollection();
    fakeIsar = FakeIsar(mockCollection);
    mockPrefs = MockSharedPreferences();
  });

  group('MigrationRunner.run — schemaVersion 3', () {
    test(
      'runs migrations v1→v3 on fresh install (no stored version)',
      () async {
        // Arrange
        when(() => mockPrefs.getInt('schema_version')).thenReturn(null);
        when(
          () => mockPrefs.setInt('schema_version', any()),
        ).thenAnswer((_) async => true);
        // Case 3 guard: categories already exist so no writeTxn needed
        when(() => mockCollection.count()).thenAnswer((_) async => 13);

        // Act
        await MigrationRunner.run(fakeIsar, mockPrefs);

        // Assert — versions 1, 2, and 3 all written to prefs
        verify(() => mockPrefs.setInt('schema_version', 1)).called(1);
        verify(() => mockPrefs.setInt('schema_version', 2)).called(1);
        verify(() => mockPrefs.setInt('schema_version', 3)).called(1);
      },
    );

    test('is a no-op when stored version equals current target (3)', () async {
      // Arrange — already at target version
      when(() => mockPrefs.getInt('schema_version')).thenReturn(3);

      // Act
      await MigrationRunner.run(fakeIsar, mockPrefs);

      // Assert — setInt never called
      verifyNever(() => mockPrefs.setInt(any(), any()));
    });

    test(
      'is a no-op when stored version is greater than target '
      '(future-proofing)',
      () async {
        // Arrange — version somehow ahead (e.g. downgrade scenario)
        when(() => mockPrefs.getInt('schema_version')).thenReturn(99);

        // Act
        await MigrationRunner.run(fakeIsar, mockPrefs);

        // Assert
        verifyNever(() => mockPrefs.setInt(any(), any()));
      },
    );
  });

  group('MigrationRunner case 3 — category seeding', () {
    setUp(() {
      // Pre-requisite: setInt must be mockable for all versions
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      // Start from version 2 so only case 3 runs
      when(() => mockPrefs.getInt('schema_version')).thenReturn(2);
    });

    test('calls count() guard — seeding triggered from version 2', () async {
      // Arrange — empty DB (no categories yet)
      when(() => mockCollection.count()).thenAnswer((_) async => 0);
      when(
        () => mockCollection.putAll(any()),
      ).thenAnswer((_) async => [1, 2, 3]);

      // Act
      await MigrationRunner.run(fakeIsar, mockPrefs);

      // Assert — count() was called (guard check), writeTxn was
      // called (seeding)
      verify(() => mockCollection.count()).called(1);
      expect(fakeIsar.writeTxnCallCount, equals(1));
    });

    test(
      'does NOT seed when categories already exist (idempotency guard)',
      () async {
        // Arrange — categories already exist
        when(() => mockCollection.count()).thenAnswer((_) async => 13);

        // Act
        await MigrationRunner.run(fakeIsar, mockPrefs);

        // Assert — count() was called but writeTxn was NOT called
        // (guard short-circuits)
        verify(() => mockCollection.count()).called(1);
        expect(fakeIsar.writeTxnCallCount, equals(0));
      },
    );

    test('putAll receives exactly 13 models on first seed', () async {
      // Arrange
      final capturedModels = <List<TransactionCategoryModel>>[];
      when(() => mockCollection.count()).thenAnswer((_) async => 0);
      when(() => mockCollection.putAll(any())).thenAnswer((invocation) async {
        capturedModels.add(
          invocation.positionalArguments[0] as List<TransactionCategoryModel>,
        );
        return List.generate(
          (invocation.positionalArguments[0] as List).length,
          (i) => i + 1,
        );
      });

      // Act
      await MigrationRunner.run(fakeIsar, mockPrefs);

      // Assert — exactly 13 models passed to putAll
      expect(capturedModels.length, equals(1));
      expect(capturedModels.first.length, equals(13));
    });

    test('seeded models include all 9 expense category PT-BR names', () async {
      // Arrange
      final capturedModels = <TransactionCategoryModel>[];
      when(() => mockCollection.count()).thenAnswer((_) async => 0);
      when(() => mockCollection.putAll(any())).thenAnswer((invocation) async {
        capturedModels.addAll(
          invocation.positionalArguments[0] as List<TransactionCategoryModel>,
        );
        return List.generate(capturedModels.length, (i) => i + 1);
      });

      // Act
      await MigrationRunner.run(fakeIsar, mockPrefs);

      final expenseCategories =
          capturedModels
              .where((m) => m.type == TransactionType.expense)
              .map((m) => m.namePtBr)
              .toList();

      // Assert D-04: all 9 expense categories present
      expect(
        expenseCategories,
        containsAll([
          'Alimentação',
          'Transporte',
          'Moradia',
          'Saúde',
          'Educação',
          'Lazer',
          'Roupas',
          'Tecnologia',
          'Outros',
        ]),
      );
      expect(expenseCategories.length, equals(9));
    });

    test('seeded models include all 4 income category PT-BR names', () async {
      // Arrange
      final capturedModels = <TransactionCategoryModel>[];
      when(() => mockCollection.count()).thenAnswer((_) async => 0);
      when(() => mockCollection.putAll(any())).thenAnswer((invocation) async {
        capturedModels.addAll(
          invocation.positionalArguments[0] as List<TransactionCategoryModel>,
        );
        return List.generate(capturedModels.length, (i) => i + 1);
      });

      // Act
      await MigrationRunner.run(fakeIsar, mockPrefs);

      final incomeCategories =
          capturedModels
              .where((m) => m.type == TransactionType.income)
              .map((m) => m.namePtBr)
              .toList();

      // Assert D-05: all 4 income categories present
      expect(
        incomeCategories,
        containsAll(['Salário', 'Freelance', 'Investimentos', 'Outros']),
      );
      expect(incomeCategories.length, equals(4));
    });

    test('all seeded categories have isDefault == true', () async {
      // Arrange
      final capturedModels = <TransactionCategoryModel>[];
      when(() => mockCollection.count()).thenAnswer((_) async => 0);
      when(() => mockCollection.putAll(any())).thenAnswer((invocation) async {
        capturedModels.addAll(
          invocation.positionalArguments[0] as List<TransactionCategoryModel>,
        );
        return List.generate(capturedModels.length, (i) => i + 1);
      });

      // Act
      await MigrationRunner.run(fakeIsar, mockPrefs);

      // Assert — every seeded category has isDefault = true
      expect(capturedModels.every((m) => m.isDefault), isTrue);
    });
  });
}
