import 'package:agenda/core/constants/secure_storage_keys.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/domain/lock/pin_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// [PinStore] over flutter_secure_storage 10.x (D-05, D-07).
///
/// The only class that reads or writes PIN material. The record and the
/// attempt state live in Keychain / Keystore-backed storage, never in the
/// plain preferences file. A failure carries only the exception TYPE, never a
/// PIN, record or salt (T-05-07).
///
/// Attempts are stored as `<failures>:<lockouts>:<cooldownUntil>`, the last
/// field being UTC milliseconds since epoch, empty when there is none.
@LazySingleton(as: PinStore)
class SecurePinStore implements PinStore {
  SecurePinStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  AsyncResult<PinRecord?> readRecord() async {
    try {
      final raw = await _storage.read(key: SecureStorageKeys.pinRecord);
      return Success(PinRecord.tryDecode(raw));
    } on Object catch (e) {
      return Err(SecurityFailure('readRecordFailed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<void> writeRecord(PinRecord record) async {
    try {
      await _storage.write(
        key: SecureStorageKeys.pinRecord,
        value: record.encode(),
      );
      return const Success(null);
    } on Object catch (e) {
      return Err(SecurityFailure('writeRecordFailed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<LockAttempts> readAttempts() async {
    try {
      final raw = await _storage.read(key: SecureStorageKeys.pinAttempts);
      if (raw == null) return const Success(LockAttempts.none);
      final attempts = _decodeAttempts(raw);
      if (attempts == null) {
        return const Err(SecurityFailure('readAttemptsFailed: malformed'));
      }
      return Success(attempts);
    } on Object catch (e) {
      return Err(SecurityFailure('readAttemptsFailed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<void> writeAttempts(LockAttempts attempts) async {
    try {
      await _storage.write(
        key: SecureStorageKeys.pinAttempts,
        value: _encodeAttempts(attempts),
      );
      return const Success(null);
    } on Object catch (e) {
      return Err(SecurityFailure('writeAttemptsFailed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<void> clear() async {
    try {
      await _storage.delete(key: SecureStorageKeys.pinRecord);
      await _storage.delete(key: SecureStorageKeys.pinAttempts);
      return const Success(null);
    } on Object catch (e) {
      return Err(SecurityFailure('clearFailed: ${e.runtimeType}'));
    }
  }

  static String _encodeAttempts(LockAttempts a) {
    final until = a.cooldownUntil?.toUtc().millisecondsSinceEpoch;
    return '${a.failures}:${a.lockouts}:${until ?? ''}';
  }

  static LockAttempts? _decodeAttempts(String raw) {
    final parts = raw.split(':');
    if (parts.length != 3) return null;
    final failures = int.tryParse(parts[0]);
    final lockouts = int.tryParse(parts[1]);
    if (failures == null || failures < 0) return null;
    if (lockouts == null || lockouts < 0) return null;
    DateTime? until;
    if (parts[2].isNotEmpty) {
      final ms = int.tryParse(parts[2]);
      if (ms == null) return null;
      until = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    return LockAttempts(
      failures: failures,
      lockouts: lockouts,
      cooldownUntil: until,
    );
  }
}
