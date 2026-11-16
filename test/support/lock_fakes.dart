// Shared mocks for the app-lock tests (phase 05). Later plans append their
// mocks here.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/application/lock/lock_device_auth.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/core/constants/secure_storage_keys.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/excursion_guard.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/domain/lock/pin_store.dart';
import 'package:agenda/domain/lock/secure_window_gateway.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/pbkdf2_pin_hasher.dart';
import 'package:agenda/presentation/lock/widgets/lock_gate.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockPinHasher extends Mock implements PinHasher {}

class MockPinStore extends Mock implements PinStore {}

class MockPinVerifier extends Mock implements PinVerifier {}

class MockAppLockCubit extends MockCubit<AppLockState>
    implements AppLockCubit {}

class MockExcursionGuard extends Mock implements ExcursionGuard {}

class MockSecureWindowGateway extends Mock implements SecureWindowGateway {}

class MockDeviceAuthGateway extends Mock implements DeviceAuthGateway {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockLockDeviceAuth extends Mock implements LockDeviceAuth {}

/// Any prompt, for stubbing and verifying device-auth calls.
const DeviceAuthPrompt fakeAuthPrompt = DeviceAuthPrompt(
  reason: 'reason',
  title: 'title',
  hint: 'hint',
  cancelLabel: 'cancel',
);

/// A [MockLockDeviceAuth] that never offers biometrics: the PIN-only lock
/// screen of the tests written before 05-11.
MockLockDeviceAuth pinOnlyDeviceAuth() {
  final auth = MockLockDeviceAuth();
  when(auth.biometricOffered).thenAnswer((_) async => false);
  return auth;
}

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
  registerFallbackValue(DateTime.utc(2026));
  registerFallbackValue(fakeAuthPrompt);
}

/// A localized app frame like `AgendaApp`: [AppLockCubit] provided above
/// `MaterialApp`, `LockGate` in `MaterialApp.builder`, and a [home] that
/// stands in for the shell.
Widget lockTestApp({
  required AppLockCubit appLock,
  Widget? home,
  Locale locale = const Locale('pt', 'BR'),
  bool disableAnimations = false,
}) {
  return BlocProvider<AppLockCubit>.value(
    value: appLock,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final gate = LockGate(child: child!);
        if (!disableAnimations) return gate;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: gate,
        );
      },
      home: home ?? const LockTestHome(),
    ),
  );
}

/// Stand-in for the app shell: a 'HOME' text and a NavigationBar.
class LockTestHome extends StatelessWidget {
  const LockTestHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('HOME')),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'A'),
          NavigationDestination(icon: Icon(Icons.list), label: 'B'),
        ],
      ),
    );
  }
}

/// Lets real async work (the PBKDF2 isolate, secure storage) finish, pumping
/// between slices, until [done] holds or the budget runs out.
Future<void> settleRealAsync(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 100,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

/// Seeds secure storage with a real PBKDF2 record for [pin]. Hashing runs
/// in an isolate, so call it outside fake async (or inside `runAsync`).
Future<void> seedPinRecord(String pin) async {
  final record = await Pbkdf2PinHasher().create(pin);
  FlutterSecureStorage.setMockInitialValues({
    SecureStorageKeys.pinRecord: record.encode(),
  });
}
