import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fireAt = DateTime.fromMillisecondsSinceEpoch(1760000000000);

  group('encodePayload', () {
    test('writes the v1 grammar with whole seconds', () {
      final raw = encodePayload(
        kind: NotificationKind.taskReminder,
        entityId: 42,
        fireAt: fireAt,
        exact: true,
      );
      expect(raw, 'v1|tk|42|1760000000|e');
    });

    test('inexact mode encodes i', () {
      final raw = encodePayload(
        kind: NotificationKind.debtReminder,
        entityId: 3,
        fireAt: fireAt,
        exact: false,
      );
      expect(raw, 'v1|db|3|1760000000|i');
    });
  });

  group('decodePayload', () {
    test('round-trips every kind and both modes', () {
      for (final kind in NotificationKind.values) {
        for (final exact in [true, false]) {
          final decoded = decodePayload(
            encodePayload(
              kind: kind,
              entityId: 42,
              fireAt: fireAt,
              exact: exact,
            ),
          );
          expect(decoded, isNotNull);
          expect(decoded!.kind, kind);
          expect(decoded.entityId, 42);
          expect(decoded.fireEpochSec, 1760000000);
          expect(decoded.exact, exact);
        }
      }
    });

    test('every malformed payload decodes to null without throwing', () {
      final malformed = <String?>[
        null,
        '',
        'v2|tk|1|1|e',
        'v1|zz|1|1|e',
        'v1|tk|abc|1|e',
        'v1|tk|-1|1|e',
        'v1|tk|1|-1|e',
        'v1|tk|+1|1|e',
        'v1|tk|1|1|x',
        'v1|tk|1|1|',
        'v1|tk|1|1',
        'v1|tk|1|1|e|extra',
        'v1|tk|99999999999999999999999|1|e',
        'v1|tk| 1|1|e',
        '|||||',
        List.filled(200, 'a').join(),
      ];
      for (final raw in malformed) {
        expect(decodePayload(raw), isNull, reason: 'payload: $raw');
      }
    });
  });
}
