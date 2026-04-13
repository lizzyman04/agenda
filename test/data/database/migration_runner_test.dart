import 'package:agenda/data/database/migration_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockIsar extends Mock implements Isar {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockIsar mockIsar;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockIsar = MockIsar();
    mockPrefs = MockSharedPreferences();
  });

  group('MigrationRunner.run', () {
    test(
      'runs migration v1 and writes version when prefs has no stored '
      'version (fresh install)',
      () async {
        // Arrange — no version stored yet
        when(() => mockPrefs.getInt('schema_version')).thenReturn(null);
        when(() => mockPrefs.setInt('schema_version', 1))
            .thenAnswer((_) async => true);

        // Act
        await MigrationRunner.run(mockIsar, mockPrefs);

        // Assert — version 1 written to prefs
        verify(() => mockPrefs.setInt('schema_version', 1)).called(1);
      },
    );

    test(
      'runs migration v1 and writes version when stored version is 0',
      () async {
        // Arrange
        when(() => mockPrefs.getInt('schema_version')).thenReturn(0);
        when(() => mockPrefs.setInt('schema_version', 1))
            .thenAnswer((_) async => true);

        // Act
        await MigrationRunner.run(mockIsar, mockPrefs);

        // Assert
        verify(() => mockPrefs.setInt('schema_version', 1)).called(1);
      },
    );

    test('is a no-op when stored version equals current target (1)', () async {
      // Arrange — already at target version
      when(() => mockPrefs.getInt('schema_version')).thenReturn(1);

      // Act
      await MigrationRunner.run(mockIsar, mockPrefs);

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
        await MigrationRunner.run(mockIsar, mockPrefs);

        // Assert
        verifyNever(() => mockPrefs.setInt(any(), any()));
      },
    );
  });
}
