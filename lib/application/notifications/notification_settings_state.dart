import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for the notification settings page state.
sealed class NotificationSettingsState extends Equatable {
  const NotificationSettingsState();
}

/// Emitted on construction, before the preferences and permissions are read.
final class NotificationSettingsInitial extends NotificationSettingsState {
  const NotificationSettingsInitial();

  @override
  List<Object?> get props => [];
}

/// Everything the settings page renders.
final class NotificationSettingsLoaded extends NotificationSettingsState {
  const NotificationSettingsLoaded({
    required this.prefs,
    required this.permission,
    required this.canScheduleExact,
    required this.waitingCount,
    this.permissionRequested = false,
  });

  /// The stored preferences.
  final NotificationPrefs prefs;

  /// The real OS notification permission, re-read on every resume.
  final NotificationPermission permission;

  /// Whether exact alarms may be scheduled (always true off Android 12+).
  final bool canScheduleExact;

  /// Reminders left out of the OS schedule by the slot budget.
  final int waitingCount;

  /// True once an OS request ended without the permission, which means the
  /// system may no longer show its dialog.
  final bool permissionRequested;

  NotificationSettingsLoaded copyWith({
    NotificationPrefs? prefs,
    NotificationPermission? permission,
    bool? canScheduleExact,
    int? waitingCount,
    bool? permissionRequested,
  }) => NotificationSettingsLoaded(
    prefs: prefs ?? this.prefs,
    permission: permission ?? this.permission,
    canScheduleExact: canScheduleExact ?? this.canScheduleExact,
    waitingCount: waitingCount ?? this.waitingCount,
    permissionRequested: permissionRequested ?? this.permissionRequested,
  );

  /// The state after an OS request ended with [result].
  NotificationSettingsLoaded afterRequest(NotificationPermission result) =>
      copyWith(
        permission: result,
        permissionRequested: result == NotificationPermission.denied,
      );

  /// The state after re-reading the OS: a grant clears [permissionRequested].
  NotificationSettingsLoaded afterRefresh(
    NotificationPermission fresh, {
    required bool exact,
  }) => copyWith(
    permission: fresh,
    canScheduleExact: exact,
    permissionRequested: fresh == NotificationPermission.granted ? false : null,
  );

  @override
  List<Object?> get props => [
    prefs,
    permission,
    canScheduleExact,
    waitingCount,
    permissionRequested,
  ];
}
