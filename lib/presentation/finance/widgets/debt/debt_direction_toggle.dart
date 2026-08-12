import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';

/// Direction toggle card ("to pay" / "to receive") for the debt form.
class DebtDirectionToggle extends StatelessWidget {
  const DebtDirectionToggle({
    required this.direction,
    required this.onChanged,
    super.key,
  });

  final DebtDirection direction;
  final ValueChanged<DebtDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SegmentedButton<DebtDirection>(
          segments: [
            ButtonSegment(
              value: DebtDirection.toPay,
              label: Text(l10n.toPay),
              icon: const Icon(Icons.arrow_upward),
            ),
            ButtonSegment(
              value: DebtDirection.toReceive,
              label: Text(l10n.toReceive),
              icon: const Icon(Icons.arrow_downward),
            ),
          ],
          selected: {direction},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}
