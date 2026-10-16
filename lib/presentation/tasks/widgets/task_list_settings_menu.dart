import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_screen.dart';
import 'package:flutter/material.dart';

/// Where the overflow menu can go. Plan 04-16 appends the backup entry.
enum TaskListSettingsDestination { notifications }

/// Temporary AppBar entry point to settings (D-15).
///
/// Phase 5 replaces it by mounting the notification settings page inside the
/// Settings screen.
class TaskListSettingsMenu extends StatelessWidget {
  const TaskListSettingsMenu({super.key});

  void _open(BuildContext context, TaskListSettingsDestination destination) {
    switch (destination) {
      case TaskListSettingsDestination.notifications:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationSettingsScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<TaskListSettingsDestination>(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n.settingsTitle,
      onSelected: (destination) => _open(context, destination),
      itemBuilder:
          (_) => [
            PopupMenuItem(
              value: TaskListSettingsDestination.notifications,
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined),
                  const SizedBox(width: 12),
                  Text(l10n.notifSettingsTitle),
                ],
              ),
            ),
          ],
    );
  }
}
