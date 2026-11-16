import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

/// Single-block PBKDF2-HMAC-SHA256 (dkLen = 32 = hLen).
///
/// Reproduces RFC 7914 section 11 (`passwd`, `salt`, 1); pinned by
/// test/infrastructure/lock/pbkdf2_pin_hasher_test.dart.
Uint8List pbkdf2HmacSha256(
  List<int> password,
  List<int> salt,
  int iterations,
) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

/// Equality whose running time does not depend on where [a] and [b] first
/// differ (T-05-11): no early return inside the loop.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// [PinHasher] over PBKDF2-HMAC-SHA256 (D-05).
///
/// 16-byte salt from [Random.secure], [iterations] rounds, 32-byte hash.
/// Every derivation runs in [Isolate.run] so the UI isolate never stalls.
/// The iteration count travels in each [PinRecord], so changing it later
/// needs no migration (RESEARCH A2).
@LazySingleton(as: PinHasher)
class Pbkdf2PinHasher implements PinHasher {
  /// Rounds used for new records.
  static const int iterations = 10000;

  /// Salt length in bytes for new records.
  static const int saltLength = 16;

  @override
  Future<PinRecord> create(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError('PIN must be $pinLength digits');
    }
    final random = Random.secure();
    final salt = List<int>.generate(saltLength, (_) => random.nextInt(256));
    final hash = await _derive(pin, salt, iterations);
    return PinRecord(iterations: iterations, salt: salt, hash: hash);
  }

  @override
  Future<bool> verify(String pin, PinRecord record) async {
    if (!isValidPin(pin)) return false;
    final hash = await _derive(pin, record.salt, record.iterations);
    return constantTimeEquals(hash, record.hash);
  }

  static Future<Uint8List> _derive(
    String pin,
    List<int> salt,
    int rounds,
  ) {
    final password = utf8.encode(pin);
    final saltCopy = List<int>.of(salt);
    return Isolate.run(() => pbkdf2HmacSha256(password, saltCopy, rounds));
  }
}
