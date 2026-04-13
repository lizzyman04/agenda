import 'package:agenda/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders AGENDA text', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    expect(find.text('AGENDA'), findsOneWidget);
  });
}
