import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatAmount', () {
    test(
      'PT-BR locale: 125000 cents with MT symbol returns "MT 1.250,00"',
      () {
        final result = formatAmount(125000, 'MT', const Locale('pt', 'BR'));
        expect(result, equals('MT 1.250,00'));
      },
    );

    test(
      'EN locale: 125000 cents with R\$ symbol returns "R\$ 1,250.00"',
      () {
        final result = formatAmount(125000, r'R$', const Locale('en'));
        expect(result, equals(r'R$ 1,250.00'));
      },
    );

    test(
      'PT-BR locale: 0 cents with MT symbol returns "MT 0,00"',
      () {
        final result = formatAmount(0, 'MT', const Locale('pt', 'BR'));
        expect(result, equals('MT 0,00'));
      },
    );

    test(
      'PT-BR locale: 100 cents (1 unit) with MT symbol returns "MT 1,00"',
      () {
        final result = formatAmount(100, 'MT', const Locale('pt', 'BR'));
        expect(result, equals('MT 1,00'));
      },
    );

    test(
      'EN locale: 100 cents (1 unit) with \$ symbol returns "\$ 1.00"',
      () {
        final result = formatAmount(100, r'$', const Locale('en'));
        expect(result, equals(r'$ 1.00'));
      },
    );
  });
}
