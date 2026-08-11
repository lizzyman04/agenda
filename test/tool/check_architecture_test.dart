// Unit coverage for tool/check_architecture.dart's three checks, run
// against synthetic fixture trees — independent of the live lib/ tree's
// ever-changing state.

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_architecture.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('check_architecture_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('checkLineLengths', () {
    test('flags a file with 151 lines as a violation', () {
      final file = File('${tempDir.path}/over_limit.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(List.filled(151, '// line').join('\n'));

      final result = checkLineLengths(tempDir, exemptions: const {});

      expect(
        result.violations.any((v) => v.contains(file.path.replaceAll(r'\', '/'))),
        isTrue,
        reason: 'expected ${file.path} to be flagged, got ${result.violations}',
      );
    });

    test('does not flag a file with exactly 150 lines', () {
      final file = File('${tempDir.path}/at_limit.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(List.filled(150, '// line').join('\n'));

      final result = checkLineLengths(tempDir, exemptions: const {});

      expect(
        result.violations.any((v) => v.contains(file.path.replaceAll(r'\', '/'))),
        isFalse,
      );
    });

    test('does not flag a file listed in lineLimitExemptions', () {
      final file = File('${tempDir.path}/exempted.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(List.filled(200, '// line').join('\n'));
      final path = file.path.replaceAll(r'\', '/');

      final result = checkLineLengths(
        tempDir,
        exemptions: {path: 'Test-only exemption justification.'},
      );

      expect(result.violations.any((v) => v.contains(path)), isFalse);
      expect(result.exemptionsUsed.any((e) => e.contains(path)), isTrue);
    });
  });

  group('checkDirectorySizes', () {
    test('flags a directory with 11 hand-written .dart files', () {
      final dir = Directory('${tempDir.path}/crowded')..createSync();
      for (var i = 0; i < 11; i++) {
        File('${dir.path}/file_$i.dart').writeAsStringSync('// $i');
      }

      final violations = checkDirectorySizes(tempDir);

      expect(
        violations.any((v) => v.contains(dir.path.replaceAll(r'\', '/'))),
        isTrue,
      );
    });

    test(
        'does not flag a directory with exactly 10 hand-written .dart '
        'files', () {
      final dir = Directory('${tempDir.path}/at_limit')..createSync();
      for (var i = 0; i < 10; i++) {
        File('${dir.path}/file_$i.dart').writeAsStringSync('// $i');
      }

      final violations = checkDirectorySizes(tempDir);

      expect(
        violations.any((v) => v.contains(dir.path.replaceAll(r'\', '/'))),
        isFalse,
      );
    });

    test('a .g.dart file does not count toward the 10-file cap', () {
      final dir = Directory('${tempDir.path}/with_generated')..createSync();
      for (var i = 0; i < 10; i++) {
        File('${dir.path}/file_$i.dart').writeAsStringSync('// $i');
      }
      // 11th file is generated — should not push the directory over the cap.
      File('${dir.path}/file_10.g.dart').writeAsStringSync('// generated');

      final violations = checkDirectorySizes(tempDir);

      expect(
        violations.any((v) => v.contains(dir.path.replaceAll(r'\', '/'))),
        isFalse,
      );
    });
  });

  group('checkReadmes', () {
    test('flags a directory under a presentation/ tree with no README.md', () {
      final presentation = Directory('${tempDir.path}/presentation')..createSync();
      final feature = Directory('${presentation.path}/feature')..createSync();

      final violations = checkReadmes([presentation]);

      expect(
        violations.any((v) => v.contains(feature.path.replaceAll(r'\', '/'))),
        isTrue,
      );
    });

    test('does not flag the same directory when README.md is present', () {
      final presentation = Directory('${tempDir.path}/presentation')..createSync();
      final feature = Directory('${presentation.path}/feature')..createSync();
      File('${feature.path}/README.md').writeAsStringSync('# Feature\n');

      final violations = checkReadmes([presentation]);

      expect(
        violations.any((v) => v.contains(feature.path.replaceAll(r'\', '/'))),
        isFalse,
      );
    });
  });
}
