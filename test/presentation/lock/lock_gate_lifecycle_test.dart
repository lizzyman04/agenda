// D-01/D-02/D-04 tracer: the privacy overlay paints on `inactive`; a
// background trip past the timeout comes back to the lock screen with no
// content frame, a short trip continues in place, and the correct PIN
// reveals the route the user left.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:agenda/presentation/lock/widgets/privacy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

void main() {
  late FakeClock clock;
  late MockPinVerifier verifier;
  late AppLockCubit appLock;

  setUpAll(registerLockFallbacks);

  Future<void> start(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    appLock = AppLockCubit(
      await SharedPreferences.getInstance(),
      ExcursionGuardImpl(clock: clock.call),
      clock: clock.call,
    )..unlock();
  }

  setUp(() {
    clock = FakeClock();
    verifier = MockPinVerifier();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    when(
      () => verifier.verify('1234', any()),
    ).thenAnswer((_) async => const PinVerified());
    getIt.registerFactory<LockScreenCubit>(
      () => LockScreenCubit(verifier, appLock),
    );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  /// Cubit emissions reach BlocBuilder in a microtask, so the first pump
  /// only schedules the rebuild and the second paints it. A real engine runs
  /// the microtask before the next vsync: one frame.
  Future<void> frame(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  /// Whether the DETAIL text field (offstage or not) holds focus.
  bool fieldFocused(WidgetTester tester) =>
      tester
          .widget<EditableText>(find.byType(EditableText, skipOffstage: false))
          .focusNode
          .hasFocus;

  /// Pumps the app and pushes the DETAIL route with a focused TextField.
  Future<void> openDetail(WidgetTester tester) async {
    await tester.pumpWidget(lockTestApp(appLock: appLock, home: const _Home()));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsOneWidget);
    expect(fieldFocused(tester), isTrue);
  }

  /// Background trip of [away], then back to `resumed` (RESEARCH "Lifecycle
  /// test sequence").
  Future<void> trip(WidgetTester tester, Duration away) async {
    final b =
        tester.binding
          ..handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await frame(tester);
    expect(find.byType(PrivacyOverlay), findsOneWidget);
    b
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(away);
    b
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frame(tester);
  }

  testWidgets('past the timeout: overlay -> lock screen, then PIN resumes '
      'DETAIL', (tester) async {
    await start({'pin_configured': true, 'lock_timeout_seconds': 60});
    await openDetail(tester);

    await trip(tester, const Duration(minutes: 2));

    expect(find.byType(PrivacyOverlay), findsNothing);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('DETAIL'), findsNothing);
    expect(fieldFocused(tester), isFalse);

    await tester.pump();
    for (final d in ['1', '2', '3', '4']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(appLock.state.locked, isFalse);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('DETAIL'), findsOneWidget);
  });

  testWidgets('short trip (30 s, timeout 60): no lock, DETAIL stays', (
    tester,
  ) async {
    await start({'pin_configured': true, 'lock_timeout_seconds': 60});
    await openDetail(tester);

    await trip(tester, const Duration(seconds: 30));

    expect(find.byType(PrivacyOverlay), findsNothing);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('DETAIL'), findsOneWidget);
  });

  testWidgets('PIN off: inactive never shows the overlay', (tester) async {
    await start({});
    await tester.pumpWidget(lockTestApp(appLock: appLock));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byType(PrivacyOverlay), findsNothing);
    expect(find.text('HOME'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(LockScreen), findsNothing);
  });
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => const Scaffold(
                        body: Column(
                          children: [
                            Text('DETAIL'),
                            TextField(autofocus: true),
                          ],
                        ),
                      ),
                ),
              ),
          child: const Text('OPEN'),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'A'),
          NavigationDestination(icon: Icon(Icons.list), label: 'B'),
        ],
      ),
    );
  }
}
