import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A stored PIN: salt, derived hash and the iteration count used (D-05).
///
/// Persisted as one versioned string,
/// `v1:<iterations>:<base64 salt>:<base64 hash>`, so a single write can
/// never tear the salt from its hash and the iteration count can be raised
/// later without a migration. The PIN itself is never part of a record.
final class PinRecord extends Equatable {
  const PinRecord({
    required this.iterations,
    required this.salt,
    required this.hash,
  });

  /// The record format written by [encode].
  static const int currentVersion = 1;

  /// Length in bytes of a PBKDF2-HMAC-SHA256 hash.
  static const int hashLength = 32;

  static const String _versionTag = 'v$currentVersion';

  /// PBKDF2 iteration count the [hash] was derived with.
  final int iterations;

  /// Random salt the [hash] was derived with.
  final List<int> salt;

  /// The derived key.
  final List<int> hash;

  /// The storage form of this record.
  String encode() =>
      '$_versionTag:$iterations:${base64.encode(salt)}:${base64.encode(hash)}';

  /// Parses [raw] as written by [encode]; null for anything malformed.
  static PinRecord? tryDecode(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 4 || parts[0] != _versionTag) return null;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) return null;
    try {
      final salt = base64.decode(parts[2]);
      final hash = base64.decode(parts[3]);
      if (salt.isEmpty || hash.length != hashLength) return null;
      return PinRecord(iterations: iterations, salt: salt, hash: hash);
    } on FormatException {
      return null;
    }
  }

  @override
  List<Object?> get props => [iterations, salt, hash];

  // Never print salt or hash (T-05-07).
  @override
  bool get stringify => false;
}
