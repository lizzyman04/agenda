import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<NotificationPrefsRepositoryImpl> _repo([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return NotificationPrefsRepositoryImpl(await SharedPreferences.getInstance());
}

void main() {
  test('an empty store yields the defaults, quotes off (D-07)', () async {
    final prefs = (await _repo()).load();
    final defaults = NotificationPrefs.defaults();

    expect(prefs.isEnabled(NotificationKind.motivationalQuote), isFalse);
    for (final kind in NotificationKind.values) {
      if (kind == NotificationKind.motivationalQuote) continue;
      expect(prefs.isEnabled(kind), isTrue, reason: kind.name);
    }
    expect(prefs.quietHoursEnabled, defaults.quietHoursEnabled);
    expect(prefs.quietStartMinutes, defaults.quietStartMinutes);
    expect(prefs.quietEndMinutes, defaults.quietEndMinutes);
    expect(prefs.briefingMinutes, defaults.briefingMinutes);
    expect(prefs.quoteFrequency, QuoteFrequency.daily);
    expect(prefs.quoteMinutes, defaults.quoteMinutes);
  });

  test('a saved value round-trips through a new repository', () async {
    final first = await _repo();
    final saved = first
        .load()
        .withEnabled(NotificationKind.budgetAlert, value: false)
        .withEnabled(NotificationKind.motivationalQuote, value: true)
        .copyWith(
          quietHoursEnabled: false,
          quietStartMinutes: 23 * 60 + 15,
          quietEndMinutes: 6 * 60 + 45,
          briefingMinutes: 7 * 60 + 5,
          quoteFrequency: QuoteFrequency.weekly,
          quoteMinutes: 12 * 60,
        );
    await first.save(saved);

    final second = NotificationPrefsRepositoryImpl(
      await SharedPreferences.getInstance(),
    );
    expect(second.load(), saved);
  });

  test('watch emits the saved value after it is persisted', () async {
    final repo = await _repo();
    final saved = repo.load().copyWith(briefingMinutes: 600);

    final emitted = <NotificationPrefs>[];
    final sub = repo.watch().listen(emitted.add);
    await repo.save(saved);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emitted, [saved]);
    expect(repo.load().briefingMinutes, 600);
  });

  test('out-of-range minutes are clamped to 0..1439', () async {
    final repo = await _repo({
      StorageKeys.notifBriefingMinutes: 5000,
      StorageKeys.notifQuoteMinutes: -20,
      StorageKeys.quietHoursStart: 1440,
    });
    final prefs = repo.load();

    expect(prefs.briefingMinutes, 1439);
    expect(prefs.quoteMinutes, 0);
    expect(prefs.quietStartMinutes, 1439);
  });

  test('an unknown frequency string falls back to daily', () async {
    final repo = await _repo({StorageKeys.notifQuoteFrequency: 'hourly'});

    expect(repo.load().quoteFrequency, QuoteFrequency.daily);
  });

  test('the quote seed is non-zero and stable across loads', () async {
    final repo = await _repo();
    final first = repo.load().quoteSeed;
    await Future<void>.delayed(Duration.zero);
    final second = repo.load().quoteSeed;

    expect(first, greaterThan(0));
    expect(second, first);

    final reopened = NotificationPrefsRepositoryImpl(
      await SharedPreferences.getInstance(),
    );
    expect(reopened.load().quoteSeed, first);
  });
}
