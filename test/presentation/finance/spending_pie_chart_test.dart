import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/presentation/finance/widgets/spending_pie_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = <TransactionCategory>[
    TransactionCategory(
      id: 1,
      namePtBr: 'Alimentação',
      type: TransactionType.expense,
      isDefault: true,
      createdAt: DateTime(2026, 5),
    ),
  ];

  Widget buildSubject({
    required Map<int, int> categorySpend,
    String emptyChartMessage = 'Sem gastos',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SpendingPieChart(
          categorySpend: categorySpend,
          categories: categories,
          currencySymbol: 'MT',
          locale: const Locale('pt', 'BR'),
          emptyChartMessage: emptyChartMessage,
        ),
      ),
    );
  }

  testWidgets('empty categorySpend renders empty message, no PieChart',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(categorySpend: const {}, emptyChartMessage: 'Sem gastos'),
    );

    expect(find.byType(PieChart), findsNothing);
    expect(find.text('Sem gastos'), findsOneWidget);
  });

  testWidgets('one category renders a PieChart with one section value=100.0',
      (tester) async {
    await tester.pumpWidget(buildSubject(categorySpend: const {1: 10000}));

    expect(find.byType(PieChart), findsOneWidget);

    final pieChart = tester.widget<PieChart>(find.byType(PieChart));
    final sections = pieChart.data.sections;
    expect(sections.length, 1);
    expect(sections.first.value, 100.0);
  });

  testWidgets('legend below chart shows category name text', (tester) async {
    await tester.pumpWidget(buildSubject(categorySpend: const {1: 10000}));

    expect(find.textContaining('Alimentação'), findsOneWidget);
  });

  test('categoryColor wraps at palette length (index 0 == index 8)', () {
    expect(SpendingPieChart.categoryColor(0), const Color(0xFF1565C0));
    expect(SpendingPieChart.categoryColor(8), const Color(0xFF1565C0));
  });
}
