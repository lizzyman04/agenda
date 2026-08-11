import 'package:agenda/core/utils/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAmountCentsOrNull', () {
    test('comma-decimal input "12,50" returns 1250', () {
      expect(parseAmountCentsOrNull('12,50'), equals(1250));
    });

    test('plain-dot input "12.50" returns 1250 (EN-locale typed input)', () {
      expect(parseAmountCentsOrNull('12.50'), equals(1250));
    });

    // NOTE ON THIS CASE — deviation from the plan's stated expectation:
    //
    // The plan's <behavior> block asserted this case should return 125050
    // (treating '.' as a thousands separator and ',' as the decimal mark).
    // Verified against the *actual* duplicated inline logic present today in
    // all 4 finance forms (e.g. transaction_form_screen.dart lines 265-268):
    //   raw.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '')
    // For '1.250,50': replaceAll(',', '.') yields '1.250.50' (now with TWO
    // dots); the RegExp filter keeps digits and dots, so nothing is
    // stripped; double.tryParse('1.250.50') is invalid Dart double syntax
    // and returns null. The 4 forms do NOT actually support thousands
    // separators — inputting "1.250,50" today silently fails validation.
    // This function replicates that exact (undesirable but pre-existing)
    // behavior per the plan's own threat model (T-03.1-08-01): preserve the
    // exact behavior of the 4 existing inline implementations, not an
    // idealized re-design. See PLAN SUMMARY for full deviation note.
    test(
      'thousands-dot + comma-decimal "1.250,50" returns null '
      '(pre-existing quirk: two dots after comma->dot conversion is not a '
      'valid double, matching current app behavior exactly)',
      () {
        expect(parseAmountCentsOrNull('1.250,50'), isNull);
      },
    );

    test('empty string returns null', () {
      expect(parseAmountCentsOrNull(''), isNull);
    });

    test('"0" returns null (not strictly positive)', () {
      expect(parseAmountCentsOrNull('0'), isNull);
    });

    // NOTE ON THIS CASE — deviation from the plan's stated expectation:
    //
    // The plan's <behavior> block asserted '-5' should return null. The
    // actual existing inline logic strips the '-' character (the RegExp
    // filter only keeps digits and dots, '-' is not in that set), leaving
    // "5", which parses to a positive 5.0 and produces 500 cents. This
    // function replicates that exact pre-existing quirk rather than adding
    // a negative-number rejection that does not exist in today's 4 forms.
    test(
      '"-5" returns 500 (pre-existing quirk: the minus sign is stripped by '
      'the non-digit-non-dot filter before parsing, matching current app '
      'behavior exactly)',
      () {
        expect(parseAmountCentsOrNull('-5'), equals(500));
      },
    );

    test('garbage input "abc" returns null', () {
      expect(parseAmountCentsOrNull('abc'), isNull);
    });
  });

  group('formatCentsForInput', () {
    test('1250 returns "12,50"', () {
      expect(formatCentsForInput(1250), equals('12,50'));
    });

    test('0 returns "" (matches the existing cents > 0 ternary pattern)', () {
      expect(formatCentsForInput(0), equals(''));
    });
  });
}
