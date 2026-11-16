// LockGate cover guarantees: hidden content is absent from semantics, back
// never removes the lock, and unlock fades as specified (DATA-05).

import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:agenda/presentation/lock/widgets/lock_gate.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

const _unlocked = AppLockState(pinEnabled: true, locked: false);
const _locked = AppLockState(pinEnabled: true, locked: true);

void main() {
  late MockPinVerifier verifier;
  late AppLockCubit appLock;

  setUpAll(registerLockFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'pin_configured': true});
    appLock = AppLockCubit(await SharedPreferences.getInstance());
    verifier = MockPinVerifier();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    getIt.registerFactory<LockScreenCubit>(
      () => LockScreenCubit(verifier, appLock),
    );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  testWidgets('locked: hidden content has no semantics, paint or hits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(lockTestApp(appLock: appLock));

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.bySemanticsLabel('HOME'), findsNothing);
    expect(find.text('HOME'), findsNothing);
    // Still mounted (navigation state is kept), just offstage.
    expect(find.text('HOME', skipOffstage: false), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('system back at the root leaves the lock up', (tester) async {
    await tester.pumpWidget(lockTestApp(appLock: appLock));
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(appLock.state.locked, isTrue);
  });

  testWidgets('system back pops a hidden route, never the lock', (
    tester,
  ) async {
    final mock = MockAppLockCubit();
    final states = StreamController<AppLockState>();
    addTearDown(states.close);
    whenListen(mock, states.stream, initialState: _unlocked);

    await tester.pumpWidget(lockTestApp(appLock: mock));
    final appNavigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      appNavigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('SECOND')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SECOND'), findsOneWidget);

    // The mocked stream delivers asynchronously; settle until it lands.
    states.add(_locked);
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('SECOND'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // The lock stays; the hidden route was popped (its exit transition is
    // frozen while tickers are off, so it finishes after unlock).
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(appNavigator.canPop(), isFalse);

    states.add(_unlocked);
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('SECOND', skipOffstage: false), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('unlock: app onstage at once, lock fades out over 150 ms', (
    tester,
  ) async {
    await tester.pumpWidget(lockTestApp(appLock: appLock));
    appLock.unlock();
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 75));
    expect(find.byType(LockScreen), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(LockScreen),
        matching: find.byKey(lockFadeKey),
      ),
      findsOneWidget,
    );
    final fade = tester.widget<FadeTransition>(find.byKey(lockFadeKey));
    expect(fade.opacity.value, inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('unlock with animations disabled removes the lock at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      lockTestApp(appLock: appLock, disableAnimations: true),
    );
    expect(find.byType(LockScreen), findsOneWidget);

    appLock.unlock();
    await tester.pump();

    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });
}
