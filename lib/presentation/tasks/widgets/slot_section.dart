import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Section widget for one 1-3-5 Rule slot (big / medium / small).
///
/// Renders the slot header with current vs max count, an optional
/// over-capacity warning banner, a list of assigned items with remove
/// buttons, and an "Add" action.
class SlotSection extends StatelessWidget {
  const SlotSection({
    super.key,
    required this.label,
    required this.maxSlots,
    required this.currentItems,
    required this.isOverCapacity,
    required this.onTapAdd,
    required this.onRemove,
  });

  final String label;
  final int maxSlots;
  final List<Item> currentItems;
  final bool isOverCapacity;
  final VoidCallback onTapAdd;
  final void Function(int id) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentCount = currentItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '$label ($currentCount/$maxSlots)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Over-capacity warning banner
        if (isOverCapacity)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              border: Border.all(color: Colors.amber.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.slotLimitExceeded,
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Items list
        ...currentItems.map(
          (item) => ListTile(
            dense: true,
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => onRemove(item.id),
              tooltip: 'Remove',
            ),
          ),
        ),

        // Add action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextButton.icon(
            onPressed: onTapAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addTask),
          ),
        ),

        const Divider(height: 1),
      ],
    );
  }
}
