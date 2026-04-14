import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EisenhowerQuadrant — enum values', () {
    test('doNow value exists', () {
      expect(EisenhowerQuadrant.doNow, isA<EisenhowerQuadrant>());
    });

    test('schedule value exists', () {
      expect(EisenhowerQuadrant.schedule, isA<EisenhowerQuadrant>());
    });

    test('delegate value exists', () {
      expect(EisenhowerQuadrant.delegate, isA<EisenhowerQuadrant>());
    });

    test('eliminate value exists', () {
      expect(EisenhowerQuadrant.eliminate, isA<EisenhowerQuadrant>());
    });

    test('enum has exactly four values', () {
      expect(EisenhowerQuadrant.values.length, 4);
    });
  });
}
