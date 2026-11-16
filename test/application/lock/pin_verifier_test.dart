import 'dart:async';

import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

const _fault = Err<Never>(SecurityFailure('readFailed: TestFault'));

void main() {
  late MockPinStore store;
  late MockPinHasher hasher;
  late FakeClock clock;
  late PinVerifier verifier;

  setUpAll(registerLockFallbacks);

  void stubAttempts(LockAttempts attempts) => when(
    () => store.readAttempts(),
  ).thenAnswer((_) async => Success(attempts));

  void stubPin({required bool matches}) {
    when(
      () => store.readRecord(),
    ).thenAnswer((_) async => Success<PinRecord?>(fakePinRecord));
    when(() => hasher.verify(any(), any())).thenAnswer((_) async => matches);
  }

  setUp(() {
    store = MockPinStore();
    hasher = MockPinHasher();
    clock = FakeClock();
    verifier = PinVerifier(store, hasher);
    stubAttempts(LockAttempts.none);
    when(
      () => store.writeAttempts(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  test('correct PIN verifies and resets the attempts', () async {
    stubAttempts(const LockAttempts(failures: 3));
    stubPin(matches: true);

    expect(await verifier.verify('1234', clock()), const PinVerified());
    verify(() => store.writeAttempts(LockAttempts.none)).called(1);
  });

  test('a failed reset write still returns PinVerified', () async {
    stubPin(matches: true);
    when(
      () => store.writeAttempts(any()),
    ).thenAnswer((_) async => const Err(SecurityFailure('w: TestFault')));

    expect(await verifier.verify('1234', clock()), const PinVerified());
  });

  for (var n = 1; n <= 4; n++) {
    test('wrong PIN $n is rejected with ${5 - n} remaining', () async {
      stubAttempts(LockAttempts(failures: n - 1));
      stubPin(matches: false);

      final outcome = await verifier.verify('0000', clock());

      expect(outcome, PinRejected(5 - n));
      verify(() => store.writeAttempts(LockAttempts(failures: n))).called(1);
    });
  }

  test('the rejection waits for the attempt write to finish', () async {
    stubPin(matches: false);
    final write = Completer<Result<void>>();
    when(() => store.writeAttempts(any())).thenAnswer((_) => write.future);

    var done = false;
    final pending = verifier.verify('0000', clock()).then((o) {
      done = true;
      return o;
    });
    await pumpEventQueue();
    expect(done, isFalse, reason: 'answered before the failure was stored');
    verify(() => store.writeAttempts(any())).called(1);

    write.complete(const Success(null));
    expect(await pending, const PinRejected(4));
  });

  test('wrong PIN 5 starts a cooldown with one lockout', () async {
    stubAttempts(const LockAttempts(failures: 4));
    stubPin(matches: false);

    final outcome = await verifier.verify('0000', clock());

    expect(outcome, isA<PinCoolingDown>());
    final attempts = (outcome as PinCoolingDown).attempts;
    expect(attempts.lockouts, 1);
    expect(attempts.isCoolingDown(clock()), isTrue);
    verify(() => store.writeAttempts(attempts)).called(1);
  });

  test('during a cooldown nothing is hashed or counted', () async {
    final cooling = LockAttempts(
      failures: 5,
      lockouts: 1,
      cooldownUntil: clock().add(const Duration(seconds: 30)),
    );
    stubAttempts(cooling);
    stubPin(matches: true);

    expect(await verifier.verify('1234', clock()), PinCoolingDown(cooling));
    verifyNever(() => hasher.verify(any(), any()));
    verifyNever(() => store.writeAttempts(any()));
  });

  group('fails closed', () {
    test('record absent', () async {
      when(
        () => store.readRecord(),
      ).thenAnswer((_) async => const Success<PinRecord?>(null));
      when(() => hasher.verify(any(), any())).thenAnswer((_) async => true);

      expect(await verifier.verify('1234', clock()), const PinCheckFailed());
      verifyNever(() => hasher.verify(any(), any()));
    });

    test('record read Err', () async {
      when(() => store.readRecord()).thenAnswer((_) async => _fault);
      expect(await verifier.verify('1234', clock()), const PinCheckFailed());
    });

    test('attempts read Err', () async {
      when(() => store.readAttempts()).thenAnswer((_) async => _fault);
      stubPin(matches: true);
      expect(await verifier.verify('1234', clock()), const PinCheckFailed());
    });

    test('attempts write Err after a wrong PIN', () async {
      stubPin(matches: false);
      when(
        () => store.writeAttempts(any()),
      ).thenAnswer((_) async => const Err(SecurityFailure('w: TestFault')));
      expect(await verifier.verify('0000', clock()), const PinCheckFailed());
    });

    test('invalid PIN format never touches the store', () async {
      stubPin(matches: true);
      for (final pin in ['', '123', '12345', '12a4']) {
        expect(await verifier.verify(pin, clock()), const PinCheckFailed());
      }
      verifyNever(() => store.readAttempts());
      verifyNever(() => store.readRecord());
      verifyNever(() => hasher.verify(any(), any()));
    });
  });

  test('resetAttempts writes LockAttempts.none', () async {
    await verifier.resetAttempts();
    verify(() => store.writeAttempts(LockAttempts.none)).called(1);
  });

  test('loadAttempts returns the stored state', () async {
    stubAttempts(const LockAttempts(failures: 2));
    final result = await verifier.loadAttempts();
    expect((result as Success<LockAttempts>).value.failures, 2);
  });
}
