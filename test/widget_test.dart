import 'package:agenda/app.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('App renders AGENDA text', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    expect(find.text('AGENDA'), findsOneWidget);
  });
}
