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
      'runs migrations v1→v2 and writes each version when prefs has no stored '
      'version (fresh install)',
      () async {
        // Arrange — no version stored yet; target is AppConfig.schemaVersion (2)
        when(() => mockPrefs.getInt('schema_version')).thenReturn(null);
        when(() => mockPrefs.setInt('schema_version', 1))
            .thenAnswer((_) async => true);
        when(() => mockPrefs.setInt('schema_version', 2))
            .thenAnswer((_) async => true);

        // Act
        await MigrationRunner.run(mockIsar, mockPrefs);

        // Assert — versions 1 and 2 both written to prefs
        verify(() => mockPrefs.setInt('schema_version', 1)).called(1);
        verify(() => mockPrefs.setInt('schema_version', 2)).called(1);
      },
    );

    test(
      'runs migrations v1→v2 and writes each version when stored version is 0',
      () async {
        // Arrange
        when(() => mockPrefs.getInt('schema_version')).thenReturn(0);
        when(() => mockPrefs.setInt('schema_version', 1))
            .thenAnswer((_) async => true);
        when(() => mockPrefs.setInt('schema_version', 2))
            .thenAnswer((_) async => true);

        // Act
        await MigrationRunner.run(mockIsar, mockPrefs);

        // Assert
        verify(() => mockPrefs.setInt('schema_version', 1)).called(1);
        verify(() => mockPrefs.setInt('schema_version', 2)).called(1);
      },
    );

    test('is a no-op when stored version equals current target (2)', () async {
      // Arrange — already at target version
      when(() => mockPrefs.getInt('schema_version')).thenReturn(2);

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
