import 'dart:async';

import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

const int _maxMinute = 1439;

/// Drives the notification settings page (NOTF-08, NOTF-09, NOTF-10).
///
/// Every setter persists through [NotificationPrefsRepository] first and only
/// then emits. The cubit never schedules anything: the sync coordinator
/// reconciles on its own from the repository's `watch()` stream (D-09).
@injectable
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(
    this._repository,
    this._permissions,
    this._reconciler,
  ) : super(const NotificationSettingsInitial());

  final NotificationPrefsRepository _repository;
  final NotificationPermissionService _permissions;
  final NotificationReconciler _reconciler;

  StreamSubscription<int>? _waitingSub;
  StreamSubscription<NotificationPrefs>? _prefsSub;

  /// Loads prefs, permission and exact-alarm capability, then follows the
  /// waiting count and external preference changes.
  Future<void> start() async {
    await _cancelSubscriptions();
    final permission = await _permissions.notificationPermission();
    final exact = await _permissions.canScheduleExact();
    if (isClosed) return;
    emit(
      NotificationSettingsLoaded(
        prefs: _repository.load(),
        permission: permission,
        canScheduleExact: exact,
        waitingCount: 0,
      ),
    );
    _waitingSub = _reconciler.truncatedCount.listen(
      (count) => _update((s) => s.copyWith(waitingCount: count)),
    );
    _prefsSub = _repository.watch().listen(
      (prefs) => _update((s) => s.copyWith(prefs: prefs)),
    );
  }

  /// Switches one kind on or off. Enabling while the OS permission is not
  /// granted raises the system prompt first, in context (NOTF-09).
  Future<void> setEnabled(
    NotificationKind kind, {
    required bool enabled,
  }) async {
    final current = state;
    if (current is! NotificationSettingsLoaded) return;
    if (enabled && current.permission != NotificationPermission.granted) {
      final result = await _permissions.requestNotificationPermission();
      _update((s) => s.copyWith(permission: result));
    }
    await _save((p) => p.withEnabled(kind, value: enabled));
  }

  Future<void> setQuietHoursEnabled({required bool enabled}) =>
      _save((p) => p.copyWith(quietHoursEnabled: enabled));

  Future<void> setQuietStart(int minutes) =>
      _save((p) => p.copyWith(quietStartMinutes: _clamp(minutes)));

  Future<void> setQuietEnd(int minutes) =>
      _save((p) => p.copyWith(quietEndMinutes: _clamp(minutes)));

  Future<void> setBriefingMinutes(int minutes) =>
      _save((p) => p.copyWith(briefingMinutes: _clamp(minutes)));

  Future<void> setQuoteFrequency(QuoteFrequency frequency) =>
      _save((p) => p.copyWith(quoteFrequency: frequency));

  Future<void> setQuoteMinutes(int minutes) =>
      _save((p) => p.copyWith(quoteMinutes: _clamp(minutes)));

  /// Re-reads the OS state; called on resume so a stale grant never shows.
  Future<void> refreshPermissions() async {
    if (state is! NotificationSettingsLoaded) return;
    final permission = await _permissions.notificationPermission();
    final exact = await _permissions.canScheduleExact();
    _update(
      (s) => s.copyWith(permission: permission, canScheduleExact: exact),
    );
  }

  /// Raises the system notification prompt from the denied banner.
  Future<void> requestPermission() async {
    if (state is! NotificationSettingsLoaded) return;
    final result = await _permissions.requestNotificationPermission();
    _update((s) => s.copyWith(permission: result));
  }

  /// Opens the system exact-alarm screen, then refreshes the capability.
  Future<void> requestExactAlarms() async {
    if (state is! NotificationSettingsLoaded) return;
    await _permissions.requestExactAlarmPermission();
    await refreshPermissions();
  }

  int _clamp(int minutes) => minutes.clamp(0, _maxMinute);

  Future<void> _save(
    NotificationPrefs Function(NotificationPrefs prefs) change,
  ) async {
    final current = state;
    if (current is! NotificationSettingsLoaded) return;
    final next = change(current.prefs);
    await _repository.save(next);
    _update((s) => s.copyWith(prefs: next));
  }

  void _update(
    NotificationSettingsLoaded Function(NotificationSettingsLoaded) f,
  ) {
    final current = state;
    if (isClosed || current is! NotificationSettingsLoaded) return;
    emit(f(current));
  }

  Future<void> _cancelSubscriptions() async {
    await _waitingSub?.cancel();
    await _prefsSub?.cancel();
    _waitingSub = null;
    _prefsSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
