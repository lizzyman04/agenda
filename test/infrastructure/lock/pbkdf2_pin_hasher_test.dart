import 'dart:convert';

import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/infrastructure/lock/pbkdf2_pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('pbkdf2HmacSha256', () {
    test('reproduces the RFC 7914 vector (passwd, salt, 1)', () {
      final out = pbkdf2HmacSha256(
        utf8.encode('passwd'),
        utf8.encode('salt'),
        1,
      );
      expect(
        _hex(out),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    test('reproduces the project vector (1234, 16 zero bytes, 10000)', () {
      final out = pbkdf2HmacSha256(
        utf8.encode('1234'),
        List<int>.filled(16, 0),
        10000,
      );
      expect(
        _hex(out),
        'e0b2a2774733c736d54c2aaddc7b90c3d15edc575c6ac20e011e58940866ba15',
      );
    });
  });

  group('constantTimeEquals', () {
    test('is true for equal input', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('is false when one byte differs', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    });

    test('is false for different lengths', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2]), isFalse);
    });
  });

  group('isValidPin', () {
    test('accepts exactly four ASCII digits only', () {
      expect(isValidPin('0000'), isTrue);
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin(''), isFalse);
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('12345'), isFalse);
      expect(isValidPin('12a4'), isFalse);
      expect(isValidPin('١٢٣٤'), isFalse); // Arabic-Indic digits
    });
  });

  group('Pbkdf2PinHasher', () {
    final hasher = Pbkdf2PinHasher();

    test('create then verify accepts the PIN and rejects another', () async {
      final record = await hasher.create('1234');
      expect(record.iterations, Pbkdf2PinHasher.iterations);
      expect(record.salt, hasLength(Pbkdf2PinHasher.saltLength));
      expect(record.hash, hasLength(PinRecord.hashLength));
      expect(await hasher.verify('1234', record), isTrue);
      expect(await hasher.verify('1235', record), isFalse);
    });

    test('create rejects an invalid PIN with ArgumentError', () {
      expect(() => hasher.create('123'), throwsArgumentError);
    });

    test('verify is false for a non-numeric PIN', () async {
      final record = await hasher.create('1234');
      expect(await hasher.verify('12a4', record), isFalse);
    });

    test('two creates of the same PIN draw different salts', () async {
      final a = await hasher.create('1234');
      final b = await hasher.create('1234');
      expect(a.salt, isNot(equals(b.salt)));
      expect(a.hash, isNot(equals(b.hash)));
    });
  });

  group('PinRecord', () {
    final record = PinRecord(
      iterations: 10000,
      salt: List<int>.filled(16, 7),
      hash: List<int>.filled(32, 9),
    );

    test('encode and tryDecode round trip', () {
      expect(record.encode(), startsWith('v1:10000:'));
      expect(PinRecord.tryDecode(record.encode()), record);
    });

    test('tryDecode rejects malformed input', () {
      final salt = base64.encode(List<int>.filled(16, 7));
      final hash = base64.encode(List<int>.filled(32, 9));
      final short = base64.encode(List<int>.filled(31, 9));
      for (final raw in <String?>[
        null,
        '',
        'v2:10000:$salt:$hash',
        'v1:0:$salt:$hash',
        'v1:x:$salt:$hash',
        'v1:10000:$salt:$short',
        'v1:10000:!!!:$hash',
        'v1:10000:$salt',
      ]) {
        expect(PinRecord.tryDecode(raw), isNull, reason: '$raw');
      }
    });

    test('toString never prints salt or hash', () {
      expect(record.toString(), isNot(contains('7')));
    });
  });
}
