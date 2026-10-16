/// Longest string value a backup field may carry (T-04-04-03).
const int maxJsonStringLength = 20000;

/// Largest integer magnitude a backup field may carry. Keeps values well
/// inside the range every JSON consumer represents exactly.
const int _maxJsonInt = 9000000000000000;

/// Encodes [d] as an ISO-8601 UTC string.
String encodeJsonDate(DateTime d) => d.toUtc().toIso8601String();

/// Null-passthrough variant of [encodeJsonDate].
String? encodeJsonDateOrNull(DateTime? d) =>
    d == null ? null : encodeJsonDate(d);

/// Strict, path-aware reader over one decoded JSON object.
///
/// Every violation (wrong type, out-of-range number, over-long string,
/// unknown enum name, bad date, missing required key) throws a
/// [FormatException] whose message starts with the full field path, for
/// example `items[3].dueDate`. Nothing is coerced: an `int` field must be an
/// int, never a double or a numeric string.
final class JsonObjectReader {
  JsonObjectReader(this._map, [this.path = '']);

  /// Wraps a decoded top-level value, rejecting anything but an object.
  factory JsonObjectReader.fromObject(Object? value, [String path = '']) {
    if (value is Map) {
      return JsonObjectReader(Map<String, Object?>.from(value), path);
    }
    final where = path.isEmpty ? 'root' : path;
    throw FormatException('$where: expected an object');
  }

  final Map<String, Object?> _map;

  /// Location of this object inside the document, empty at the root.
  final String path;

  /// Keys present in this object.
  Iterable<String> get keys => _map.keys;

  /// Same object with an empty path, so child paths omit this prefix.
  JsonObjectReader get rooted => JsonObjectReader(_map);

  String _at(String key) => path.isEmpty ? key : '$path.$key';

  Never _fail(String key, String problem) =>
      throw FormatException('${_at(key)}: $problem');

  Object _required(String key) {
    final v = _map[key];
    if (v == null) _fail(key, 'required value is missing');
    return v;
  }

  int requireInt(String key) {
    final v = _required(key);
    if (v is! int) _fail(key, 'expected an integer');
    if (v.abs() > _maxJsonInt) _fail(key, 'integer out of range');
    return v;
  }

  int? optInt(String key) => _map[key] == null ? null : requireInt(key);

  String requireString(String key) {
    final v = _required(key);
    if (v is! String) _fail(key, 'expected a string');
    if (v.length > maxJsonStringLength) _fail(key, 'string too long');
    return v;
  }

  String? optString(String key) =>
      _map[key] == null ? null : requireString(key);

  bool requireBool(String key) {
    final v = _required(key);
    if (v is! bool) _fail(key, 'expected a boolean');
    return v;
  }

  /// Accepts a JSON int or double.
  double requireDouble(String key) {
    final v = _required(key);
    if (v is! num) _fail(key, 'expected a number');
    if (!v.isFinite) _fail(key, 'number out of range');
    return v.toDouble();
  }

  double? optDouble(String key) =>
      _map[key] == null ? null : requireDouble(key);

  DateTime requireDate(String key) {
    final parsed = DateTime.tryParse(requireString(key));
    if (parsed == null) _fail(key, 'expected an ISO-8601 date');
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  DateTime? optDate(String key) => _map[key] == null ? null : requireDate(key);

  /// Matches [values] by `name`; an unknown name is rejected.
  T requireEnum<T extends Enum>(String key, List<T> values) {
    final match = values.asNameMap()[requireString(key)];
    if (match == null) _fail(key, 'unknown value');
    return match;
  }

  /// Nested object, or null when absent or null.
  JsonObjectReader? optObject(String key) =>
      _map[key] == null ? null : requireObject(key);

  JsonObjectReader requireObject(String key) =>
      JsonObjectReader.fromObject(_required(key), _at(key));

  /// List of nested objects; each element must itself be an object.
  List<JsonObjectReader> requireList(String key) {
    final v = _required(key);
    if (v is! List) _fail(key, 'expected a list');
    return [
      for (var i = 0; i < v.length; i++)
        JsonObjectReader.fromObject(v[i], '${_at(key)}[$i]'),
    ];
  }
}
