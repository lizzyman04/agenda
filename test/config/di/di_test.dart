import 'package:agenda/config/di/injection.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Reset GetIt between test runs to avoid state bleed.
  setUp(() async {
    // Provide a mock SharedPreferences so preResolve does not
    // touch the file system.
    SharedPreferences.setMockInitialValues({});
    if (getIt.isRegistered<IsarService>()) {
      await getIt.reset();
    }
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('DI graph', () {
    test('getIt resolves IsarService without error', () {
      final service = getIt<IsarService>();
      expect(service, isA<IsarService>());
      expect(service, same(IsarService.instance));
    });

    test('getIt resolves SharedPreferences without error', () {
      final prefs = getIt<SharedPreferences>();
      expect(prefs, isA<SharedPreferences>());
    });

    test(
      'IsarService is a singleton: same instance on repeated calls',
      () {
        final a = getIt<IsarService>();
        final b = getIt<IsarService>();
        expect(identical(a, b), isTrue);
      },
    );
  });
}
