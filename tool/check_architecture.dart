// Architecture compliance guard.
//
// Checks the hand-written `lib/` tree against three house rules:
//   1. No hand-written .dart file exceeds [maxLinesPerFile] lines.
//   2. No directory holds more than [maxFilesPerDirectory] hand-written
//      .dart files (grouped by a file's immediate parent directory only).
//   3. Every directory under lib/presentation/ and lib/application/ has a
//      README.md.
//
// Run: dart run tool/check_architecture.dart
//
// NOTE: informational mode only (Phase 03.1-01). This script always exits 0
// for now — it is not yet wired into CI. Enforcement (exit 1 on violations,
// CI wiring) is deferred to plan 03.1-18, once the tree is compliant.
//
// The three checks below are exposed as standalone functions (each taking
// its own root `Directory`/list of roots) so they can be unit-tested
// against synthetic fixture trees, independent of the live `lib/` tree's
// ever-changing state — see test/tool/check_architecture_test.dart.

import 'dart:io';

import 'architecture_exemptions.dart';

const maxLinesPerFile = 150;
const maxFilesPerDirectory = 10;

/// Mirrors `analysis_options.yaml`'s `analyzer.exclude` list exactly, so
/// "hand-written" here means the same thing it means to the analyzer.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path == 'lib/config/di/injection.config.dart' ||
    path.startsWith('lib/generated/');

/// Result of [checkLineLengths]: the violations found, plus the list of
/// exempted files that were skipped (for the "documented exemptions in
/// effect" printout).
typedef LineCheckResult = ({
  List<String> violations,
  List<String> exemptionsUsed,
});

/// Scans [root] (recursively) for hand-written `.dart` files whose line
/// count exceeds [maxLines]. Files listed in [exemptions] are skipped (and
/// reported separately) rather than counted as violations.
LineCheckResult checkLineLengths(
  Directory root, {
  int maxLines = maxLinesPerFile,
  Map<String, String> exemptions = lineLimitExemptions,
}) {
  final violations = <String>[];
  final exemptionsUsed = <String>[];

  if (!root.existsSync()) {
    return (violations: violations, exemptionsUsed: exemptionsUsed);
  }

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (isGenerated(path)) continue;

    if (exemptions.containsKey(path)) {
      exemptionsUsed.add('$path — ${exemptions[path]}');
      continue;
    }

    final lineCount = entity.readAsLinesSync().length;
    if (lineCount > maxLines) {
      violations.add('LINES  $path: $lineCount > $maxLines');
    }
  }

  return (violations: violations, exemptionsUsed: exemptionsUsed);
}

/// Scans [root] (recursively) for directories holding more than [maxFiles]
/// hand-written `.dart` files, grouped by a file's immediate parent
/// directory only (subdirectories do not count toward their parent's
/// total). Generated files (see [isGenerated]) never count.
List<String> checkDirectorySizes(
  Directory root, {
  int maxFiles = maxFilesPerDirectory,
}) {
  final violations = <String>[];
  if (!root.existsSync()) return violations;

  final dartFilesByDir = <String, List<File>>{};

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (isGenerated(path)) continue;

    dartFilesByDir.putIfAbsent(entity.parent.path, () => []).add(entity);
  }

  dartFilesByDir.forEach((dir, files) {
    if (files.length > maxFiles) {
      violations.add(
        'FILES  $dir: ${files.length} hand-written files > $maxFiles',
      );
    }
  });

  return violations;
}

/// Checks every directory under each of [roots] (recursively, including
/// the roots themselves) for a `README.md`. Directories listed in
/// [exemptDirs] are skipped.
List<String> checkReadmes(
  List<Directory> roots, {
  Set<String> exemptDirs = readmeExemptDirs,
}) {
  final violations = <String>[];

  final existingRoots = roots.where((d) => d.existsSync());
  final scopedDirs = <Directory>[
    for (final root in existingRoots) ...[
      root,
      ...root.listSync(recursive: true).whereType<Directory>(),
    ],
  ];

  for (final dir in scopedDirs) {
    final path = dir.path.replaceAll(r'\', '/');
    if (exemptDirs.contains(path)) continue;
    final readme = File('$path/README.md');
    if (!readme.existsSync()) {
      violations.add('README $path: missing README.md');
    }
  }

  return violations;
}

void main() {
  final libDir = Directory('lib');

  final lineResult = checkLineLengths(libDir);
  final directoryViolations = checkDirectorySizes(libDir);
  final readmeViolations = checkReadmes([
    Directory('lib/presentation'),
    Directory('lib/application'),
  ]);

  final violations = [
    ...lineResult.violations,
    ...directoryViolations,
    ...readmeViolations,
  ];

  if (lineResult.exemptionsUsed.isNotEmpty) {
    stdout.writeln('Documented exemptions in effect:');
    for (final e in lineResult.exemptionsUsed) {
      stdout.writeln('  - $e');
    }
    stdout.writeln();
  }

  if (violations.isEmpty) {
    stdout.writeln('Architecture guard: PASS');
    exit(0);
  }

  stdout.writeln(
    'Architecture guard: FAIL (${violations.length} violation(s)) '
    '[informational only — not yet enforced in CI, see 03.1-18]',
  );
  for (final v in violations) {
    stdout.writeln('  - $v');
  }
  // Informational mode (Phase 03.1-01): always exit 0. Enforcement mode
  // (exit 1 on violations) is deferred to plan 03.1-18.
  exit(0);
}
