import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/data/backup/json/json_fields.dart';

/// Version of the backup FILE layout (not the Isar schema).
const int backupFormatVersion = 1;

/// Value of the envelope's `app` marker.
const String backupAppId = 'agenda';

/// Keys of the envelope's `collections` map.
abstract final class BackupJsonKeys {
  static const String items = 'items';
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String budgets = 'budgets';
  static const String goals = 'goals';
  static const String debts = 'debts';
  static const String recurringPayments = 'recurringPayments';
}

/// Builds the top-level backup document.
Map<String, Object?> buildBackupEnvelope({
  required DateTime exportedAt,
  required Map<String, List<Map<String, Object?>>> collections,
}) => {
  'app': backupAppId,
  'formatVersion': backupFormatVersion,
  'schemaVersion': AppConfig.schemaVersion,
  'exportedAt': encodeJsonDate(exportedAt),
  'collections': collections,
};

/// Result of [parseBackupEnvelope]: validated header plus per-collection
/// row readers.
///
/// Version GATING (unsupported or newer files) is deliberately not decided
/// here; the import engine does that.
final class ParsedEnvelope {
  const ParsedEnvelope({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.collections,
  });

  final int formatVersion;
  final int schemaVersion;
  final DateTime exportedAt;

  /// Row readers per collection key, paths like `items[3]`.
  final Map<String, List<JsonObjectReader>> collections;

  /// Rows of [key]; throws [FormatException] when the collection is absent.
  List<JsonObjectReader> rows(String key) {
    final found = collections[key];
    if (found == null) throw FormatException('$key: collection is missing');
    return found;
  }
}

/// Validates a decoded JSON document's envelope.
ParsedEnvelope parseBackupEnvelope(Object? decoded) {
  final root = JsonObjectReader.fromObject(decoded);
  if (root.requireString('app') != backupAppId) {
    throw const FormatException('app: not an AGENDA backup');
  }
  // Re-rooted so row paths read `items[3].field`, not `collections.items...`.
  final raw = root.requireObject('collections').rooted;
  return ParsedEnvelope(
    formatVersion: root.requireInt('formatVersion'),
    schemaVersion: root.requireInt('schemaVersion'),
    exportedAt: root.requireDate('exportedAt'),
    collections: {for (final k in raw.keys) k: raw.requireList(k)},
  );
}
