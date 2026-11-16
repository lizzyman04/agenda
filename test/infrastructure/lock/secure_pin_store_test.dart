import 'package:agenda/core/constants/secure_storage_keys.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/infrastructure/lock/pbkdf2_pin_hasher.dart';
import 'package:agenda/infrastructure/lock/secure_pin_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

T _value<T>(Result<T> result) => switch (result) {
  Success(:final value) => value,
  Err(:final failure) => throw StateError(failure.message),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage storage;
  late SecurePinStore store;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    store = SecurePinStore(storage);
  });

  test('tracer: a PIN written through the store verifies through '
      'the hasher', () async {
    final hasher = Pbkdf2PinHasher();
    _value(await store.writeRecord(await hasher.create('2580')));

    final record = _value(await store.readRecord());
    expect(record, isNotNull);
    expect(await hasher.verify('2580', record!), isTrue);
    expect(await hasher.verify('2581', record), isFalse);
  });

  test('record round trip', () async {
    final record = PinRecord(
      iterations: 10000,
      salt: List<int>.generate(16, (i) => i),
      hash: List<int>.generate(32, (i) => 255 - i),
    );
    _value(await store.writeRecord(record));
    expect(_value(await store.readRecord()), record);
  });

  test('absent record reads as null', () async {
    expect(_value(await store.readRecord()), isNull);
  });

  test('malformed record reads as Success(null)', () async {
    await storage.write(key: SecureStorageKeys.pinRecord, value: 'garbage');
    final result = await store.readRecord();
    expect(result, isA<Success<PinRecord?>>());
    expect(_value(result), isNull);
  });

  test('attempts round trip without cooldownUntil', () async {
    const attempts = LockAttempts(failures: 3);
    _value(await store.writeAttempts(attempts));
    expect(_value(await store.readAttempts()), attempts);
  });

  test('attempts round trip with cooldownUntil', () async {
    final attempts = LockAttempts(
      failures: 5,
      lockouts: 1,
      cooldownUntil: DateTime.utc(2026, 11, 16, 12, 30, 15, 250),
    );
    _value(await store.writeAttempts(attempts));
    expect(_value(await store.readAttempts()), attempts);
  });

  test('absent attempts read as LockAttempts.none', () async {
    expect(_value(await store.readAttempts()), LockAttempts.none);
  });

  test('malformed attempts read as Err(SecurityFailure)', () async {
    await storage.write(key: SecureStorageKeys.pinAttempts, value: '1:x:');
    final result = await store.readAttempts();
    expect(result, isA<Err<LockAttempts>>());
    expect((result as Err<LockAttempts>).failure, isA<SecurityFailure>());
  });

  test('clear removes the record and the attempts', () async {
    await storage.write(key: SecureStorageKeys.pinRecord, value: 'r');
    await storage.write(key: SecureStorageKeys.pinAttempts, value: '1:0:');
    _value(await store.clear());
    expect(await storage.read(key: SecureStorageKeys.pinRecord), isNull);
    expect(await storage.read(key: SecureStorageKeys.pinAttempts), isNull);
  });
}
