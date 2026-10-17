import 'dart:async';

import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../infrastructure/notifications/fake_notification_gateway.dart';

class MockPrefsRepository extends Mock implements NotificationPrefsRepository {}

class MockReconciler extends Mock implements NotificationReconciler {}

void main() {
  late MockPrefsRepository repository;
  late MockReconciler reconciler;
  late FakeNotificationPermissionService permissions;
  late StreamController<int> waiting;
  late StreamController<NotificationPrefs> prefsStream;
  late List<String> events;
  late NotificationSettingsCubit cubit;

  setUpAll(() => registerFallbackValue(NotificationPrefs.defaults()));

  setUp(() {
    events = [];
    repository = MockPrefsRepository();
    reconciler = MockReconciler();
    permissions = FakeNotificationPermissionService();
    waiting = StreamController<int>.broadcast();
    prefsStream = StreamController<NotificationPrefs>.broadcast();
    when(() => repository.load()).thenReturn(NotificationPrefs.defaults());
    when(() => repository.watch()).thenAnswer((_) => prefsStream.stream);
    when(() => repository.save(any())).thenAnswer((_) async {
      events.add('save');
    });
    when(() => reconciler.truncatedCount).thenAnswer((_) => waiting.stream);
    cubit = NotificationSettingsCubit(repository, permissions, reconciler);
  });

  tearDown(() async {
    await cubit.close();
    await waiting.close();
    await prefsStream.close();
  });

  NotificationSettingsLoaded loaded() =>
      cubit.state as NotificationSettingsLoaded;

  group('NotificationSettingsCubit', () {
    test('starts in Initial', () {
      expect(cubit.state, const NotificationSettingsInitial());
    });

    test('start() emits Loaded with the stored prefs and OS state', () async {
      permissions
        ..permission = NotificationPermission.granted
        ..exact = false;
      await cubit.start();

      expect(loaded().prefs, NotificationPrefs.defaults());
      expect(loaded().permission, NotificationPermission.granted);
      expect(loaded().canScheduleExact, isFalse);
      expect(loaded().waitingCount, 0);
    });

    test('setEnabled with permission denied requests it, then saves', () async {
      await cubit.start();
      await cubit.setEnabled(NotificationKind.motivationalQuote, enabled: true);
      await Future<void>.delayed(Duration.zero);

      expect(permissions.notificationRequests, 1);
      final saved =
          verify(() => repository.save(captureAny())).captured.single
              as NotificationPrefs;
      expect(saved.isEnabled(NotificationKind.motivationalQuote), isTrue);
      expect(loaded().permission, NotificationPermission.granted);
      expect(
        loaded().prefs.isEnabled(NotificationKind.motivationalQuote),
        isTrue,
      );
    });

    test('setEnabled does not prompt when already granted', () async {
      permissions.permission = NotificationPermission.granted;
      await cubit.start();

      await cubit.setEnabled(NotificationKind.budgetAlert, enabled: false);

      expect(permissions.notificationRequests, 0);
      expect(loaded().prefs.isEnabled(NotificationKind.budgetAlert), isFalse);
    });

    test('setEnabled false never prompts even when denied', () async {
      await cubit.start();
      await cubit.setEnabled(NotificationKind.taskReminder, enabled: false);
      expect(permissions.notificationRequests, 0);
    });

    test('persists BEFORE emitting', () async {
      permissions.permission = NotificationPermission.granted;
      final gate = Completer<void>();
      when(() => repository.save(any())).thenAnswer((_) async {
        events.add('save-start');
        await gate.future;
        events.add('save-done');
      });
      await cubit.start();
      cubit.stream.listen((_) => events.add('emit'));

      final pending = cubit.setBriefingMinutes(600);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['save-start']);
      expect(loaded().prefs.briefingMinutes, isNot(600));

      gate.complete();
      await pending;
      await Future<void>.delayed(Duration.zero);
      expect(events, ['save-start', 'save-done', 'emit']);
      expect(loaded().prefs.briefingMinutes, 600);
    });

    test('minutes are clamped to 0..1439', () async {
      await cubit.start();

      await cubit.setBriefingMinutes(5000);
      expect(loaded().prefs.briefingMinutes, 1439);
      await cubit.setQuoteMinutes(-30);
      expect(loaded().prefs.quoteMinutes, 0);
      await cubit.setQuietStart(2000);
      expect(loaded().prefs.quietStartMinutes, 1439);
      await cubit.setQuietEnd(-1);
      expect(loaded().prefs.quietEndMinutes, 0);
    });

    test('quiet hours switch and quote frequency are persisted', () async {
      await cubit.start();

      await cubit.setQuietHoursEnabled(enabled: false);
      await cubit.setQuoteFrequency(QuoteFrequency.weekly);

      expect(loaded().prefs.quietHoursEnabled, isFalse);
      expect(loaded().prefs.quoteFrequency, QuoteFrequency.weekly);
      verify(() => repository.save(any())).called(2);
    });

    test('truncatedCount updates waitingCount', () async {
      await cubit.start();
      waiting.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(loaded().waitingCount, 3);
      waiting.add(0);
      await Future<void>.delayed(Duration.zero);
      expect(loaded().waitingCount, 0);
    });

    test('external prefs changes are followed', () async {
      await cubit.start();
      prefsStream.add(
        NotificationPrefs.defaults().copyWith(briefingMinutes: 725),
      );
      await Future<void>.delayed(Duration.zero);
      expect(loaded().prefs.briefingMinutes, 725);
    });

    test('refreshPermissions re-reads the OS state', () async {
      await cubit.start();
      expect(loaded().permission, NotificationPermission.denied);

      permissions
        ..permission = NotificationPermission.granted
        ..exact = false;
      await cubit.refreshPermissions();

      expect(loaded().permission, NotificationPermission.granted);
      expect(loaded().canScheduleExact, isFalse);
    });

    test('requestPermission and requestExactAlarms call the service', () async {
      await cubit.start();
      permissions.exact = false;

      await cubit.requestPermission();
      expect(permissions.notificationRequests, 1);
      expect(loaded().permission, NotificationPermission.granted);

      permissions.exact = true;
      await cubit.requestExactAlarms();
      expect(permissions.exactAlarmRequests, 1);
      expect(loaded().canScheduleExact, isTrue);
    });

    test(
      'a refused request sets permissionRequested, a grant does not',
      () async {
        permissions.grantOnRequest = false;
        await cubit.start();
        expect(loaded().permissionRequested, isFalse);

        await cubit.requestPermission();
        expect(permissions.notificationRequests, 1);
        expect(permissions.openSettingsCalls, 0);
        expect(loaded().permission, NotificationPermission.denied);
        expect(loaded().permissionRequested, isTrue);
      },
    );

    test('a granted request leaves permissionRequested false', () async {
      await cubit.start();
      await cubit.requestPermission();
      expect(loaded().permission, NotificationPermission.granted);
      expect(loaded().permissionRequested, isFalse);
    });

    test(
      'after a refusal requestPermission opens the system settings',
      () async {
        permissions.grantOnRequest = false;
        await cubit.start();
        await cubit.requestPermission();

        await cubit.requestPermission();
        expect(permissions.notificationRequests, 1);
        expect(permissions.openSettingsCalls, 1);
        expect(loaded().permissionRequested, isTrue);
      },
    );

    test('enabling a kind that ends denied sets permissionRequested', () async {
      permissions.grantOnRequest = false;
      await cubit.start();
      await cubit.setEnabled(NotificationKind.motivationalQuote, enabled: true);
      expect(permissions.notificationRequests, 1);
      expect(loaded().permissionRequested, isTrue);
    });

    test(
      'refreshPermissions clears permissionRequested once granted',
      () async {
        permissions.grantOnRequest = false;
        await cubit.start();
        await cubit.requestPermission();
        expect(loaded().permissionRequested, isTrue);

        await cubit.refreshPermissions();
        expect(loaded().permissionRequested, isTrue);

        permissions.permission = NotificationPermission.granted;
        await cubit.refreshPermissions();
        expect(loaded().permissionRequested, isFalse);
      },
    );

    test('methods before start() do nothing', () async {
      await cubit.setEnabled(NotificationKind.taskReminder, enabled: false);
      await cubit.setQuietStart(10);
      await cubit.setBriefingMinutes(10);
      await cubit.setQuoteMinutes(10);
      await cubit.setQuoteFrequency(QuoteFrequency.weekly);
      await cubit.setQuietHoursEnabled(enabled: false);
      await cubit.refreshPermissions();
      await cubit.requestPermission();
      await cubit.requestExactAlarms();

      expect(cubit.state, const NotificationSettingsInitial());
      verifyNever(() => repository.save(any()));
      expect(permissions.notificationRequests, 0);
      expect(permissions.exactAlarmRequests, 0);
    });

    test('close() cancels both subscriptions', () async {
      await cubit.start();
      expect(waiting.hasListener, isTrue);
      expect(prefsStream.hasListener, isTrue);

      await cubit.close();

      expect(waiting.hasListener, isFalse);
      expect(prefsStream.hasListener, isFalse);
    });
  });
}
