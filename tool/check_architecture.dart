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

void main() {
  final violations = <String>[];
  final exemptionsUsed = <String>[];
  final libDir = Directory('lib');

  final dartFilesByDir = <String, List<File>>{};

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (isGenerated(path)) continue;

    dartFilesByDir.putIfAbsent(entity.parent.path, () => []).add(entity);

    if (lineLimitExemptions.containsKey(path)) {
      exemptionsUsed.add('$path — ${lineLimitExemptions[path]}');
      continue;
    }

    final lineCount = entity.readAsLinesSync().length;
    if (lineCount > maxLinesPerFile) {
      violations.add('LINES  $path: $lineCount > $maxLinesPerFile');
    }
  }

  dartFilesByDir.forEach((dir, files) {
    if (files.length > maxFilesPerDirectory) {
      violations.add(
        'FILES  $dir: ${files.length} hand-written files > '
        '$maxFilesPerDirectory',
      );
    }
  });

  final scopedRoots = <Directory>[
    Directory('lib/presentation'),
    Directory('lib/application'),
  ].where((d) => d.existsSync());

  final scopedDirs = <Directory>[
    for (final root in scopedRoots) ...[
      root,
      ...root.listSync(recursive: true).whereType<Directory>(),
    ],
  ];

  for (final dir in scopedDirs) {
    final path = dir.path.replaceAll(r'\', '/');
    if (readmeExemptDirs.contains(path)) continue;
    final readme = File('$path/README.md');
    if (!readme.existsSync()) {
      violations.add('README $path: missing README.md');
    }
  }

  if (exemptionsUsed.isNotEmpty) {
    stdout.writeln('Documented exemptions in effect:');
    for (final e in exemptionsUsed) {
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
