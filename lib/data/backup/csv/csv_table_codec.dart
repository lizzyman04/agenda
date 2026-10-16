import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:csv/csv.dart';

/// Encodes [header] and [rows] as one CSV document: BOM first, the dialect's
/// field delimiter, CRLF record separators.
///
/// Every cell is written as a String (null becomes empty); the csv package
/// performs no type conversion, and quotes any field holding the delimiter,
/// a quote, a CR or LF, or leading/trailing space.
String encodeCsvTable({
  required List<String> header,
  required List<List<Object?>> rows,
  required CsvDialect dialect,
}) {
  final codec = Csv(
    fieldDelimiter: dialect.delimiter,
    autoDetect: false,
  );
  final table = <List<String>>[
    header,
    for (final row in rows) [for (final cell in row) cell?.toString() ?? ''],
  ];
  return '$csvBom${codec.encode(table)}$csvLineDelimiter';
}
