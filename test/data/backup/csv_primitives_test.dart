// Pure tests for the CSV encoding primitives (plan 04-08, Task 1): dialects,
// the injection guard, amount formatting and the BOM/CRLF table encoder.

import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvDialect', () {
    test(
      'en uses comma and dot, every other code uses semicolon and comma',
      () {
        expect(CsvDialect.forLanguage('en').delimiter, ',');
        expect(CsvDialect.forLanguage('en').decimalSeparator, '.');
        for (final code in ['pt', 'pt_BR', 'pt-BR', 'es', '']) {
          expect(CsvDialect.forLanguage(code).delimiter, ';');
          expect(CsvDialect.forLanguage(code).decimalSeparator, ',');
        }
      },
    );
  });

  group('formatCsvDate', () {
    test('local midnight is date-only', () {
      expect(formatCsvDate(DateTime(2026, 10, 12)), '2026-10-12');
    });

    test('other timestamps carry time and milliseconds', () {
      expect(
        formatCsvDate(DateTime(2026, 1, 2, 3, 4, 5, 6)),
        '2026-01-02T03:04:05.006',
      );
    });
  });

  group('CSV text guard', () {
    const hostile = [
      '=SUM(A1)',
      '+1',
      '-2',
      '@x',
      '\tx',
      '\rx',
      "'=x",
      "''=x",
      'plain',
      '',
      "'plain",
      "it's",
    ];

    test('neutralises formula leads with one apostrophe', () {
      expect(guardCsvText('=SUM(A1)'), "'=SUM(A1)");
      expect(guardCsvText('+1'), "'+1");
      expect(guardCsvText('-2'), "'-2");
      expect(guardCsvText('@x'), "'@x");
      expect(guardCsvText('\tx'), "'\tx");
      expect(guardCsvText('\rx'), "'\rx");
      expect(guardCsvText("'=x"), "''=x");
    });

    test('leaves harmless text alone', () {
      for (final s in ['plain', '', "'plain", "it's", 'a=b']) {
        expect(guardCsvText(s), s);
      }
    });

    test('guard then unguard is lossless for every input', () {
      for (final s in hostile) {
        expect(unguardCsvText(guardCsvText(s)), s, reason: 'input: "$s"');
      }
    });

    test('unguard leaves unguarded text alone', () {
      expect(unguardCsvText("'plain"), "'plain");
      expect(unguardCsvText('plain'), 'plain');
    });
  });

  group('formatAmountCell', () {
    test('plain digits, separator, two decimals', () {
      expect(formatAmountCell(125050, ','), '1250,50');
      expect(formatAmountCell(125050, '.'), '1250.50');
      expect(formatAmountCell(0, ','), '0,00');
      expect(formatAmountCell(5, ','), '0,05');
    });

    test('a negative keeps its minus sign', () {
      expect(formatAmountCell(-505, '.'), '-5.05');
    });
  });

  group('encodeCsvTable', () {
    test('PT dialect: BOM, semicolons, CRLF, quoting', () {
      final text = encodeCsvTable(
        header: ['a', 'b'],
        rows: [
          ['x;y "z"\nw', null],
          [1, true],
        ],
        dialect: CsvDialect.pt,
      );
      expect(text.startsWith(csvBom), isTrue);
      expect(csvBom.codeUnits, [0xFEFF]);
      final body = text.substring(1);
      expect(body, 'a;b\r\n"x;y ""z""\nw";\r\n1;true\r\n');
    });

    test('EN dialect uses commas and leaves semicolons unquoted', () {
      final text = encodeCsvTable(
        header: ['a', 'b'],
        rows: [
          ['x;y', 'p,q'],
        ],
        dialect: CsvDialect.en,
      );
      expect(text.substring(1), 'a,b\r\nx;y,"p,q"\r\n');
    });
  });
}
