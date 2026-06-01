import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required VoidCallback onCta,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FinanceEmptyState(
          icon: Icons.receipt_long_outlined,
          heading: 'Nenhuma transação',
          body: 'Registre sua primeira receita ou despesa.',
          ctaLabel: 'Adicionar transação',
          onCta: onCta,
        ),
      ),
    );
  }

  testWidgets('renders icon', (tester) async {
    await tester.pumpWidget(buildSubject(onCta: () {}));

    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });

  testWidgets('renders heading text', (tester) async {
    await tester.pumpWidget(buildSubject(onCta: () {}));

    expect(find.text('Nenhuma transação'), findsOneWidget);
  });

  testWidgets('renders body text', (tester) async {
    await tester.pumpWidget(buildSubject(onCta: () {}));

    expect(
      find.text('Registre sua primeira receita ou despesa.'),
      findsOneWidget,
    );
  });

  testWidgets('renders FilledButton with ctaLabel', (tester) async {
    await tester.pumpWidget(buildSubject(onCta: () {}));

    expect(find.widgetWithText(FilledButton, 'Adicionar transação'),
        findsOneWidget);
  });

  testWidgets('calls onCta when FilledButton is tapped', (tester) async {
    var callCount = 0;

    await tester.pumpWidget(buildSubject(onCta: () => callCount++));
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar transação'));
    await tester.pump();

    expect(callCount, 1);
  });
}
