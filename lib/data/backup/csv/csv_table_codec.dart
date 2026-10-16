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

/// Largest number of data rows [decodeCsvTable] accepts (T-04-08-02).
const int maxCsvDataRows = 100000;

/// A decoded CSV file: lower-cased header names and string cells.
///
/// Spreadsheet convention: the header is row 1, so `rows[i]` is row `i + 2`.
final class CsvTable {
  const CsvTable({required this.header, required this.rows});

  final List<String> header;
  final List<List<String>> rows;
}

const List<String> _sniffDelimiters = [';', ',', '\t'];
final RegExp _headerToken = RegExp(r'^[a-z_]+$');

List<String> _tokens(String line, String delimiter) => [
  for (final t in line.split(delimiter))
    t.replaceAll('"', '').trim().toLowerCase(),
];

// Picks the delimiter that splits the header row into 2+ canonical names.
String? _sniffDelimiter(String headerLine) {
  for (final d in _sniffDelimiters) {
    final tokens = _tokens(headerLine, d);
    if (tokens.length >= 2 && tokens.every(_headerToken.hasMatch)) return d;
  }
  return null;
}

/// Decodes [text] strictly: strips the BOM, sniffs the delimiter from the
/// header row, keeps every cell a String and rejects ragged rows.
///
/// Throws [FormatException] for empty input, an unrecognisable header, a row
/// whose cell count differs from the header (message names the row), or more
/// than [maxCsvDataRows] data rows.
CsvTable decodeCsvTable(String text) {
  final body = text.startsWith(csvBom) ? text.substring(1) : text;
  if (body.trim().isEmpty) throw const FormatException('the file is empty');
  final firstLine = body.trimLeft().split('\n').first.trimRight();
  final delimiter = _sniffDelimiter(firstLine);
  if (delimiter == null) {
    throw const FormatException('row 1: the header row is not recognised');
  }
  final records = Csv(
    fieldDelimiter: delimiter,
    autoDetect: false,
  ).decode(body);
  if (records.length - 1 > maxCsvDataRows) {
    throw const FormatException('too many rows');
  }
  final header = _tokens(firstLine, delimiter);
  final rows = <List<String>>[];
  for (var i = 1; i < records.length; i++) {
    final cells = [for (final c in records[i]) c?.toString() ?? ''];
    if (cells.length != header.length) {
      throw FormatException(
        'row ${i + 1}: expected ${header.length} cells, found ${cells.length}',
      );
    }
    rows.add(cells);
  }
  return CsvTable(header: header, rows: rows);
}
