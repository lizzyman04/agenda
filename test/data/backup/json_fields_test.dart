import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _formatErrorAt(String path) => throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        startsWith(path),
      ),
    );

void main() {
  JsonObjectReader reader(Map<String, Object?> m, [String path = 'items[3]']) =>
      JsonObjectReader(m, path);

  group('JsonObjectReader strictness', () {
    test('reads a valid object back', () {
      final r = reader({
        'n': 7,
        's': 'hi',
        'b': true,
        'd': 1.5,
        'i': 2,
        'when': '2026-10-12T10:00:00.000Z',
        'e': 'task',
        'obj': {'x': 1},
        'list': [
          {'y': 2},
        ],
      });
      expect(r.requireInt('n'), 7);
      expect(r.requireString('s'), 'hi');
      expect(r.requireBool('b'), isTrue);
      expect(r.requireDouble('d'), 1.5);
      expect(r.requireDouble('i'), 2.0);
      expect(r.requireDate('when').isAtSameMomentAs(
        DateTime.utc(2026, 10, 12, 10),
      ), isTrue);
      expect(r.requireEnum('e', ItemType.values), ItemType.task);
      expect(r.optObject('obj')!.requireInt('x'), 1);
      expect(r.optObject('missing'), isNull);
      expect(r.requireList('list').single.requireInt('y'), 2);
      expect(r.optInt('nope'), isNull);
      expect(r.optString('nope'), isNull);
    });

    test('wrong-type int names the field path', () {
      expect(() => reader({'n': 'x'}).requireInt('n'),
          _formatErrorAt('items[3].n'));
    });

    test('a double is rejected for an int field', () {
      expect(() => reader({'n': 1.5}).requireInt('n'),
          _formatErrorAt('items[3].n'));
    });

    test('an int beyond the safe bound is rejected', () {
      expect(() => reader({'n': 9000000000000001}).requireInt('n'),
          _formatErrorAt('items[3].n'));
    });

    test('a string over the length cap is rejected', () {
      final r = reader({'s': 'a' * (maxJsonStringLength + 1)});
      expect(() => r.requireString('s'), _formatErrorAt('items[3].s'));
      expect(reader({'s': 'a' * maxJsonStringLength}).requireString('s'),
          hasLength(maxJsonStringLength));
    });

    test('an unknown enum name is rejected', () {
      expect(() => reader({'e': 'nope'}).requireEnum('e', ItemType.values),
          _formatErrorAt('items[3].e'));
    });

    test('a bad date string is rejected', () {
      expect(() => reader({'d': 'not a date'}).requireDate('d'),
          _formatErrorAt('items[3].d'));
    });

    test('a missing required key is rejected', () {
      expect(() => reader({}).requireString('title'),
          _formatErrorAt('items[3].title'));
    });

    test('a non-object list element carries an indexed path', () {
      final r = reader({'list': [1]}, 'goals[0]');
      expect(() => r.requireList('list'), _formatErrorAt('goals[0].list[0]'));
    });

    test('a root reader omits the path prefix', () {
      expect(() => JsonObjectReader.fromObject(null),
          _formatErrorAt('root'));
      expect(() => JsonObjectReader({}).requireInt('n'), _formatErrorAt('n'));
    });
  });

  test('encodeJsonDate round-trips through requireDate', () {
    final d = DateTime(2026, 10, 12, 9, 30, 15, 123, 456);
    final r = reader({'d': encodeJsonDate(d)});
    expect(r.requireDate('d').isAtSameMomentAs(d), isTrue);
    expect(encodeJsonDateOrNull(null), isNull);
  });
}
