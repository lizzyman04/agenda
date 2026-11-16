// ExcursionGuardImpl (D-03, RESEARCH Pattern 4): active while an
// app-initiated excursion runs and for a 2 s grace after it ends.

import 'dart:async';

import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';

void main() {
  late FakeClock clock;
  late ExcursionGuardImpl guard;

  setUp(() {
    clock = FakeClock();
    guard = ExcursionGuardImpl(clock: clock.call);
  });

  test('inactive before any run', () {
    expect(guard.isActive(clock()), isFalse);
  });

  test('active from inside an awaited run, and returns its value', () async {
    bool? inside;
    final value = await guard.run(() async {
      clock.advance(const Duration(minutes: 3));
      inside = guard.isActive(clock());
      return 42;
    });
    expect(inside, isTrue);
    expect(value, 42);
  });

  test('active up to end + 2 s, inactive at end + 2.1 s', () async {
    await guard.run(() async {});
    final end = clock();
    expect(ExcursionGuardImpl.grace, const Duration(seconds: 2));
    expect(guard.isActive(end.add(const Duration(seconds: 2))), isTrue);
    expect(
      guard.isActive(end.add(const Duration(milliseconds: 2100))),
      isFalse,
    );
  });

  test('two overlapping runs keep it active until both finish', () async {
    final first = Completer<void>();
    final second = Completer<void>();
    final a = guard.run(() => first.future);
    final b = guard.run(() => second.future);

    first.complete();
    await a;
    clock.advance(const Duration(minutes: 1));
    expect(guard.isActive(clock()), isTrue);

    second.complete();
    await b;
    clock.advance(const Duration(seconds: 3));
    expect(guard.isActive(clock()), isFalse);
  });

  test('a nested run keeps the outer excursion active', () async {
    await guard.run(() async {
      await guard.run(() async {});
      clock.advance(const Duration(minutes: 1));
      expect(guard.isActive(clock()), isTrue);
    });
  });

  test('a throwing action still ends the excursion and rethrows', () async {
    await expectLater(
      guard.run<void>(() async => throw StateError('picker')),
      throwsStateError,
    );
    expect(guard.isActive(clock()), isTrue); // within the grace
    clock.advance(const Duration(seconds: 3));
    expect(guard.isActive(clock()), isFalse);
  });
}
