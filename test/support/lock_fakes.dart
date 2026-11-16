// Shared mocks for the app-lock tests (phase 05). Later plans append their
// mocks here.

import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/domain/lock/pin_store.dart';
import 'package:mocktail/mocktail.dart';

class MockPinHasher extends Mock implements PinHasher {}

class MockPinStore extends Mock implements PinStore {}

/// A well-formed record with fixed bytes, for stubbing.
final PinRecord fakePinRecord = PinRecord(
  iterations: 1,
  salt: List<int>.filled(16, 1),
  hash: List<int>.filled(PinRecord.hashLength, 2),
);

/// Registers mocktail fallbacks for the lock value types. Call once from
/// `setUpAll`.
void registerLockFallbacks() {
  registerFallbackValue(fakePinRecord);
  registerFallbackValue(LockAttempts.none);
}
