import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/presentation/finance/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression suite for UAT test 2 — the duplicated-note half of the defect.
///
/// Before the fix, `TransactionCard` put `transaction.note ?? categoryName`
/// in the `ListTile` title AND repeated the same note in a `Chip` below the
/// subtitle, so a transaction with a note rendered that note twice on one
/// card. The subtitle additionally repeated the category as
/// `'$categoryName · $formattedDate'`, which is what put `#10` on screen
/// twice.
///
/// `'renders a note exactly once'` FAILS against the pre-fix widget: the
/// note resolves to `findsNWidgets(2)` there, not `findsOneWidget`.

Transaction _transaction({String? note}) => Transaction(
      id: 7,
      type: TransactionType.expense,
      amountCents: 120000,
      categoryId: 10,
      date: DateTime(2026, 8, 10),
      note: note,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

Widget _app({required Transaction transaction, required String categoryName}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    home: Scaffold(
      body: TransactionCard(
        transaction: transaction,
        categoryName: categoryName,
        currencySymbol: 'MT',
        locale: const Locale('pt', 'BR'),
        onDelete: () {},
        onTap: () {},
      ),
    ),
  );
}

void main() {
  group('TransactionCard', () {
    testWidgets('renders the category name as the title', (tester) async {
      await tester.pumpWidget(
        _app(
          transaction: _transaction(),
          categoryName: 'Alimentação',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alimentação'), findsOneWidget);
    });

    testWidgets('renders a note exactly once', (tester) async {
      await tester.pumpWidget(
        _app(
          transaction: _transaction(note: 'Mercado semana'),
          categoryName: 'Alimentação',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Mercado semana'),
        findsOneWidget,
        reason: 'the note belongs to the chip only — pre-fix it also '
            'occupied the ListTile title, making this findsNWidgets(2)',
      );
      expect(
        find.text('Alimentação'),
        findsOneWidget,
        reason: 'the category belongs to the title only — pre-fix the '
            'subtitle repeated it as "category · date"',
      );
    });

    testWidgets('renders no chip when the note is null', (tester) async {
      await tester.pumpWidget(
        _app(
          transaction: _transaction(),
          categoryName: 'Alimentação',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('renders no chip when the note is whitespace', (tester) async {
      await tester.pumpWidget(
        _app(
          transaction: _transaction(note: '   '),
          categoryName: 'Alimentação',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });
  });
}
