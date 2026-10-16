import 'dart:typed_data';

/// An in-memory backup artifact: a suggested file name plus its raw bytes.
///
/// The domain layer never touches the file system. Whoever receives a
/// [BackupFile] (the file-picker gateway) decides where the bytes land.
class BackupFile {
  const BackupFile({required this.name, required this.bytes});

  /// Suggested file name, for example `agenda-backup-2026-10-12.json`.
  final String name;

  /// Encoded file content.
  final Uint8List bytes;
}
