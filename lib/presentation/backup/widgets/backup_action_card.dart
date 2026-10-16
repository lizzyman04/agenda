import 'package:flutter/material.dart';

/// A tappable card for one backup action: icon, title, description, chevron.
///
/// A null [onPressed] disables the card (used while an export is running).
class BackupActionCard extends StatelessWidget {
  const BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        enabled: onPressed != null,
        onTap: onPressed,
      ),
    );
  }
}
