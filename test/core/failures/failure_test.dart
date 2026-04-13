import 'package:flutter_test/flutter_test.dart';

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';

void main() {
  group('Failure hierarchy', () {
    test('DatabaseFailure carries message', () {
      const f = DatabaseFailure('connection lost');
      expect(f.message, 'connection lost');
      expect(f, isA<Failure>());
    });

    test('ValidationFailure carries message', () {
      const f = ValidationFailure('title is required');
      expect(f.message, 'title is required');
      expect(f, isA<Failure>());
    });

    test('NotificationFailure carries message', () {
      const f = NotificationFailure('permission denied');
      expect(f.message, 'permission denied');
      expect(f, isA<Failure>());
    });

    test('BackupFailure carries message', () {
      const f = BackupFailure('file not found');
      expect(f.message, 'file not found');
      expect(f, isA<Failure>());
    });

    test('SecurityFailure carries message', () {
      const f = SecurityFailure('PIN mismatch');
      expect(f.message, 'PIN mismatch');
      expect(f, isA<Failure>());
    });

    test('Failure subtypes are distinct types', () {
      const db = DatabaseFailure('x');
      const val = ValidationFailure('x');
      expect(db, isNot(isA<ValidationFailure>()));
      expect(val, isNot(isA<DatabaseFailure>()));
    });
  });

  group('Result pattern matching', () {
    test('Success wraps value', () {
      const result = Success(42);
      expect(result.value, 42);
    });

    test('Err wraps failure', () {
      const result = Err<int>(DatabaseFailure('oops'));
      expect(result.failure, isA<DatabaseFailure>());
      expect((result.failure as DatabaseFailure).message, 'oops');
    });

    test('switch on result dispatches correctly', () {
      // ignore: prefer_const_constructors — intentional runtime test
      final Object result = Success(99);
      var dispatched = false;

      switch (result) {
        case Success(:final value):
          expect(value, 99);
          dispatched = true;
        case Err(:final failure):
          fail('Should not reach Err branch, got: $failure');
      }

      expect(dispatched, isTrue);
    });
  });
}
