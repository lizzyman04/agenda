// SC-1 / DATA-05 tracer: with a PIN configured the first frame is the lock
// screen, and the correct PIN reveals the app; with no PIN, no lock.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

void main() {
  Future<void> configure(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    if (getIt.isRegistered<IsarService>()) await getIt.reset();
    await configureDependencies();
  }

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('PIN configured: frame 1 is the lock screen; 1234 unlocks', (
    tester,
  ) async {
    await tester.runAsync(() => seedPinRecord('1234'));
    await configure({'pin_configured': true});
    final appLock = getIt<AppLockCubit>();

    await tester.pumpWidget(lockTestApp(appLock: appLock));

    // First pump: only the lock screen exists onstage.
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    // Let the attempt state load before typing.
    await settleRealAsync(tester, () => false, maxRounds: 3);
    for (final d in ['1', '2', '3', '4']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await settleRealAsync(tester, () => !appLock.state.locked);
    await tester.pumpAndSettle();

    expect(appLock.state.locked, isFalse);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a wrong PIN keeps the lock', (tester) async {
    await tester.runAsync(() => seedPinRecord('1234'));
    await configure({'pin_configured': true});
    final appLock = getIt<AppLockCubit>();

    await tester.pumpWidget(lockTestApp(appLock: appLock));
    await settleRealAsync(tester, () => false, maxRounds: 3);
    for (final d in ['9', '9', '9', '9']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await settleRealAsync(tester, () => false, maxRounds: 25);

    expect(appLock.state.locked, isTrue);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('no PIN configured: HOME on the first pump, never a lock', (
    tester,
  ) async {
    await configure({});

    await tester.pumpWidget(lockTestApp(appLock: getIt<AppLockCubit>()));

    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
  });
}
