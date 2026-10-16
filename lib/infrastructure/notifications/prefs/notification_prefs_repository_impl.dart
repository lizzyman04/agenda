import 'dart:async';
import 'dart:math';

import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _maxMinute = 1439;

/// [NotificationPrefsRepository] over [SharedPreferences].
///
/// Absent keys fall back to [NotificationPrefs.defaults]. Stored minutes
/// are clamped to 0..1439 and an unknown frequency string reads as daily,
/// so a hand-edited or corrupted store can never produce an invalid value.
/// [save] persists first and emits second, so a listener that reloads on
/// the event sees the stored data (D-09).
@LazySingleton(as: NotificationPrefsRepository)
class NotificationPrefsRepositoryImpl implements NotificationPrefsRepository {
  NotificationPrefsRepositoryImpl(this._store);

  final SharedPreferences _store;
  final StreamController<NotificationPrefs> _changes =
      StreamController<NotificationPrefs>.broadcast();

  @override
  NotificationPrefs load() {
    final defaults = NotificationPrefs.defaults();
    return NotificationPrefs(
      enabled: {
        for (final kind in NotificationKind.values)
          kind:
              _store.getBool('${StorageKeys.notifEnabledPrefix}${kind.code}') ??
              defaults.isEnabled(kind),
      },
      quietHoursEnabled:
          _store.getBool(StorageKeys.quietHoursEnabled) ??
          defaults.quietHoursEnabled,
      quietStartMinutes: _minutes(
        StorageKeys.quietHoursStart,
        defaults.quietStartMinutes,
      ),
      quietEndMinutes: _minutes(
        StorageKeys.quietHoursEnd,
        defaults.quietEndMinutes,
      ),
      briefingMinutes: _minutes(
        StorageKeys.notifBriefingMinutes,
        defaults.briefingMinutes,
      ),
      quoteFrequency: _frequency(),
      quoteMinutes: _minutes(
        StorageKeys.notifQuoteMinutes,
        defaults.quoteMinutes,
      ),
      quoteSeed: _seed(),
    );
  }

  @override
  Future<void> save(NotificationPrefs prefs) async {
    await Future.wait([
      for (final kind in NotificationKind.values)
        _store.setBool(
          '${StorageKeys.notifEnabledPrefix}${kind.code}',
          prefs.isEnabled(kind),
        ),
      _store.setBool(StorageKeys.quietHoursEnabled, prefs.quietHoursEnabled),
      _store.setInt(
        StorageKeys.quietHoursStart,
        _clamp(prefs.quietStartMinutes),
      ),
      _store.setInt(StorageKeys.quietHoursEnd, _clamp(prefs.quietEndMinutes)),
      _store.setInt(
        StorageKeys.notifBriefingMinutes,
        _clamp(prefs.briefingMinutes),
      ),
      _store.setString(
        StorageKeys.notifQuoteFrequency,
        prefs.quoteFrequency.name,
      ),
      _store.setInt(StorageKeys.notifQuoteMinutes, _clamp(prefs.quoteMinutes)),
      _store.setInt(StorageKeys.notifQuoteSeed, prefs.quoteSeed),
    ]);
    if (!_changes.isClosed) _changes.add(prefs);
  }

  @override
  Stream<NotificationPrefs> watch() => _changes.stream;

  int _clamp(int minutes) => minutes.clamp(0, _maxMinute);

  int _minutes(String key, int fallback) =>
      _clamp(_store.getInt(key) ?? fallback);

  QuoteFrequency _frequency() {
    final stored = _store.getString(StorageKeys.notifQuoteFrequency);
    for (final value in QuoteFrequency.values) {
      if (value.name == stored) return value;
    }
    return QuoteFrequency.daily;
  }

  /// Reads the quote seed, creating a positive one on first read.
  int _seed() {
    final stored = _store.getInt(StorageKeys.notifQuoteSeed);
    if (stored != null && stored > 0) return stored;
    final created = Random().nextInt(0x7FFFFFFE) + 1;
    unawaited(_store.setInt(StorageKeys.notifQuoteSeed, created));
    return created;
  }
}
