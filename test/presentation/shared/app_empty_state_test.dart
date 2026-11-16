import 'package:agenda/presentation/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({String? ctaLabel, VoidCallback? onCta}) {
    return MaterialApp(
      home: Scaffold(
        body: AppEmptyState(
          icon: Icons.inbox_outlined,
          heading: 'Nothing here',
          body: 'Add your first entry.',
          ctaLabel: ctaLabel,
          onCta: onCta,
        ),
      ),
    );
  }

  testWidgets('renders the icon at size 72 in onSurfaceVariant',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
    final cs = Theme.of(tester.element(find.byType(AppEmptyState)))
        .colorScheme;
    expect(icon.size, 72);
    expect(icon.color, cs.onSurfaceVariant);
  });

  testWidgets('renders heading and body text', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add your first entry.'), findsOneWidget);
  });

  testWidgets('pads horizontally by 32', (tester) async {
    await tester.pumpWidget(buildSubject());

    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(AppEmptyState),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, const EdgeInsets.symmetric(horizontal: 32));
  });

  testWidgets('renders no CTA when neither CTA arg is given', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders no CTA when only ctaLabel is given', (tester) async {
    await tester.pumpWidget(buildSubject(ctaLabel: 'Add'));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders no CTA when only onCta is given', (tester) async {
    await tester.pumpWidget(buildSubject(onCta: () {}));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders the CTA and calls onCta when tapped', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      buildSubject(ctaLabel: 'Add', onCta: () => calls++),
    );

    final button = find.widgetWithText(FilledButton, 'Add');
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump();

    expect(calls, 1);
  });
}
