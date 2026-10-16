import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Writes the automatic safety backup taken just before an import replaces
/// data (D-12), keeping only the newest [keep] files.
///
/// Files live in `<app documents>/backups`, a private location that is
/// excluded from Android Auto Backup (D-13). Names are generated from the
/// clock and never from anything the user picked (CWE-22, T-04-11-05).
class SafetyBackupStore {
  SafetyBackupStore({
    Directory? baseDirectory,
    DateTime Function()? clock,
    this.keep = 3,
  }) : _base = baseDirectory,
       _clock = clock ?? DateTime.now;

  /// Resolves the base directory when none is injected. Tests replace it.
  @visibleForTesting
  static Future<Directory> Function() directoryResolver =
      getApplicationDocumentsDirectory;

  /// How many safety backups survive a write.
  final int keep;

  final Directory? _base;
  final DateTime Function() _clock;

  static final RegExp _name = RegExp(
    r'^safety-backup-(\d{8}-\d{6})(?:-(\d+))?\.json$',
  );

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Writes [bytes] as a new safety backup, rotates older ones and returns
  /// the absolute path of the new file.
  Future<String> write(Uint8List bytes) async {
    final base = _base ?? await directoryResolver();
    final dir = Directory('${base.path}${Platform.pathSeparator}backups');
    await dir.create(recursive: true);
    final t = _clock();
    final stamp =
        '${t.year.toString().padLeft(4, '0')}${_two(t.month)}${_two(t.day)}'
        '-${_two(t.hour)}${_two(t.minute)}${_two(t.second)}';
    var file = File(
      '${dir.path}${Platform.pathSeparator}safety-backup-$stamp.json',
    );
    for (var n = 1; file.existsSync(); n++) {
      file = File(
        '${dir.path}${Platform.pathSeparator}safety-backup-$stamp-$n.json',
      );
    }
    await file.writeAsBytes(bytes, flush: true);
    await _rotate(dir, file);
    return file.absolute.path;
  }

  // Newest first by (timestamp, collision suffix). The file just written is
  // always kept, even if the clock moved backwards.
  Future<void> _rotate(Directory dir, File fresh) async {
    final entries = <(String, int, File)>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final match = _name.firstMatch(entity.uri.pathSegments.last);
      if (match == null) continue;
      entries.add((match.group(1)!, int.parse(match.group(2) ?? '0'), entity));
    }
    entries.sort((a, b) {
      final byStamp = b.$1.compareTo(a.$1);
      return byStamp != 0 ? byStamp : b.$2.compareTo(a.$2);
    });
    final survivors = entries.take(keep).map((e) => e.$3.path).toSet();
    for (final (_, _, file) in entries) {
      if (survivors.contains(file.path) || file.path == fresh.path) continue;
      await file.delete();
    }
  }
}
